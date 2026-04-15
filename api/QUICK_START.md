# Quick Start Guide

## 🚀 Cara Cepat Menjalankan API

### 1. Install Dependencies
```bash
cd api
npm install
```

### 2. Setup Database
```bash
# Login ke MySQL
mysql -u root -p

# Jalankan script (di MySQL prompt)
source database/schema.sql
```

Atau import `database/schema.sql` via phpMyAdmin/MySQL Workbench.

### 3. Configure Environment
```bash
# Copy .env.example ke .env
copy .env.example .env

# Edit .env dan sesuaikan:
# - DB_PASSWORD (password MySQL Anda)
# - EMAIL_USER & EMAIL_PASSWORD (jika ingin fitur OTP)
```

### 4. Run Server
```bash
npm start
```

Server akan berjalan di `http://localhost:3000`

### 5. Test API
Buka browser: `http://localhost:3000`

Atau test login:
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"budi@example.com\",\"password\":\"password123\"}"
```

## 📝 Sample Credentials

**User 1:**
- Email: `budi@example.com`
- Password: `password123`
- NFC ID: `NFC-GYM123456`

**User 2:**
- Email: `siti@example.com`
- Password: `password123`
- NFC ID: `NFC-GYM789012`

## 📚 Dokumentasi Lengkap

- **README.md** - Overview dan fitur
- **SETUP_GUIDE.md** - Panduan setup detail
- **API_DOCUMENTATION.md** - Dokumentasi API lengkap
- **FLUTTER_INTEGRATION.md** - Panduan integrasi dengan Flutter
- **postman_collection.json** - Collection untuk testing di Postman

## 🔗 Endpoints Utama

- `POST /api/auth/login` - Login
- `POST /api/auth/register` - Register
- `GET /api/user/profile` - Get profile (need auth)
- `POST /api/check-in/nfc` - Check-in NFC
- `GET /api/membership/info` - Get membership (need auth)
- `GET /api/promos` - Get promos

## 💡 Tips

1. Gunakan Postman untuk testing (import `postman_collection.json`)
2. Cek console log untuk debug
3. Untuk Flutter, gunakan `http://10.0.2.2:3000` (Android Emulator)
4. Password sample user: `password123`

## ❓ Troubleshooting

**Database connection failed?**
- Cek MySQL service running
- Cek credentials di `.env`

**Port already in use?**
- Ubah PORT di `.env`

**Token tidak valid?**
- Login ulang untuk dapat token baru

## 📞 Need Help?

Baca dokumentasi lengkap di file-file yang tersedia atau cek error message di console.

Happy coding! 🎉
