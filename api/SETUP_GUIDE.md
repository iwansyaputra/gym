# Setup Guide - Membership Gym API

## 📋 Prerequisites

Pastikan Anda sudah menginstall:
- Node.js (v14+) - [Download](https://nodejs.org/)
- MySQL (v5.7+) - [Download](https://dev.mysql.com/downloads/)
- Git (optional)
- Postman (untuk testing) - [Download](https://www.postman.com/downloads/)

## 🔧 Step-by-Step Setup

### 1. Install Dependencies

Buka terminal/command prompt di folder `api`:

```bash
cd api
npm install
```

### 2. Setup MySQL Database

#### Opsi A: Menggunakan MySQL Command Line

```bash
# Login ke MySQL
mysql -u root -p

# Jalankan script schema
source database/schema.sql

# Atau copy-paste isi file schema.sql ke MySQL command line
```

#### Opsi B: Menggunakan phpMyAdmin

1. Buka phpMyAdmin di browser (biasanya http://localhost/phpmyadmin)
2. Buat database baru bernama `membership_gym`
3. Pilih database tersebut
4. Klik tab "SQL"
5. Copy-paste isi file `database/schema.sql`
6. Klik "Go"

#### Opsi C: Menggunakan MySQL Workbench

1. Buka MySQL Workbench
2. Connect ke MySQL server
3. File → Open SQL Script → pilih `database/schema.sql`
4. Execute (⚡ icon atau Ctrl+Shift+Enter)

### 3. Configure Environment Variables

Copy file `.env.example` menjadi `.env`:

```bash
# Windows
copy .env.example .env

# Linux/Mac
cp .env.example .env
```

Edit file `.env` dan sesuaikan dengan konfigurasi Anda:

```env
# Database Configuration
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=membership_gym

# JWT Secret (ganti dengan string random yang aman)
JWT_SECRET=ganti_dengan_random_string_yang_panjang

# Email Configuration (untuk OTP)
EMAIL_USER=your_email@gmail.com
EMAIL_PASSWORD=your_gmail_app_password
```

#### Setup Gmail untuk OTP (Optional)

Jika ingin menggunakan fitur OTP via email:

1. Login ke Gmail
2. Buka https://myaccount.google.com/security
3. Aktifkan "2-Step Verification"
4. Buat "App Password":
   - Pilih app: Mail
   - Pilih device: Other (Custom name)
   - Copy password yang digenerate
5. Paste password tersebut ke `EMAIL_PASSWORD` di file `.env`

### 4. Test Database Connection

Jalankan server untuk test koneksi:

```bash
npm start
```

Jika berhasil, Anda akan melihat:
```
✅ Database connected successfully
🚀 Server running on port 3000
```

Jika gagal, periksa:
- MySQL service sudah running
- Username, password, dan database name di `.env` sudah benar
- Port MySQL (default 3306)

### 5. Test API Endpoints

#### Menggunakan Browser

Buka browser dan akses:
```
http://localhost:3000
```

Anda akan melihat response:
```json
{
  "success": true,
  "message": "Membership Gym API is running",
  "version": "1.0.0"
}
```

#### Menggunakan Postman

1. Import file `postman_collection.json` ke Postman
2. Set variable `base_url` = `http://localhost:3000`
3. Test endpoint "Login" dengan data sample:
   ```json
   {
     "email": "budi@example.com",
     "password": "password123"
   }
   ```
4. Copy token dari response
5. Set variable `token` dengan token yang didapat
6. Test endpoint lain yang memerlukan authentication

#### Menggunakan cURL

```bash
# Test health check
curl http://localhost:3000/health

# Test login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"budi@example.com\",\"password\":\"password123\"}"

# Test get profile (ganti YOUR_TOKEN dengan token dari login)
curl http://localhost:3000/api/user/profile \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 🧪 Testing dengan Sample Data

Database schema sudah include sample data:

### Sample Users:
- **Email**: budi@example.com | **Password**: password123
- **Email**: siti@example.com | **Password**: password123

### Sample NFC Cards:
- **NFC ID**: NFC-GYM123456 (untuk user Budi)
- **NFC ID**: NFC-GYM789012 (untuk user Siti)

### Test Flow:

1. **Login**
   ```
   POST /api/auth/login
   Body: { "email": "budi@example.com", "password": "password123" }
   ```

2. **Get Profile**
   ```
   GET /api/user/profile
   Header: Authorization: Bearer {token}
   ```

3. **Check-in dengan NFC**
   ```
   POST /api/check-in/nfc
   Body: { "nfc_id": "NFC-GYM123456" }
   ```

4. **Get Membership Info**
   ```
   GET /api/membership/info
   Header: Authorization: Bearer {token}
   ```

5. **Get Promos**
   ```
   GET /api/promos
   ```

## 🐛 Troubleshooting

### Error: "Database connection failed"
- Pastikan MySQL service running
- Cek credentials di `.env`
- Cek apakah database `membership_gym` sudah dibuat

### Error: "Cannot find module"
- Jalankan `npm install` lagi
- Hapus folder `node_modules` dan `package-lock.json`, lalu `npm install`

### Error: "Port 3000 already in use"
- Ubah PORT di `.env` menjadi port lain (misal 3001)
- Atau stop aplikasi yang menggunakan port 3000

### Error: "Token tidak valid"
- Pastikan format header: `Authorization: Bearer {token}`
- Token mungkin expired, login ulang untuk dapat token baru

### Email OTP tidak terkirim
- Pastikan EMAIL_USER dan EMAIL_PASSWORD sudah benar
- Gunakan App Password, bukan password Gmail biasa
- Cek koneksi internet

## 📱 Integrasi dengan Flutter App

Untuk mengintegrasikan dengan aplikasi Flutter:

1. Pastikan API sudah running
2. Di Flutter, gunakan package `http` atau `dio`
3. Base URL: `http://localhost:3000` (untuk emulator Android gunakan `http://10.0.2.2:3000`)
4. Simpan token JWT setelah login (gunakan `shared_preferences`)
5. Sertakan token di header untuk setiap request yang memerlukan authentication

Contoh di Flutter:
```dart
import 'package:http/http.dart' as http;

final response = await http.get(
  Uri.parse('http://10.0.2.2:3000/api/user/profile'),
  headers: {
    'Authorization': 'Bearer $token',
  },
);
```

## 🚀 Deployment (Production)

Untuk deploy ke production:

1. Ubah `NODE_ENV=production` di `.env`
2. Ganti `JWT_SECRET` dengan string yang lebih aman
3. Setup database production
4. Deploy ke hosting (Heroku, DigitalOcean, AWS, dll)
5. Update base URL di Flutter app

## 📞 Support

Jika ada masalah, cek:
- README.md untuk dokumentasi lengkap
- Console log untuk error messages
- Database apakah data sudah sesuai

Happy coding! 🎉
