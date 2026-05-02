// Admin Routes
const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { verifyToken, isAdmin } = require('../middleware/auth');

// All admin routes require authentication AND admin role
router.use(verifyToken);
router.use(isAdmin);

// Get all users
router.get('/users', adminController.getAllUsers);

// Get dashboard statistics
router.get('/dashboard/stats', adminController.getDashboardStats);

// Get check-in statistics
router.get('/checkin/stats', adminController.getCheckInStatistics);

// Get revenue statistics
router.get('/revenue/stats', adminController.getRevenueStatistics);

// Update user by admin
router.put('/users/:id', adminController.updateUserByAdmin);

// Delete user
router.delete('/users/:id', adminController.deleteUser);

// Get all transactions
router.get('/transactions', adminController.getAllTransactions);

// Get all check-ins
router.get('/checkins', adminController.getAllCheckIns);

// Get member full history (checkins, transactions, wallet)
router.get('/users/:id/history', adminController.getMemberFullHistory);

// Get all wallets
router.get('/wallets', adminController.getAllWallets);

// Top up wallet
router.post('/wallets/topup', adminController.topUpWallet);

// Get member wallet history
router.get('/wallets/:userId/history', adminController.getMemberWalletHistory);

module.exports = router;
