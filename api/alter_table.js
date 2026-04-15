const { pool } = require('./config/database');

async function addColumns() {
    try {
        console.log('Adding columns to users table...');

        await pool.query(`
            ALTER TABLE users 
            ADD COLUMN alamat TEXT DEFAULT NULL AFTER is_verified,
            ADD COLUMN jenis_kelamin ENUM('Laki-laki', 'Perempuan') DEFAULT NULL AFTER alamat,
            ADD COLUMN tanggal_lahir DATE DEFAULT NULL AFTER jenis_kelamin
        `);

        console.log('Columns added successfully!');
        process.exit();
    } catch (error) {
        if (error.code === 'ER_DUP_FIELDNAME') {
            console.log('Columns already exist.');
        } else {
            console.error('Error adding columns:', error);
        }
        process.exit();
    }
}

addColumns();
