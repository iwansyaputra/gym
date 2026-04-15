const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');

const NEW_DB_NAME = 'membership_gym_new';

const dbConfig = {
    host: 'localhost',
    user: 'root',
    password: '',
    port: 3307,
    multipleStatements: true
};

async function createNewDatabase() {
    console.log(`🔄 Creating FRESH database: ${NEW_DB_NAME}...`);

    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        console.log('✅ Connected to MySQL server');

        // Drop if exists (in case we ran this before)
        await connection.query(`DROP DATABASE IF EXISTS ${NEW_DB_NAME}`);
        await connection.query(`CREATE DATABASE ${NEW_DB_NAME}`);
        await connection.query(`USE ${NEW_DB_NAME}`);

        // Run Schema
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

        // Add 'role' column
        console.log('🔧 Adding role column...');
        try {
            await connection.query("ALTER TABLE users ADD COLUMN role VARCHAR(20) DEFAULT 'user' AFTER is_verified");
        } catch (e) {
            console.log('Role column issue (maybe already added):', e.message);
        }

        // Create User
        console.log('👤 Creating account for iwansyaputra031204@gmail.com...');
        const hash = await bcrypt.hash('12345678', 10);

        await connection.query(`
            INSERT INTO users (nama, email, hp, password, is_verified, role)
            VALUES (?, ?, ?, ?, 1, 'admin')
        `, ['Iwan Syaputra', 'iwansyaputra031204@gmail.com', '0812345678', hash]);

        // Update .env file
        console.log('📝 Updating .env to use new database...');
        const envPath = path.join(__dirname, '.env');
        let envContent = fs.readFileSync(envPath, 'utf8');

        // Replace DB_NAME
        // Regex to find DB_NAME=... and replace it
        if (envContent.includes('DB_NAME=')) {
            envContent = envContent.replace(/DB_NAME=.*/g, `DB_NAME=${NEW_DB_NAME}`);
        } else {
            envContent += `\nDB_NAME=${NEW_DB_NAME}`;
        }

        fs.writeFileSync(envPath, envContent);

        console.log('✅ SUCCESS! Database migrated to new name.');
        console.log('🔑 Login with: iwansyaputra031204@gmail.com / 12345678');

    } catch (error) {
        console.error('❌ FATAL ERROR:', error);
    } finally {
        if (connection) await connection.end();
    }
}

createNewDatabase();
