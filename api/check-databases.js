const mysql = require('mysql2/promise');

// Create direct connection (tanpa pool) untuk cek both databases
const checkDatabases = async () => {
    const config = {
        host: 'localhost',
        user: 'root',
        password: '',
        port: 3306
    };

    try {
        console.log('🔍 Checking MySQL databases...\n');
        
        const connection = await mysql.createConnection(config);
        
        // List all databases
        const [databases] = await connection.query('SHOW DATABASES;');
        console.log('📊 Available databases:');
        databases.forEach(db => console.log('   -', db.Database));
        console.log('');

        // Check specific databases
        const dbNames = ['gym', 'membership_gym'];
        
        for (const dbName of dbNames) {
            try {
                const [tables] = await connection.query(
                    `SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ?`,
                    [dbName]
                );
                
                console.log(`📦 Database: ${dbName}`);
                console.log(`   Tables (${tables.length}):`);
                
                if (tables.length > 0) {
                    tables.forEach(t => console.log(`     - ${t.TABLE_NAME}`));
                    
                    // Check users table
                    if (tables.some(t => t.TABLE_NAME === 'users')) {
                        const [users] = await connection.query(
                            `SELECT id, nama, email, role FROM ${dbName}.users`
                        );
                        console.log(`   Users in ${dbName}:`);
                        users.forEach(u => {
                            console.log(`     [${u.id}] ${u.nama} (${u.email}) - Role: ${u.role}`);
                        });
                    }
                } else {
                    console.log('   (No tables)');
                }
                console.log('');
            } catch (e) {
                console.log(`   ❌ Database does not exist\n`);
            }
        }

        connection.end();
        process.exit(0);
    } catch (error) {
        console.error('❌ Error:', error.message);
        process.exit(1);
    }
};

checkDatabases();
