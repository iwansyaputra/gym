const { pool } = require('../config/database');
const { esmartlinkRequest, verifyCallbackSignature } = require('../config/esmartlink');
const fs = require('fs');
const path = require('path');

const getMembershipPackages = () => {
    try {
        const pkgPath = path.join(__dirname, '../config/packages.json');
        const data = fs.readFileSync(pkgPath, 'utf8');
        const list = JSON.parse(data);
        const map = {};
        for (const p of list) {
            map[p.slug] = { durasi: p.durasi, price: p.harga, nama: p.nama };
        }
        return map;
    } catch (e) {
        console.error('Error reading packages in paymentController:', e);
        return {
            bulanan: { durasi: 30, price: 175000, nama: 'Paket Bulanan' },
            '3bulan': { durasi: 90, price: 472500, nama: 'Paket 3 Bulan' }
        };
    }
};

const mapGatewayStatusToLocal = (status = '') => {
    const normalized = String(status).toUpperCase();

    if (normalized === 'SUCCESS' || normalized === 'PAID') {
        return 'success';
    }

    if (normalized === 'PENDING' || normalized === 'PROCESS') {
        return 'pending';
    }

    if (normalized === 'FAILED' || normalized === 'CANCELED' || normalized === 'EXPIRED') {
        return 'failed';
    }

    return 'pending';
};

const syncMembershipByTransactionStatus = async (connection, transaction, status) => {
    if (!transaction.membership_id) {
        return;
    }

    if (status === 'success') {
        await connection.query('UPDATE memberships SET status = "active" WHERE id = ?', [transaction.membership_id]);
        await connection.query('UPDATE member_cards SET is_active = TRUE WHERE user_id = ?', [transaction.user_id]);
        return;
    }

    if (status === 'failed') {
        await connection.query('UPDATE memberships SET status = "expired" WHERE id = ?', [transaction.membership_id]);
    }
};

const parseGatewayReference = (rawReference) => {
    if (!rawReference) {
        return null;
    }

    try {
        const parsed = JSON.parse(rawReference);
        return parsed.transaction_id || null;
    } catch (error) {
        return rawReference;
    }
};

