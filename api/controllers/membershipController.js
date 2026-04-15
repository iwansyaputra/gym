const { pool } = require('../config/database');
const moment = require('moment');

// Get membership info
const getMembershipInfo = async (req, res) => {
    try {
        const userId = req.user.userId;

        const [memberships] = await pool.query(
            'SELECT * FROM memberships WHERE user_id = ? ORDER BY tanggal_berakhir DESC LIMIT 1',
            [userId]
        );

        if (memberships.length === 0) {
            return res.json({
                success: true,
                data: null,
                message: 'Anda belum memiliki membership'
            });
        }

        const membership = memberships[0];
        const remainingDays = moment(membership.tanggal_berakhir).diff(moment(), 'days');

        res.json({
            success: true,
            data: {
                ...membership,
                remaining_days: remainingDays,
                is_active: remainingDays >= 0 && membership.status === 'active'
            }
        });

    } catch (error) {
        console.error('Get membership info error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server'
        });
    }
};

// Get membership packages
const getMembershipPackages = async (req, res) => {
    try {
        const packages = [
            {
                id: 1,
                nama: 'Paket Bulanan',
                durasi: 30,
                harga: 250000,
                deskripsi: 'Akses gym selama 1 bulan',
                fitur: [
                    'Akses semua alat gym',
                    'Konsultasi trainer 1x',
                    'Loker gratis'
                ]
            },
            {
                id: 2,
                nama: 'Paket 3 Bulan',
                durasi: 90,
                harga: 650000,
                deskripsi: 'Akses gym selama 3 bulan',
                fitur: [
                    'Akses semua alat gym',
                    'Konsultasi trainer 3x',
                    'Loker gratis',
                    'Diskon 13%'
                ]
            },
            {
                id: 3,
                nama: 'Paket 6 Bulan',
                durasi: 180,
                harga: 1200000,
                deskripsi: 'Akses gym selama 6 bulan',
                fitur: [
                    'Akses semua alat gym',
                    'Konsultasi trainer unlimited',
                    'Loker gratis',
                    'Diskon 20%',
                    'Free 1 sesi personal training'
                ]
            },
            {
                id: 4,
                nama: 'Paket Tahunan',
                durasi: 365,
                harga: 2500000,
                deskripsi: 'Akses gym selama 1 tahun',
                fitur: [
                    'Akses semua alat gym',
                    'Konsultasi trainer unlimited',
                    'Loker gratis',
                    'Diskon 30%',
                    'Free 3 sesi personal training',
                    'Akses kelas grup'
                ]
            }
        ];

        res.json({
            success: true,
            data: packages
        });

    } catch (error) {
        console.error('Get membership packages error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server'
        });
    }
};

// Extend membership
const extendMembership = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { package_id, payment_method } = req.body;

        if (!package_id || !payment_method) {
            return res.status(400).json({
                success: false,
                message: 'Package ID dan metode pembayaran harus diisi'
            });
        }

        // Get package info (hardcoded for now)
        const packages = {
            1: { durasi: 30, harga: 250000, nama: 'Paket Bulanan' },
            2: { durasi: 90, harga: 650000, nama: 'Paket 3 Bulan' },
            3: { durasi: 180, harga: 1200000, nama: 'Paket 6 Bulan' },
            4: { durasi: 365, harga: 2500000, nama: 'Paket Tahunan' }
        };

        const selectedPackage = packages[package_id];

        if (!selectedPackage) {
            return res.status(400).json({
                success: false,
                message: 'Paket tidak ditemukan'
            });
        }

        // Get current membership
        const [currentMemberships] = await pool.query(
            'SELECT * FROM memberships WHERE user_id = ? ORDER BY tanggal_berakhir DESC LIMIT 1',
            [userId]
        );

        let startDate, endDate;

        if (currentMemberships.length > 0 && moment(currentMemberships[0].tanggal_berakhir).isAfter(moment())) {
            // Extend from current end date
            startDate = moment(currentMemberships[0].tanggal_berakhir).add(1, 'day');
            endDate = moment(startDate).add(selectedPackage.durasi, 'days');
        } else {
            // Start from today
            startDate = moment();
            endDate = moment().add(selectedPackage.durasi, 'days');
        }

        // Create new membership
        const [membershipResult] = await pool.query(
            'INSERT INTO memberships (user_id, paket, tanggal_mulai, tanggal_berakhir, status) VALUES (?, ?, ?, ?, ?)',
            [userId, selectedPackage.nama, startDate.format('YYYY-MM-DD'), endDate.format('YYYY-MM-DD'), 'pending']
        );

        // Create transaction
        await pool.query(
            'INSERT INTO transactions (user_id, membership_id, jenis_transaksi, jumlah, metode_pembayaran, status) VALUES (?, ?, ?, ?, ?, ?)',
            [userId, membershipResult.insertId, 'perpanjangan', selectedPackage.harga, payment_method, 'pending']
        );

        res.json({
            success: true,
            message: 'Permintaan perpanjangan membership berhasil. Silakan lakukan pembayaran.',
            data: {
                membership_id: membershipResult.insertId,
                start_date: startDate.format('YYYY-MM-DD'),
                end_date: endDate.format('YYYY-MM-DD'),
                amount: selectedPackage.harga
            }
        });

    } catch (error) {
        console.error('Extend membership error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server'
        });
    }
};

module.exports = {
    getMembershipInfo,
    getMembershipPackages,
    extendMembership
};
