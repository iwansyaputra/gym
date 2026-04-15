const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { pool } = require('../config/database');
const { generateOTP, sendOTPEmail } = require('../utils/email');
const moment = require('moment');

// Register new user
const register = async (req, res) => {
    try {
        const { nama, email, hp, password, alamat, jenis_kelamin, tanggal_lahir } = req.body;

        // Validation - Basic fields mandatory
        if (!nama || !email || !hp || !password) {
            return res.status(400).json({
                success: false,
                message: 'Semua field harus diisi'
            });
        }

        // Check if user already exists (Email or HP)
        const [existingUsers] = await pool.query(
            'SELECT * FROM users WHERE email = ? OR hp = ?',
            [email, hp]
        );

        let userId;

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 10);

        if (existingUsers.length > 0) {
            const existingUser = existingUsers[0];

            // Cek apakah yang duplicate adalah Email atau HP
            if (existingUser.email === email && existingUser.is_verified) {
                return res.status(400).json({
                    success: false,
                    message: 'Email sudah terdaftar. Silakan login.'
                });
            }

            if (existingUser.hp === hp && existingUser.is_verified) {
                return res.status(400).json({
                    success: false,
                    message: 'Nomor HP sudah terdaftar. Gunakan nomor lain.'
                });
            }

            // Jika belum verified, kita bisa update datanya (Resend OTP / Retry Register)
            // Tapi pastikan kita mengupdate user yang BENAR (match email)
            if (existingUser.email !== email) {
                return res.status(400).json({
                    success: false,
                    message: 'Nomor HP sudah digunakan oleh akun lain.'
                });
            }

            // Update data user (termasuk alamat dll)
            await pool.query(
                `UPDATE users SET 
                    nama = ?, 
                    hp = ?, 
                    password = ?, 
                    alamat = ?, 
                    jenis_kelamin = ?, 
                    tanggal_lahir = ?,
                    role = 'user'
                WHERE id = ?`,
                [nama, hp, hashedPassword, alamat, jenis_kelamin, tanggal_lahir, existingUser.id]
            );
            userId = existingUser.id;

        } else {
            // USER BARU
            // 1. Insert User
            const [result] = await pool.query(
                `INSERT INTO users (
                    nama, email, hp, password, is_verified, role,
                    alamat, jenis_kelamin, tanggal_lahir
                ) VALUES (?, ?, ?, ?, FALSE, 'user', ?, ?, ?)`,
                [nama, email, hp, hashedPassword, alamat, jenis_kelamin, tanggal_lahir]
            );
            userId = result.insertId;

            // 2. LANGSUNG BUAT MEMBER CARD (Status Inactive dulu)
            // Format: HELIOZ + YY + MM + INISIAL + USERID
            const date = new Date();
            const yearShort = date.getFullYear().toString().slice(-2); // 2025 -> 25
            const month = (date.getMonth() + 1).toString().padStart(2, '0'); // 12
            const initial = nama.charAt(0).toUpperCase();

            const cardNumber = `HELIOZ${yearShort}${month}${initial}${userId}`;
            const nfcId = `NFC-${cardNumber}`;

            await pool.query(
                'INSERT INTO member_cards (user_id, card_number, nfc_id, is_active) VALUES (?, ?, ?, FALSE)',
                [userId, cardNumber, nfcId]
            );
        }

        // 3. Handle Admin Action (Skip OTP, Auto-verify)
        const { is_admin_action, package_id } = req.body;

        if (is_admin_action) {
            // Auto-verify user
            await pool.query('UPDATE users SET is_verified = TRUE WHERE id = ?', [userId]);
            // Auto-activate card
            await pool.query('UPDATE member_cards SET is_active = TRUE WHERE user_id = ?', [userId]);

            // Create membership if package_id is provided
            if (package_id) {
                const packages = {
                    '1': { durasi: 30, nama: 'Paket Bulanan', harga: 250000 },
                    '2': { durasi: 90, nama: 'Paket 3 Bulan', harga: 650000 },
                    '3': { durasi: 180, nama: 'Paket 6 Bulan', harga: 1200000 },
                    '4': { durasi: 365, nama: 'Paket Tahunan', harga: 2500000 }
                };

                const selectedPkg = packages[package_id];
                if (selectedPkg) {
                    const startDate = moment().format('YYYY-MM-DD');
                    const endDate = moment().add(selectedPkg.durasi, 'days').format('YYYY-MM-DD');

                    const [mResult] = await pool.query(
                        'INSERT INTO memberships (user_id, paket, tanggal_mulai, tanggal_berakhir, status) VALUES (?, ?, ?, ?, ?)',
                        [userId, selectedPkg.nama, startDate, endDate, 'pending']
                    );

                    // Create pending transaction
                    await pool.query(
                        'INSERT INTO transactions (user_id, membership_id, jenis_transaksi, jumlah, metode_pembayaran, status) VALUES (?, ?, ?, ?, ?, ?)',
                        [userId, mResult.insertId, 'membership', selectedPkg.harga, 'cash', 'pending']
                    );
                }
            }

            return res.status(201).json({
                success: true,
                message: 'Member berhasil ditambahkan oleh Admin (Otomatis Aktif)'
            });
        }

        // 4. Generate & Send OTP (Normal user registration)
        const otpCode = generateOTP();
        const expiresAt = moment().add(5, 'minutes').format('YYYY-MM-DD HH:mm:ss');

        await pool.query(
            'INSERT INTO otps (email, otp_code, expires_at) VALUES (?, ?, ?)',
            [email, otpCode, expiresAt]
        );

        const emailSent = await sendOTPEmail(email, otpCode);

        res.status(201).json({
            success: true,
            message: 'Registrasi berhasil. Kode OTP telah dikirim ke email Anda.',
            data: {
                userId: userId,
                email: email
            }
        });

    } catch (error) {
        console.error('Register error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server: ' + error.message
        });
    }
};

