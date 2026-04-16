const { pool } = require('../config/database');
const bcrypt = require('bcryptjs');
const moment = require('moment');
const { esmartlinkRequest } = require('../config/esmartlink');

const parseGatewayReference = (rawReference) => {
    if (!rawReference) return null;

    try {
        const parsed = JSON.parse(rawReference);
        return parsed.transaction_id || null;
    } catch (error) {
        return rawReference;
    }
};

const mapGatewayStatusToLocal = (status = '') => {
    const normalized = String(status).toUpperCase();
    if (normalized === 'SUCCESS' || normalized === 'PAID') return 'success';
    if (normalized === 'FAILED' || normalized === 'CANCELED' || normalized === 'EXPIRED') return 'failed';
    return 'pending';
};

// Get user profile
const getProfile = async (req, res) => {
    try {
        const userId = req.user.userId;

        // 1) Reconcile data lama: jika transaksi sudah success tapi membership masih pending
        await pool.query(
            `UPDATE memberships m
             JOIN transactions t ON t.membership_id = m.id
             SET m.status = 'active'
             WHERE m.user_id = ? AND m.status = 'pending' AND t.status = 'success'`,
            [userId]
        );

        // 2) Sync transaksi pending terbaru ke E-Smartlink (untuk kasus callback tidak sampai)
        const [pendingTransactions] = await pool.query(
            `SELECT id, order_id, membership_id, bukti_pembayaran
             FROM transactions
             WHERE user_id = ? AND metode_pembayaran = 'esmartlink' AND status = 'pending'
             ORDER BY tanggal_transaksi DESC
             LIMIT 5`,
            [userId]
        );

        for (const tx of pendingTransactions) {
            const gatewayTransactionId = parseGatewayReference(tx.bukti_pembayaran);
            if (!gatewayTransactionId) continue;

            try {
                const inquiryResponse = await esmartlinkRequest({
                    method: 'GET',
                    path: `/api/payment/inquiry-order/${gatewayTransactionId}`
                });

                const gatewayStatus = inquiryResponse?.data?.status;
                const localStatus = mapGatewayStatusToLocal(gatewayStatus);

                if (localStatus !== 'pending') {
                    await pool.query('UPDATE transactions SET status = ? WHERE id = ?', [localStatus, tx.id]);

                    if (tx.membership_id) {
                        if (localStatus === 'success') {
                            await pool.query('UPDATE memberships SET status = "active" WHERE id = ?', [tx.membership_id]);
                            await pool.query('UPDATE member_cards SET is_active = TRUE WHERE user_id = ?', [userId]);
                        } else if (localStatus === 'failed') {
                            await pool.query('UPDATE memberships SET status = "expired" WHERE id = ?', [tx.membership_id]);
                        }
                    }
                }
            } catch (syncError) {
                console.warn(`Profile reconcile gagal untuk order ${tx.order_id}:`, syncError.message);
            }
        }

        const [users] = await pool.query(
            'SELECT id, nama, email, hp, jenis_kelamin, tanggal_lahir, alamat, foto_profil, created_at FROM users WHERE id = ?',
            [userId]
        );

        if (users.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'User tidak ditemukan'
            });
        }

        // Get active membership
        const [memberships] = await pool.query(
            'SELECT * FROM memberships WHERE user_id = ? AND status = "active" ORDER BY tanggal_berakhir DESC LIMIT 1',
            [userId]
        );

        // Get member card
        const [cards] = await pool.query(
            'SELECT card_number, nfc_id FROM member_cards WHERE user_id = ? AND is_active = TRUE LIMIT 1',
            [userId]
        );

        // Format tanggal lahir user agar tidak kena timezone shift
        const user = users[0];
        if (user.tanggal_lahir) {
            user.tanggal_lahir = moment(user.tanggal_lahir).format('YYYY-MM-DD');
        }

        res.json({
            success: true,
            data: {
                user: user,
                membership: memberships.length > 0 ? memberships[0] : null,
                card: cards.length > 0 ? cards[0] : null
            }
        });

    } catch (error) {
        console.error('Get profile error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server'
        });
    }
};

// Update profile
const updateProfile = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { nama, hp } = req.body;

        if (!nama || !hp) {
            return res.status(400).json({
                success: false,
                message: 'Nama dan nomor HP harus diisi'
            });
        }

        await pool.query(
            'UPDATE users SET nama = ?, hp = ? WHERE id = ?',
            [nama, hp, userId]
        );

        res.json({
            success: true,
            message: 'Profile berhasil diupdate'
        });

    } catch (error) {
        console.error('Update profile error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server'
        });
    }
};

// Change password
const changePassword = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { oldPassword, newPassword } = req.body;

        if (!oldPassword || !newPassword) {
            return res.status(400).json({
                success: false,
                message: 'Password lama dan baru harus diisi'
            });
        }

        // Get current password
        const [users] = await pool.query(
            'SELECT password FROM users WHERE id = ?',
            [userId]
        );

        if (users.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'User tidak ditemukan'
            });
        }

        // Verify old password
        const isPasswordValid = await bcrypt.compare(oldPassword, users[0].password);

        if (!isPasswordValid) {
            return res.status(400).json({
                success: false,
                message: 'Password lama tidak sesuai'
            });
        }

        // Hash new password
        const hashedPassword = await bcrypt.hash(newPassword, 10);

        // Update password
        await pool.query(
            'UPDATE users SET password = ? WHERE id = ?',
            [hashedPassword, userId]
        );

        res.json({
            success: true,
            message: 'Password berhasil diubah'
        });

    } catch (error) {
        console.error('Change password error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server'
        });
    }
};

module.exports = {
    getProfile,
    updateProfile,
    changePassword
};
