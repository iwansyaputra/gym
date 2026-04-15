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

module.exports = router;
