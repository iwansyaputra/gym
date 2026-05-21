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
const walletRoutes = require('./routes/walletRoutes');

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
app.use('/api/wallet', walletRoutes);

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

// Start server (Hanya berjalan di lokal, Vercel akan mengeksekusi module.exports)
if (!process.env.VERCEL) {
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
            });
        } catch (error) {
            console.error('Failed to start server:', error);
            process.exit(1);
        }
    };

    startServer();
}

module.exports = app;
