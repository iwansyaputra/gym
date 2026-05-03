# 🏋️ GymKu — Sistem Manajemen Gym Terpadu

Sistem manajemen gym lengkap berbasis **Flutter (mobile)**, **Admin Web (HTML/JS)**, dan **Backend API (Node.js)**. Dilengkapi integrasi NFC check-in menggunakan **ACR122U** hardware reader dan **Host Card Emulation (HCE)** pada perangkat Android.

---

## ✨ Fitur Terbaru (Mei 2026)
1. **Rebranding Identitas Aplikasi (GYMKU)**: Pembaruan total pada nama aplikasi dan ikon launcher dengan desain estetik Dark Blue & Black yang kuat dan modern menggunakan `flutter_launcher_icons`.
2. **Riwayat Check-in Member (Mobile)**: Penambahan Tab Baru pada halaman Riwayat di aplikasi Flutter. Member kini bisa melihat riwayat kehadiran (tanggal & jam) mereka secara personal yang dipisahkan dari riwayat transaksi.
3. **Sinkronisasi Zona Waktu Real-time**: Peningkatan akurasi waktu check-in dengan sistem yang mampu menerjemahkan data UTC dari server Node.js ke Waktu Indonesia Barat (WIB) secara *real-time* di semua perangkat, tanpa terpengaruh bug zona waktu dari Android Emulator.
4. **Pembersihan Kode Kusam**: Penghapusan skrip generator UI usang (`dark_css.py`, `clean_css.py`) dan optimalisasi codebase Flutter dengan `dart fix`.
5. **Programming Kartu Fisik NFC**: Mendukung penulisan/pendaftaran ID Member secara langsung ke memori internal kartu fisik (NTAG213 / Mifare Classic 1K).
6. **Sistem Dompet (Wallet) Terintegrasi**: Fitur "Kelola Saldo" tersinkronisasi penuh antara Admin Web dan Backend.
7. **Sentralisasi UI Admin**: Struktur menu Sidebar pada Web Admin telah difaktorisasi ke dalam satu komponen pusat (`js/components.js`).
8. **Proteksi Check-In Berbasis Langganan**: Pada Mobile App, fitur *Check-in NFC* otomatis terblokir jika user berstatus **Non-Member** atau kadaluwarsa.

---

## 📦 Komponen Sistem

| Komponen | Teknologi | Lokasi | Port |
|----------|-----------|--------|------|
| Backend API | Node.js + Express + MySQL | `api/` | 3000 |
| Admin Web Dashboard | HTML / CSS / JavaScript | `admin_web/` | 5500 (dev) |
| Mobile App | Flutter (Android) | `lib/` | - |
| Database | MySQL via Laragon | - | 3306 |
| NFC Bridge | Python + pyscard + websockets | `api/nfc-bridge.py` | 8765 (WS) |

---

## 🚀 Quick Start

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
> Server berjalan di `http://0.0.0.0:3000` — dapat diakses dari HP di jaringan yang sama.

### 3. Buka Admin Web

> ⚠️ **Wajib dibuka via HTTP server**, bukan langsung dari `file://`  
> (Browser modern memblokir fetch dari `file://` ke `http://`)

**Cara 1 — Double klik:**
```
admin_web/jalankan-admin-web.bat
```
Lalu buka: `http://localhost:5500`

**Cara 2 — Manual:**
```bash
cd admin_web
python -m http.server 5500
```

**Login:** `admin@gym.com` / `admin123`

### 4. Jalankan Mobile App (Flutter)
```bash
flutter pub get
flutter run
```

---

## 🔧 Konfigurasi IP

Jika berpindah WiFi, **IP server berubah**. Update di 2 tempat:

### Admin Web — `admin_web/js/config.js`
```javascript
const FALLBACK_API_HOST = '192.168.x.x'; // Ganti dengan IP baru (hasil ipconfig)
```

### Flutter App — `lib/services/api_config.dart`
```dart
static const String _currentIP = '192.168.x.x'; // Ganti dengan IP baru
```

> Cek IP saat ini: jalankan `ipconfig` → lihat "IPv4 Address" di adapter WiFi aktif.

