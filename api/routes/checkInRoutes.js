const express = require('express');
const router = express.Router();
const checkInController = require('../controllers/checkInController');
const authMiddleware = require('../middleware/auth');

// Check-in routes
router.post('/nfc', checkInController.checkInNFC); // Public endpoint for NFC reader
router.get('/history', authMiddleware, checkInController.getCheckInHistory);
router.get('/stats', authMiddleware, checkInController.getCheckInStats);

module.exports = router;
