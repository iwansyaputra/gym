const { pool } = require('./config/database');

async function checkTableUser() {
    try {
        const [rows] = await pool.query('DESCRIBE users');
        console.log('Structure of table users:');
        rows.forEach(row => {
            console.log(`${row.Field} (${row.Type})`);
        });
        process.exit();
    } catch (error) {
        console.error(error);
        process.exit(1);
    }
}

checkTableUser();