---

## 📡 Integrasi NFC (ACR122U + HCE)

Sistem check-in NFC mendukung dua mode:

### Mode 1: ACR122U USB Reader (Recommended untuk Admin PC)

**Arsitektur:**
```
[HP Android (HCE)] → [ACR122U USB] → [nfc-bridge.py] → WebSocket → [checkin.html]
```

**Persiapan:**
```bash
pip install pyscard websockets
```

**Cara Menjalankan:**
```bash
# Double klik:
api/jalankan-nfc-bridge.bat

# Atau manual:
cd api
python nfc-bridge.py
```

**Alur Teknis:**
1. HP Android (Flutter app, mode HCE aktif) ditempelkan ke ACR122U
2. `nfc-bridge.py` kirim **SELECT AID** (`A0 00 DA DA DA DA DA`) ke HP
3. HP merespons dengan `nfc_id` member dalam format ASCII bytes
4. Bridge decode bytes → string `nfc_id`
5. Kirim ke browser via WebSocket (`ws://localhost:8765`)
6. `checkin.html` terima `nfc_id` → auto check-in ke database

**Proteksi Double Check-in (3 lapis):**

| Lapis | Lokasi | Mekanisme |
|-------|--------|-----------|
| Bridge cooldown | `nfc-bridge.py` | NFC ID sama diabaikan dalam **5 detik** |
| Browser debounce | `checkin.js` | Timestamp-based lock **10 detik** per NFC ID |
| Atomic SQL | `checkInController.js` | `INSERT...WHERE NOT EXISTS` + mutex per userId |

### Mode 2: Web NFC API (Fallback — Mobile Chrome saja)
Jika `nfc-bridge.py` tidak aktif, otomatis fallback ke Web NFC API (hanya Chrome di Android).

---

## 📱 Fitur Mobile App (Flutter)

- **Login / Register** dengan OTP email
- **Dashboard** info membership aktif
- **Check-in NFC** via HCE — HP berfungsi sebagai kartu virtual
  - Mengirim `nfc_id` dari database sebagai payload APDU
  - **Tidak** memanggil API check-in secara langsung (dicatat oleh admin web)
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
| `members.html` | Manajemen member (CRUD) |
| `checkin.html` | Check-in NFC real-time via ACR122U |
| `topup.html` | Manajemen dan top up saldo dompet member |
| `packages.html` | Manajemen paket membership |
| `transactions.html` | Riwayat transaksi |
| `reports.html` | Laporan + K-Means clustering aktivitas member |

---

## 🗂️ Struktur Proyek

```
membership_gym/
├── api/                          # Backend Node.js
│   ├── server.js                 # Entry point Express
│   ├── nfc-bridge.py             # NFC Bridge (ACR122U → WebSocket)
│   ├── jalankan-nfc-bridge.bat   # Script Windows untuk jalankan bridge
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
│   ├── transactions.html
│   ├── reports.html
│   ├── topup.html                # Kelola Saldo Member
│   ├── jalankan-admin-web.bat    # Script jalankan HTTP server lokal
│   ├── css/style.css
│   └── js/
│       ├── components.js         # UI Components terpusat (Sidebar)
│       ├── config.js             # API URL config (update IP di sini)
│       ├── auth.js
│       ├── api.js
│       ├── login.js
│       ├── dashboard.js
│       ├── checkin.js            # WebSocket + auto check-in logic
│       ├── members.js
│       ├── packages.js
│       ├── transactions.js
│       ├── topup.js              # Logika topup & riwayat saldo
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
│   │   ├── promo_page.dart
│   │   └── profile_page.dart
│   └── services/
│       ├── api_service.dart
│       ├── api_config.dart          # IP server config (update IP di sini)
│       └── auth_storage.dart
│
├── membership_gym.sql            # Database dump lengkap
└── README.md
```

---

## 🔌 API Endpoints

### Auth
| Method | Endpoint | Keterangan |
|--------|----------|------------|
| POST | `/api/auth/register` | Registrasi user baru |
| POST | `/api/auth/login` | Login (JWT token) |
| POST | `/api/auth/verify-otp` | Verifikasi OTP email |

