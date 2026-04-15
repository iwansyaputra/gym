const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');

const dbConfig = {
    host: 'localhost',
    user: 'root',
    password: '',
    port: 3307,
    multipleStatements: true
};

async function rebuildDatabase() {
    console.log('🔄 Starting database rebuild...');

    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        console.log('✅ Connected to MySQL server');

        // 1. Drop and Recreate
        console.log('🗑️ Dropping existing database...');
        await connection.query('DROP DATABASE IF EXISTS membership_gym');
        console.log('✨ Creating new database...');
        await connection.query('CREATE DATABASE membership_gym');
        await connection.query('USE membership_gym');

        // 2. Run Schema
        const schemaPath = path.join(__dirname, 'database', 'schema.sql');
        let schemaSql = fs.readFileSync(schemaPath, 'utf8');
        const statements = schemaSql.split(';').map(s => s.trim()).filter(s => s.length > 0);

        console.log(`📝 Executing ${statements.length} schema statements...`);
        for (const stmt of statements) {
            if (stmt.toUpperCase().startsWith('CREATE DATABASE') || stmt.toUpperCase().startsWith('USE ')) continue;
            try {
                await connection.query(stmt);
            } catch (err) {
                console.warn(`⚠️ Warning: ${err.message}`);
            }
        }

        // 3. Add 'role' column (missing in schema.sql but required)
        console.log('🔧 Adding extra columns (role)...');
        try {
            await connection.query("ALTER TABLE users ADD COLUMN role VARCHAR(20) DEFAULT 'user' AFTER is_verified");
        } catch (e) {
            console.log('Role column might already exist or error:', e.message);
        }

        // 4. Create User 'iwansyaputra031204@gmail.com'
        console.log('👤 Creating account for iwansyaputra031204@gmail.com...');
        // Password: 12345678
        const hash = await bcrypt.hash('12345678', 10);

        // Check if user exists first (though we just dropped DB, so they won't)
        // Using 'nama' and 'hp' as per schema.sql
        await connection.query(`
            INSERT INTO users (nama, email, hp, password, is_verified, role)
            VALUES (?, ?, ?, ?, 1, 'admin')
        `, ['Iwan Syaputra', 'iwansyaputra031204@gmail.com', '0812345678', hash]);

        console.log('✅ Database repaired and user created!');
        console.log('🔑 Email: iwansyaputra031204@gmail.com');
        console.log('🔑 Password: 12345678');

    } catch (error) {
        console.error('❌ FATAL ERROR:', error);
    } finally {
        if (connection) await connection.end();
    }
}

rebuildDatabase();
