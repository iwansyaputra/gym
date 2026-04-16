const express = require('express');
const router = express.Router();
const {
    createPayment,
    handleNotification,
    checkPaymentStatus,
    getPaymentHistory,
    finishPayment,
    unfinishPayment,
    errorPayment
} = require('../controllers/paymentController');
const authenticateToken = require('../middleware/auth');

// Create payment (protected)
router.post('/create', authenticateToken, createPayment);

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
