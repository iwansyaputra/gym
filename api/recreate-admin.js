const bcrypt = require('bcryptjs');
const { pool } = require('./config/database');
require('dotenv').config();

const recreateAdmin = async () => {
    try {
        console.log('🔄 Recreating admin account with verified password...\n');

        // Delete existing admin account
        await pool.query('DELETE FROM users WHERE email = ?', ['admin@gym.com']);
        console.log('✓ Old account deleted\n');

        // Hash password
        const plainPassword = 'admin123';
        const hashedPassword = await bcrypt.hash(plainPassword, 10);

        // Insert new admin user
        const [result] = await pool.query(
            `INSERT INTO users (
                nama, 
                email, 
                hp, 
                password, 
                is_verified, 
                role,
                created_at,
                updated_at
            ) VALUES (?, ?, ?, ?, TRUE, 'admin', NOW(), NOW())`,
            ['Admin Gym', 'admin@gym.com', '08999999999', hashedPassword]
        );

        console.log('✅ New admin account created!\n');

        // Verify password immediately
        const isPasswordValid = await bcrypt.compare(plainPassword, hashedPassword);
        console.log(`✓ Password verification: ${isPasswordValid ? '✅ SUCCESS' : '❌ FAILED'}\n`);

        console.log('📋 Login Credentials:');
        console.log('─'.repeat(40));
        console.log(`Email    : admin@gym.com`);
        console.log(`Password : admin123`);
        console.log(`Role     : admin`);
        console.log(`Status   : Verified & Active`);
        console.log('─'.repeat(40));

        console.log('\n🚀 Pastikan API server sedang berjalan:');
        console.log('   npm start  (atau  npm run dev)');
        console.log('\n💡 Jika masih error "Email atau password salah!":');
        console.log('   - Cek network tab di Developer Tools (F12)');
        console.log('   - Pastikan API endpoint bisa diakses');
        console.log('   - Cek IP config di admin_web/js/config.js\n');

        process.exit(0);
    } catch (error) {
        console.error('❌ Error:', error.message);
        process.exit(1);
    }
};

recreateAdmin();
