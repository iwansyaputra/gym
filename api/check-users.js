const { pool } = require('./config/database');
require('dotenv').config();

const checkUsers = async () => {
    try {
        const [users] = await pool.query(
            'SELECT id, nama, email, role, is_verified, password FROM users WHERE email = ? ORDER BY id DESC',
            ['admin@gym.com']
        );

        console.log('Total users with email admin@gym.com:', users.length);
        console.log('');

        users.forEach((u, i) => {
            console.log(`[${i + 1}] User ID: ${u.id}`);
            console.log(`   Name: ${u.nama}`);
            console.log(`   Email: ${u.email}`);
            console.log(`   Role: ${u.role}`);
            console.log(`   Is Verified: ${u.is_verified}`);
            console.log(`   Password Hash: ${u.password.substring(0, 20)}...`);
            console.log('');
        });

        process.exit(0);
    } catch (error) {
        console.error('Error:', error.message);
        process.exit(1);
    }
};

checkUsers();
