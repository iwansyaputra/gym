const { pool } = require('./config/database');

async function deleteUser() {
    const email = 'iwansyaputra031204@gmail.com';
    try {
        console.log(`Deleting data for ${email}...`);

        // Cari User ID dulu untuk hapus member cards
        const [users] = await pool.query('SELECT id FROM users WHERE email = ?', [email]);

        if (users.length > 0) {
            const userId = users[0].id;
            await pool.query('DELETE FROM member_cards WHERE user_id = ?', [userId]);
            await pool.query('DELETE FROM memberships WHERE user_id = ?', [userId]);
        }

        // Hapus OTPS
        await pool.query('DELETE FROM otps WHERE email = ?', [email]);

        // Hapus User (User dihapus, reference lain mungkin cascade atau error kalau tanpa cascade, tapi cards/membership sudah dihapus manual)
        const [res] = await pool.query('DELETE FROM users WHERE email = ?', [email]);

        if (res.affectedRows > 0) {
            console.log('User BERHASIL dihapus. Silakan register ulang dengan data yang benar.');
        } else {
            console.log('User tidak ditemukan.');
        }

    } catch (error) {
        console.error('Error deleting user:', error);
    } finally {
        process.exit();
    }
}

deleteUser();
