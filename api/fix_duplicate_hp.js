const mysql = require('mysql2/promise');
require('dotenv').config();

// Direct connection configuration to avoid import issues
const dbConfig = {
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'membership_gym',
    port: process.env.DB_PORT || 3306 // Ensure this matches your Laragon/MySQL port
};

async function fixDuplicates() {
    console.log('🔌 Connecting to database with config:', { ...dbConfig, password: '****' });
    let connection;

    try {
        connection = await mysql.createConnection(dbConfig);
        console.log('✅ Connected.');

        // 1. Check & Fix Duplicate HP
        console.log('🔍 Checking for duplicate HP numbers...');
        const [duplicateHps] = await connection.execute(`
            SELECT hp, COUNT(*) as count 
            FROM users 
            GROUP BY hp 
            HAVING count > 1
        `);

        if (duplicateHps.length > 0) {
            console.log(`⚠️ Found ${duplicateHps.length} sets of duplicate HPs.`);

            for (const dup of duplicateHps) {
                const hp = dup.hp;
                // Get all users with this HP, ordered by ID (keep the latest one or earliest one? Let's keep the latest one usually, or the one with more data. For now, keep the latest ID as "valid" and rename others.)
                const [users] = await connection.execute('SELECT id, email FROM users WHERE hp = ? ORDER BY id DESC', [hp]);

                // Skip the first one (latest), rename the rest
                for (let i = 1; i < users.length; i++) {
                    const user = users[i];
                    const newHp = `${hp}_OLD_${user.id}`;
                    await connection.execute('UPDATE users SET hp = ? WHERE id = ?', [newHp, user.id]);
                    console.log(`   > Renamed HP for user ${user.email} (ID: ${user.id}) to ${newHp}`);
                }
            }
        } else {
            console.log('✅ No duplicate HP numbers found.');
        }

        // 2. Check & Fix Duplicate Emails
        console.log('🔍 Checking for duplicate Emails...');
        const [duplicateEmails] = await connection.execute(`
            SELECT email, COUNT(*) as count 
            FROM users 
            GROUP BY email 
            HAVING count > 1
        `);

        if (duplicateEmails.length > 0) {
            console.log(`⚠️ Found ${duplicateEmails.length} sets of duplicate Emails.`);

            for (const dup of duplicateEmails) {
                const email = dup.email;
                const [users] = await connection.execute('SELECT id, nama FROM users WHERE email = ? ORDER BY id DESC', [email]);

                for (let i = 1; i < users.length; i++) {
                    const user = users[i];
                    const newEmail = `OLD_${user.id}_${email}`;
                    await connection.execute('UPDATE users SET email = ? WHERE id = ?', [newEmail, user.id]);
                    console.log(`   > Renamed Email for user ID ${user.id} to ${newEmail}`);
                }
            }
        } else {
            console.log('✅ No duplicate Emails found.');
        }

    } catch (error) {
        console.error('❌ Error during fix:', error);
    } finally {
        if (connection) await connection.end();
        console.log('👋 Done.');
    }
}

fixDuplicates();
