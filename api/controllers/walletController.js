const { pool } = require('../config/database');

/// Controller untuk manajemen wallet / saldo member
/// Endpoints: GET /wallet/my, GET /wallet/my/history, POST /wallet/extend
/// Semua endpoint dilindungi auth middleware (token wajib)

// ─── GET /wallet/my ───────────────────────────────────────────────────────────
// Ambil saldo wallet user yang sedang login
const getMyWallet = async (req, res) => {
    try {
        const userId = req.user.userId;

        // Upsert: buat row wallet jika belum ada
        await pool.query(
            'INSERT INTO wallets (user_id, saldo) VALUES (?, 0) ON DUPLICATE KEY UPDATE user_id = user_id',
            [userId]
        );

        const [[wallet]] = await pool.query(
            'SELECT user_id, saldo, updated_at FROM wallets WHERE user_id = ?',
            [userId]
        );

        res.json({
            success: true,
            data: {
                user_id: wallet.user_id,
                saldo: parseFloat(wallet.saldo) || 0,
                updated_at: wallet.updated_at
            }
        });
    } catch (error) {
        console.error('getMyWallet error:', error);
        res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
    }
};

// ─── GET /wallet/my/history ───────────────────────────────────────────────────
// Ambil riwayat transaksi wallet user yang sedang login
const getMyWalletHistory = async (req, res) => {
    try {
        const userId = req.user.userId;

        const [rows] = await pool.query(
            `SELECT id, jenis, jumlah, saldo_awal, saldo_akhir, keterangan, created_at
             FROM wallet_transactions
             WHERE user_id = ?
             ORDER BY created_at DESC
             LIMIT 100`,
            [userId]
        );

        res.json({ success: true, data: rows });
    } catch (error) {
        console.error('getMyWalletHistory error:', error);
        res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
    }
};

