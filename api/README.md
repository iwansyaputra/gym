# Membership Gym API

Backend API untuk aplikasi Membership Gym menggunakan Node.js, Express, dan MySQL.

## 🚀 Fitur

- **Authentication**: Register, Login, OTP Verification
- **User Management**: Profile management, Change password
- **Membership**: Check membership status, Extend membership
- **Check-in**: NFC check-in, Check-in history & statistics
- **Transactions**: Payment history, Create & confirm payments
- **Promos**: Get active promos

## 📋 Prerequisites

- Node.js (v14 atau lebih tinggi)
- MySQL (v5.7 atau lebih tinggi)
- npm atau yarn

## 🛠️ Installation

1. **Clone repository atau navigate ke folder api**
   ```bash
   cd api
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Setup Database**
   - Buat database MySQL
   - Import schema dari `database/schema.sql`
   ```bash
   mysql -u root -p < database/schema.sql
   ```

4. **Configure Environment**
   - Copy `.env.example` ke `.env`
   ```bash
   cp .env.example .env
   ```
   - Edit `.env` dan sesuaikan dengan konfigurasi Anda:
   ```env
   PORT=3000
   DB_HOST=localhost
   DB_USER=root
   DB_PASSWORD=your_password
   DB_NAME=membership_gym
   JWT_SECRET=your_secret_key
   EMAIL_USER=your_email@gmail.com
   EMAIL_PASSWORD=your_app_password
   ```

5. **Run Server**
   ```bash
   # Development mode
   npm run dev

   # Production mode
   npm start
   ```

## 📡 API Endpoints

### Authentication
- `POST /api/auth/register` - Register user baru
- `POST /api/auth/login` - Login user
- `POST /api/auth/verify-otp` - Verifikasi OTP
- `POST /api/auth/resend-otp` - Kirim ulang OTP

### User
- `GET /api/user/profile` - Get user profile (Protected)
- `PUT /api/user/profile` - Update profile (Protected)
- `PUT /api/user/change-password` - Change password (Protected)

### Check-in
- `POST /api/check-in/nfc` - Check-in dengan NFC
- `GET /api/check-in/history` - Get check-in history (Protected)
- `GET /api/check-in/stats` - Get check-in statistics (Protected)

### Membership
- `GET /api/membership/info` - Get membership info (Protected)
- `GET /api/membership/packages` - Get available packages (Protected)
- `POST /api/membership/extend` - Extend membership (Protected)

### Transactions
- `GET /api/transactions/history` - Get transaction history (Protected)
- `GET /api/transactions/:id` - Get transaction detail (Protected)
- `POST /api/transactions/create` - Create payment (Protected)
- `POST /api/transactions/confirm` - Confirm payment

### Promos
- `GET /api/promos` - Get all active promos
- `GET /api/promos/:id` - Get promo detail

## 🔐 Authentication

API menggunakan JWT (JSON Web Token) untuk authentication. Untuk endpoint yang protected, sertakan token di header:

```
Authorization: Bearer <your_token>
```

## 📝 Request & Response Examples

### Register
**Request:**
```json
POST /api/auth/register
{
  "nama": "John Doe",
  "email": "john@example.com",
  "hp": "08123456789",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Registrasi berhasil. Kode OTP telah dikirim ke email Anda.",
  "data": {
    "userId": 1,
    "email": "john@example.com"
  }
}
```

### Login
**Request:**
```json
POST /api/auth/login
{
  "email": "john@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login berhasil",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "nama": "John Doe",
      "email": "john@example.com",
      "hp": "08123456789"
    },
    "membership": {
      "id": 1,
      "paket": "bulanan",
      "tanggal_berakhir": "2024-02-01"
    }
  }
}
```

### Check-in NFC
**Request:**
```json
POST /api/check-in/nfc
{
  "nfc_id": "NFC-GYM123456"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Check-in berhasil! Selamat berlatih 💪",
  "data": {
    "user": {
      "nama": "John Doe",
      "email": "john@example.com"
    },
    "check_in_time": "2024-01-15 10:30:00"
  }
}
```

## 🗄️ Database Schema

Database terdiri dari tabel-tabel berikut:
- `users` - Data pengguna
- `memberships` - Data membership
- `member_cards` - Data kartu member (NFC)
- `check_ins` - Riwayat check-in
- `transactions` - Riwayat transaksi
- `promos` - Data promo
- `otps` - Data OTP untuk verifikasi

## 🔧 Development

```bash
# Install dependencies
npm install

# Run in development mode with auto-reload
npm run dev

# Run in production mode
npm start
```

## 📦 Dependencies

- **express** - Web framework
- **mysql2** - MySQL client
- **bcryptjs** - Password hashing
- **jsonwebtoken** - JWT authentication
- **dotenv** - Environment variables
- **cors** - CORS middleware
- **nodemailer** - Email sending
- **moment** - Date manipulation

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

ISC

## 👨‍💻 Author

Membership Gym Development Team
