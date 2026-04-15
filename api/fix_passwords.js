const bcrypt = require('bcryptjs');
const { pool } = require('./config/database');
const readline = require('readline');

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

async function fixPasswords() {
    try {
        console.log('🔍 Mencari user di database...\n');

        // Get all users
        const [users] = await pool.query('SELECT id, nama, email, password FROM users');

        if (users.length === 0) {
            console.log('❌ Tidak ada user di database');
            process.exit(0);
        }

        console.log(`Ditemukan ${users.length} user:\n`);
        users.forEach((user, index) => {
            const isHashed = user.password.startsWith('$2a$') || user.password.startsWith('$2b$');
            console.log(`${index + 1}. ${user.nama} (${user.email}) - Password ${isHashed ? 'sudah di-hash ✅' : 'BELUM di-hash ❌'}`);
        });

        console.log('\n' + '='.repeat(60));
        console.log('PILIHAN:');
        console.log('1. Hash semua password yang belum di-hash dengan password default');
        console.log('2. Hash password untuk user tertentu dengan password custom');
        console.log('3. Lihat daftar user saja (tidak mengubah apapun)');
        console.log('='.repeat(60));

        rl.question('\nPilih opsi (1/2/3): ', async (choice) => {
            if (choice === '1') {
                // Hash all unhashed passwords with default password
                rl.question('Masukkan password default untuk semua user (contoh: password123): ', async (defaultPassword) => {
                    if (!defaultPassword) {
                        console.log('❌ Password tidak boleh kosong');
                        rl.close();
                        process.exit(1);
                    }

                    const hashedPassword = await bcrypt.hash(defaultPassword, 10);
                    let updated = 0;

                    for (const user of users) {
                        const isHashed = user.password.startsWith('$2a$') || user.password.startsWith('$2b$');
                        if (!isHashed) {
                            await pool.query('UPDATE users SET password = ? WHERE id = ?', [hashedPassword, user.id]);
                            console.log(`✅ Password untuk ${user.nama} (${user.email}) berhasil di-hash`);
                            updated++;
                        }
                    }

                    console.log(`\n✨ Selesai! ${updated} password berhasil di-hash`);
                    console.log(`Password untuk semua user yang di-update: ${defaultPassword}`);
                    rl.close();
                    process.exit(0);
                });
            } else if (choice === '2') {
                // Hash password for specific user
                rl.question('Masukkan email user: ', async (email) => {
                    const user = users.find(u => u.email === email);
                    if (!user) {
                        console.log('❌ User tidak ditemukan');
                        rl.close();
                        process.exit(1);
                    }

                    rl.question(`Masukkan password baru untuk ${user.nama}: `, async (password) => {
                        if (!password) {
                            console.log('❌ Password tidak boleh kosong');
                            rl.close();
                            process.exit(1);
                        }

                        const hashedPassword = await bcrypt.hash(password, 10);
                        await pool.query('UPDATE users SET password = ? WHERE id = ?', [hashedPassword, user.id]);

                        console.log(`\n✅ Password untuk ${user.nama} (${user.email}) berhasil diupdate`);
                        console.log(`Email: ${email}`);
                        console.log(`Password: ${password}`);
                        rl.close();
                        process.exit(0);
                    });
                });
            } else if (choice === '3') {
                console.log('\n✅ Selesai melihat daftar user');
                rl.close();
                process.exit(0);
            } else {
                console.log('❌ Pilihan tidak valid');
                rl.close();
                process.exit(1);
            }
        });

    } catch (error) {
        console.error('❌ Error:', error);
        rl.close();
        process.exit(1);
    }
}

fixPasswords();
