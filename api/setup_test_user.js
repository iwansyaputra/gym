const bcrypt = require('bcryptjs');
const { pool } = require('./config/database');

const setupTestUser = async () => {
    try {
        console.log('🔧 Setup Test User Started...');

        // Password untuk test user: "password123"
        const testPassword = 'password123';
        const hashedPassword = await bcrypt.hash(testPassword, 10);

        console.log('✅ Password Hash Generated:', hashedPassword);

        // Check if user exists
        const [existing] = await pool.query(
            'SELECT * FROM users WHERE email = ?',
            ['test@example.com']
        );

        if (existing.length > 0) {
            console.log('⚠️  Test user already exists');
            return;
        }

        // Insert test user
        const [result] = await pool.query(
            'INSERT INTO users (nama, email, hp, password) VALUES (?, ?, ?, ?)',
            ['Test User', 'test@example.com', '08999888777', hashedPassword]
        );

        console.log('✅ Test User Created:');
        console.log('   Email: test@example.com');
        console.log('   Password: password123');
        console.log('   User ID:', result.insertId);

        // Insert test membership
        const userId = result.insertId;
        const [membershipResult] = await pool.query(
            'INSERT INTO memberships (user_id, paket, tanggal_mulai, tanggal_berakhir, status) VALUES (?, ?, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 30 DAY), ?)',
            [userId, 'bulanan', 'active']
        );

        console.log('✅ Test Membership Created (30 hari active)');

        // Insert test member card
        await pool.query(
            'INSERT INTO member_cards (user_id, card_number, nfc_id, is_active) VALUES (?, ?, ?, ?)',
            [userId, 'CARD-' + userId, 'NFC-' + userId, true]
        );

        console.log('✅ Test Member Card Created');
        console.log('\n✅ Setup Complete! You can now login with:');
        console.log('   Email: test@example.com');
        console.log('   Password: password123');

    } catch (error) {
        console.error('❌ Setup Error:', error.message);
    } finally {
        process.exit(0);
    }
};

setupTestUser();
