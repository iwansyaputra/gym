const express = require('express');
const os = require('os');
const cors = require('cors');
const bodyParser = require('body-parser');
require('dotenv').config();

const { testConnection } = require('./config/database');

// Import routes
const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const checkInRoutes = require('./routes/checkInRoutes');
const membershipRoutes = require('./routes/membershipRoutes');
const transactionRoutes = require('./routes/transactionRoutes');
const promoRoutes = require('./routes/promoRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const adminRoutes = require('./routes/adminRoutes');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Request logging middleware
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
    next();
});

// Health check endpoint
app.get('/', (req, res) => {
    res.json({
        success: true,
        message: 'Membership Gym API is running',
        version: '1.0.0',
        timestamp: new Date().toISOString()
    });
});

app.get('/health', (req, res) => {
    res.json({
        success: true,
        status: 'healthy',
        timestamp: new Date().toISOString()
    });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/user', userRoutes);
app.use('/api/check-in', checkInRoutes);
app.use('/api/membership', membershipRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/promos', promoRoutes);
app.use('/api/payment', paymentRoutes);
app.use('/api/admin', adminRoutes);

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'Endpoint tidak ditemukan'
    });
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('Error:', err);
    res.status(err.status || 500).json({
        success: false,
        message: err.message || 'Terjadi kesalahan pada server',
        ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    });
});

// Start server
const startServer = async () => {
    try {
        // Test database connection
        await testConnection();

        // Listen on all network interfaces (0.0.0.0) to allow access from mobile devices
        app.listen(PORT, '0.0.0.0', () => {
            const networkInterfaces = os.networkInterfaces();
            let networkIP = 'localhost';

            for (const interfaceName in networkInterfaces) {
                for (const iface of networkInterfaces[interfaceName]) {
                    if (iface.family === 'IPv4' && !iface.internal) {
                        networkIP = iface.address;
                        break;
                    }
                }
            }

            console.log('='.repeat(50));
            console.log(`🚀 Server running on port ${PORT}`);
            console.log(`📍 Local: http://localhost:${PORT}`);
            console.log(`📍 Network: http://${networkIP}:${PORT}`);
            console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
            console.log('='.repeat(50));
            console.log('\n📋 Available endpoints:');
            console.log('  GET  /                          - API info');
            console.log('  GET  /health                    - Health check');
            console.log('  POST /api/auth/register         - Register user');
            console.log('  POST /api/auth/login            - Login user');
            console.log('  POST /api/auth/verify-otp       - Verify OTP');
            console.log('  POST /api/auth/resend-otp       - Resend OTP');
            console.log('  GET  /api/user/profile          - Get user profile');
            console.log('  PUT  /api/user/profile          - Update profile');
            console.log('  PUT  /api/user/change-password  - Change password');
            console.log('  POST /api/check-in/nfc          - Check-in with NFC');
            console.log('  GET  /api/check-in/history      - Get check-in history');
            console.log('  GET  /api/check-in/stats        - Get check-in stats');
            console.log('  GET  /api/membership/info       - Get membership info');
            console.log('  GET  /api/membership/packages   - Get packages');
            console.log('  POST /api/membership/extend     - Extend membership');
            console.log('  GET  /api/transactions/history  - Get transactions');
            console.log('  GET  /api/transactions/:id      - Get transaction detail');
            console.log('  POST /api/transactions/create   - Create payment');
            console.log('  POST /api/transactions/confirm  - Confirm payment');
            console.log('  GET  /api/promos                - Get all promos');
            console.log('  GET  /api/promos/:id            - Get promo detail');
            console.log('  POST /api/payment/create        - Create payment (E-Smartlink)');
            console.log('  POST /api/payment/notification  - E-Smartlink callback');
            console.log('  GET  /api/payment/status/:id    - Check payment status');
            console.log('  GET  /api/payment/history       - Get payment history');
            console.log('='.repeat(50));
        });
    } catch (error) {
        console.error('Failed to start server:', error);
        process.exit(1);
    }
};

startServer();

module.exports = app;
