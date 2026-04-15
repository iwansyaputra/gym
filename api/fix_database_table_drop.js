const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');

const dbConfig = {
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'membership_gym', // Connect directly to DB
    port: 3307,
    multipleStatements: true
};

async function rebuildDatabase() {
    console.log('🔄 Starting database rebuild (Table Drop Method)...');

    let connection;
    try {
        // Only valid if DB exists. If DB doesn't exist, this throws error.
        try {
            connection = await mysql.createConnection(dbConfig);
        } catch (e) {
            // If DB doesn't exist, we must create it.
            console.log('Database might not exist, trying to create...');
            const conn2 = await mysql.createConnection({ ...dbConfig, database: undefined });
            await conn2.query('CREATE DATABASE IF NOT EXISTS membership_gym');
            await conn2.end();
            connection = await mysql.createConnection(dbConfig);
        }

        console.log('✅ Connected to database');

        // 1. Drop All Tables
        console.log('🗑️ Cleaning up tables...');
        await connection.query('SET FOREIGN_KEY_CHECKS = 0');

        const [tables] = await connection.query('SHOW TABLES');
        if (tables.length > 0) {
            const tableNames = tables.map(row => Object.values(row)[0]);
            console.log(`Found ${tableNames.length} tables to drop.`);
            for (const table of tableNames) {
                try {
                    await connection.query(`DROP TABLE IF EXISTS \`${table}\``);
                    console.log(`Dropped ${table}`);
                } catch (err) {
                    console.warn(`Failed to drop ${table}: ${err.message}`);
                }
            }
        }
        await connection.query('SET FOREIGN_KEY_CHECKS = 1');

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

        // 3. Add 'role' column
        console.log('🔧 Adding extra columns (role)...');
        try {
            await connection.query("ALTER TABLE users ADD COLUMN role VARCHAR(20) DEFAULT 'user' AFTER is_verified");
        } catch (e) {
            // Ignore if already exists (though it shouldn't)
        }

        // 4. Create User
        console.log('👤 Creating account for iwansyaputra031204@gmail.com...');
        const hash = await bcrypt.hash('12345678', 10);

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