// Verify OTP
const verifyOTP = async (req, res) => {
    try {
        const { email, otp } = req.body;

        if (!email || !otp) {
            return res.status(400).json({
                success: false,
                message: 'Email dan OTP harus diisi'
            });
        }

        // Check OTP
        const [otpRecords] = await pool.query(
            'SELECT * FROM otps WHERE email = ? AND otp_code = ? AND is_used = FALSE AND expires_at > NOW() ORDER BY created_at DESC LIMIT 1',
            [email, otp]
        );

        if (otpRecords.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'Kode OTP tidak valid atau sudah kadaluarsa'
            });
        }

        // Get User ID
        const [users] = await pool.query('SELECT id, nama, email, hp, foto_profil FROM users WHERE email = ?', [email]);
        if (users.length === 0) {
            return res.status(404).json({ success: false, message: 'User tidak ditemukan' });
        }
        const user = users[0];

        // 1. Mark OTP as used
        await pool.query(
            'UPDATE otps SET is_used = TRUE WHERE id = ?',
            [otpRecords[0].id]
        );

        // 2. ACTIVATE USER
        await pool.query(
            'UPDATE users SET is_verified = TRUE WHERE email = ?',
            [email]
        );

        // 3. ACTIVATE MEMBER CARD (Yang sudah dibuat saat registrasi)
        await pool.query(
            'UPDATE member_cards SET is_active = TRUE WHERE user_id = ?',
            [user.id]
        );

        // -- Jaga-jaga: kalo card belum ada (kasus user lama retry), buatkan sekarang --
        const [existingCards] = await pool.query('SELECT * FROM member_cards WHERE user_id = ?', [user.id]);
        if (existingCards.length === 0) {
            const date = new Date();
            const yearShort = date.getFullYear().toString().slice(-2);
            const month = (date.getMonth() + 1).toString().padStart(2, '0');
            const initial = user.nama ? user.nama.charAt(0).toUpperCase() : 'X';
            const cardNumber = `HELIOZ${yearShort}${month}${initial}${user.id}`;
            const nfcId = `NFC-${cardNumber}`;
            await pool.query(
                'INSERT INTO member_cards (user_id, card_number, nfc_id, is_active) VALUES (?, ?, ?, TRUE)',
                [user.id, cardNumber, nfcId]
            );
        }

        // 4. Auto-login: Get Full Data
        const [userData] = await pool.query(`
            SELECT u.*, mc.card_number 
            FROM users u 
            LEFT JOIN member_cards mc ON u.id = mc.user_id 
            WHERE u.email = ?
        `, [email]);

        const updatedUser = userData[0];

        // Generate Token
        const token = jwt.sign(
            { userId: updatedUser.id, email: updatedUser.email },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRES_IN }
        );

        res.json({
            success: true,
            message: 'Verifikasi OTP berhasil. Akun aktif.',
            data: {
                token,
                user: {
                    id: updatedUser.id,
                    nama: updatedUser.nama,
                    email: updatedUser.email,
                    hp: updatedUser.hp,
                    foto_profil: updatedUser.foto_profil,
                    jenis_kelamin: updatedUser.jenis_kelamin,
                    tanggal_lahir: updatedUser.tanggal_lahir ? moment(updatedUser.tanggal_lahir).format('YYYY-MM-DD') : null,
                    alamat: updatedUser.alamat,
                    card_number: updatedUser.card_number
                }
            }
        });

    } catch (error) {
        console.error('Verify OTP error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server'
        });
    }
};