const createPayment = async (req, res) => {
    const connection = await pool.getConnection();
    let transactionStarted = false;

    try {
        const { paket, harga } = req.body;
        const userId = req.user.userId;

        if (!paket || !harga) {
            return res.status(400).json({
                success: false,
                message: 'Paket dan harga harus diisi'
            });
        }

        const normalizedPaket = String(paket).toLowerCase();
        const packagesMap = getMembershipPackages();
        const selectedPackage = packagesMap[normalizedPaket];
        if (!selectedPackage) {
            return res.status(400).json({
                success: false,
                message: 'Paket tidak valid. Gunakan nama paket yang tersedia (bulanan, 3bulan, tahunan, dll).'
            });
        }

        const clientHarga = Number(harga);
        if (!Number.isFinite(clientHarga) || clientHarga <= 0) {
            return res.status(400).json({
                success: false,
                message: 'Harga harus berupa angka lebih dari 0'
            });
        }

        if (clientHarga !== selectedPackage.price) {
            return res.status(400).json({
                success: false,
                message: `Harga paket ${normalizedPaket} tidak sesuai`
            });
        }

        const numericHarga = selectedPackage.price;

        const [users] = await connection.query('SELECT * FROM users WHERE id = ?', [userId]);
        if (users.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'User tidak ditemukan'
            });
        }

        const user = users[0];
        const orderId = `GYM-${Date.now()}-${userId}`;
        // Retrieve current active membership to accumulate correctly
        const [currentMemberships] = await connection.query(
            'SELECT * FROM memberships WHERE user_id = ? AND status IN ("active", "pending") ORDER BY tanggal_berakhir DESC LIMIT 1',
            [userId]
        );

        let tanggalMulai = new Date();
        if (currentMemberships.length > 0) {
            const currentEnd = new Date(currentMemberships[0].tanggal_berakhir);
            if (currentEnd > tanggalMulai) {
                // Member masih aktif, mulai dari masa aktif terakhir
                tanggalMulai = new Date(currentEnd);
            }
        }

        const tanggalBerakhir = new Date(tanggalMulai);
        tanggalBerakhir.setDate(tanggalBerakhir.getDate() + selectedPackage.durasi);

        await connection.beginTransaction();
        transactionStarted = true;

        const [membershipResult] = await connection.query(
            `INSERT INTO memberships (user_id, paket, tanggal_mulai, tanggal_berakhir, status)
             VALUES (?, ?, ?, ?, 'pending')`,
            [userId, normalizedPaket, tanggalMulai, tanggalBerakhir]
        );
        const membershipId = membershipResult.insertId;

        const [transactionResult] = await connection.query(
            `INSERT INTO transactions (user_id, membership_id, jenis_transaksi, jumlah, metode_pembayaran, status, order_id)
             VALUES (?, ?, 'membership', ?, 'esmartlink', 'pending', ?)`,
            [userId, membershipId, numericHarga, orderId]
        );
        const transactionId = transactionResult.insertId;

        const backendPublicUrl =
            process.env.BACKEND_PUBLIC_URL ||
            process.env.FRONTEND_URL ||
            `http://localhost:${process.env.PORT || 3000}`;

        const requestBody = {
            order_id: orderId,
            amount: numericHarga,
            description: `Pembayaran membership ${normalizedPaket}`,
            customer: {
                name: user.nama,
                email: user.email,
                phone: user.hp || '-'
            },
            item: [
                {
                    name: `Membership ${normalizedPaket}`,
                    amount: numericHarga,
                    qty: 1
                }
            ],
            channel: [process.env.ESMARTLINK_CHANNEL || 'VA_CIMB'],
            type: 'payment-page',
            payment_mode: process.env.ESMARTLINK_PAYMENT_MODE || 'CLOSE',
            expired_time: process.env.ESMARTLINK_EXPIRED_TIME || '',
            callback_url: `${backendPublicUrl}/api/payment/notification`,
            success_redirect_url: `${backendPublicUrl}/api/payment/finish`,
            failed_redirect_url: `${backendPublicUrl}/api/payment/error`,
            return_url: `${backendPublicUrl}/api/payment/pending`
        };

        const gatewayResponse = await esmartlinkRequest({
            method: 'POST',
            path: '/api/payment/create-order',
            body: requestBody
        });

        const gatewayData = gatewayResponse?.data || {};
        const gatewayTransactionId = gatewayData.transaction_id || null;
        const paymentUrl = gatewayData.payment_url || null;

        if (!paymentUrl) {
            throw new Error('Payment URL dari E-Smartlink tidak ditemukan');
        }

        await connection.query(
            'UPDATE transactions SET bukti_pembayaran = ? WHERE id = ?',
            [JSON.stringify({ gateway: 'esmartlink', transaction_id: gatewayTransactionId }), transactionId]
        );

        await connection.commit();
        transactionStarted = false;

        console.log('[E-Smartlink] Create Order Success');
        console.log(`  order_id       : ${orderId}`);
        console.log(`  transaction_id : ${gatewayTransactionId || '-'}`);
        console.log(`  payment_url    : ${paymentUrl}`);

        res.json({
            success: true,
                message: 'Link pembayaran berhasil dibuat',
            data: {
                order_id: orderId,
                transaction_id: gatewayTransactionId,
                payment_url: paymentUrl,
                membership_id: membershipId
            }
        });
    } catch (error) {
        if (transactionStarted) {
            await connection.rollback();
        }
        console.error('Create payment (E-Smartlink) error:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Terjadi kesalahan pada server'
        });
    } finally {
        connection.release();
    }
};