### User
| Method | Endpoint | Keterangan |
|--------|----------|------------|
| GET | `/api/user/profile` | Profil user + data kartu + membership |
| PUT | `/api/user/profile` | Update profil |
| PUT | `/api/user/change-password` | Ganti password |

### Check-in
| Method | Endpoint | Keterangan |
|--------|----------|------------|
| POST | `/api/check-in/lookup` | Cari member by NFC ID (tanpa catat DB) |
| POST | `/api/check-in/nfc` | Catat check-in ke database |
| GET | `/api/check-in/history` | Riwayat check-in |

### Admin
| Method | Endpoint | Keterangan |
|--------|----------|------------|
| GET | `/api/admin/users` | Semua member |
| GET | `/api/admin/dashboard/stats` | Statistik dashboard |
| GET | `/api/admin/checkin/stats` | Statistik check-in |
| GET | `/api/admin/wallets` | Data dompet member |
| POST | `/api/admin/wallets/topup` | Top up saldo member |
| GET | `/api/admin/wallets/:id/history` | Riwayat saldo member |

### Membership & Transaksi
| Method | Endpoint | Keterangan |
|--------|----------|------------|
| GET | `/api/membership/packages` | Daftar paket |
| POST | `/api/membership/extend` | Perpanjang membership |
| GET | `/api/transactions/history` | Riwayat transaksi |
| POST | `/api/payment/create` | Buat pembayaran (E-Smartlink) |

---

## 🗃️ Skema Database Utama

```sql
users           -- Data user/member
member_cards    -- Kartu NFC (nfc_id, card_number, is_active)
memberships     -- Data paket membership aktif
check_ins       -- Log check-in (user_id, check_in_time, check_in_method)
transactions    -- Riwayat transaksi pembayaran
packages        -- Paket membership tersedia
promos          -- Data promosi/diskon
wallets         -- Data dompet digital/saldo member
wallet_transactions -- Riwayat topup & potong saldo
```

> **Kolom penting:** `member_cards.nfc_id` — ID unik yang disimpan di Flutter (via HCE) dan dibaca oleh ACR122U bridge.

---

## 🛠️ Troubleshooting

### ❌ "Failed to fetch" saat login Admin Web
- Pastikan backend berjalan: `cd api && npm run dev`
- Buka admin web via HTTP server, **bukan** `file://`
- Cek IP di `admin_web/js/config.js` sudah sesuai hasil `ipconfig`

### ❌ ACR122U tidak terdeteksi
- Pastikan driver PC/SC sudah terinstall (download dari ACS website)
- Colok ulang USB, restart bridge
- Cek di Device Manager: "ACS ACR122U"

### ❌ NFC ID tidak terbaca / baca angka random
- Pastikan HP Android dalam kondisi HCE aktif (klik tombol "Mulai Scan" di app Flutter)
- `nfc-bridge.py` membaca APDU response (nfc_id ASCII) — bukan UID fisik kartu
- Lihat log di terminal bridge untuk debug urutan APDU

### ❌ Double check-in
- Restart `nfc-bridge.py` dan hard refresh browser (`Ctrl+Shift+R`)
- Backend sudah memiliki proteksi atomic SQL (INSERT WHERE NOT EXISTS 60 detik)
- Bridge sudah memiliki cooldown 5 detik per NFC ID

### ❌ Flutter tidak bisa connect ke API
- Update IP di `lib/services/api_config.dart` → `_currentIP`
- Pastikan HP dan PC dalam WiFi yang sama
- Cek firewall Windows: izinkan port 3000

---

## 💳 Payment Gateway (E-Smartlink)

Konfigurasi di `api/.env`:
```env
ESMARTLINK_MERCHANT_ID=your_merchant_id
ESMARTLINK_API_KEY=your_api_key
ESMARTLINK_BASE_URL=https://api.esmartlink.co.id
```

---

## 👤 Developer

**Iwan Syaputra**  
📧 iwantugaskuliah@gmail.com

---

*Terakhir diupdate: Mei 2026*
