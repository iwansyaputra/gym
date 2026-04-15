const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const dbConfig = {
    host: 'localhost',
    user: 'root',
    password: '',
    database: process.env.DB_NAME || 'membership_gym',
    port: 3307
};

async function ensureUser() {
    console.log(`👤 Checking user in: ${dbConfig.database}`);
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);

        const [rows] = await connection.query("SELECT * FROM users WHERE email = 'iwansyaputra031204@gmail.com'");

        if (rows.length === 0) {
            console.log('User missing. Creating...');
            const hash = await bcrypt.hash('12345678', 10);
            await connection.query(`
                INSERT INTO users (nama, email, hp, password, is_verified, role)
                VALUES (?, ?, ?, ?, 1, 'admin')
            `, ['Iwan Syaputra', 'iwansyaputra031204@gmail.com', '0812345678', hash]);
            console.log('✅ User created successfully.');
        } else {
            console.log('✅ User already exists.');
        }

    } catch (error) {
        console.error('❌ Error checking/creating user:', error);
    } finally {
        if (connection) await connection.end();
    }
}

ensureUser();
