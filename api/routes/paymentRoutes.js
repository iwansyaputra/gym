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

// Midtrans webhook notification (tidak perlu auth karena dari Midtrans)
router.post('/notification', handleNotification);

// Check payment status (protected)
router.get('/status/:order_id', authenticateToken, checkPaymentStatus);

// Get payment history (protected)
router.get('/history', authenticateToken, getPaymentHistory);

// Callback handlers for Midtrans Snap (redirects)
router.get('/finish', finishPayment);
router.get('/error', errorPayment);
router.get('/pending', unfinishPayment);

module.exports = router;
