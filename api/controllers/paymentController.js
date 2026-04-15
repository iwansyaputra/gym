const { snap, core } = require('../config/midtrans');
const { pool } = require('../config/database');
const crypto = require('crypto');

// Create payment transaction
const createPayment = async (req, res) => {
    try {
        const { paket, harga } = req.body;
        const userId = req.user.userId; // dari middleware auth

        // Validasi
        if (!paket || !harga) {
            return res.status(400).json({
                success: false,
                message: 'Paket dan harga harus diisi'
            });
        }

        // Get user data
        const [users] = await pool.query('SELECT * FROM users WHERE id = ?', [userId]);
        if (users.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'User tidak ditemukan'
            });
        }
        const user = users[0];

        // Generate unique order ID
        const orderId = `GYM-${Date.now()}-${userId}`;

        // Hitung tanggal membership
        const tanggalMulai = new Date();
        let tanggalBerakhir = new Date();

        if (paket === 'bulanan') {
            tanggalBerakhir.setMonth(tanggalBerakhir.getMonth() + 1);
        } else if (paket === 'tahunan') {
            tanggalBerakhir.setFullYear(tanggalBerakhir.getFullYear() + 1);
        }

        // 1. Buat membership record (status pending)
        const [membershipResult] = await pool.query(
            `INSERT INTO memberships (user_id, paket, tanggal_mulai, tanggal_berakhir, status) 
             VALUES (?, ?, ?, ?, 'pending')`,
            [userId, paket, tanggalMulai, tanggalBerakhir]
        );
        const membershipId = membershipResult.insertId;

        // 2. Buat transaction record (status pending)
        await pool.query(
            `INSERT INTO transactions (user_id, membership_id, jenis_transaksi, jumlah, metode_pembayaran, status, order_id) 
             VALUES (?, ?, 'membership', ?, 'midtrans', 'pending', ?)`,
            [userId, membershipId, harga, orderId]
        );

        // 3. Buat parameter untuk Midtrans Snap
        const parameter = {
            transaction_details: {
                order_id: orderId,
                gross_amount: parseInt(harga)
            },
            customer_details: {
                first_name: user.nama,
                email: user.email,
                phone: user.hp
            },
            item_details: [
                {
                    id: `membership-${paket}`,
                    price: parseInt(harga),
                    quantity: 1,
                    name: `Membership ${paket.charAt(0).toUpperCase() + paket.slice(1)}`
                }
            ],
            callbacks: {
                finish: `${process.env.FRONTEND_URL || 'http://localhost:3000'}/api/payment/finish`,
                error: `${process.env.FRONTEND_URL || 'http://localhost:3000'}/api/payment/error`,
                pending: `${process.env.FRONTEND_URL || 'http://localhost:3000'}/api/payment/pending`
            }
        };

        // 4. Create transaction token dari Midtrans
        const transaction = await snap.createTransaction(parameter);

        res.json({
            success: true,
            message: 'Token pembayaran berhasil dibuat',
            data: {
                token: transaction.token,
                redirect_url: transaction.redirect_url,
                order_id: orderId,
                membership_id: membershipId
            }
        });

    } catch (error) {
        console.error('Create payment error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server: ' + error.message
        });
    }
};

// Webhook handler untuk notifikasi dari Midtrans
const handleNotification = async (req, res) => {
    try {
        const notification = req.body;

        // Verify notification dari Midtrans
        const statusResponse = await core.transaction.notification(notification);

        const orderId = statusResponse.order_id;
        const transactionStatus = statusResponse.transaction_status;
        const fraudStatus = statusResponse.fraud_status;

        console.log(`Transaction notification received. Order ID: ${orderId}. Transaction status: ${transactionStatus}. Fraud status: ${fraudStatus}`);

        // Get transaction dari database
        const [transactions] = await pool.query(
            'SELECT * FROM transactions WHERE order_id = ?',
            [orderId]
        );

        if (transactions.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Transaction not found'
            });
        }

        const transaction = transactions[0];
        let newStatus = 'pending';

        // Update status berdasarkan response Midtrans
        if (transactionStatus === 'capture') {
            if (fraudStatus === 'accept') {
                newStatus = 'success';
            }
        } else if (transactionStatus === 'settlement') {
            newStatus = 'success';
        } else if (transactionStatus === 'cancel' || transactionStatus === 'deny' || transactionStatus === 'expire') {
            newStatus = 'failed';
        } else if (transactionStatus === 'pending') {
            newStatus = 'pending';
        }

        // Update transaction status
        await pool.query(
            'UPDATE transactions SET status = ?, updated_at = NOW() WHERE order_id = ?',
            [newStatus, orderId]
        );

        // Jika success, activate membership
        if (newStatus === 'success') {
            await pool.query(
                'UPDATE memberships SET status = "active" WHERE id = ?',
                [transaction.membership_id]
            );

            // Activate member card jika belum active
            await pool.query(
                'UPDATE member_cards SET is_active = TRUE WHERE user_id = ?',
                [transaction.user_id]
            );
        } else if (newStatus === 'failed') {
            // Jika failed, set membership ke expired
            await pool.query(
                'UPDATE memberships SET status = "expired" WHERE id = ?',
                [transaction.membership_id]
            );
        }

        res.json({
            success: true,
            message: 'Notification processed'
        });

    } catch (error) {
        console.error('Notification handler error:', error);
        res.status(500).json({
            success: false,
            message: 'Error processing notification'
        });
    }
};

// Check payment status
const checkPaymentStatus = async (req, res) => {
    try {
        const { order_id } = req.params;
        const userId = req.user.userId;

        // Get transaction dari database
        const [transactions] = await pool.query(
            'SELECT t.*, m.paket, m.status as membership_status FROM transactions t LEFT JOIN memberships m ON t.membership_id = m.id WHERE t.order_id = ? AND t.user_id = ?',
            [order_id, userId]
        );

        if (transactions.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Transaksi tidak ditemukan'
            });
        }

        const transaction = transactions[0];

        // Check status dari Midtrans
        try {
            const statusResponse = await core.transaction.status(order_id);

            res.json({
                success: true,
                data: {
                    order_id: transaction.order_id,
                    status: transaction.status,
                    paket: transaction.paket,
                    jumlah: transaction.jumlah,
                    membership_status: transaction.membership_status,
                    midtrans_status: statusResponse.transaction_status,
                    payment_type: statusResponse.payment_type,
                    transaction_time: statusResponse.transaction_time
                }
            });
        } catch (midtransError) {
            // Jika error dari Midtrans, return data dari database saja
            res.json({
                success: true,
                data: {
                    order_id: transaction.order_id,
                    status: transaction.status,
                    paket: transaction.paket,
                    jumlah: transaction.jumlah,
                    membership_status: transaction.membership_status
                }
            });
        }

    } catch (error) {
        console.error('Check payment status error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server'
        });
    }
};

// Get user's payment history
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

        res.json({
            success: true,
            data: transactions
        });

    } catch (error) {
        console.error('Get payment history error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server'
        });
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

module.exports = {
    createPayment,
    handleNotification,
    checkPaymentStatus,
    getPaymentHistory,
    finishPayment,
    unfinishPayment,
    errorPayment
};