const handleNotification = async (req, res) => {
    const connection = await pool.getConnection();
    let transactionStarted = false;

    try {
        const callbackData = req.body?.data || req.body || {};
        const orderId = callbackData.order_id;

        if (!orderId) {
            return res.status(400).json({
                success: false,
                message: 'order_id tidak ditemukan di payload callback'
            });
        }

        if (!verifyCallbackSignature(callbackData)) {
            return res.status(401).json({
                success: false,
                message: 'Signature callback tidak valid'
            });
        }

        const [transactions] = await connection.query('SELECT * FROM transactions WHERE order_id = ?', [orderId]);
        if (transactions.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Transaksi tidak ditemukan'
            });
        }

        const transaction = transactions[0];
        const newStatus = mapGatewayStatusToLocal(callbackData.status);

        await connection.beginTransaction();
        transactionStarted = true;
        await connection.query('UPDATE transactions SET status = ?, bukti_pembayaran = ? WHERE order_id = ?', [
            newStatus,
            JSON.stringify({
                gateway: 'esmartlink',
                transaction_id: callbackData.transaction_id || parseGatewayReference(transaction.bukti_pembayaran),
                payment_code: callbackData.payment_code || null,
                raw_status: callbackData.status || null
            }),
            orderId
        ]);

        // Handle berdasarkan jenis transaksi
        if (transaction.jenis_transaksi === 'topup_saldo' && newStatus === 'success') {
            // Kredit saldo ke wallet user
            const jumlah = Number(transaction.jumlah);
            const userId = transaction.user_id;

            // Pastikan baris wallet ada
            await connection.query(
                'INSERT INTO wallets (user_id, saldo) VALUES (?, 0) ON DUPLICATE KEY UPDATE user_id = user_id',
                [userId]
            );
            const [[wallet]] = await connection.query(
                'SELECT saldo FROM wallets WHERE user_id = ? FOR UPDATE',
                [userId]
            );
            const saldoAwal = parseFloat(wallet.saldo) || 0;
            const saldoAkhir = saldoAwal + jumlah;

            await connection.query(
                'UPDATE wallets SET saldo = ? WHERE user_id = ?',
                [saldoAkhir, userId]
            );
            await connection.query(
                `INSERT INTO wallet_transactions (user_id, jenis, jumlah, saldo_awal, saldo_akhir, keterangan, ref_id)
                 VALUES (?, 'topup', ?, ?, ?, 'Top up via E-Smartlink', ?)`,
                [userId, jumlah, saldoAwal, saldoAkhir, transaction.id]
            );
            console.log(`[Wallet] Top up saldo berhasil: user_id=${userId}, jumlah=${jumlah}, saldo_akhir=${saldoAkhir}`);
        } else {
            // Transaksi membership biasa
            await syncMembershipByTransactionStatus(connection, transaction, newStatus);
        }

        await connection.commit();
        transactionStarted = false;

        res.json({
            success: true,
            message: 'Notification processed'
        });
    } catch (error) {
        if (transactionStarted) {
            await connection.rollback();
        }
        console.error('Handle callback (E-Smartlink) error:', error);
        res.status(500).json({
            success: false,
            message: 'Error processing callback'
        });
    } finally {
        connection.release();
    }
};

