const bcrypt = require('bcryptjs');
const { pool } = require('./config/database');
require('dotenv').config();

// Test password verification
const testPassword = async () => {
    try {
        const email = 'admin@gym.com';
        const password = 'admin123';

        console.log('🔍 Testing password verification...\n');
        console.log(`Email: ${email}`);
        console.log(`Password Input: ${password}\n`);

        // Get user from database
        const [users] = await pool.query(
            'SELECT * FROM users WHERE email = ?',
            [email]
        );

        if (users.length === 0) {
            console.log('❌ User tidak ditemukan');
            process.exit(1);
        }

        const user = users[0];
        console.log(`User found: ${user.nama}`);
        console.log(`Role: ${user.role}`);
        console.log(`Is Verified: ${user.is_verified}`);
        console.log(`Stored Hash: ${user.password}\n`);

        // Test bcrypt comparison
        const isPasswordValid = await bcrypt.compare(password, user.password);

        console.log(`Password Match: ${isPasswordValid ? '✅ YES' : '❌ NO'}`);

        if (!isPasswordValid) {
            console.log('\n🔧 Troubleshooting:');
            console.log('- Trying to create new hash for comparison...');

            const newHash = await bcrypt.hash(password, 10);
            console.log(`New Hash: ${newHash}`);

            const matchWithNew = await bcrypt.compare(password, newHash);
            console.log(`Matches with new hash: ${matchWithNew ? '✅ YES' : '❌ NO'}`);

            console.log('\n💡 Solution: Update database with new hash');
            await pool.query(
                'UPDATE users SET password = ? WHERE email = ?',
                [newHash, email]
            );
            console.log('✅ Password updated in database!');
        }

        process.exit(0);
    } catch (error) {
        console.error('❌ Error:', error.message);
        process.exit(1);
    }
};

testPassword();
