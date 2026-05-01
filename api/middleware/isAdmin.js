/// Middleware isAdmin — pastikan user yang login memiliki role 'admin'
/// Harus digunakan setelah authenticateToken middleware
const isAdmin = (req, res, next) => {
    if (!req.user) {
        return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    if (req.user.role !== 'admin') {
        return res.status(403).json({
            success: false,
            message: 'Akses ditolak. Hanya admin yang dapat menggunakan fitur ini.'
        });
    }

    next();
};

module.exports = isAdmin;
