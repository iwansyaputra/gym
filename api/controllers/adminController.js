// Admin Controller - Additional endpoints for admin web
const { pool } = require('../config/database');

// Get all users (for admin)
const getAllUsers = async (req, res) => {
    try {
        const { status, reportType, period, search, limit = 1000, offset = 0 } = req.query;

        let query = `
            SELECT 
                u.id,
                u.nama as name,
                u.email,
                u.hp as phone,
                u.jenis_kelamin as gender,
                u.tanggal_lahir as date_of_birth,
                u.alamat as address,
                u.is_verified,
                u.created_at,
                m.paket as package_name,
                m.tanggal_berakhir as membership_expiry,
                m.status as membership_status,
                (SELECT check_in_time FROM check_ins WHERE user_id = u.id ORDER BY check_in_time DESC LIMIT 1) as last_checkin
            FROM users u
            LEFT JOIN (
                SELECT user_id, paket, tanggal_berakhir, status
                FROM memberships
                WHERE id IN (SELECT MAX(id) FROM memberships GROUP BY user_id)
            ) m ON u.id = m.user_id
            WHERE u.role = 'user'
        `;

        const params = [];

        // Filter by search
        if (search) {
            query += ` AND (u.nama LIKE ? OR u.email LIKE ? OR u.hp LIKE ?)`;
            params.push(`%${search}%`, `%${search}%`, `%${search}%`);
        }

        // Filter by status/reportType
        const filterType = reportType || status;
        const now = new Date().toISOString().split('T')[0];

        if (filterType && filterType !== 'all' && filterType !== 'overview') {
            if (filterType === 'active') {
                query += ` AND m.status = 'active' AND m.tanggal_berakhir >= ?`;
                params.push(now);
            } else if (filterType === 'expired') {
                query += ` AND (m.status = 'expired' OR m.tanggal_berakhir < ?)`;
                params.push(now);
            } else if (filterType === 'expiring') {
                query += ` AND m.status = 'active' AND m.tanggal_berakhir BETWEEN ? AND DATE_ADD(?, INTERVAL 7 DAY)`;
                params.push(now, now);
            } else if (filterType === 'pending') {
                query += ` AND m.status = 'pending'`;
            } else if (filterType === 'new') {
                // 'new' usually implies created recently, controlled by period
            }
        }

        // Filter by period (for creation date)
        if (period && period !== 'all') {
            if (period === 'today') {
                query += ` AND DATE(u.created_at) = CURDATE()`;
            } else if (period === 'week') {
                query += ` AND u.created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)`;
            } else if (period === 'month') {
                query += ` AND u.created_at >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)`;
            } else if (period === 'year') {
                query += ` AND u.created_at >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)`;
            }
        }

        // Handle heavy report requests by allowing larger limits
        const queryLimit = (reportType || period) ? 10000 : parseInt(limit);

        query += ` ORDER BY u.created_at DESC LIMIT ? OFFSET ?`;
        params.push(queryLimit, parseInt(offset));

        const [users] = await pool.query(query, params);

        // Get total count
        let countQuery = `SELECT COUNT(*) as total FROM users u WHERE u.role = 'user'`;
        const countParams = [];

        if (search) {
            countQuery += ` AND (u.nama LIKE ? OR u.email LIKE ? OR u.hp LIKE ?)`;
            countParams.push(`%${search}%`, `%${search}%`, `%${search}%`);
        }

        const [countResult] = await pool.query(countQuery, countParams);
        const total = countResult[0]?.total || 0;

        res.json({
            success: true,
            data: users,
            pagination: {
                total,
                limit: queryLimit,
                offset: parseInt(offset),
                hasMore: parseInt(offset) + users.length < total
            }
        });
    } catch (error) {
        console.error('Error getting all users:', error);
        res.status(500).json({
            success: false,
            message: 'Gagal mengambil data users: ' + error.message
        });
    }
};

// Delete user (admin only)
const deleteUser = async (req, res) => {
    try {
        const { id } = req.params;

        // Check if user exists
        const [users] = await pool.query('SELECT id FROM users WHERE id = ?', [id]);

        if (users.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'User tidak ditemukan'
            });
        }

        // Delete related records (cascade will handle some, but let's be safe)
        // Note: FOREIGN KEY CASCADE in schema will handle memberships, check_ins, etc.

        // Delete user
        await pool.query('DELETE FROM users WHERE id = ?', [id]);

        res.json({
            success: true,
            message: 'User berhasil dihapus'
        });
    } catch (error) {
        console.error('Error deleting user:', error);
        res.status(500).json({
            success: false,
            message: 'Gagal menghapus user: ' + error.message
        });
    }
};

