const jwt = require('jsonwebtoken');
const { pool } = require('../config/database');

const authMiddleware = async (req, res, next) => {
    try {
        // Get token from header
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                success: false,
                message: 'Token tidak ditemukan. Silakan login terlebih dahulu.'
            });
        }

        const token = authHeader.substring(7); // Remove 'Bearer ' prefix

        // Verify token
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        // Add user info to request
        req.user = decoded;

        next();
    } catch (error) {
        if (error.name === 'TokenExpiredError') {
            return res.status(401).json({
                success: false,
                message: 'Token telah kadaluarsa. Silakan login kembali.'
            });
        }

        return res.status(401).json({
            success: false,
            message: 'Token tidak valid.'
        });
    }
};

// Middleware to check if user is admin
const isAdmin = async (req, res, next) => {
    try {
        const userId = req.user.userId;

        // Check if user has admin role
        const [users] = await pool.query(
            'SELECT role FROM users WHERE id = ?',
            [userId]
        );

        if (users.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'User tidak ditemukan.'
            });
        }

        if (users[0].role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Akses ditolak. Hanya admin yang dapat mengakses.'
            });
        }

        next();
    } catch (error) {
        console.error('Error checking admin role:', error);
        return res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan saat memeriksa role.'
        });
    }
};

// Export both as named exports and default
module.exports = authMiddleware;
module.exports.verifyToken = authMiddleware;
module.exports.isAdmin = isAdmin;