/// Buat transaksi top up saldo via E-Smartlink payment
/// Order ID format: TOPUP-{timestamp}-{userId}
/// Setelah pembayaran sukses, callback akan kredit saldo ke wallet user
const createTopUpPayment = async (req, res) => {
    const connection = await pool.getConnection();
    let transactionStarted = false;

    try {
        const { jumlah } = req.body;
        const userId = req.user.userId;

        const nominal = Number(jumlah);
        if (!nominal || nominal < 10000) {
            return res.status(400).json({
                success: false,
                message: 'Jumlah top up minimal Rp 10.000'
            });
        }

        const [users] = await connection.query('SELECT * FROM users WHERE id = ?', [userId]);
        if (users.length === 0) {
            return res.status(404).json({ success: false, message: 'User tidak ditemukan' });
        }
        const user = users[0];

        const orderId = `TOPUP-${Date.now()}-${userId}`;

        const backendPublicUrl =
            process.env.BACKEND_PUBLIC_URL ||
            process.env.FRONTEND_URL ||
            `http://localhost:${process.env.PORT || 3000}`;

        await connection.beginTransaction();
        transactionStarted = true;

        // Simpan transaksi top up di tabel transactions dengan jenis_transaksi='topup_saldo'
        const [txResult] = await connection.query(
            `INSERT INTO transactions (user_id, membership_id, jenis_transaksi, jumlah, metode_pembayaran, status, order_id)
             VALUES (?, NULL, 'topup_saldo', ?, 'esmartlink', 'pending', ?)`,
            [userId, nominal, orderId]
        );
        const transactionId = txResult.insertId;

        const requestBody = {
            order_id: orderId,
            amount: nominal,
            description: `Top Up Saldo GymKu — Rp ${nominal.toLocaleString('id-ID')}`,
            customer: {
                name: user.nama,
                email: user.email,
                phone: user.hp || '-'
            },
            item: [
                {
                    name: 'Top Up Saldo',
                    amount: nominal,
                    qty: 1
                }
            ],
            channel: [process.env.ESMARTLINK_CHANNEL || 'VA_CIMB'],
            type: 'payment-page',
            payment_mode: process.env.ESMARTLINK_PAYMENT_MODE || 'CLOSE',
            expired_time: process.env.ESMARTLINK_EXPIRED_TIME || '',
            callback_url: `${backendPublicUrl}/api/payment/notification`,
            success_redirect_url: `${backendPublicUrl}/api/payment/finish`,
            failed_redirect_url: `${backendPublicUrl}/api/payment/error`,
            return_url: `${backendPublicUrl}/api/payment/pending`
        };

        const gatewayResponse = await esmartlinkRequest({
            method: 'POST',
            path: '/api/payment/create-order',
            body: requestBody
        });

        const gatewayData = gatewayResponse?.data || {};
        const gatewayTransactionId = gatewayData.transaction_id || null;
        const paymentUrl = gatewayData.payment_url || null;

        if (!paymentUrl) {
            throw new Error('Payment URL dari E-Smartlink tidak ditemukan');
        }

        await connection.query(
            'UPDATE transactions SET bukti_pembayaran = ? WHERE id = ?',
            [JSON.stringify({ gateway: 'esmartlink', transaction_id: gatewayTransactionId }), transactionId]
        );

        await connection.commit();
        transactionStarted = false;

        console.log('[E-Smartlink] Top Up Order Created');
        console.log(`  order_id  : ${orderId}`);
        console.log(`  nominal   : ${nominal}`);
        console.log(`  payment_url: ${paymentUrl}`);

        res.json({
            success: true,
            message: 'Link pembayaran top up berhasil dibuat',
            data: {
                order_id: orderId,
                transaction_id: gatewayTransactionId,
                payment_url: paymentUrl,
                jumlah: nominal
            }
        });
    } catch (error) {
        if (transactionStarted) {
            await connection.rollback();
        }
        console.error('Create top up payment error:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Terjadi kesalahan pada server'
        });
    } finally {
        connection.release();
    }
};

