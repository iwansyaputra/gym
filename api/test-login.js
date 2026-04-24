const bcrypt = require('bcryptjs');
const { pool } = require('./config/database');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const testLogin = async () => {
    try {
        const email = 'admin@gym.com';
        const password = 'admin123';

        console.log('🧪 Testing Login Flow...\n');
        console.log('📋 Configuration:');
        console.log('   DB Host:', process.env.DB_HOST || 'localhost');
        console.log('   DB Name:', process.env.DB_NAME || 'membership_gym');
        console.log('   DB User:', process.env.DB_USER || 'root');
        console.log('');

        console.log('🔐 Login Credentials:');
        console.log('   Email:', email);
        console.log('   Password:', password);
        console.log('');

        // Step 1: Find user
        console.log('📍 Step 1: Finding user...');
        const [users] = await pool.query(
            'SELECT * FROM users WHERE email = ?',
            [email]
        );

        if (users.length === 0) {
            console.log('   ❌ User not found');
            process.exit(1);
        }

        const user = users[0];
        console.log('   ✅ User found');
        console.log('      ID:', user.id);
        console.log('      Name:', user.nama);
        console.log('      Email:', user.email);
        console.log('      Role:', user.role);
        console.log('      Verified:', user.is_verified ? 'Yes' : 'No');
        console.log('');

        // Step 2: Check if verified
        console.log('📍 Step 2: Checking verification...');
        if (!user.is_verified) {
            console.log('   ❌ Account not verified');
            process.exit(1);
        }
        console.log('   ✅ Account is verified');
        console.log('');

        // Step 3: Verify password
        console.log('📍 Step 3: Verifying password...');
        const isPasswordValid = await bcrypt.compare(password, user.password);
        
        if (!isPasswordValid) {
            console.log('   ❌ Password is INVALID');
            console.log('      Stored hash:', user.password.substring(0, 30) + '...');
            process.exit(1);
        }
        console.log('   ✅ Password is VALID');
        console.log('');

        // Step 4: Check if admin
        console.log('📍 Step 4: Checking admin role...');
        if (user.role !== 'admin') {
            console.log('   ❌ User is not an admin');
            process.exit(1);
        }
        console.log('   ✅ User has admin role');
        console.log('');

        // Step 5: Generate token
        console.log('📍 Step 5: Generating JWT token...');
        const token = jwt.sign(
            {
                userId: user.id,
                email: user.email,
                role: user.role || 'user'
            },
            process.env.JWT_SECRET || 'gym_membership_secret_key_2024_very_secure_random_string',
            { expiresIn: '7d' }
        );
        console.log('   ✅ Token generated');
        console.log('      Token:', token.substring(0, 40) + '...');
        console.log('');

        console.log('✅ LOGIN SUCCESSFUL!\n');
        console.log('📊 Response Data:');
        console.log({
            success: true,
            message: 'Login berhasil',
            data: {
                token: token,
                user: {
                    id: user.id,
                    nama: user.nama,
                    email: user.email,
                    role: user.role
                }
            }
        });
        console.log('');
        console.log('💡 Sekarang coba login di browser lagi!');

        process.exit(0);
    } catch (error) {
        console.error('❌ Error:', error.message);
        console.error(error);
        process.exit(1);
    }
};

testLogin();
