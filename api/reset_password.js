const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const dbConfig = {
    host: 'localhost',
    user: 'root',
    password: '',
    database: process.env.DB_NAME || 'membership_gym',
    port: 3307 // Explicitly use 3307
};

async function resetPassword() {
    console.log(`🔑 Resetting password on: ${dbConfig.database}:${dbConfig.port}`);
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);

        const hash = await bcrypt.hash('12345678', 10);
        console.log('Generated Hash length:', hash.length);

        const [result] = await connection.query(
            "UPDATE users SET password = ?, is_verified = 1 WHERE email = 'iwansyaputra031204@gmail.com'",
            [hash]
        );

        console.log(`Affected rows: ${result.affectedRows}`);
        if (result.affectedRows === 0) {
            console.log('User not found!');
        } else {
            console.log('✅ Password reset to 12345678');
        }

    } catch (error) {
        console.error('❌ Error resetting password:', error);
    } finally {
        if (connection) await connection.end();
    }
}

resetPassword();
