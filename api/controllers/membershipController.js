const { pool } = require('../config/database');
const moment = require('moment');
const fs = require('fs');
const path = require('path');

const packagesPath = path.join(__dirname, '../config/packages.json');

const loadPackages = () => {
    try {
        const data = fs.readFileSync(packagesPath, 'utf8');
        return JSON.parse(data);
    } catch (err) {
        console.error('Error reading packages.json:', err);
        return [];
    }
};

const savePackages = (packages) => {
    fs.writeFileSync(packagesPath, JSON.stringify(packages, null, 4), 'utf8');
};

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
        const packages = loadPackages();

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

// Update membership package price
const updateMembershipPackage = async (req, res) => {
    try {
        const { id } = req.params;
        const { harga, nama, durasi, deskripsi, fitur } = req.body;

        if (harga === undefined || harga < 0) {
            return res.status(400).json({ success: false, message: 'Harga tidak valid' });
        }

        const packages = loadPackages();
        const pkgIndex = packages.findIndex(p => p.id == id);
        
        if (pkgIndex === -1) {
            return res.status(404).json({ success: false, message: 'Paket tidak ditemukan' });
        }

        packages[pkgIndex].harga = Number(harga);
        if (nama) packages[pkgIndex].nama = nama;
        if (durasi) packages[pkgIndex].durasi = Number(durasi);
        if (deskripsi) packages[pkgIndex].deskripsi = deskripsi;
        if (fitur && Array.isArray(fitur)) packages[pkgIndex].fitur = fitur;

        savePackages(packages);

        res.json({
            success: true,
            message: 'Detail paket berhasil diperbarui',
            data: packages[pkgIndex]
        });
    } catch (error) {
        console.error('Update membership package error:', error);
        res.status(500).json({ success: false, message: 'Terjadi kesalahan internal' });
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

        const packageList = loadPackages();
        const selectedPackage = packageList.find(p => p.id == package_id);

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
    updateMembershipPackage,
    extendMembership
};
