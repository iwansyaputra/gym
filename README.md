# 🏋️ GymKu — Sistem Manajemen Gym Terpadu

Sistem manajemen gym lengkap berbasis **Flutter (mobile)**, **Admin Web (HTML/CSS/JS)**, **Landing Page**, dan **Backend API (Node.js/Express)**. Dilengkapi integrasi NFC check-in menggunakan **ACR122U** hardware reader dan **Host Card Emulation (HCE)** pada perangkat Android.

---

## 🌐 Link Produksi

| Layanan | URL |
|---------|-----|
| 🖥️ Admin Dashboard | **https://gymku.motalindo.com/** |
| 🌍 Landing Page | **Vercel Deployment** (`landing/`) |
| ⚙️ Backend API | **https://api.gymku.my.id/** |
| 📱 Mobile App | APK / Google Play (Flutter) |

**Akun Admin:** `admin@gym.com` / `admin123`

---

## 🛠️ Technology Stack — Penjelasan Lengkap

### 📱 1. Mobile App — Flutter + Dart

| Item | Detail |
|------|--------|
| **Framework** | **Flutter** — framework UI cross-platform buatan Google |
| **Bahasa** | **Dart** (SDK `>=3.9.0 <4.0.0`) |
| **Target Platform** | Android (namespace: `com.motalindo.gymku`) |
| **Design System** | Material Design 3 (`useMaterial3: true`) |
| **Build System** | Gradle Kotlin DSL (`build.gradle.kts`) — Java 17 |
| **Min SDK** | Android (ditentukan oleh Flutter) |

#### Dependensi Flutter (pubspec.yaml)

| Package | Versi | Fungsi |
|---------|-------|--------|
| `http` | ^1.1.0 | HTTP client untuk panggilan REST API ke backend |
| `shared_preferences` | ^2.2.2 | Penyimpanan lokal (token JWT, session) |
| `nfc_host_card_emulation` | ^1.1.0 | Host Card Emulation — HP Android menjadi kartu NFC virtual |
| `webview_flutter` | ^4.4.2 | Menampilkan konten web (instruksi pembayaran) |
| `intl` | ^0.19.0 | Format tanggal & mata uang (Rupiah) |
| `url_launcher` | ^6.2.5 | Membuka URL eksternal dari dalam app |
| `cupertino_icons` | ^1.0.8 | Ikon iOS-style |

#### Dev Dependencies

| Package | Versi | Fungsi |
|---------|-------|--------|
| `flutter_lints` | ^6.0.0 | Linting & analisis kualitas kode Dart |
| `flutter_launcher_icons` | ^0.13.1 | Generate ikon launcher dari `assets/logo.png` |

#### Halaman Flutter (`lib/pages/`)

| File | Fungsi |
|------|--------|
| `login.dart` | Login dengan email & password |
| `registrasi.dart` | Registrasi akun baru |
| `otp_page.dart` | Verifikasi OTP email |
| `beranda.dart` | Dashboard utama (info membership & saldo) |
| `card.dart` | Kartu member digital |
| `check_in_nfc_page.dart` | HCE NFC — HP berfungsi sebagai kartu virtual |
| `membership_packages_page.dart` | Daftar & beli paket membership |
| `payment.dart` | Flow pembayaran E-Smartlink |
| `payment_detail_page.dart` | Detail & instruksi pembayaran |
| `saldo_page.dart` | Halaman dompet digital / saldo |
| `topup_payment_page.dart` | Top-up saldo via payment gateway |
| `riwayat.dart` | Riwayat check-in & transaksi |
| `promo.dart` | Daftar promo & diskon |
| `akun.dart` | Profil & pengaturan akun |

#### Services (`lib/services/`)

| File | Fungsi |
|------|--------|
| `api_service.dart` | Semua panggilan HTTP ke backend API |
| `api_config.dart` | Konfigurasi URL API (prod: `api.gymku.my.id`) |
| `auth_storage.dart` | Kelola token JWT & data session lokal |
| `payment_service.dart` | Logic khusus integrasi pembayaran E-Smartlink |

#### Widgets (`lib/widgets/`)

