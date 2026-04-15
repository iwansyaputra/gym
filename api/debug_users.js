
const mysql = require('mysql2/promise');
require('dotenv').config();

async function checkUsers() {
    const pool = mysql.createPool({
        host: process.env.DB_HOST || 'localhost',
        user: process.env.DB_USER || 'root',
        password: process.env.DB_PASSWORD || '',
        database: process.env.DB_NAME || 'membership_gym',
        port: process.env.DB_PORT || 3306
    });

    try {
        const [rows] = await pool.query('SELECT email, role, is_verified FROM users');
        console.log('Users found:', rows);
    } catch (error) {
        console.error('Error fetching users:', error);
    } finally {
        pool.end();
    }
}

checkUsers();