// ─── POST /wallet/extend ──────────────────────────────────────────────────────
// Perpanjang membership menggunakan saldo wallet
const extendWithWallet = async (req, res) => {
    const connection = await pool.getConnection();
    let transactionStarted = false;

    try {
        const userId = req.user.userId;
        const { package_id: packageId, promo_id } = req.body;

        if (!packageId) {
            return res.status(400).json({
                success: false,
                message: 'package_id wajib diisi'
            });
        }

        // Ambil info paket dari packages.json
        const fs = require('fs');
        const path = require('path');
        let selectedPackage = null;
        try {
            const pkgPath = path.join(__dirname, '../config/packages.json');
            const list = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));

            // Coba match berdasarkan: slug, id, harga (fallback jika Flutter kirim sortValue=harga)
            const pkgStr = String(packageId).toLowerCase().trim();
            selectedPackage =
                list.find(p => p.slug === pkgStr) ||
                list.find(p => String(p.id) === pkgStr) ||
                list.find(p => String(p.harga) === pkgStr) ||
                list.find(p => (p.nama || '').toLowerCase().includes(pkgStr));

            console.log(`[extendWithWallet] package_id="${packageId}" → found: ${selectedPackage?.nama || 'NULL'}`);
        } catch (e) {
            console.error('Error reading packages.json:', e);
        }

        if (!selectedPackage) {
            return res.status(400).json({
                success: false,
                message: 'Paket tidak ditemukan'
            });
        }

        const hargaAsli = Number(selectedPackage.harga);
        const durasi = Number(selectedPackage.durasi);

        // ── Validasi promo & hitung harga akhir ──────────────────────────────
        let harga = hargaAsli;
        let appliedDiskon = 0;
        let appliedPromoId = null;

        if (promo_id) {
            const [promoRows] = await connection.query(
                `SELECT id, judul, diskon_persen FROM promos
                 WHERE id = ? AND is_active = TRUE
                   AND tanggal_mulai <= CURDATE() AND tanggal_berakhir >= CURDATE()
                 LIMIT 1`,
                [promo_id]
            );

            if (promoRows.length === 0) {
                return res.status(400).json({
                    success: false,
                    message: 'Promo tidak valid atau sudah kedaluwarsa'
                });
            }

            const promo = promoRows[0];
            appliedDiskon = Number(promo.diskon_persen) || 0;
            appliedPromoId = promo.id;
            // Gunakan Math.floor agar konsisten dengan Flutter (~/ 100)
            harga = Math.floor(hargaAsli * (100 - appliedDiskon) / 100);

            console.log(`[extendWithWallet] promo_id=${appliedPromoId} diskon=${appliedDiskon}% harga_asli=${hargaAsli} harga_final=${harga}`);
        }

        // Cek saldo — lock row untuk mencegah race condition
        await connection.query(
            'INSERT INTO wallets (user_id, saldo) VALUES (?, 0) ON DUPLICATE KEY UPDATE user_id = user_id',
            [userId]
        );
        const [[wallet]] = await connection.query(
            'SELECT saldo FROM wallets WHERE user_id = ? FOR UPDATE',
            [userId]
        );

        if (!wallet || parseFloat(wallet.saldo) < harga) {
            const saldoAda = parseFloat(wallet?.saldo || 0);
            return res.status(400).json({
                success: false,
                message: `Saldo tidak cukup. Saldo: Rp ${saldoAda.toLocaleString('id-ID')}, Harga: Rp ${harga.toLocaleString('id-ID')}`
            });
        }

        const saldoAwal = parseFloat(wallet.saldo);
        const saldoAkhir = saldoAwal - harga;

        // Hitung tanggal membership
        const [currentMemberships] = await connection.query(
            'SELECT * FROM memberships WHERE user_id = ? AND status IN ("active","pending") ORDER BY tanggal_berakhir DESC LIMIT 1',
            [userId]
        );

        let tanggalMulai = new Date();
        if (currentMemberships.length > 0) {
            const currentEnd = new Date(currentMemberships[0].tanggal_berakhir);
            if (currentEnd > tanggalMulai) tanggalMulai = new Date(currentEnd);
        }

        const tanggalBerakhir = new Date(tanggalMulai);
        if (durasi === 0) {
            // Paket harian habis di penghujung hari yang sama
            tanggalBerakhir.setHours(23, 59, 59, 999);
        } else {
            tanggalBerakhir.setDate(tanggalBerakhir.getDate() + durasi);
        }

        await connection.beginTransaction();
        transactionStarted = true;

        // Buat membership baru dengan status 'active' langsung
        const [membershipResult] = await connection.query(
            `INSERT INTO memberships (user_id, paket, tanggal_mulai, tanggal_berakhir, status)
             VALUES (?, ?, ?, ?, 'active')`,
            [userId, selectedPackage.slug || packageId, tanggalMulai, tanggalBerakhir]
        );
        const membershipId = membershipResult.insertId;

        // Aktifkan kartu member
        await connection.query(
            'UPDATE member_cards SET is_active = TRUE WHERE user_id = ?',
            [userId]
        );

        // Catat transaksi — simpan jumlah SETELAH diskon
        const orderId = `WALLET-${Date.now()}-${userId}`;
        const keteranganTx = appliedDiskon > 0
            ? `Membership ${selectedPackage.nama} (Diskon ${appliedDiskon}%) via saldo`
            : `Membership ${selectedPackage.nama} via saldo`;

        await connection.query(
            `INSERT INTO transactions (user_id, membership_id, jenis_transaksi, jumlah, metode_pembayaran, status, order_id)
             VALUES (?, ?, 'membership', ?, 'wallet', 'success', ?)`,
            [userId, membershipId, harga, orderId]
        );

        // Kurangi saldo wallet
        await connection.query(
            'UPDATE wallets SET saldo = ? WHERE user_id = ?',
            [saldoAkhir, userId]
        );

        // Catat wallet_transaction
        await connection.query(
            `INSERT INTO wallet_transactions (user_id, jenis, jumlah, saldo_awal, saldo_akhir, keterangan)
             VALUES (?, 'debit', ?, ?, ?, ?)`,
            [userId, harga, saldoAwal, saldoAkhir,
             `${keteranganTx} (${orderId})`]
        );

        await connection.commit();
        transactionStarted = false;

        console.log(`[extendWithWallet] ✅ user=${userId} paket=${selectedPackage.nama} harga=${harga} saldo_akhir=${saldoAkhir}`);

        res.json({
            success: true,
            message: `Membership ${selectedPackage.nama} berhasil diperpanjang hingga ${tanggalBerakhir.toLocaleDateString('id-ID')}`,
            data: {
                membership_id: membershipId,
                tanggal_mulai: tanggalMulai,
                tanggal_berakhir: tanggalBerakhir,
                harga_dibayar: harga,
                diskon_applied: appliedDiskon,
                saldo_sekarang: saldoAkhir,
                order_id: orderId
            }
        });
    } catch (error) {
        if (transactionStarted) {
            try { await connection.rollback(); } catch (_) {}
        }
        console.error('extendWithWallet error:', error);
        res.status(500).json({ success: false, message: error.message || 'Terjadi kesalahan server' });
    } finally {
        connection.release();
    }
};

module.exports = { getMyWallet, getMyWalletHistory, extendWithWallet };
