const { pool } = require('../config/database');
const moment = require('moment');

// Check-in with NFC
const checkInNFC = async (req, res) => {
    try {
        const { nfc_id } = req.body;

        if (!nfc_id) {
            return res.status(400).json({
                success: false,
                message: 'NFC ID harus diisi'
            });
        }

        // Find user by NFC ID
        const [cards] = await pool.query(
            'SELECT user_id FROM member_cards WHERE nfc_id = ? AND is_active = TRUE',
            [nfc_id]
        );

        if (cards.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Kartu member tidak ditemukan atau tidak aktif'
            });
        }

        const userId = cards[0].user_id;

        // Check if user has active membership
        const [memberships] = await pool.query(
            'SELECT * FROM memberships WHERE user_id = ? AND status = "active" AND tanggal_berakhir >= CURDATE()',
            [userId]
        );

        if (memberships.length === 0) {
            return res.status(403).json({
                success: false,
                message: 'Membership Anda sudah tidak aktif. Silakan perpanjang terlebih dahulu.'
            });
        }

        // Record check-in
        await pool.query(
            'INSERT INTO check_ins (user_id, check_in_method) VALUES (?, ?)',
            [userId, 'nfc']
        );

        // Get user info
        const [users] = await pool.query(
            'SELECT nama, email FROM users WHERE id = ?',
            [userId]
        );

        res.json({
            success: true,
            message: 'Check-in berhasil! Selamat berlatih 💪',
            data: {
                user: users[0],
                check_in_time: moment().format('YYYY-MM-DD HH:mm:ss')
            }
        });

    } catch (error) {
        console.error('Check-in NFC error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server'
        });
    }
};

// Get check-in history
const getCheckInHistory = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { limit = 10, offset = 0 } = req.query;

        const [checkIns] = await pool.query(
            'SELECT * FROM check_ins WHERE user_id = ? ORDER BY check_in_time DESC LIMIT ? OFFSET ?',
            [userId, parseInt(limit), parseInt(offset)]
        );

        // Get total count
        const [countResult] = await pool.query(
            'SELECT COUNT(*) as total FROM check_ins WHERE user_id = ?',
            [userId]
        );

        res.json({
            success: true,
            data: {
                check_ins: checkIns,
                total: countResult[0].total,
                limit: parseInt(limit),
                offset: parseInt(offset)
            }
        });

    } catch (error) {
        console.error('Get check-in history error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server'
        });
    }
};

// Get check-in stats
const getCheckInStats = async (req, res) => {
    try {
        const userId = req.user.userId;

        // Total check-ins
        const [totalResult] = await pool.query(
            'SELECT COUNT(*) as total FROM check_ins WHERE user_id = ?',
            [userId]
        );

        // This month check-ins
        const [monthResult] = await pool.query(
            'SELECT COUNT(*) as total FROM check_ins WHERE user_id = ? AND MONTH(check_in_time) = MONTH(CURDATE()) AND YEAR(check_in_time) = YEAR(CURDATE())',
            [userId]
        );

        // This week check-ins
        const [weekResult] = await pool.query(
            'SELECT COUNT(*) as total FROM check_ins WHERE user_id = ? AND YEARWEEK(check_in_time) = YEARWEEK(CURDATE())',
            [userId]
        );

        res.json({
            success: true,
            data: {
                total_check_ins: totalResult[0].total,
                this_month: monthResult[0].total,
                this_week: weekResult[0].total
            }
        });

    } catch (error) {
        console.error('Get check-in stats error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server'
        });
    }
};

module.exports = {
    checkInNFC,
    getCheckInHistory,
    getCheckInStats
};
