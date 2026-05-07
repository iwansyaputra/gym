# GymKu API — Backend Server

Backend API untuk sistem GymKu menggunakan **Node.js**, **Express**, dan **MySQL**. Di-deploy di `https://api.gymku.motalindo.com`.

---

## 🌐 Production

**Base URL:** `https://api.gymku.motalindo.com/api`

---

## 🚀 Fitur

- **Authentication**: Register, Login, OTP Verification
- **User Management**: Profile, Change Password
- **Membership**: Status, Extend, Packages
- **Check-in**: NFC check-in via ACR122U bridge, riwayat & statistik
- **Transactions**: Payment history, Create & confirm payments
- **Wallet**: Topup saldo, riwayat transaksi saldo
- **Promos**: Daftar & detail promo aktif
- **Admin**: Dashboard stats, member management, wallet management
- **Payment Gateway**: Integrasi E-Smartlink (Virtual Account CIMB)

---

## 📋 Prerequisites

- Node.js v18+
- MySQL v5.7+
- npm

---

## 🛠️ Installation (Development)

### 1. Install dependencies
```bash
cd api
npm install
```

### 2. Setup Database
```bash
# Import schema ke MySQL
mysql -u root -p gym < ../membership_gym.sql
```

### 3. Configure Environment
```bash
cp .env.example .env
```

Edit `.env`:
```env
PORT=3000
NODE_ENV=development

DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=gym
DB_PORT=3306

JWT_SECRET=gym_membership_secret_key_2024_very_secure_random_string
JWT_EXPIRES_IN=7d

EMAIL_USER=your_email@gmail.com
EMAIL_PASSWORD=your_app_password_16_digit

NFC_SECRET_KEY=nfc-bridge-secret-2024
```

### 4. Run Server
```bash
# Development (auto-reload)
npm run dev

# Production
npm start
```

> Server berjalan di `http://0.0.0.0:3000`

---

## 📡 API Endpoints

### Authentication
| Method | Endpoint | Keterangan |
|--------|----------|------------|
| POST | `/api/auth/register` | Registrasi user baru |
| POST | `/api/auth/login` | Login → JWT token |
| POST | `/api/auth/verify-otp` | Verifikasi OTP email |
| POST | `/api/auth/resend-otp` | Kirim ulang OTP |

### User (Protected — Bearer Token)
| Method | Endpoint | Keterangan |
|--------|----------|------------|
| GET | `/api/user/profile` | Profil + kartu NFC + membership |
| PUT | `/api/user/profile` | Update profil |
| PUT | `/api/user/change-password` | Ganti password |

### Check-in
| Method | Endpoint | Header | Keterangan |
|--------|----------|--------|------------|
| POST | `/api/check-in/lookup` | Bearer Token | Cari member by NFC ID (tidak catat DB) |
| POST | `/api/check-in/nfc` | `X-NFC-Secret` | Catat check-in ke database |
| GET | `/api/check-in/history` | Bearer Token | Riwayat check-in user |

### Membership (Protected)
| Method | Endpoint | Keterangan |
|--------|----------|------------|
| GET | `/api/membership/info` | Info membership aktif |
| GET | `/api/membership/packages` | Daftar paket tersedia |
| POST | `/api/membership/extend` | Perpanjang membership |

### Transactions (Protected)
| Method | Endpoint | Keterangan |
|--------|----------|------------|
| GET | `/api/transactions/history` | Riwayat transaksi |
| GET | `/api/transactions/:id` | Detail transaksi |
| POST | `/api/transactions/create` | Buat transaksi baru |
| POST | `/api/transactions/confirm` | Konfirmasi pembayaran |

### Payment (Protected)
| Method | Endpoint | Keterangan |
|--------|----------|------------|
| POST | `/api/payment/create` | Buat pembayaran (E-Smartlink VA) |
| GET | `/api/payment/status/:id` | Cek status pembayaran |

### Promos
| Method | Endpoint | Keterangan |
|--------|----------|------------|
| GET | `/api/promos` | Semua promo aktif |
| GET | `/api/promos/:id` | Detail promo |

