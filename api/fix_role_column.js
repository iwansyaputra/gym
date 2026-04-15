const mysql = require('mysql2/promise');
require('dotenv').config();

const dbConfig = {
    host: 'localhost',
    user: 'root',
    password: '',
    database: process.env.DB_NAME || 'membership_gym',
    port: 3307
};

async function addRoleColumn() {
    console.log(`🔧 Fixing database: ${dbConfig.database} on port ${dbConfig.port}`);
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);

        // Check if column exists
        const [columns] = await connection.query("SHOW COLUMNS FROM users LIKE 'role'");
        if (columns.length === 0) {
            console.log("Column 'role' missing. Adding it now...");
            await connection.query("ALTER TABLE users ADD COLUMN role VARCHAR(20) DEFAULT 'user' AFTER is_verified");
            console.log("✅ Column 'role' added successfully.");
        } else {
            console.log("ℹ️ Column 'role' already exists.");
        }

        // Just in case, define the user again with the role if they don't have it
        // Or update them
        await connection.query("UPDATE users SET role='admin' WHERE email='iwansyaputra031204@gmail.com'");
        console.log("✅ User role updated to admin.");

    } catch (error) {
        console.error('❌ Error fixing database:', error);
    } finally {
        if (connection) await connection.end();
    }
}

addRoleColumn();
