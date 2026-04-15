const { pool } = require('../config/database');
const bcrypt = require('bcryptjs');
const moment = require('moment');

// Get user profile
const getProfile = async (req, res) => {
    try {
        const userId = req.user.userId;

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
