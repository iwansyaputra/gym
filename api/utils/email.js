const nodemailer = require('nodemailer');

// Create transporter
// Create transporter for Gmail
const transporter = nodemailer.createTransport({
  service: 'gmail', // Gunakan service 'gmail' bawaan nodemailer
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASSWORD
  }
});

// Generate 6-digit OTP
const generateOTP = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

// Send OTP email
const sendOTPEmail = async (email, otp) => {
  const mailOptions = {
    from: process.env.EMAIL_USER,
    to: email,
    subject: 'Kode OTP Verifikasi - Membership Gym',
    html: `
      <div style="font-family: Arial, sans-serif; padding: 20px; background-color: #f8f9fa;">
        <div style="max-width: 600px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 10px;">
          <h2 style="color: #E26D88; text-align: center;">Verifikasi Akun Anda</h2>
          <p>Terima kasih telah mendaftar di Membership Gym!</p>
          <p>Gunakan kode OTP berikut untuk verifikasi akun Anda:</p>
          <div style="background-color: #FDE3EA; padding: 20px; text-align: center; border-radius: 8px; margin: 20px 0;">
            <h1 style="color: #E26D88; margin: 0; font-size: 36px; letter-spacing: 5px;">${otp}</h1>
          </div>
          <p style="color: #666;">Kode OTP ini akan kadaluarsa dalam 5 menit.</p>
          <p style="color: #666;">Jika Anda tidak melakukan pendaftaran, abaikan email ini.</p>
          <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
          <p style="color: #999; font-size: 12px; text-align: center;">© 2024 Membership Gym. All rights reserved.</p>
        </div>
      </div>
    `
  };

  try {
    // DEVELOPMENT MODE: Selalu print OTP di console agar mudah ditest tanpa setup SMTP asli
    console.log('\n' + '='.repeat(60));
    console.log('📧  EMAIL SIMULATION (Development Mode)');
    console.log(`👤  To:      ${email}`);
    console.log(`🔢  OTP:     ${otp}  <--- MASUKKAN KODE INI DI APLIKASI`);
    console.log('='.repeat(60) + '\n');

    // KIRIM EMAIL SUNGGUHAN
    // Hapus pengecekan NODE_ENV agar email selalu dikirim
    try {
      console.log('🔄  Sedang mengirim email ke server Gmail...');
      const info = await transporter.sendMail(mailOptions);
      console.log('✅  Email terkirim! Response:', info.response);
      return true;
    } catch (sendError) {
      console.error('❌  Gagal saat sendMail:', sendError.message);
      throw sendError; // Lempar error ke blok catch luar
    }

  } catch (error) {
    console.error('⚠️  FINAL ERROR kirim email:', error.message);

    // Di development, meski gagal kirim email, kita return true biar user bisa testing
    // Tapi user akan lihat error log di atas
    if (process.env.NODE_ENV === 'development') {
      console.log('⚠️  Mode Dev: Menganggap sukses agar bisa lanjut verifikasi OTP manual.');
      return true;
    }
    return false;
  }
};

module.exports = { generateOTP, sendOTPEmail };
