// Script to add admin role to database and create admin user
const { pool } = require('./config/database');
const bcrypt = require('bcryptjs');

async function setupAdminRole() {
    try {
        console.log('🔧 Setting up admin role...\n');

        // 1. Add role column to users table
        console.log('1. Adding role column to users table...');
        const [columns] = await pool.query(`
            SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_NAME = 'users'
            AND COLUMN_NAME = 'role'
        `);

        if (columns.length === 0) {
            await pool.query(`
                ALTER TABLE users
                ADD COLUMN role VARCHAR(20) DEFAULT 'user' AFTER is_verified
            `);
            console.log('✅ Role column added\n');
        } else {
            console.log('✅ Role column already exists\n');
        }

        // 2. Update existing users to have 'user' role
        console.log('2. Updating existing users to have user role...');
        await pool.query(`
            UPDATE users SET role = 'user' WHERE role IS NULL OR role = ''
        `);
        console.log('✅ Existing users updated\n');

        // 3. Check if admin user exists
        console.log('3. Checking for admin user...');
        const [existingAdmin] = await pool.query(
            'SELECT id, email FROM users WHERE email = ?',
            ['admin@gymku.com']
        );

        if (existingAdmin.length > 0) {
            console.log('⚠️  Admin user already exists, updating role...');
            await pool.query(
                'UPDATE users SET role = ? WHERE email = ?',
                ['admin', 'admin@gymku.com']
            );
            console.log('✅ Admin role updated for existing user\n');
        } else {
            // 4. Create admin user
            console.log('4. Creating admin user...');
            const hashedPassword = await bcrypt.hash('admin123', 10);

            await pool.query(`
                INSERT INTO users (
                    nama, 
                    email, 
                    password, 
                    hp, 
                    role,
                    is_verified, 
                    created_at
                ) VALUES (?, ?, ?, ?, ?, ?, NOW())
            `, [
                'Admin GymKu',
                'admin@gymku.com',
                hashedPassword,
                '081234567890',
                'admin',
                1
            ]);
            console.log('✅ Admin user created\n');
        }

        // 5. Display admin users
        console.log('5. Admin users in database:');
        const [adminUsers] = await pool.query(
            'SELECT id, nama, email, role, created_at FROM users WHERE role = ?',
            ['admin']
        );

        console.table(adminUsers);

        console.log('\n✅ Setup completed successfully!');
        console.log('\n📝 Admin credentials:');
        console.log('   Email: admin@gymku.com');
        console.log('   Password: admin123');
        console.log('\n⚠️  IMPORTANT: Change the admin password after first login!\n');

        process.exit(0);
    } catch (error) {
        console.error('❌ Error setting up admin role:', error);
        process.exit(1);
    }
}

// Run the setup
setupAdminRole();
