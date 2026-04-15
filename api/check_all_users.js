
const mysql = require('mysql2/promise');
require('dotenv').config();

async function checkAllUsers() {
    const dbConfig = {
        host: process.env.DB_HOST || 'localhost',
        user: process.env.DB_USER || 'root',
        password: process.env.DB_PASSWORD || '',
        database: process.env.DB_NAME || 'membership_gym',
        port: process.env.DB_PORT || 3306
    };

    try {
        const connection = await mysql.createConnection(dbConfig);
        const [rows] = await connection.execute('SELECT id, nama, email, role, is_verified FROM users');
        console.log('--- ALL USERS ---');
        console.table(rows);
        await connection.end();
    } catch (error) {
        console.error('Error:', error);
    }
}

checkAllUsers();