// Login
const login = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                success: false,
                message: 'Email dan password harus diisi'
            });
        }

        // Find user
        const [users] = await pool.query(
            'SELECT * FROM users WHERE email = ?',
            [email]
        );

        if (users.length === 0) {
            return res.status(401).json({
                success: false,
                message: 'Email atau password salah'
            });
        }

        const user = users[0];

        // CHECK IF USER IS VERIFIED
        if (!user.is_verified) {
            return res.status(401).json({
                success: false,
                message: 'Akun belum diverifikasi. Silakan cek email Anda untuk kode OTP.'
            });
        }

        // Check password
        const isPasswordValid = await bcrypt.compare(password, user.password);

        if (!isPasswordValid) {
            return res.status(401).json({
                success: false,
                message: 'Email atau password salah'
            });
        }

        // Generate JWT token with role
        const token = jwt.sign(
            {
                userId: user.id,
                email: user.email,
                role: user.role || 'user'  // Include role in token
            },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRES_IN }
        );

        // Get membership info
        const [memberships] = await pool.query(
            'SELECT * FROM memberships WHERE user_id = ? AND status = "active" ORDER BY tanggal_berakhir DESC LIMIT 1',
            [user.id]
        );

        // Get Card Info
        const [cards] = await pool.query('SELECT card_number FROM member_cards WHERE user_id = ?', [user.id]);
        const cardNumber = cards.length > 0 ? cards[0].card_number : null;

        res.json({
            success: true,
            message: 'Login berhasil',
            data: {
                token,
                user: {
                    id: user.id,
                    nama: user.nama,
                    email: user.email,
                    hp: user.hp,
                    foto_profil: user.foto_profil,
                    jenis_kelamin: user.jenis_kelamin,
                    tanggal_lahir: user.tanggal_lahir ? moment(user.tanggal_lahir).format('YYYY-MM-DD') : null,
                    alamat: user.alamat,
                    card_number: cardNumber,
                    role: user.role || 'user'  // Include role in response
                },
                membership: memberships.length > 0 ? memberships[0] : null
            }
        });

    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server: ' + error.message
        });
    }
};

// Resend OTP
const resendOTP = async (req, res) => {
    try {
        const { email } = req.body;

        if (!email) {
            return res.status(400).json({
                success: false,
                message: 'Email harus diisi'
            });
        }

        // Generate new OTP
        const otpCode = generateOTP();
        const expiresAt = moment().add(5, 'minutes').format('YYYY-MM-DD HH:mm:ss');

        // Save OTP to database
        await pool.query(
            'INSERT INTO otps (email, otp_code, expires_at) VALUES (?, ?, ?)',
            [email, otpCode, expiresAt]
        );

        // Send OTP email
        const emailSent = await sendOTPEmail(email, otpCode);

        if (!emailSent) {
            return res.status(500).json({
                success: false,
                message: 'Gagal mengirim OTP. Silakan coba lagi.'
            });
        }

        res.json({
            success: true,
            message: 'Kode OTP baru telah dikirim ke email Anda'
        });

    } catch (error) {
        console.error('Resend OTP error:', error);
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server'
        });
    }
};

module.exports = {
    register,
    verifyOTP,
    login,
    resendOTP
};