| File | Fungsi |
|------|--------|
| `payment_channel_sheet.dart` | Bottom sheet pemilihan channel bayar (VA BCA, BNI, dll) |

#### Native Android (Kotlin)

- Namespace: `com.motalindo.gymku`
- Build: Gradle Kotlin DSL dengan signing config release
- AndroidManifest.xml: Permission NFC, HCE service declaration
- Keystore: `gymku-release.jks` untuk signing APK release

---

### ⚙️ 2. Backend API — Node.js + Express.js

| Item | Detail |
|------|--------|
| **Runtime** | **Node.js** — JavaScript runtime di server |
| **Framework** | **Express.js** v4.18.2 — minimalist web framework untuk REST API |
| **Bahasa** | **JavaScript** (CommonJS modules via `require()`) |
| **Database** | **MySQL** via `mysql2` v3.6.5 (connection pooling) |
| **Entry Point** | `api/server.js` |
| **Dev Server** | **Nodemon** v3.0.2 (`npm run dev` — auto-restart saat file berubah) |
| **Deployment** | **Docker** (Dockerfile tersedia) + **Vercel** (vercel.json tersedia) |

#### Dependensi Backend (package.json)

| Package | Versi | Fungsi |
|---------|-------|--------|
| `express` | ^4.18.2 | Web framework — routing, middleware, request handling |
| `mysql2` | ^3.6.5 | MySQL driver — koneksi database dengan connection pooling |
| `jsonwebtoken` | ^9.0.2 | JWT — generate & verify token untuk autentikasi |
| `bcryptjs` | ^2.4.3 | Hash & verify password (bcrypt algorithm) |
| `cors` | ^2.8.5 | Cross-Origin Resource Sharing — izinkan request dari domain lain |
| `body-parser` | ^1.20.2 | Parse request body JSON & URL-encoded |
| `dotenv` | ^16.3.1 | Load environment variables dari file `.env` |
| `nodemailer` | ^8.0.5 | Kirim email OTP untuk verifikasi akun |
| `moment` | ^2.29.4 | Manipulasi tanggal & waktu (timezone WIB) |

#### Struktur Backend (`api/`)

```
api/
├── server.js                  # Entry point Express (port 3000, listen 0.0.0.0)
├── package.json               # Dependensi Node.js
├── .env                       # Environment variables (DB, email, E-Smartlink)
├── vercel.json                # Konfigurasi deployment Vercel
├── nfc-bridge.py              # NFC Bridge Python (ACR122U → WebSocket)
├── jalankan-nfc-bridge.bat    # Script Windows untuk NFC bridge
├── buka-chrome-checkin.bat    # Chrome dengan --allow-insecure-localhost
├── controllers/
│   ├── authController.js      # Login, register, OTP, JWT
│   ├── userController.js      # CRUD profil user
│   ├── checkInController.js   # Check-in NFC (atomic SQL + mutex anti-duplicate)
│   ├── membershipController.js # Paket membership
│   ├── transactionController.js # Riwayat transaksi
│   ├── paymentController.js   # Integrasi E-Smartlink payment gateway
│   ├── promoController.js     # CRUD promo & diskon
│   ├── walletController.js    # Dompet digital (saldo, topup, riwayat)
│   └── adminController.js     # Dashboard stats, admin operations
├── routes/
│   ├── authRoutes.js          # /api/auth/*
│   ├── userRoutes.js          # /api/user/*
│   ├── checkInRoutes.js       # /api/check-in/*
│   ├── membershipRoutes.js    # /api/membership/*
│   ├── transactionRoutes.js   # /api/transactions/*
│   ├── paymentRoutes.js       # /api/payment/*
│   ├── promoRoutes.js         # /api/promos/*
│   ├── walletRoutes.js        # /api/wallet/*
│   └── adminRoutes.js         # /api/admin/*
├── middleware/
│   ├── auth.js                # JWT token verification middleware
│   └── isAdmin.js             # Role-based access (admin only)
├── config/
│   ├── database.js            # MySQL connection pool config
│   ├── esmartlink.js          # E-Smartlink payment gateway config
│   └── packages.json          # Default package definitions
├── utils/
│   ├── email.js               # Nodemailer — kirim email OTP
│   └── helpers.js             # Fungsi utilitas umum
└── postman/                   # Postman collection untuk testing API
```