const getDashboardStats = async (req, res) => {
    try {
        // Total members (users only, not admins)
        const [totalMembers] = await pool.query("SELECT COUNT(*) as count FROM users WHERE role = 'user'");

        // Today's check-ins
        const [todayCheckins] = await pool.query(
            "SELECT COUNT(*) as count FROM check_ins WHERE DATE(check_in_time) = CURDATE()"
        );

        // Monthly revenue
        const [monthlyRevenue] = await pool.query(
            "SELECT SUM(jumlah) as total FROM transactions WHERE status = 'success' AND MONTH(tanggal_transaksi) = MONTH(CURRENT_DATE()) AND YEAR(tanggal_transaksi) = YEAR(CURRENT_DATE())"
        );

        // Expiring members (within 7 days)
        const [expiringMembers] = await pool.query(`
            SELECT COUNT(*) as count 
            FROM memberships 
            WHERE status = 'active' 
            AND tanggal_berakhir BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)
        `);

        // New members (last 30 days)
        const [newMembers] = await pool.query(
            "SELECT COUNT(*) as count FROM users WHERE role = 'user' AND created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)"
        );

        res.json({
            success: true,
            data: {
                totalMembers: totalMembers[0]?.count || 0,
                todayCheckins: todayCheckins[0]?.count || 0,
                monthlyRevenue: parseFloat(monthlyRevenue[0]?.total || 0),
                expiringMembers: expiringMembers[0]?.count || 0,
                newMembers: newMembers[0]?.count || 0,
                memberGrowth: 12 // Placeholder
            }
        });
    } catch (error) {
        console.error('Error getting dashboard stats:', error);
        res.status(500).json({
            success: false,
            message: 'Gagal mengambil statistik dashboard: ' + error.message
        });
    }
};

const getCheckInStatistics = async (req, res) => {
    try {
        // Get check-ins for the last 7 days
        const [checkins] = await pool.query(`
            SELECT 
                DATE(check_in_time) as date,
                COUNT(*) as count
            FROM check_ins
            WHERE check_in_time >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
            GROUP BY DATE(check_in_time)
            ORDER BY date ASC
        `);

        // Format data for chart
        const weekly = [];
        const labels = [];
        const now = new Date();

        for (let i = 6; i >= 0; i--) {
            const d = new Date(now);
            d.setDate(d.getDate() - i);
            const dateStr = d.toISOString().split('T')[0];

            const dayData = checkins.find(c => {
                const cDate = new Date(c.date);
                return cDate.toISOString().split('T')[0] === dateStr;
            });

            weekly.push(dayData ? dayData.count : 0);
            labels.push(d.toLocaleDateString('id-ID', { weekday: 'short' }));
        }

        res.json({
            success: true,
            data: {
                labels,
                weekly,
                today: weekly[6] || 0
            }
        });
    } catch (error) {
        console.error('Error getting check-in statistics:', error);
        res.status(500).json({
            success: false,
            message: 'Gagal mengambil statistik check-in: ' + error.message
        });
    }
};

const getRevenueStatistics = async (req, res) => {
    try {
        // Get revenue for the last 6 months
        const [revenue] = await pool.query(`
            SELECT 
                DATE_FORMAT(tanggal_transaksi, '%Y-%m') as month,
                SUM(jumlah) as total
            FROM transactions
            WHERE status = 'success'
            AND tanggal_transaksi >= DATE_SUB(DATE_FORMAT(CURDATE(), '%Y-%m-01'), INTERVAL 5 MONTH)
            GROUP BY month
            ORDER BY month ASC
        `);

        // Format data for chart
        const monthly = [];
        const labels = [];
        const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

        for (let i = 5; i >= 0; i--) {
            const d = new Date();
            d.setMonth(d.getMonth() - i);
            const monthStr = d.toISOString().slice(0, 7); // YYYY-MM

            const monthData = revenue.find(r => r.month === monthStr);
            monthly.push(parseFloat(monthData ? monthData.total : 0));
            labels.push(monthNames[d.getMonth()]);
        }

        res.json({
            success: true,
            data: {
                labels,
                monthly
            }
        });
    } catch (error) {
        console.error('Error getting revenue statistics:', error);
        res.status(500).json({
            success: false,
            message: 'Gagal mengambil statistik pendapatan: ' + error.message
        });
    }
};