### Admin (Protected — Admin role)
| Method | Endpoint | Keterangan |
|--------|----------|------------|
| GET | `/api/admin/users` | Semua member |
| GET | `/api/admin/users/:id` | Detail member |
| PUT | `/api/admin/users/:id` | Update member |
| DELETE | `/api/admin/users/:id` | Hapus member |
| GET | `/api/admin/dashboard/stats` | Statistik dashboard |
| GET | `/api/admin/checkin/stats` | Statistik check-in |
| GET | `/api/admin/wallets` | Data wallet semua member |
| POST | `/api/admin/wallets/topup` | Top up saldo member |
| GET | `/api/admin/wallets/:id/history` | Riwayat saldo member |

---

## 🔐 Autentikasi

### JWT Token (Endpoint Protected)
```http
Authorization: Bearer <token>
```

### NFC Bridge Secret (Endpoint Check-in dari nfc-bridge.py)
```http
X-NFC-Secret: nfc-bridge-secret-2024
```
Nilai ini harus sama dengan `NFC_SECRET_KEY` di `.env`.

---

## 📝 Contoh Request & Response

### Login
```json
POST /api/auth/login
{
  "email": "user@example.com",
  "password": "password123"
}
```
```json
{
  "success": true,
  "message": "Login berhasil",
  "data": {
    "token": "eyJhbGci...",
    "user": { "id": 1, "name": "John Doe", "email": "user@example.com" }
  }
}
```

### Check-in NFC (dari nfc-bridge.py)
```json
POST /api/check-in/nfc
Header: X-NFC-Secret: nfc-bridge-secret-2024

{
  "nfc_id": "0012345678"
}
```
```json
{
  "success": true,
  "message": "Check-in berhasil! Selamat berlatih 💪",
  "member": {
    "name": "John Doe",
    "membership_status": "active",
    "gym_name": "GymKu Utama"
  },
  "check_in_time": "2026-05-07T04:30:00Z"
}
```

---

## 🗄️ Skema Database

```sql
users               -- Data user/member
member_cards        -- Kartu NFC (nfc_id, card_number, is_active)
memberships         -- Data paket membership aktif
check_ins           -- Log check-in
transactions        -- Riwayat transaksi pembayaran
packages            -- Paket membership
promos              -- Promosi & diskon
wallets             -- Dompet digital member
wallet_transactions -- Riwayat topup & potong saldo
gyms                -- Data cabang gym
otps                -- OTP untuk verifikasi email
```

---

## 🐳 Deployment (Docker)

```dockerfile
# Dockerfile sudah tersedia di api/Dockerfile
```

```bash
# Build
docker build -t gymku-api .

# Run
docker run -p 3000:3000 --env-file .env gymku-api
```

---

## 📦 Dependencies

| Package | Kegunaan |
|---------|----------|
| `express` | Web framework |
| `mysql2` | MySQL client |
| `bcryptjs` | Password hashing |
| `jsonwebtoken` | JWT authentication |
| `dotenv` | Environment variables |
| `cors` | CORS middleware |
| `nodemailer` | Kirim OTP via email |
| `moment` | Manipulasi tanggal/waktu |

---

## 🔌 NFC Bridge (nfc-bridge.py)

File `nfc-bridge.py` adalah script Python yang berjalan di komputer admin (bukan di server hosting).

**Fungsi:** Baca kartu NFC dari ACR122U → POST ke API production

```bash
# Install dependensi
pip install pyscard websockets requests

# Jalankan (Windows)
jalankan-nfc-bridge.bat

# Jalankan (manual)
python nfc-bridge.py
```

**Konfigurasi di nfc-bridge.py:**
```python
API_BASE_URL = "https://api.gymku.motalindo.com/api"
NFC_SECRET_KEY = "nfc-bridge-secret-2024"
WS_PORT = 8765  # WebSocket lokal untuk browser
```

> Bridge berjalan di `ws://localhost:8765` dan langsung POST ke server produksi.

---

## 👤 Developer

**Iwan Syaputra**  
📧 iwantugaskuliah@gmail.com

---

*Terakhir diupdate: Mei 2026 — v2.0 Production*
