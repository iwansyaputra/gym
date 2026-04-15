const { pool } = require('../config/database');

// Get transaction history
const getTransactionHistory = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { limit = 10, offset = 0, status } = req.query;

        let query = 'SELECT * FROM transactions WHERE user_id = ?';
        const params = [userId];

        if (status) {
            query += ' AND status = ?';
            params.push(status);
        }

        query += ' ORDER BY tanggal_transaksi DESC LIMIT ? OFFSET ?';
        params.push(parseInt(limit), parseInt(offset));

        const [transactions] = await pool.query(query, params);

        // Get total count
        let countQuery = 'SELECT COUNT(*) as total FROM transactions WHERE user_id = ?';
        const countParams = [userId];

        if (status) {
            countQuery += ' AND status = ?';
            countParams.push(status);
        }

        const [countResult] = await pool.query(countQuery, countParams);

        res.json({
            success: true,
            data: {
                transactions,
                total: countResult[0].total,
                limit: parseInt(limit),
                offset: parseInt(offset)
            }
        });

    } catch (error) {
        console.error('Get transaction history error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server'
        });
    }
};

// Get transaction detail
const getTransactionDetail = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { id } = req.params;

        const [transactions] = await pool.query(
            'SELECT t.*, m.paket, m.tanggal_mulai, m.tanggal_berakhir FROM transactions t LEFT JOIN memberships m ON t.membership_id = m.id WHERE t.id = ? AND t.user_id = ?',
            [id, userId]
        );

        if (transactions.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Transaksi tidak ditemukan'
            });
        }

        res.json({
            success: true,
            data: transactions[0]
        });

    } catch (error) {
        console.error('Get transaction detail error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server'
        });
    }
};

// Create payment
const createPayment = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { membership_id, amount, payment_method } = req.body;

        if (!membership_id || !amount || !payment_method) {
            return res.status(400).json({
                success: false,
                message: 'Semua field harus diisi'
            });
        }

        // Create transaction
        const [result] = await pool.query(
            'INSERT INTO transactions (user_id, membership_id, jenis_transaksi, jumlah, metode_pembayaran, status) VALUES (?, ?, ?, ?, ?, ?)',
            [userId, membership_id, 'membership', amount, payment_method, 'pending']
        );

        res.json({
            success: true,
            message: 'Transaksi berhasil dibuat. Silakan lakukan pembayaran.',
            data: {
                transaction_id: result.insertId
            }
        });

    } catch (error) {
        console.error('Create payment error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server'
        });
    }
};

// Confirm payment (admin or webhook)
const confirmPayment = async (req, res) => {
    try {
        const { transaction_id } = req.body;

        if (!transaction_id) {
            return res.status(400).json({
                success: false,
                message: 'Transaction ID harus diisi'
            });
        }

        // Get transaction
        const [transactions] = await pool.query(
            'SELECT * FROM transactions WHERE id = ?',
            [transaction_id]
        );

        if (transactions.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Transaksi tidak ditemukan'
            });
        }

        const transaction = transactions[0];

        // Update transaction status
        await pool.query(
            'UPDATE transactions SET status = ? WHERE id = ?',
            ['success', transaction_id]
        );

        // Activate membership
        if (transaction.membership_id) {
            await pool.query(
                'UPDATE memberships SET status = ? WHERE id = ?',
                ['active', transaction.membership_id]
            );
        }

        res.json({
            success: true,
            message: 'Pembayaran berhasil dikonfirmasi'
        });

    } catch (error) {
        console.error('Confirm payment error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server'
        });
    }
};

module.exports = {
    getTransactionHistory,
    getTransactionDetail,
    createPayment,
    confirmPayment
};
