const express = require('express');
const router = express.Router();
const {
    createPayment,
    createTopUpPayment,
    confirmTopUpPayment,
    handleNotification,
    checkPaymentStatus,
    getPaymentHistory,
    finishPayment,
    unfinishPayment,
    errorPayment
} = require('../controllers/paymentController');
const authenticateToken = require('../middleware/auth');

// Create payment membership (protected)
router.post('/create', authenticateToken, createPayment);

// Create top up saldo payment via E-Smartlink (protected)
router.post('/topup', authenticateToken, createTopUpPayment);

// Konfirmasi top up dari client setelah WebView sukses (polling fallback)
router.post('/topup/confirm/:order_id', authenticateToken, confirmTopUpPayment);

// E-Smartlink callback notification (tanpa auth karena dipanggil gateway)
router.post('/notification', handleNotification);

// Check payment status (protected)
router.get('/status/:order_id', authenticateToken, checkPaymentStatus);

// Get payment history (protected)
router.get('/history', authenticateToken, getPaymentHistory);

// Callback redirect handlers
router.get('/finish', finishPayment);
router.get('/error', errorPayment);
router.get('/pending', unfinishPayment);

module.exports = router;

