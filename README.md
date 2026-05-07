# 🏋️ GymKu — Sistem Manajemen Gym Terpadu

Sistem manajemen gym lengkap berbasis **Flutter (mobile)**, **Admin Web (HTML/JS)**, dan **Backend API (Node.js)**. Dilengkapi integrasi NFC check-in menggunakan **ACR122U** hardware reader dan **Host Card Emulation (HCE)** pada perangkat Android.

---

## 🌐 Link Produksi

| Layanan | URL |
|---------|-----|
| 🖥️ Admin Dashboard | **https://gymku.motalindo.com/** |
| ⚙️ Backend API | **https://api.gymku.motalindo.com/** |
| 📱 Mobile App | APK / Google Play (Flutter) |

**Akun Admin:** `admin@gym.com` / `admin123`

---

## ✨ Changelog (Mei 2026)

### v2.0 — Production Deployment
1. **Deploy ke Production**: Admin Web dan Backend API kini live di domain `motalindo.com` menggunakan hosting berbasis Docker.
2. **NFC Bridge — HTTPS Workaround**: Solusi koneksi `ws://localhost:8765` dari halaman HTTPS menggunakan file `buka-chrome-checkin.bat` (flag `--allow-insecure-localhost`).
3. **Fallback WebSocket**: `checkin.js` kini mencoba `ws://localhost:8765` → fallback `ws://127.0.0.1:8765` secara otomatis.
4. **Konfigurasi URL Produksi**: `config.js` dan `nfc-bridge.py` sudah dikonfigurasi penuh ke `api.gymku.motalindo.com`.

### v1.x — Fitur Sebelumnya
5. **Rebranding GYMKU**: Nama aplikasi & ikon launcher baru (Dark Blue & Black).
6. **Riwayat Check-in Member (Mobile)**: Tab baru di halaman Riwayat untuk kehadiran personal.
7. **Sinkronisasi Zona Waktu**: UTC → WIB real-time di semua platform.
8. **Programming Kartu Fisik NFC**: Tulis User ID ke memori NTAG213 / Mifare Classic 1K.
9. **Sistem Dompet (Wallet)**: Kelola saldo member — Admin Web & Backend tersinkronisasi.
10. **Sentralisasi UI Admin**: Sidebar komponen terpusat di `js/components.js`.
11. **Proteksi Check-In Berbasis Langganan**: Check-in NFC diblokir jika membership expired.
12. **Export Laporan Excel**: Format `.xlsx` via ExcelJS — filter bulan/semua waktu.
13. **K-Means Clustering**: Analisis segmentasi aktivitas member di halaman Laporan.

---

## 📦 Komponen Sistem

