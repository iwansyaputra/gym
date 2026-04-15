const express = require('express');
const router = express.Router();
const membershipController = require('../controllers/membershipController');
const authMiddleware = require('../middleware/auth');

// Membership routes (protected)
router.get('/info', authMiddleware, membershipController.getMembershipInfo);
router.get('/packages', authMiddleware, membershipController.getMembershipPackages);
router.post('/extend', authMiddleware, membershipController.extendMembership);

module.exports = router;