const checkPaymentStatus = async (req, res) => {
    const connection = await pool.getConnection();

    try {
        const { order_id: orderId } = req.params;
        const userId = req.user.userId;

        const [transactions] = await connection.query(
            `SELECT t.*, m.paket, m.status AS membership_status
             FROM transactions t
             LEFT JOIN memberships m ON t.membership_id = m.id
             WHERE t.order_id = ? AND t.user_id = ?`,
            [orderId, userId]
        );

        if (transactions.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Transaksi tidak ditemukan'
            });
        }

        const transaction = transactions[0];
        const gatewayTransactionId = parseGatewayReference(transaction.bukti_pembayaran);
        let inquiryData = null;

        if (gatewayTransactionId) {
            try {
                const inquiryResponse = await esmartlinkRequest({
                    method: 'GET',
                    path: `/api/payment/inquiry-order/${gatewayTransactionId}`
                });

                inquiryData = inquiryResponse?.data || null;
                const latestStatus = mapGatewayStatusToLocal(inquiryData?.status);

                if (latestStatus !== transaction.status) {
                    await connection.beginTransaction();
                    await connection.query('UPDATE transactions SET status = ? WHERE id = ?', [latestStatus, transaction.id]);
                    await syncMembershipByTransactionStatus(connection, transaction, latestStatus);
                    await connection.commit();
                    transaction.status = latestStatus;
                    if (latestStatus === 'success') transaction.membership_status = 'active';
                    else if (latestStatus === 'failed') transaction.membership_status = 'expired';
                }
            } catch (gatewayError) {
                console.warn(`Inquiry E-Smartlink gagal untuk order ${orderId}:`, gatewayError.message);
            }
        }

        res.json({
            success: true,
            data: {
                order_id: transaction.order_id,
                status: transaction.status,
                paket: transaction.paket,
                jumlah: transaction.jumlah,
                membership_status: transaction.membership_status,
                gateway: 'esmartlink',
                gateway_status: inquiryData?.status || null,
                payment_code: inquiryData?.payment_code || null,
                channel: inquiryData?.channel || null,
                transaction_time: inquiryData?.transaction_time || null
            }
        });
    } catch (error) {
        try { await connection.rollback(); } catch (_) {}
        console.error('Check payment status error:', error);
        res.status(500).json({ success: false, message: 'Terjadi kesalahan pada server' });
    } finally {
        connection.release();
    }
};

const getPaymentHistory = async (req, res) => {
    try {
        const userId = req.user.userId;
        const [transactions] = await pool.query(
            `SELECT t.*, m.paket, m.tanggal_mulai, m.tanggal_berakhir, m.status as membership_status
             FROM transactions t
             LEFT JOIN memberships m ON t.membership_id = m.id
             WHERE t.user_id = ?
             ORDER BY t.tanggal_transaksi DESC`,
            [userId]
        );
        res.json({ success: true, data: transactions });
    } catch (error) {
        console.error('Get payment history error:', error);
        res.status(500).json({ success: false, message: 'Terjadi kesalahan pada server' });
    }
};

const finishPayment = (req, res) => {
    res.send('<h1>Pembayaran Berhasil!</h1><p>Silakan kembali ke aplikasi.</p>');
};

const unfinishPayment = (req, res) => {
    res.send('<h1>Pembayaran Sedang Diproses.</h1><p>Silakan selesaikan pembayaran Anda.</p>');
};

const errorPayment = (req, res) => {
    res.send('<h1>Pembayaran Gagal.</h1><p>Silakan coba lagi.</p>');
};

