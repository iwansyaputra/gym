const express = require('express');
const router = express.Router();
const promoController = require('../controllers/promoController');
const authenticateToken = require('../middleware/auth');
const isAdmin = require('../middleware/isAdmin');

// ─── Public routes (mobile app) ───────────────────────────────────────────────
router.get('/', promoController.getPromos);
router.get('/active-discount', promoController.getActiveDiscount);
router.get('/:id', promoController.getPromoDetail);

// ─── Admin routes (protected) ─────────────────────────────────────────────────
router.get('/admin/all', authenticateToken, isAdmin, promoController.getAllPromosAdmin);
router.post('/admin', authenticateToken, isAdmin, promoController.createPromo);
router.put('/admin/:id', authenticateToken, isAdmin, promoController.updatePromo);
router.delete('/admin/:id', authenticateToken, isAdmin, promoController.deletePromo);

module.exports = router;

