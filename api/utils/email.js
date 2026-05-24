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
      <div style="font-family: 'Inter', 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #050810; padding: 40px 20px; text-align: left;">
        <div style="max-width: 560px; margin: 0 auto; background-color: #080d1a; border-radius: 16px; border: 1px solid rgba(0, 102, 255, 0.15); overflow: hidden; box-shadow: 0 12px 40px rgba(0, 0, 0, 0.6);">
          <!-- Top Accent Gradient -->
          <div style="height: 6px; background: linear-gradient(90deg, #0066ff, #00d4ff);"></div>
          
          <div style="padding: 40px 35px 35px 35px;">
            <!-- Header Brand -->
            <div style="text-align: center; margin-bottom: 30px;">
              <h1 style="color: #ffffff; font-size: 28px; font-weight: 800; margin: 0; letter-spacing: 1px;">
                <span style="background: linear-gradient(135deg, #0066ff, #00d4ff); -webkit-background-clip: text; -webkit-text-fill-color: transparent; color: #00d4ff;">GYM</span>KU
              </h1>
              <div style="color: #94a3b8; font-size: 11px; margin-top: 6px; letter-spacing: 2px; text-transform: uppercase; font-weight: 600;">Smart Fitness Ecosystem</div>
            </div>

            <!-- Body Title -->
            <h2 style="color: #ffffff; font-size: 20px; font-weight: 700; text-align: center; margin-top: 0; margin-bottom: 24px;">Verifikasi Akun Anda</h2>
            
            <p style="color: #e2e8f0; font-size: 15px; line-height: 1.6; margin-bottom: 12px; margin-top: 0;">Terima kasih telah mendaftar di <strong>GYMKU</strong>!</p>
            <p style="color: #94a3b8; font-size: 14px; line-height: 1.6; margin-bottom: 28px; margin-top: 0;">Gunakan kode OTP di bawah ini untuk menyelesaikan proses verifikasi pendaftaran akun Anda:</p>
            
            <!-- OTP Box Container -->
            <div style="background: rgba(0, 102, 255, 0.05); border: 1px dashed rgba(0, 212, 255, 0.3); padding: 24px; text-align: center; border-radius: 12px; margin: 28px 0;">
              <div style="color: #00d4ff; font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: 1.5px; margin-bottom: 8px;">KODE VERIFIKASI (OTP)</div>
              <div style="color: #ffffff; font-family: 'Courier New', Courier, monospace; font-size: 40px; font-weight: 800; margin: 0; letter-spacing: 8px;">${otp}</div>
            </div>
            
            <!-- Information Alert -->
            <div style="background-color: rgba(124, 58, 237, 0.08); border-left: 3px solid #7c3aed; padding: 14px 18px; border-radius: 6px; margin-bottom: 28px;">
              <p style="color: #94a3b8; font-size: 13px; line-height: 1.5; margin: 0;">
                ⚡ Kode OTP ini bersifat rahasia dan akan kadaluarsa dalam waktu <strong>5 menit</strong>.
              </p>
            </div>
            
            <p style="color: #64748b; font-size: 13px; line-height: 1.5; margin-bottom: 35px; text-align: center; margin-top: 0;">
              Jika Anda tidak merasa melakukan pendaftaran, abaikan email ini dengan aman.
            </p>
            
            <!-- Footer -->
            <div style="border-top: 1px solid rgba(255, 255, 255, 0.08); padding-top: 24px; text-align: center;">
              <p style="color: #64748b; font-size: 11px; margin: 0; line-height: 1.6;">
                © 2026 GYMKU X Universitas Harkat Negeri. All rights reserved.
              </p>
            </div>
          </div>
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