---

### 🖥️ 3. Admin Web Dashboard — HTML + CSS + Vanilla JavaScript

| Item | Detail |
|------|--------|
| **Bahasa Markup** | **HTML5** — semantic elements |
| **Styling** | **Vanilla CSS** — custom properties (CSS Variables) untuk tema Light/Dark |
| **JavaScript** | **Vanilla JavaScript (ES6+)** — tanpa framework/library JS |
| **Charting** | **Chart.js** v4.4.0 (via CDN) — grafik check-in & revenue |
| **Export PDF** | **jsPDF** v2.5.1 + **jspdf-autotable** v3.5.31 (via CDN) |
| **Export Excel** | **ExcelJS** v4.3.0 (via CDN) — export laporan `.xlsx` |
| **Font** | **Google Fonts** — Inter (body) + Outfit (display/heading) |
| **Tema** | CSS Variables + `data-theme` attribute (`dark`/`light`) dengan localStorage |
| **FOUC Prevention** | Inline `<script>` di `<head>` untuk set tema sebelum render |

> **Catatan:** Admin Web **tidak** menggunakan framework JavaScript apapun (React, Vue, Angular, dll). Semua interaktivitas dibangun dengan **Vanilla JavaScript ES6+** murni menggunakan `fetch()` API, DOM manipulation, dan event listeners.

#### Library JavaScript via CDN

| Library | Versi | CDN Source | Dipakai di |
|---------|-------|------------|------------|
| Chart.js | 4.4.0 | jsdelivr.net | `dashboard.html`, `reports.html` |
| jsPDF | 2.5.1 | cdnjs.cloudflare.com | `reports.html` (export PDF) |
| jspdf-autotable | 3.5.31 | cdnjs.cloudflare.com | `reports.html` (tabel PDF) |
| ExcelJS | 4.3.0 | cdnjs.cloudflare.com | `reports.html` (export Excel) |

#### File JavaScript Custom (`admin/js/`)

| File | Fungsi |
|------|--------|
| `config.js` | Konfigurasi API URL, helper functions (format currency/date/toast) |
| `components.js` | Komponen UI terpusat (Sidebar navigation, tema toggle) |
| `auth.js` | Cek autentikasi JWT, redirect ke login jika expired |
| `api.js` | Wrapper `fetch()` — header Authorization otomatis |
| `login.js` | Logic form login admin |
| `dashboard.js` | Load statistik KPI, chart check-in mingguan & revenue |
| `checkin.js` | WebSocket ke NFC bridge + auto check-in logic |
| `members.js` | CRUD member, link kartu NFC, export data |
| `packages.js` | CRUD paket membership |
| `promos.js` | CRUD promo & diskon |
| `transactions.js` | Tampil riwayat transaksi |
| `topup.js` | Top-up saldo dompet member |
| `reports.js` | Laporan keuangan, member, K-Means clustering |

#### Halaman Admin (`admin/`)

| File | Fungsi |
|------|--------|
| `index.html` | **Landing Page** admin (terintegrasi di admin/) |
| `login.html` | Form login admin |
| `dashboard.html` | Dashboard statistik harian |
| `members.html` | Manajemen member (CRUD + NFC card) |
| `checkin.html` | Check-in NFC real-time via ACR122U |
| `topup.html` | Top-up saldo dompet member |
| `packages.html` | Manajemen paket membership |
| `promos.html` | Manajemen promo & diskon |
| `transactions.html` | Riwayat transaksi |
| `reports.html` | Laporan + K-Means clustering |
| `privacy.html` | Kebijakan privasi |

#### Styling (`admin/css/`)

| File | Fungsi |
|------|--------|
| `style.css` | Stylesheet utama (47KB) — layout, komponen, responsive, tema |
| `aesthetic.css` | Tambahan estetika (glassmorphism, glow effects) |

---

### 🌐 4. Landing Page — HTML + CSS + Vanilla JavaScript

