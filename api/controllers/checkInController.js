const { pool } = require('../config/database');
const moment = require('moment');

// ── In-memory mutex: cegah 2 request concurrent untuk user yang sama ──────────
const _checkinLocks = new Set();

// Lookup member info by NFC ID or User ID (NO check-in recorded)
const lookupMember = async (req, res) => {
    try {
        const { nfc_id } = req.body;
        if (!nfc_id) return res.status(400).json({ success: false, message: 'NFC ID harus diisi' });

        let [cards] = await pool.query('SELECT user_id FROM member_cards WHERE nfc_id = ? AND is_active = TRUE', [nfc_id]);
        let userId;
        if (cards.length > 0) {
            userId = cards[0].user_id;
        } else {
            const [users] = await pool.query('SELECT id FROM users WHERE id = ?', [nfc_id]);
            if (users.length > 0) userId = users[0].id;
            else return res.status(404).json({ success: false, message: 'Kartu member tidak ditemukan / ID tidak valid' });
        }

        const [users] = await pool.query(
            `SELECT u.id, u.nama as name, u.email, u.hp as phone, mc.nfc_id,
                m.paket as package_name, m.tanggal_berakhir as membership_expiry, m.status as membership_status,
                (SELECT check_in_time FROM check_ins WHERE user_id = u.id ORDER BY check_in_time DESC LIMIT 1) as last_checkin
             FROM users u
             LEFT JOIN member_cards mc ON u.id = mc.user_id
             LEFT JOIN memberships m ON u.id = m.user_id AND m.status = 'active' AND m.tanggal_berakhir >= CURDATE()
             WHERE u.id = ? ORDER BY m.tanggal_berakhir DESC LIMIT 1`,
            [userId]
        );

        if (!users || users.length === 0) return res.status(404).json({ success: false, message: 'Data member tidak ditemukan' });
        const member = users[0];
        const hasActiveMembership = member.membership_expiry && new Date(member.membership_expiry) >= new Date();

        res.json({ success: true, data: { user: member, has_active_membership: hasActiveMembership } });
    } catch (error) {
        console.error('Lookup member error:', error);
        res.status(500).json({ success: false, message: 'Terjadi kesalahan pada server' });
    }
};

// Check-in with NFC
// Bisa dipanggil oleh:
// 1. Python NFC bridge: kirim header X-NFC-Secret (tanpa JWT)
// 2. Admin web: kirim JWT token biasa (via middleware auth)
const checkInNFC = async (req, res) => {
    try {
        const { nfc_id } = req.body;

        if (!nfc_id) {
            return res.status(400).json({
                success: false,
                message: 'NFC ID harus diisi'
            });
        }

        // ── Validasi: bisa dari Python bridge (X-NFC-Secret) atau JWT user ──
        const nfcSecret = req.headers['x-nfc-secret'];
        const isFromBridge = nfcSecret && nfcSecret === process.env.NFC_SECRET_KEY;

        if (!isFromBridge && !req.user) {
            return res.status(401).json({
                success: false,
                message: 'Unauthorized: butuh X-NFC-Secret atau JWT token'
            });
        }

        // Find user by NFC ID or directly by User ID
        let [cards] = await pool.query(
            'SELECT user_id FROM member_cards WHERE nfc_id = ? AND is_active = TRUE',
            [nfc_id]
        );

        let userId;

        if (cards.length > 0) {
            userId = cards[0].user_id;
        } else {
            // Coba cek jika nfc_id yang dikirim adalah user_id dari database
            const [users] = await pool.query('SELECT id FROM users WHERE id = ?', [nfc_id]);
            if (users.length > 0) {
                userId = users[0].id;
            } else {
                return res.status(404).json({
                    success: false,
                    message: 'Kartu member tidak ditemukan / ID tidak valid'
                });
            }
        }

        // Check if user has active membership
        const [memberships] = await pool.query(
            'SELECT * FROM memberships WHERE user_id = ? AND status = "active" AND tanggal_berakhir >= CURDATE()',
            [userId]
        );

        if (memberships.length === 0) {
            // Ambil nama member meski membership expired (untuk tampil di display)
            const [expiredUser] = await pool.query('SELECT nama as name FROM users WHERE id = ?', [userId]);
            return res.status(403).json({
                success: false,
                message: 'Membership tidak aktif. Silakan perpanjang terlebih dahulu.',
                member: expiredUser.length > 0 ? { name: expiredUser[0].name } : null
            });
        }

        // ── Mutex: blok request lain untuk userId yang sama ─────────────────
        if (_checkinLocks.has(userId)) {
            return res.status(429).json({
                success: false,
                message: 'Check-in sedang diproses. Tunggu sebentar.'
            });
        }
        _checkinLocks.add(userId);

        try {
            // ── Atomic INSERT: hanya insert jika belum check-in 60 detik terakhir ──
            const [result] = await pool.query(
                `INSERT INTO check_ins (user_id, check_in_method)
                 SELECT ?, 'nfc' FROM DUAL
                 WHERE NOT EXISTS (
                     SELECT 1 FROM check_ins
                     WHERE user_id = ?
                     AND check_in_time >= NOW() - INTERVAL 60 SECOND
                 )`,
                [userId, userId]
            );

            if (result.affectedRows === 0) {
                return res.status(429).json({
                    success: false,
                    message: 'Sudah check-in baru saja. Tunggu 1 menit sebelum check-in lagi.'
                });
            }
        } finally {
            _checkinLocks.delete(userId);
        }

        // Get full user info & membership stats for UI display
        const [users] = await pool.query(
            `SELECT 
                u.id, 
                u.nama as name, 
                u.email, 
                u.hp as phone,
                m.paket as package_name,
                m.tanggal_berakhir as membership_expiry,
                (SELECT COUNT(*) FROM check_ins WHERE user_id = u.id) as total_checkins,
                (SELECT check_in_time FROM check_ins WHERE user_id = u.id ORDER BY check_in_time DESC LIMIT 1 OFFSET 1) as last_checkin
             FROM users u
             LEFT JOIN memberships m ON u.id = m.user_id AND m.status = 'active' AND m.tanggal_berakhir >= CURDATE()
             WHERE u.id = ?
             ORDER BY m.tanggal_berakhir DESC LIMIT 1`,
            [userId]
        );

        const member = users[0];

        res.json({
            success: true,
            message: 'Check-in berhasil!',
            member: {
                id: member.id,
                name: member.name,
                email: member.email,
                phone: member.phone,
                package_name: member.package_name,
                membership_expiry: member.membership_expiry,
                total_checkins: member.total_checkins,
            },
            check_in_time: moment().tz('Asia/Jakarta').format('YYYY-MM-DD HH:mm:ss'),
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
    lookupMember,
    checkInNFC,
    getCheckInHistory,
    getCheckInStats
};
