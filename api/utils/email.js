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
      <div style="font-family: 'Inter', 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #050810; padding: 40px 16px; text-align: left;">
        <div style="max-width: 520px; margin: 0 auto; background-color: #080d1a; border-radius: 20px; border: 1px solid rgba(0, 102, 255, 0.18); overflow: hidden; box-shadow: 0 20px 60px rgba(0, 0, 0, 0.7);">

          <!-- Top gradient bar -->
          <div style="height: 5px; background: linear-gradient(90deg, #0066ff 0%, #00d4ff 100%);"></div>

          <div style="padding: 36px 28px 32px 28px;">

            <!-- Logo -->
            <div style="text-align: center; margin-bottom: 28px;">
              <div style="display: inline-block; background: linear-gradient(135deg, rgba(0,102,255,0.15), rgba(0,212,255,0.08)); border: 1px solid rgba(0,212,255,0.2); border-radius: 14px; padding: 10px 24px;">
                <span style="font-size: 26px; font-weight: 900; letter-spacing: 2px; color: #ffffff;">GYM<span style="color: #00d4ff;">KU</span></span>
              </div>
              <div style="color: #475569; font-size: 10px; margin-top: 8px; letter-spacing: 3px; text-transform: uppercase; font-weight: 600;">Smart Fitness Ecosystem</div>
            </div>

            <!-- Title -->
            <h2 style="color: #f1f5f9; font-size: 19px; font-weight: 700; text-align: center; margin: 0 0 20px 0;">Verifikasi Akun Anda</h2>

            <p style="color: #cbd5e1; font-size: 14px; line-height: 1.65; margin: 0 0 8px 0;">
              Terima kasih telah mendaftar di <strong style="color: #ffffff;">GYMKU</strong>!
            </p>
            <p style="color: #64748b; font-size: 13px; line-height: 1.65; margin: 0 0 28px 0;">
              Masukkan kode OTP berikut untuk menyelesaikan verifikasi akun Anda:
            </p>

            <!-- OTP Box -->
            <div style="background: linear-gradient(135deg, rgba(0,102,255,0.07), rgba(0,212,255,0.04)); border: 1px solid rgba(0,212,255,0.22); padding: 28px 20px; text-align: center; border-radius: 16px; margin: 0 0 24px 0;">
              <div style="color: #00d4ff; font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 2.5px; margin-bottom: 18px;">Kode Verifikasi</div>
              <!-- Individual digit boxes — tidak akan wrap di mobile -->
              <div style="display: table; margin: 0 auto; border-collapse: separate; border-spacing: 8px 0;">
                <div style="display: table-row;">
                  ${otp.split('').map(d => `<div style="display:table-cell; width:42px; height:54px; vertical-align:middle; background: rgba(0,102,255,0.14); border: 1px solid rgba(0,212,255,0.35); border-radius: 10px; color: #ffffff; font-family: 'Courier New', monospace; font-size: 28px; font-weight: 800; text-align:center;">${d}</div>`).join('')}
                </div>
              </div>
              <div style="color: #475569; font-size: 11px; margin-top: 18px; letter-spacing: 0.5px;">Berlaku selama <strong style="color: #94a3b8;">5 menit</strong></div>
            </div>

            <!-- Warning alert -->
            <div style="background: rgba(124,58,237,0.09); border: 1px solid rgba(124,58,237,0.22); border-radius: 10px; padding: 13px 16px; margin-bottom: 24px;">
              <p style="color: #94a3b8; font-size: 12.5px; line-height: 1.55; margin: 0;">
                ⚡ Kode ini bersifat <strong style="color: #c4b5fd;">rahasia</strong>. Jangan bagikan kepada siapapun, termasuk pihak yang mengatasnamakan GYMKU.
              </p>
            </div>

            <p style="color: #334155; font-size: 12px; line-height: 1.5; text-align: center; margin: 0 0 28px 0;">
              Jika Anda tidak merasa mendaftar, abaikan email ini.
            </p>

            <!-- Footer -->
            <div style="border-top: 1px solid rgba(255,255,255,0.07); padding-top: 20px; text-align: center;">
              <p style="color: #1e293b; font-size: 11px; margin: 0; line-height: 1.6;">
                © 2026 <strong style="color: #334155;">GYMKU</strong> × Universitas Harkat Negeri. All rights reserved.
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