// Update user by admin
const updateUserByAdmin = async (req, res) => {
    try {
        const { id } = req.params;
        const { name, email, phone, gender, date_of_birth, address } = req.body;

        // Check if user exists
        const [users] = await pool.query('SELECT id FROM users WHERE id = ?', [id]);

        if (users.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'User tidak ditemukan'
            });
        }

        // Update user
        const updateFields = [];
        const params = [];

        if (name) {
            updateFields.push('nama = ?');
            params.push(name);
        }
        if (email) {
            updateFields.push('email = ?');
            params.push(email);
        }
        if (phone) {
            updateFields.push('hp = ?');
            params.push(phone);
        }
        if (gender) {
            updateFields.push('jenis_kelamin = ?');
            params.push(gender);
        }
        if (date_of_birth) {
            updateFields.push('tanggal_lahir = ?');
            params.push(date_of_birth);
        }
        if (address) {
            updateFields.push('alamat = ?');
            params.push(address);
        }

        if (updateFields.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'Tidak ada data yang diupdate'
            });
        }

        params.push(id);
        const query = `UPDATE users SET ${updateFields.join(', ')} WHERE id = ?`;

        await pool.query(query, params);

        res.json({
            success: true,
            message: 'User berhasil diupdate'
        });
    } catch (error) {
        console.error('Error updating user:', error);
        res.status(500).json({
            success: false,
            message: 'Gagal mengupdate user: ' + error.message
        });
    }
};

// Get all transactions (admin only)
const getAllTransactions = async (req, res) => {
    try {
        const { status, period, startDate, endDate, limit = 1000, offset = 0 } = req.query;

        let query = `
            SELECT 
                t.*,
                u.nama as user_name,
                u.email as user_email,
                m.paket as package_name
            FROM transactions t
            LEFT JOIN users u ON t.user_id = u.id
            LEFT JOIN memberships m ON t.membership_id = m.id
            WHERE 1=1
        `;

        const params = [];

        if (status) {
            query += ' AND t.status = ?';
            params.push(status);
        }

        // Filter by period
        if (period) {
            if (period === 'today') {
                query += ' AND DATE(t.tanggal_transaksi) = CURDATE()';
            } else if (period === 'week') {
                query += ' AND yearweek(t.tanggal_transaksi) = yearweek(curdate())';
            } else if (period === 'month') {
                query += ' AND MONTH(t.tanggal_transaksi) = MONTH(CURDATE()) AND YEAR(t.tanggal_transaksi) = YEAR(CURDATE())';
            } else if (period === 'year') {
                query += ' AND YEAR(t.tanggal_transaksi) = YEAR(CURDATE())';
            } else if (period === 'custom' && startDate && endDate) {
                query += ' AND DATE(t.tanggal_transaksi) BETWEEN ? AND ?';
                params.push(startDate, endDate);
            }
        }

        // Larger limit for reports
        const queryLimit = (period) ? 10000 : parseInt(limit);

        query += ' ORDER BY t.tanggal_transaksi DESC LIMIT ? OFFSET ?';
        params.push(queryLimit, parseInt(offset));

        const [transactions] = await pool.query(query, params);

        res.json({
            success: true,
            data: transactions
        });
    } catch (error) {
        console.error('Error getting all transactions:', error);
        res.status(500).json({
            success: false,
            message: 'Gagal mengambil data transaksi: ' + error.message
        });
    }
};

// Get all check-ins (admin only)
const getAllCheckIns = async (req, res) => {
    try {
        const { limit = 100, offset = 0 } = req.query;

        const [checkins] = await pool.query(`
            SELECT 
                c.*,
                u.nama as user_name,
                u.email as user_email
            FROM check_ins c
            LEFT JOIN users u ON c.user_id = u.id
            ORDER BY c.check_in_time DESC
            LIMIT ? OFFSET ?
        `, [parseInt(limit), parseInt(offset)]);

        res.json({
            success: true,
            data: checkins
        });
    } catch (error) {
        console.error('Error getting all check-ins:', error);
        res.status(500).json({
            success: false,
            message: 'Gagal mengambil data check-in'
        });
    }
};

module.exports = {
    getAllUsers,
    deleteUser,
    getDashboardStats,
    getCheckInStatistics,
    updateUserByAdmin,
    getAllTransactions,
    getAllCheckIns,
    getRevenueStatistics
};
