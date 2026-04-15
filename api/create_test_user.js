const bcrypt = require('bcryptjs');
const { pool } = require('./config/database');

async function createTestUser() {
    try {
        // Hash password
        const hashedPassword = await bcrypt.hash('password123', 10);
        
        // Delete existing test user if exists
        await pool.query('DELETE FROM users WHERE email = ?', ['test@gym.com']);
        
        // Create test user
        const [result] = await pool.query(
            'INSERT INTO users (nama, email, hp, password) VALUES (?, ?, ?, ?)',
            ['Test User', 'test@gym.com', '081234567890', hashedPassword]
        );
        
        console.log('✅ Test user created successfully!');
        console.log('Email: test@gym.com');
        console.log('Password: password123');
        console.log('User ID:', result.insertId);
        
        // Create active membership for test user
        const userId = result.insertId;
        await pool.query(
            'INSERT INTO memberships (user_id, paket, tanggal_mulai, tanggal_berakhir, status) VALUES (?, ?, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 30 DAY), ?)',
            [userId, 'bulanan', 'active']
        );
        
        console.log('✅ Active membership created for test user!');
        
        process.exit(0);
    } catch (error) {
        console.error('❌ Error creating test user:', error);
        process.exit(1);
    }
}

createTestUser();