| Item | Detail |
|------|--------|
| **Lokasi** | `landing/` (deployment terpisah) dan `admin/index.html` (terintegrasi) |
| **Bahasa** | **HTML5** + **Vanilla CSS** + **Vanilla JavaScript ES6+** |
| **Font** | **Google Fonts** — Inter + Outfit |
| **Desain** | Glassmorphism, gradient orbs, smooth scroll, intersection observer |
| **Tema** | Light/Dark mode (CSS Variables + localStorage) |
| **Responsive** | Mobile-first design, hamburger menu |

| File | Lokasi | Fungsi |
|------|--------|--------|
| `landing/index.html` | Landing standalone | Homepage utama |
| `landing/style.css` | Landing standalone | Styling landing (28KB) |
| `landing/script.js` | Landing standalone | Animasi, scroll, tema toggle |
| `admin/index.html` | Admin terintegrasi | Landing + navigasi ke login admin |
| `admin/landing-style.css` | Admin terintegrasi | Styling landing (28KB) |
| `admin/landing-script.js` | Admin terintegrasi | Script landing |

---

### 🐍 5. NFC Bridge — Python

| Item | Detail |
|------|--------|
| **Bahasa** | **Python 3** |
| **File** | `api/nfc-bridge.py` (28KB) |
| **Library** | `pyscard` (smartcard/NFC), `websockets` (WebSocket server), `requests` (HTTP) |
| **Hardware** | ACR122U USB NFC Reader |
| **Protokol** | APDU commands, WebSocket (`ws://localhost:8765`) |

---

### 🗃️ 6. Database — MySQL

| Item | Detail |
|------|--------|
| **DBMS** | **MySQL** |
| **Driver** | `mysql2` (Node.js) dengan connection pooling |
| **Schema** | `membership_gym.sql` (35KB) — dump lengkap |
| **Development** | Laragon (MySQL built-in) + phpMyAdmin |

---

### 🐳 7. DevOps & Deployment

| Tool | Fungsi |
|------|--------|
| **Docker** | Containerisasi API backend (`api/Dockerfile`) |
| **Vercel** | Serverless deployment API (`api/vercel.json` dengan `@vercel/node`) |
| **Laragon** | Local development server (Windows) — MySQL + Apache |
| **Git** | Version control |
| **Gradle** | Build system Android (Kotlin DSL) |

---

## ✨ Changelog (Juni 2026)

### v2.2 — Global Theme System & Brand Enhancement
1. **Global Theme Switching (Light/Dark Mode)**: Sistem tema terpadu berbasis CSS Variables pada Landing Page & Admin Web, dengan inisialisasi instan (FOUC prevention).
2. **Topbar Theme Toggle**: Tombol toggle tema minimalis di header Admin Panel.
3. **Enhanced KPI Stat Cards**: Penyempurnaan kontras pada dark/light mode.
4. **Peningkatan Durasi OTP**: Masa kadaluarsa OTP diperpanjang menjadi **5 menit**.
5. **Pembaruan Branding & Legal**: Copyright "GYMKU X Universitas Harkat Negeri", favicon & logo baru.
6. **Ikon Bank Pembayaran Asli**: Logo bank asli (BCA, BNI, Mandiri, BRI, dll) di Landing Page.
7. **Landing Page Responsive Fix**: Perbaikan layout CSS Grid di section `#payment` untuk desktop.

### v2.1 — Multi-Channel Payment & Production Gateway
1. **Multi-Channel Payment**: 9+ channel bayar (VA BCA, BNI, BRI, Mandiri, Permata, CIMB, BNC, Alfamart, Indomaret) melalui Bottom Sheet di Flutter.
2. **Production Gateway**: Beralih dari Sandbox ke Production E-Smartlink.
3. **Auto-Polling Top Up**: Deteksi pembayaran otomatis (interval 5 detik).
4. **Redesign Riwayat Transaksi**: UI kartu baru + halaman detail pembayaran.

### v2.0 — Production Deployment
1. **Deploy ke Production**: Admin Web & API live di domain `motalindo.com` (Docker).
2. **NFC Bridge — HTTPS Workaround**: `buka-chrome-checkin.bat` dengan `--allow-insecure-localhost`.
3. **Fallback WebSocket**: `ws://localhost:8765` → fallback `ws://127.0.0.1:8765`.
4. **Konfigurasi URL Produksi**: Semua config menunjuk ke production.

