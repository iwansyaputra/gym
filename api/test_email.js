const nodemailer = require('nodemailer');
require('dotenv').config();

// Konfigurasi manual untuk memastikan nilai yang dipakai benar
const config = {
    service: 'gmail',
    auth: {
        user: 'iwantugaskuliah@gmail.com',
        pass: 'rmtw utjw eohl gxhv' // App Password yang tadi Anda berikan
    }
};

console.log('🔄 Mencoba menghubungkan ke Gmail...');
console.log(`👤 User: ${config.auth.user}`);
// console.log(`🔑 Pass: ${config.auth.pass}`); // Jangan print password

const transporter = nodemailer.createTransport(config);

const mailOptions = {
    from: config.auth.user,
    to: config.auth.user, // Kirim ke diri sendiri untuk test
    subject: 'Test Email dari Node.js',
    text: 'Halo! Jika email ini masuk, berarti konfigurasi SMTP sudah benar.'
};

transporter.sendMail(mailOptions, (error, info) => {
    if (error) {
        console.log('\n❌ GAGAL MENGIRIM EMAIL!');
        console.log('Error Message:', error.message);
        console.log('Code:', error.code);
        console.log('Response:', error.response);

        if (error.response && error.response.includes('Username and Password not accepted')) {
            console.log('\n🔍 DIAGNOSA:');
            console.log('Password salah atau Alamat Email salah.');
            console.log('PENTING: App Password (16 digit) HARUS dibuat dari akun Google yang SAMA dengan alamat email pengirim.');
            console.log('Apakah "rmtw utjw eohl gxhv" digenerate dari akun "iwantugaskuliah@gmail.com"?');
        }
    } else {
        console.log('\n✅ BERHASIL MENGIRIM EMAIL!');
        console.log('Response:', info.response);
    }
});
