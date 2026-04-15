const { pool } = require('./config/database');

async function checkDatabase() {
    try {
        console.log('🔍 Checking database connection...\n');

        // Test connection
        const connection = await pool.getConnection();
        console.log('✅ Connected to MySQL server!\n');

        // Check if database exists
        const [databases] = await connection.query('SHOW DATABASES');
        console.log('📋 Available databases:');
        databases.forEach(db => {
            console.log(`   - ${db.Database}`);
        });

        // Check if membership_gym exists
        const dbExists = databases.some(db => db.Database === 'membership_gym');

        if (!dbExists) {
            console.log('\n⚠️  Database "membership_gym" NOT FOUND!');
            console.log('Creating database...');
            await connection.query('CREATE DATABASE membership_gym');
            console.log('✅ Database "membership_gym" created!\n');
        } else {
            console.log('\n✅ Database "membership_gym" exists!\n');
        }

        // Use the database
        await connection.query('USE membership_gym');

        // Check tables
        const [tables] = await connection.query('SHOW TABLES');

        if (tables.length === 0) {
            console.log('⚠️  No tables found in database!');
            console.log('You need to run the schema.sql file.\n');
        } else {
            console.log('📊 Tables in database:');
            tables.forEach(table => {
                const tableName = table[`Tables_in_membership_gym`];
                console.log(`   - ${tableName}`);
            });
            console.log('');
        }

        // Check users table structure
        if (tables.length > 0) {
            try {
                const [columns] = await connection.query(`
                    SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT
                    FROM INFORMATION_SCHEMA.COLUMNS 
                    WHERE TABLE_SCHEMA = 'membership_gym' 
                    AND TABLE_NAME = 'users'
                    ORDER BY ORDINAL_POSITION
                `);

                if (columns.length > 0) {
                    console.log('👤 Users table structure:');
                    columns.forEach(col => {
                        console.log(`   - ${col.COLUMN_NAME} (${col.COLUMN_TYPE})`);
                    });
                    console.log('');
                }
            } catch (err) {
                console.log('⚠️  Could not check users table structure');
            }
        }

        connection.release();
        console.log('🎉 Database check complete!\n');

        process.exit(0);
    } catch (error) {
        console.error('\n❌ Error:', error.message);
        console.error('\n💡 Troubleshooting:');
        console.error('   1. Make sure MySQL is running (Laragon or other local MySQL)');
        console.error('   2. Check if MySQL is running on port 3306');
        console.error('   3. Verify .env file has correct database credentials');
        console.error('   4. Try opening phpMyAdmin: http://localhost/phpmyadmin\n');
        process.exit(1);
    }
}

checkDatabase();