### v1.x — Fitur Sebelumnya
5. **Rebranding GYMKU**: Nama & ikon launcher baru.
6. **Riwayat Check-in Member (Mobile)**: Tab kehadiran personal.
7. **Sinkronisasi Zona Waktu**: UTC → WIB real-time.
8. **Programming Kartu Fisik NFC**: Tulis User ID ke NTAG213 / Mifare Classic 1K.
9. **Sistem Dompet (Wallet)**: Kelola saldo member.
10. **Sentralisasi UI Admin**: Sidebar di `js/components.js`.
11. **Proteksi Check-In Berbasis Langganan**: Block jika membership expired.
12. **Export Laporan Excel**: Format `.xlsx` via ExcelJS.
13. **K-Means Clustering**: Segmentasi aktivitas member di halaman Laporan.

---

## 📦 Ringkasan Komponen Sistem

| Komponen | Teknologi Utama | Bahasa | Lokasi | Produksi |
|----------|----------------|--------|--------|----------|
| Mobile App | Flutter + Dart | Dart | `lib/` | APK / Play Store |
| Backend API | Node.js + Express.js | JavaScript (ES6+) | `api/` | `api.gymku.my.id` (Vercel) |
| Admin Web | HTML5 + CSS3 + Vanilla JS | JavaScript (ES6+) | `admin/` | `gymku.motalindo.com` |
| Landing Page | HTML5 + CSS3 + Vanilla JS | JavaScript (ES6+) | `landing/` | Vercel |
| Database | MySQL | SQL | `membership_gym.sql` | Hosted MySQL |
| NFC Bridge | Python + pyscard + websockets | Python 3 | `api/nfc-bridge.py` | Lokal (ws://localhost:8765) |
| Android Native | Kotlin + Gradle KTS | Kotlin | `android/` | Bundled in APK |

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
npm run dev    # Menggunakan nodemon — auto-restart saat file berubah
```
> Server berjalan di `http://0.0.0.0:3000`

### 3. Buka Admin Web
> ⚠️ **Wajib dibuka via HTTP server**, bukan langsung `file://`

Buka file HTML di `admin/` melalui Laragon atau live server. **Login:** `admin@gym.com` / `admin123`

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
3. Semua fitur terhubung ke `api.gymku.my.id`

---

## 📡 Integrasi NFC (ACR122U + HCE)

### Arsitektur (Production)
```
[HP Android / Kartu NFC Fisik]
        ↓ (tempel ke reader)
[ACR122U — USB ke Komputer Admin]
        ↓
[nfc-bridge.py — ws://localhost:8765]
        ↓ (WebSocket lokal)
[Browser Chrome — gymku.motalindo.com/checkin.html]
        ↓ (HTTPS)
[API — api.gymku.my.id/api/check-in/nfc]
        ↓
[Database MySQL Hosting]
```

> **Penting**: NFC Bridge berjalan di **komputer admin** (lokal), bukan di server hosting.

### Mode 1: ACR122U USB Reader

**Langkah:**
1. Jalankan NFC Bridge: `api\jalankan-nfc-bridge.bat`
2. Buka Chrome khusus: `api\buka-chrome-checkin.bat` (flag `--allow-insecure-localhost`)

**Instalasi Python (sekali):** `pip install pyscard websockets requests`

### Mode 2: Web NFC API (Fallback)
Jika `nfc-bridge.py` tidak aktif, fallback ke Web NFC API (Chrome Android saja).

### Proteksi Double Check-in (3 lapis)

| Lapis | Lokasi | Mekanisme |
|-------|--------|-----------|
| Bridge cooldown | `nfc-bridge.py` | NFC ID sama diabaikan selama **5 detik** |
| Browser debounce | `checkin.js` | Timestamp lock **10 detik** per NFC ID |
| Atomic SQL | `checkInController.js` | `INSERT...WHERE NOT EXISTS` + mutex per userId |

---

## 🔌 API Endpoints

**Base URL:** `https://api.gymku.my.id/api`

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
| GET | `/user/profile` | Profil user + kartu + membership |
| PUT | `/user/profile` | Update profil |
| PUT | `/user/change-password` | Ganti password |

### Check-in
| Method | Endpoint | Keterangan |
|--------|----------|------------|
| POST | `/check-in/lookup` | Cari member by NFC ID |
| POST | `/check-in/nfc` | Catat check-in (butuh `X-NFC-Secret`) |
| GET | `/check-in/history` | Riwayat check-in |

### Admin
| Method | Endpoint | Keterangan |
|--------|----------|------------|
| GET | `/admin/users` | Semua member |
| PUT | `/admin/users/:id` | Update member |
| DELETE | `/admin/users/:id` | Hapus member |
| GET | `/admin/dashboard/stats` | Statistik dashboard |
| GET | `/admin/checkin/stats` | Statistik check-in |
| GET | `/admin/wallets` | Data dompet member |
| POST | `/admin/wallets/topup` | Top up saldo |
| GET | `/admin/wallets/:id/history` | Riwayat saldo |

### Membership, Transaksi & Payment
| Method | Endpoint | Keterangan |
|--------|----------|------------|
| GET | `/membership/packages` | Daftar paket |
| POST | `/membership/extend` | Perpanjang membership |
| GET | `/transactions/history` | Riwayat transaksi |
| POST | `/payment/create` | Buat pembayaran (E-Smartlink) |
| GET | `/payment/status` | Cek status pembayaran |
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

---

## 🔐 Autentikasi API

**JWT Header (user/admin):**
```
Authorization: Bearer <token>
```

**NFC Bridge Secret:**
```
X-NFC-Secret: nfc-bridge-secret-2024
```

---

## 💳 Payment Gateway (E-Smartlink)

Integrasi **Production** E-Smartlink dengan channel bayar dinamis dari Flutter.

```env
# api/.env
ESMARTLINK_BASE_URL=https://payment-service.pakar-digital.com
ESMARTLINK_USERNAME=api-smartlink@poltekharber.ac.id
ESMARTLINK_PASSWORD=your_password
ESMARTLINK_PAYMENT_MODE=CLOSE
```

Channel bayar dikirim dinamis dari Flutter: `VA_BCA`, `VA_BNI`, `VA_BRI`, `VA_MANDIRI`, `VA_PERMATA`, `VA_CIMB`, `VA_BNC`, `ALFAMART`, `INDOMARET`.

---

## 🐳 Deployment

### Docker (API)
```bash
docker build -t gymku-api ./api
docker run -p 3000:3000 --env-file api/.env gymku-api
```

### Vercel (API)
API juga mendukung deployment Vercel (`api/vercel.json` dengan `@vercel/node`). Server.js mengekspor `module.exports = app` dan skip `app.listen()` ketika `process.env.VERCEL` terdeteksi.

---

## 🛠️ Troubleshooting

### ❌ Admin web tidak bisa login
- Buka **https://gymku.motalindo.com/** (bukan `http://`)
- Pastikan email & password: `admin@gym.com` / `admin123`
- Cek console: API harus menjawab dari `api.gymku.my.id`

### ❌ ACR122U tidak bisa konek dari HTTPS
- Gunakan `api\buka-chrome-checkin.bat` (Chrome + `--allow-insecure-localhost`)
- Pastikan `nfc-bridge.py` sudah berjalan

### ❌ ACR122U tidak terdeteksi
- Install driver PC/SC dari [ACS website](https://www.acs.com.hk/en/drivers/)
- Cek Device Manager: "ACS ACR122U"
- Test: `python -c "from smartcard.System import readers; print(readers())"`

### ❌ Flutter tidak bisa connect ke API (dev lokal)
- Update URL di `lib/services/api_config.dart`
- Pastikan HP dan PC dalam WiFi yang sama
- Cek firewall Windows: izinkan port 3000

### ❌ "Failed to fetch" saat development lokal
- Pastikan backend berjalan: `cd api && npm run dev`
- Buka admin web via HTTP server, **bukan** `file://`

---

## 👤 Developer

**Iwan Syaputra | Alya Dwi Rahma**
📧 iwantugaskuliah@gmail.com | alyadwirahma603@gmail.com

---

*Terakhir diupdate: Juni 2026 — v2.2 Release*
