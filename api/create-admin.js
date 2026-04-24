const bcrypt = require('bcryptjs');
const { pool } = require('./config/database');
require('dotenv').config();

// Admin credentials
const ADMIN_EMAIL = 'admin@gym.com';
const ADMIN_PASSWORD = 'admin123';
const ADMIN_NAME = 'Admin Gym';
const ADMIN_PHONE = '08999999999';

const createAdminAccount = async () => {
    try {
        console.log('🔄 Creating admin account...\n');

        // Check if admin already exists
        const [existingAdmin] = await pool.query(
            'SELECT * FROM users WHERE email = ? OR role = ?',
            [ADMIN_EMAIL, 'admin']
        );

        if (existingAdmin.length > 0) {
            console.log('⚠️  Admin account sudah ada!');
            console.log('Email:', existingAdmin[0].email);
            console.log('Role:', existingAdmin[0].role);
            process.exit(0);
        }

        // Hash password
        const hashedPassword = await bcrypt.hash(ADMIN_PASSWORD, 10);
        console.log('✓ Password telah di-hash\n');

        // Insert admin user
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
            [ADMIN_NAME, ADMIN_EMAIL, ADMIN_PHONE, hashedPassword]
        );

        console.log('✅ Admin account berhasil dibuat!\n');
        console.log('📋 Detail Akun:');
        console.log('   Email    : ' + ADMIN_EMAIL);
        console.log('   Password : ' + ADMIN_PASSWORD);
        console.log('   Role     : admin');
        console.log('   Status   : Verified (aktif)\n');
        console.log('🔑 Sekarang Anda bisa login ke admin dashboard.\n');

        process.exit(0);
    } catch (error) {
        console.error('❌ Error creating admin account:', error.message);
        process.exit(1);
    }
};

// Run the function
createAdminAccount();
