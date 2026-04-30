const express = require('express');
const router = express.Router();
const { getMyWallet, getMyWalletHistory, extendWithWallet } = require('../controllers/walletController');
const authenticateToken = require('../middleware/auth');

// GET /api/wallet/my — saldo wallet user yang login
router.get('/my', authenticateToken, getMyWallet);

// GET /api/wallet/my/history — riwayat transaksi wallet
router.get('/my/history', authenticateToken, getMyWalletHistory);

// POST /api/wallet/extend — perpanjang membership pakai saldo
router.post('/extend', authenticateToken, extendWithWallet);

module.exports = router;
