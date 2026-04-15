const express = require('express');
const router = express.Router();
const transactionController = require('../controllers/transactionController');
const authMiddleware = require('../middleware/auth');

// Transaction routes (protected)
router.get('/history', authMiddleware, transactionController.getTransactionHistory);
router.get('/:id', authMiddleware, transactionController.getTransactionDetail);
router.post('/create', authMiddleware, transactionController.createPayment);
router.post('/confirm', transactionController.confirmPayment); // Can be called by payment gateway webhook

module.exports = router;
