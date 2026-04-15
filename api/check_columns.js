const mysql = require('mysql2/promise');
require('dotenv').config();

const dbConfig = {
    host: 'localhost',
    user: 'root',
    password: '',
    database: process.env.DB_NAME || 'membership_gym_new',
    port: 3307
};

async function checkColumns() {
    console.log(`Checking columns for database: ${dbConfig.database} on port ${dbConfig.port}`);
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const [rows] = await connection.query("SHOW COLUMNS FROM users");
        console.log('Columns in users table:');
        rows.forEach(row => {
            console.log(`- ${row.Field} (${row.Type})`);
        });
    } catch (error) {
        console.error('Error checking columns:', error);
    } finally {
        if (connection) await connection.end();
    }
}

checkColumns();
