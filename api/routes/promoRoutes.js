const express = require('express');
const router = express.Router();
const promoController = require('../controllers/promoController');

// Promo routes (public)
router.get('/', promoController.getPromos);
router.get('/:id', promoController.getPromoDetail);

module.exports = router;