/// Konfirmasi pembayaran top up — dipanggil dari Flutter setelah WebView
/// mendeteksi sukses. Polling ke E-Smartlink untuk verifikasi, lalu kredit saldo.
/// Ini solusi untuk environment development di mana callback URL tidak bisa diakses.
const confirmTopUpPayment = async (req, res) => {
    const connection = await pool.getConnection();
    let transactionStarted = false;

    try {
        const { order_id: orderId } = req.params;
        const userId = req.user.userId;

        // 1. Cari transaksi top up milik user ini
        const [transactions] = await connection.query(
            `SELECT * FROM transactions WHERE order_id = ? AND user_id = ? AND jenis_transaksi = 'topup_saldo'`,
            [orderId, userId]
        );

        if (transactions.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Transaksi top up tidak ditemukan'
            });
        }

        const transaction = transactions[0];

        // 2. Kalau sudah sukses sebelumnya, jangan kredit dua kali
        if (transaction.status === 'success') {
            return res.json({
                success: true,
                message: 'Saldo sudah dikreditkan sebelumnya',
                alreadyCredited: true
            });
        }

        // 3. Inquiry status ke E-Smartlink untuk verifikasi pembayaran
        let gatewayStatus = null;
        let gatewayTransactionId = null;

        try {
            const reference = parseGatewayReference(transaction.bukti_pembayaran);
            if (reference) {
                const inquiryRes = await esmartlinkRequest({
                    method: 'GET',
                    path: `/api/payment/inquiry-order/${reference}`
                });
                gatewayStatus = inquiryRes?.data?.status || inquiryRes?.status || null;
                gatewayTransactionId = inquiryRes?.data?.transaction_id || reference;
                console.log(`[TopUp Confirm] order=${orderId} gateway_status=${gatewayStatus}`);
            }
        } catch (inquiryErr) {
            console.warn('[TopUp Confirm] Inquiry gagal, lanjut berdasarkan WebView callback:', inquiryErr.message);
        }

        const localStatus = mapGatewayStatusToLocal(gatewayStatus || 'SUCCESS');

        // 4. Jika E-Smartlink belum konfirmasi, tolak
        if (localStatus === 'failed') {
            await connection.query(
                'UPDATE transactions SET status = ? WHERE order_id = ?',
                ['failed', orderId]
            );
            return res.status(400).json({
                success: false,
                message: 'Pembayaran belum dikonfirmasi oleh gateway'
            });
        }

        // 5. Kredit saldo wallet (dalam transaction DB)
        const jumlah = Number(transaction.jumlah);
        await connection.beginTransaction();
        transactionStarted = true;

        // Update status transaksi → success
        await connection.query(
            'UPDATE transactions SET status = ?, bukti_pembayaran = ? WHERE order_id = ?',
            [
                'success',
                JSON.stringify({
                    gateway: 'esmartlink',
                    transaction_id: gatewayTransactionId,
                    confirmed_by: 'client_polling',
                    confirmed_at: new Date().toISOString()
                }),
                orderId
            ]
        );

        // Upsert wallet
        await connection.query(
            'INSERT INTO wallets (user_id, saldo) VALUES (?, 0) ON DUPLICATE KEY UPDATE user_id = user_id',
            [userId]
        );

        const [[wallet]] = await connection.query(
            'SELECT saldo FROM wallets WHERE user_id = ? FOR UPDATE',
            [userId]
        );
        const saldoAwal = parseFloat(wallet.saldo) || 0;
        const saldoAkhir = saldoAwal + jumlah;

        await connection.query(
            'UPDATE wallets SET saldo = ? WHERE user_id = ?',
            [saldoAkhir, userId]
        );

        // Catat di wallet_transactions
        await connection.query(
            `INSERT INTO wallet_transactions (user_id, jenis, jumlah, saldo_awal, saldo_akhir, keterangan)
             VALUES (?, 'topup', ?, ?, ?, ?)`,
            [userId, jumlah, saldoAwal, saldoAkhir,
             `Top up ${jumlah.toLocaleString('id-ID')} via E-Smartlink (${orderId})`]
        );

        await connection.commit();
        transactionStarted = false;

        console.log(`[TopUp Confirm] ✅ Saldo dikreditkan: user=${userId} jumlah=${jumlah} saldo_akhir=${saldoAkhir}`);

        res.json({
            success: true,
            message: `Saldo berhasil ditambahkan Rp ${jumlah.toLocaleString('id-ID')}`,
            data: {
                jumlah,
                saldo_baru: saldoAkhir,
                order_id: orderId
            }
        });
    } catch (error) {
        if (transactionStarted) {
            try { await connection.rollback(); } catch (_) {}
        }
        console.error('[TopUp Confirm] Error:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Terjadi kesalahan server'
        });
    } finally {
        connection.release();
    }
};

module.exports = {
    createPayment,
    createTopUpPayment,
    confirmTopUpPayment,
    handleNotification,
    checkPaymentStatus,
    getPaymentHistory,
    finishPayment,
    unfinishPayment,
    errorPayment
};