| Komponen | Teknologi | Lokasi | Produksi |
|----------|-----------|--------|----------|
| Backend API | Node.js + Express + MySQL | `api/` | `api.gymku.motalindo.com` |
| Admin Web | HTML / CSS / JavaScript | `admin_web/` | `gymku.motalindo.com` |
| Mobile App | Flutter (Android) | `lib/` | APK / Play Store |
| Database | MySQL | `membership_gym.sql` | Hosted MySQL |
| NFC Bridge | Python + pyscard + websockets | `api/nfc-bridge.py` | Lokal (ws://localhost:8765) |

---

## 🚀 Quick Start — Development (Lokal)

### 1. Persiapan Database
```bash
# Jalankan Laragon (MySQL aktif)
# Buka phpMyAdmin → Import file: membership_gym.sql
```

### 2. Jalankan Backend API
```bash
cd api
npm install
npm run dev
```
> Server berjalan di `http://0.0.0.0:3000`

### 3. Buka Admin Web
> ⚠️ **Wajib dibuka via HTTP server**, bukan langsung `file://`

```
admin_web/jalankan-admin-web.bat
```
Lalu buka: `http://localhost:5500`

**Login:** `admin@gym.com` / `admin123`

### 4. Jalankan Mobile App (Flutter)
```bash
flutter pub get
flutter run
```

---

## 🚀 Quick Start — Production

Admin Web dan API sudah live. Tidak perlu menjalankan backend secara lokal.

1. Buka **https://gymku.motalindo.com/** di browser
2. Login dengan `admin@gym.com` / `admin123`
3. Semua fitur langsung terhubung ke `api.gymku.motalindo.com`

---

## 📡 Integrasi NFC (ACR122U + HCE)

Sistem check-in NFC mendukung dua mode:

### Mode 1: ACR122U USB Reader (Disarankan untuk Admin)

**Arsitektur (Production):**
```
[HP Android / Kartu NFC Fisik]
        ↓ (tempel ke reader)
[ACR122U — USB ke Komputer Admin]
        ↓
[nfc-bridge.py — ws://localhost:8765]
        ↓ (WebSocket lokal)
[Browser Chrome — gymku.motalindo.com/checkin.html]
        ↓ (HTTPS)
[API — api.gymku.motalindo.com/api/check-in/nfc]
        ↓
[Database MySQL Hosting]
```

> **Penting**: NFC Bridge **berjalan di komputer admin** (lokal), bukan di server hosting. Ini karena hardware USB tidak bisa diakses dari cloud.

#### Langkah Penggunaan (Production):

**Step 1 — Jalankan NFC Bridge:**
```
api\jalankan-nfc-bridge.bat
```
Bridge akan POST langsung ke `https://api.gymku.motalindo.com`

**Step 2 — Buka Chrome khusus NFC:**
```
api\buka-chrome-checkin.bat
```
Script ini membuka Chrome dengan flag `--allow-insecure-localhost` agar koneksi `ws://localhost:8765` diizinkan dari halaman HTTPS.

> ⚠️ **Kenapa perlu `buka-chrome-checkin.bat`?**  
> Browser memblokir koneksi WebSocket `ws://` (tidak terenkripsi) dari halaman `https://` sebagai *mixed content*. File `.bat` ini membuka instance Chrome khusus dengan exception untuk localhost.

#### Instalasi Dependensi Python (sekali saja):
```bash
pip install pyscard websockets requests
```

#### Alur Teknis HCE (HP Android):
1. HP Android (Flutter app, mode HCE aktif) ditempelkan ke ACR122U
2. `nfc-bridge.py` kirim **SELECT AID** (`A0 00 DA DA DA DA DA`) ke HP
3. HP merespons dengan `nfc_id` member dalam format ASCII bytes
4. Bridge decode bytes → string `nfc_id`
5. POST ke API → check-in dicatat ke database
6. Hasil dikirim ke browser via WebSocket

#### Alur Teknis Kartu Fisik (NTAG / Mifare):
1. Kartu ditempelkan ke ACR122U
2. Bridge baca UID kartu fisik → konversi ke 10-digit desimal
3. POST ke API → check-in dicatat

#### Proteksi Double Check-in (3 lapis):

| Lapis | Lokasi | Mekanisme |
|-------|--------|-----------| 
| Bridge cooldown | `nfc-bridge.py` | NFC ID sama diabaikan selama **5 detik** |
| Browser debounce | `checkin.js` | Timestamp-based lock **10 detik** per NFC ID |
| Atomic SQL | `checkInController.js` | `INSERT...WHERE NOT EXISTS` + mutex per userId |

### Mode 2: Web NFC API (Fallback — Mobile Chrome saja)
Jika `nfc-bridge.py` tidak aktif, otomatis fallback ke Web NFC API (hanya Chrome di Android).

---

## 📱 Fitur Mobile App (Flutter)

- **Login / Register** dengan OTP email
- **Dashboard** info membership aktif & saldo wallet
- **Check-in NFC** via HCE — HP berfungsi sebagai kartu virtual
  - Mengirim `nfc_id` dari database sebagai payload APDU
  - Tidak memanggil API check-in secara langsung (dicatat oleh admin web)
- **Paket Membership** — lihat & beli paket
- **Transaksi** — riwayat pembayaran
- **Payment Gateway** — integrasi E-Smartlink
- **Profil** — edit data diri

---

## 🖥️ Fitur Admin Web

| Halaman | Fungsi |
|---------|--------|
| `index.html` | Login admin |
| `dashboard.html` | Statistik harian — member, check-in, revenue |
| `members.html` | Manajemen member (CRUD + link kartu NFC) |
| `checkin.html` | Check-in NFC real-time via ACR122U |
| `topup.html` | Manajemen dan top up saldo dompet member |
| `packages.html` | Manajemen paket membership |
| `promos.html` | Manajemen promosi & diskon |
| `transactions.html` | Riwayat transaksi |
| `reports.html` | Laporan + K-Means clustering aktivitas member |

---

## 🗂️ Struktur Proyek

```
membership_gym/
├── api/                          # Backend Node.js
│   ├── server.js                 # Entry point Express
│   ├── nfc-bridge.py             # NFC Bridge (ACR122U → WebSocket)
│   ├── jalankan-nfc-bridge.bat   # Jalankan NFC bridge (Windows)
│   ├── buka-chrome-checkin.bat   # Buka Chrome dgn ws:// exception
│   ├── Dockerfile                # Docker config untuk hosting
│   ├── .env                      # Environment variables
│   ├── controllers/
│   │   ├── authController.js
│   │   ├── userController.js
│   │   ├── checkInController.js  # Anti double check-in (atomic SQL + mutex)
│   │   ├── membershipController.js
│   │   ├── transactionController.js
│   │   ├── promoController.js
│   │   ├── paymentController.js
│   │   ├── walletController.js
│   │   └── adminController.js
│   ├── routes/
│   ├── middleware/
│   ├── config/
│   │   ├── database.js
│   │   └── esmartlink.js
│   └── database/
│       └── schema.sql
│
├── admin_web/                    # Admin Dashboard
│   ├── index.html                # Login
│   ├── dashboard.html
│   ├── checkin.html              # NFC Check-in (ACR122U)
│   ├── members.html
│   ├── packages.html
│   ├── promos.html
│   ├── transactions.html
│   ├── reports.html
│   ├── topup.html                # Kelola Saldo Member
│   ├── jalankan-admin-web.bat    # HTTP server lokal (dev only)
│   ├── css/
│   │   ├── style.css
│   │   └── aesthetic.css
│   └── js/
│       ├── components.js         # UI Components terpusat (Sidebar)
│       ├── config.js             # API URL → api.gymku.motalindo.com
│       ├── auth.js
│       ├── api.js
│       ├── login.js
│       ├── dashboard.js
│       ├── checkin.js            # WebSocket + auto check-in logic
│       ├── members.js
│       ├── packages.js
│       ├── promos.js
│       ├── transactions.js
│       ├── topup.js
│       └── reports.js
│
├── lib/                          # Flutter Mobile App
│   ├── main.dart
│   ├── pages/
│   │   ├── login_page.dart
│   │   ├── register_page.dart
│   │   ├── home_page.dart
│   │   ├── check_in_nfc_page.dart   # HCE NFC emulation
│   │   ├── membership_page.dart
│   │   ├── transaction_page.dart
│   │   ├── payment.dart             # E-Smartlink payment flow
│   │   ├── promo_page.dart
│   │   └── profile_page.dart
│   └── services/
│       ├── api_service.dart
│       ├── api_config.dart          # URL config (prod: api.gymku.motalindo.com)
│       └── auth_storage.dart
│
├── membership_gym.sql            # Database dump lengkap
└── README.md
```

---

## 🔌 API Endpoints

**Base URL Production:** `https://api.gymku.motalindo.com/api`

### Auth
| Method | Endpoint | Keterangan |
|--------|----------|------------|
| POST | `/auth/register` | Registrasi user baru |
| POST | `/auth/login` | Login (JWT token) |
| POST | `/auth/verify-otp` | Verifikasi OTP email |
| POST | `/auth/resend-otp` | Kirim ulang OTP |

### User
| Method | Endpoint | Keterangan |
|--------|----------|------------|
| GET | `/user/profile` | Profil user + data kartu + membership |
| PUT | `/user/profile` | Update profil |
| PUT | `/user/change-password` | Ganti password |

### Check-in
| Method | Endpoint | Keterangan |
|--------|----------|------------|
| POST | `/check-in/lookup` | Cari member by NFC ID (tanpa catat DB) |
| POST | `/check-in/nfc` | Catat check-in ke database (butuh `X-NFC-Secret`) |
| GET | `/check-in/history` | Riwayat check-in |

### Admin
| Method | Endpoint | Keterangan |
|--------|----------|------------|
| GET | `/admin/users` | Semua member |
| PUT | `/admin/users/:id` | Update data member |
| DELETE | `/admin/users/:id` | Hapus member |
| GET | `/admin/dashboard/stats` | Statistik dashboard |
| GET | `/admin/checkin/stats` | Statistik check-in |
| GET | `/admin/wallets` | Data dompet member |
| POST | `/admin/wallets/topup` | Top up saldo member |
| GET | `/admin/wallets/:id/history` | Riwayat saldo member |

### Membership & Transaksi
| Method | Endpoint | Keterangan |
|--------|----------|------------|
| GET | `/membership/packages` | Daftar paket |
| POST | `/membership/extend` | Perpanjang membership |
| GET | `/transactions/history` | Riwayat transaksi |
| POST | `/payment/create` | Buat pembayaran (E-Smartlink) |
| GET | `/promos` | Daftar promo aktif |

---

## 🗃️ Skema Database Utama

```sql
users               -- Data user/member
member_cards        -- Kartu NFC (nfc_id, card_number, is_active)
memberships         -- Data paket membership aktif
check_ins           -- Log check-in (user_id, check_in_time, method)
transactions        -- Riwayat transaksi pembayaran
packages            -- Paket membership tersedia
promos              -- Data promosi/diskon
wallets             -- Data dompet digital/saldo member
wallet_transactions -- Riwayat topup & potong saldo
gyms                -- Data cabang gym
```

> **Kolom penting:** `member_cards.nfc_id` — ID unik yang disimpan di Flutter (via HCE) dan dibaca oleh ACR122U bridge.

---

## 🔐 Autentikasi API

Endpoint protected menggunakan JWT header:
```
Authorization: Bearer <token>
```

Endpoint NFC check-in dari bridge menggunakan secret key:
```
X-NFC-Secret: nfc-bridge-secret-2024
```

---

## 🛠️ Troubleshooting

### ❌ Admin web tidak bisa login (production)
- Buka **https://gymku.motalindo.com/** (bukan `http://`)
- Pastikan email & password benar: `admin@gym.com` / `admin123`
- Cek console browser: API harus menjawab dari `api.gymku.motalindo.com`

### ❌ ACR122U tidak bisa konek dari halaman HTTPS
- **Jangan** buka `checkin.html` biasa dari Chrome
- Gunakan: `api\buka-chrome-checkin.bat` (membuka Chrome dengan `--allow-insecure-localhost`)
- Pastikan `nfc-bridge.py` sudah berjalan terlebih dahulu

### ❌ ACR122U tidak terdeteksi
- Pastikan driver PC/SC terinstall (download dari [ACS website](https://www.acs.com.hk/en/drivers/))
- Colok ulang USB, restart bridge
- Cek di Device Manager: "ACS ACR122U"
- Jalankan: `python -c "from smartcard.System import readers; print(readers())"`

### ❌ NFC ID tidak terbaca / baca angka random
- Pastikan HP Android dalam kondisi HCE aktif (klik tombol "Mulai Scan" di app Flutter)
- Lihat log terminal bridge untuk debug urutan APDU
- Jika pakai kartu fisik: bridge baca UID → konversi ke 10-digit desimal

### ❌ Double check-in
- Restart `nfc-bridge.py` dan hard refresh browser (`Ctrl+Shift+R`)
- Backend memiliki proteksi atomic SQL (INSERT WHERE NOT EXISTS 60 detik)
- Bridge memiliki cooldown 5 detik per NFC ID

### ❌ Flutter tidak bisa connect ke API (dev lokal)
- Update URL di `lib/services/api_config.dart`
- Pastikan HP dan PC dalam WiFi yang sama
- Cek firewall Windows: izinkan port 3000

### ❌ "Failed to fetch" saat development lokal
- Pastikan backend berjalan: `cd api && npm run dev`
- Buka admin web via HTTP server, **bukan** `file://`
- Cek `admin_web/js/config.js` → `BASE_URL` untuk development

---

## 💳 Payment Gateway (E-Smartlink)

Konfigurasi di `api/.env`:
```env
ESMARTLINK_BASE_URL=https://payment-service-sbx.pakar-digital.com
ESMARTLINK_USERNAME=api-smartlink-sbx@poltekharber.ac.id
ESMARTLINK_PASSWORD=your_password
ESMARTLINK_CHANNEL=VA_CIMB
ESMARTLINK_PAYMENT_MODE=CLOSE
```

---

## 🐳 Deployment (Docker)

API di-deploy menggunakan Docker. File `api/Dockerfile` sudah tersedia.

```bash
# Build image
docker build -t gymku-api ./api

# Run container
docker run -p 3000:3000 --env-file api/.env gymku-api
```

---

## 👤 Developer

**Iwan Syaputra**  
📧 iwantugaskuliah@gmail.com

---

*Terakhir diupdate: Mei 2026 — v2.0 Production Release*
