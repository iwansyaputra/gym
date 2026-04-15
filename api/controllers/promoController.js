const { pool } = require('../config/database');
const moment = require('moment');

// Get all active promos
const getPromos = async (req, res) => {
    try {
        const [promos] = await pool.query(
            'SELECT * FROM promos WHERE is_active = TRUE AND tanggal_berakhir >= CURDATE() ORDER BY tanggal_mulai DESC'
        );

        // Add status for each promo
        const promosWithStatus = promos.map(promo => ({
            ...promo,
            is_valid: moment().isBetween(moment(promo.tanggal_mulai), moment(promo.tanggal_berakhir)),
            days_remaining: moment(promo.tanggal_berakhir).diff(moment(), 'days')
        }));

        res.json({
            success: true,
            data: promosWithStatus
        });

    } catch (error) {
        console.error('Get promos error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server'
        });
    }
};

// Get promo detail
const getPromoDetail = async (req, res) => {
    try {
        const { id } = req.params;

        const [promos] = await pool.query(
            'SELECT * FROM promos WHERE id = ?',
            [id]
        );

        if (promos.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Promo tidak ditemukan'
            });
        }

        const promo = promos[0];

        res.json({
            success: true,
            data: {
                ...promo,
                is_valid: moment().isBetween(moment(promo.tanggal_mulai), moment(promo.tanggal_berakhir)),
                days_remaining: moment(promo.tanggal_berakhir).diff(moment(), 'days')
            }
        });

    } catch (error) {
        console.error('Get promo detail error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server'
        });
    }
};

module.exports = {
    getPromos,
    getPromoDetail
};
