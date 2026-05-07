const express = require('express');
const router = express.Router();
const checkInController = require('../controllers/checkInController');
const authMiddleware = require('../middleware/auth');

// Check-in routes
router.post('/lookup', checkInController.lookupMember);   // Preview member info (no check-in)
router.post('/nfc', checkInController.checkInNFC);        // Check-in: Python bridge (X-NFC-Secret) atau JWT
router.get('/history', authMiddleware, checkInController.getCheckInHistory);
router.get('/stats', authMiddleware, checkInController.getCheckInStats);

module.exports = router;
