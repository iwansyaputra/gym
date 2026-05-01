const { pool } = require('../config/database');
const moment = require('moment');

// Get all active promos (public — mobile app)
const getPromos = async (req, res) => {
    try {
        const [promos] = await pool.query(
            'SELECT * FROM promos WHERE is_active = TRUE AND tanggal_berakhir >= CURDATE() ORDER BY tanggal_mulai DESC'
        );

        const promosWithStatus = promos.map(promo => ({
            ...promo,
            diskon: promo.diskon_persen,   // alias agar Flutter bisa baca
            is_valid: moment().isBetween(moment(promo.tanggal_mulai), moment(promo.tanggal_berakhir)),
            days_remaining: moment(promo.tanggal_berakhir).diff(moment(), 'days')
        }));

        res.json({ success: true, data: promosWithStatus });
    } catch (error) {
        console.error('Get promos error:', error);
        res.status(500).json({ success: false, message: 'Terjadi kesalahan pada server' });
    }
};

// Get promo detail (public)
const getPromoDetail = async (req, res) => {
    try {
        const { id } = req.params;
        const [promos] = await pool.query('SELECT * FROM promos WHERE id = ?', [id]);

        if (promos.length === 0) {
            return res.status(404).json({ success: false, message: 'Promo tidak ditemukan' });
        }

        const promo = promos[0];
        res.json({
            success: true,
            data: {
                ...promo,
                diskon: promo.diskon_persen,
                is_valid: moment().isBetween(moment(promo.tanggal_mulai), moment(promo.tanggal_berakhir)),
                days_remaining: moment(promo.tanggal_berakhir).diff(moment(), 'days')
            }
        });
    } catch (error) {
        console.error('Get promo detail error:', error);
        res.status(500).json({ success: false, message: 'Terjadi kesalahan pada server' });
    }
};

// GET /promos/admin/all — semua promo termasuk yg tidak aktif (admin only)
const getAllPromosAdmin = async (req, res) => {
    try {
        const [promos] = await pool.query('SELECT * FROM promos ORDER BY created_at DESC');
        res.json({
            success: true,
            data: promos.map(p => ({
                ...p,
                diskon: p.diskon_persen,
                is_valid: moment().isBetween(moment(p.tanggal_mulai), moment(p.tanggal_berakhir)),
                days_remaining: moment(p.tanggal_berakhir).diff(moment(), 'days')
            }))
        });
    } catch (error) {
        console.error('getAllPromosAdmin error:', error);
        res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
    }
};

// POST /promos/admin — tambah promo baru (admin only)
const createPromo = async (req, res) => {
    try {
        const { judul, deskripsi, diskon_persen, tanggal_mulai, tanggal_berakhir, is_active } = req.body;

        if (!judul || !tanggal_mulai || !tanggal_berakhir) {
            return res.status(400).json({ success: false, message: 'judul, tanggal_mulai, tanggal_berakhir wajib diisi' });
        }

        const diskon = Math.max(0, Math.min(100, Number(diskon_persen) || 0));
        const active = is_active !== undefined ? Boolean(is_active) : true;

        const [result] = await pool.query(
            `INSERT INTO promos (judul, deskripsi, diskon_persen, tanggal_mulai, tanggal_berakhir, is_active)
             VALUES (?, ?, ?, ?, ?, ?)`,
            [judul, deskripsi || '', diskon, tanggal_mulai, tanggal_berakhir, active]
        );

        res.json({ success: true, message: 'Promo berhasil ditambahkan', data: { id: result.insertId } });
    } catch (error) {
        console.error('createPromo error:', error);
        res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
    }
};

// PUT /promos/admin/:id — update promo (admin only)
const updatePromo = async (req, res) => {
    try {
        const { id } = req.params;
        const { judul, deskripsi, diskon_persen, tanggal_mulai, tanggal_berakhir, is_active } = req.body;

        const [existing] = await pool.query('SELECT id FROM promos WHERE id = ?', [id]);
        if (existing.length === 0) {
            return res.status(404).json({ success: false, message: 'Promo tidak ditemukan' });
        }

        const diskon = Math.max(0, Math.min(100, Number(diskon_persen) || 0));

        await pool.query(
            `UPDATE promos SET judul=?, deskripsi=?, diskon_persen=?, tanggal_mulai=?, tanggal_berakhir=?, is_active=?
             WHERE id=?`,
            [judul, deskripsi || '', diskon, tanggal_mulai, tanggal_berakhir, Boolean(is_active), id]
        );

        res.json({ success: true, message: 'Promo berhasil diperbarui' });
    } catch (error) {
        console.error('updatePromo error:', error);
        res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
    }
};

// DELETE /promos/admin/:id — hapus promo (admin only)
const deletePromo = async (req, res) => {
    try {
        const { id } = req.params;
        await pool.query('DELETE FROM promos WHERE id = ?', [id]);
        res.json({ success: true, message: 'Promo berhasil dihapus' });
    } catch (error) {
        console.error('deletePromo error:', error);
        res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
    }
};

// GET /promos/active-discount — kembalikan diskon promo aktif tertinggi (dipakai membership_packages untuk sync harga)
const getActiveDiscount = async (req, res) => {
    try {
        const [rows] = await pool.query(
            `SELECT id, judul, diskon_persen FROM promos
             WHERE is_active = TRUE AND tanggal_mulai <= CURDATE() AND tanggal_berakhir >= CURDATE()
             ORDER BY diskon_persen DESC LIMIT 1`
        );

        if (rows.length === 0) {
            return res.json({ success: true, data: null });
        }

        const promo = rows[0];
        res.json({
            success: true,
            data: {
                id: promo.id,
                judul: promo.judul,
                diskon_persen: promo.diskon_persen
            }
        });
    } catch (error) {
        console.error('getActiveDiscount error:', error);
        res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
    }
};

module.exports = {
    getPromos,
    getPromoDetail,
    getAllPromosAdmin,
    createPromo,
    updatePromo,
    deletePromo,
    getActiveDiscount
};

