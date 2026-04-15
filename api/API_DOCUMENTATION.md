# API Documentation - Membership Gym

## Base URL
```
http://localhost:3000/api
```

## Authentication
Beberapa endpoint memerlukan authentication. Sertakan JWT token di header:
```
Authorization: Bearer {your_token}
```

---

## 📋 Endpoints

### 1. Authentication

#### 1.1 Register
Mendaftarkan user baru dan mengirim OTP ke email.

**Endpoint:** `POST /auth/register`

**Request Body:**
```json
{
  "nama": "John Doe",
  "email": "john@example.com",
  "hp": "08123456789",
  "password": "password123"
}
```

**Response Success (201):**
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

**Response Error (400):**
```json
{
  "success": false,
  "message": "Email atau nomor HP sudah terdaftar"
}
```

---

#### 1.2 Verify OTP
Verifikasi kode OTP yang dikirim ke email.

**Endpoint:** `POST /auth/verify-otp`

**Request Body:**
```json
{
  "email": "john@example.com",
  "otp": "123456"
}
```

**Response Success (200):**
```json
{
  "success": true,
  "message": "Verifikasi OTP berhasil"
}
```

**Response Error (400):**
```json
{
  "success": false,
  "message": "Kode OTP tidak valid atau sudah kadaluarsa"
}
```

---

#### 1.3 Login
Login user dan mendapatkan JWT token.

**Endpoint:** `POST /auth/login`

**Request Body:**
```json
{
  "email": "budi@example.com",
  "password": "password123"
}
```

**Response Success (200):**
```json
{
  "success": true,
  "message": "Login berhasil",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "nama": "Budi Santoso",
      "email": "budi@example.com",
      "hp": "08123456789",
      "foto_profil": null
    },
    "membership": {
      "id": 1,
      "user_id": 1,
      "paket": "bulanan",
      "tanggal_mulai": "2024-01-01",
      "tanggal_berakhir": "2024-01-31",
      "status": "active"
    }
  }
}
```

**Response Error (401):**
```json
{
  "success": false,
  "message": "Email atau password salah"
}
```

---

#### 1.4 Resend OTP
Mengirim ulang kode OTP ke email.

**Endpoint:** `POST /auth/resend-otp`

**Request Body:**
```json
{
  "email": "john@example.com"
}
```

**Response Success (200):**
```json
{
  "success": true,
  "message": "Kode OTP baru telah dikirim ke email Anda"
}
```

---

### 2. User Management

#### 2.1 Get Profile
Mendapatkan informasi profile user.

**Endpoint:** `GET /user/profile`

**Headers:** `Authorization: Bearer {token}`

**Response Success (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "nama": "Budi Santoso",
      "email": "budi@example.com",
      "hp": "08123456789",
      "foto_profil": null,
      "created_at": "2024-01-01T00:00:00.000Z"
    },
    "membership": {
      "id": 1,
      "paket": "bulanan",
      "tanggal_mulai": "2024-01-01",
      "tanggal_berakhir": "2024-01-31",
      "status": "active"
    },
    "card": {
      "card_number": "GYM123456",
      "nfc_id": "NFC-GYM123456"
    }
  }
}
```

---

#### 2.2 Update Profile
Update informasi profile user.

**Endpoint:** `PUT /user/profile`

**Headers:** `Authorization: Bearer {token}`

**Request Body:**
```json
{
  "nama": "Budi Santoso Updated",
  "hp": "08987654321"
}
```

**Response Success (200):**
```json
{
  "success": true,
  "message": "Profile berhasil diupdate"
}
```

---

#### 2.3 Change Password
Mengubah password user.

**Endpoint:** `PUT /user/change-password`

**Headers:** `Authorization: Bearer {token}`

**Request Body:**
```json
{
  "oldPassword": "password123",
  "newPassword": "newpassword123"
}
```

**Response Success (200):**
```json
{
  "success": true,
  "message": "Password berhasil diubah"
}
```

**Response Error (400):**
```json
{
  "success": false,
  "message": "Password lama tidak sesuai"
}
```

---

### 3. Check-in

#### 3.1 Check-in NFC
Check-in menggunakan NFC card.

**Endpoint:** `POST /check-in/nfc`

**Request Body:**
```json
{
  "nfc_id": "NFC-GYM123456"
}
```

**Response Success (200):**
```json
{
  "success": true,
  "message": "Check-in berhasil! Selamat berlatih 💪",
  "data": {
    "user": {
      "nama": "Budi Santoso",
      "email": "budi@example.com"
    },
    "check_in_time": "2024-01-15 10:30:00"
  }
}
```

**Response Error (404):**
```json
{
  "success": false,
  "message": "Kartu member tidak ditemukan atau tidak aktif"
}
```

**Response Error (403):**
```json
{
  "success": false,
  "message": "Membership Anda sudah tidak aktif. Silakan perpanjang terlebih dahulu."
}
```

---

#### 3.2 Get Check-in History
Mendapatkan riwayat check-in user.

**Endpoint:** `GET /check-in/history?limit=10&offset=0`

**Headers:** `Authorization: Bearer {token}`

**Query Parameters:**
- `limit` (optional): Jumlah data per halaman (default: 10)
- `offset` (optional): Offset untuk pagination (default: 0)

**Response Success (200):**
```json
{
  "success": true,
  "data": {
    "check_ins": [
      {
        "id": 1,
        "user_id": 1,
        "check_in_time": "2024-01-15T10:30:00.000Z",
        "check_in_method": "nfc",
        "location": "Main Gym"
      }
    ],
    "total": 25,
    "limit": 10,
    "offset": 0
  }
}
```

---

#### 3.3 Get Check-in Stats
Mendapatkan statistik check-in user.

**Endpoint:** `GET /check-in/stats`

**Headers:** `Authorization: Bearer {token}`

**Response Success (200):**
```json
{
  "success": true,
  "data": {
    "total_check_ins": 25,
    "this_month": 8,
    "this_week": 3
  }
}
```

---

### 4. Membership

#### 4.1 Get Membership Info
Mendapatkan informasi membership user.

**Endpoint:** `GET /membership/info`

**Headers:** `Authorization: Bearer {token}`

**Response Success (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "user_id": 1,
    "paket": "bulanan",
    "tanggal_mulai": "2024-01-01",
    "tanggal_berakhir": "2024-01-31",
    "status": "active",
    "remaining_days": 15,
    "is_active": true
  }
}
```

---

#### 4.2 Get Membership Packages
Mendapatkan daftar paket membership yang tersedia.

**Endpoint:** `GET /membership/packages`

**Headers:** `Authorization: Bearer {token}`

**Response Success (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "nama": "Paket Bulanan",
      "durasi": 30,
      "harga": 250000,
      "deskripsi": "Akses gym selama 1 bulan",
      "fitur": [
        "Akses semua alat gym",
        "Konsultasi trainer 1x",
        "Loker gratis"
      ]
    },
    {
      "id": 2,
      "nama": "Paket 3 Bulan",
      "durasi": 90,
      "harga": 650000,
      "deskripsi": "Akses gym selama 3 bulan",
      "fitur": [
        "Akses semua alat gym",
        "Konsultasi trainer 3x",
        "Loker gratis",
        "Diskon 13%"
      ]
    }
  ]
}
```

---

#### 4.3 Extend Membership
Perpanjang membership.

**Endpoint:** `POST /membership/extend`

**Headers:** `Authorization: Bearer {token}`

**Request Body:**
```json
{
  "package_id": 1,
  "payment_method": "transfer"
}
```

**Response Success (200):**
```json
{
  "success": true,
  "message": "Permintaan perpanjangan membership berhasil. Silakan lakukan pembayaran.",
  "data": {
    "membership_id": 2,
    "start_date": "2024-02-01",
    "end_date": "2024-03-01",
    "amount": 250000
  }
}
```

---

### 5. Transactions

#### 5.1 Get Transaction History
Mendapatkan riwayat transaksi user.

**Endpoint:** `GET /transactions/history?limit=10&offset=0&status=success`

**Headers:** `Authorization: Bearer {token}`

**Query Parameters:**
- `limit` (optional): Jumlah data per halaman
- `offset` (optional): Offset untuk pagination
- `status` (optional): Filter by status (pending, success, failed)

**Response Success (200):**
```json
{
  "success": true,
  "data": {
    "transactions": [
      {
        "id": 1,
        "user_id": 1,
        "membership_id": 1,
        "jenis_transaksi": "membership",
        "jumlah": 250000,
        "metode_pembayaran": "transfer",
        "status": "success",
        "tanggal_transaksi": "2024-01-01T00:00:00.000Z",
        "bukti_pembayaran": null
      }
    ],
    "total": 5,
    "limit": 10,
    "offset": 0
  }
}
```

---

#### 5.2 Get Transaction Detail
Mendapatkan detail transaksi.

**Endpoint:** `GET /transactions/:id`

**Headers:** `Authorization: Bearer {token}`

**Response Success (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "user_id": 1,
    "membership_id": 1,
    "jenis_transaksi": "membership",
    "jumlah": 250000,
    "metode_pembayaran": "transfer",
    "status": "success",
    "tanggal_transaksi": "2024-01-01T00:00:00.000Z",
    "paket": "bulanan",
    "tanggal_mulai": "2024-01-01",
    "tanggal_berakhir": "2024-01-31"
  }
}
```

---

#### 5.3 Create Payment
Membuat transaksi pembayaran baru.

**Endpoint:** `POST /transactions/create`

**Headers:** `Authorization: Bearer {token}`

**Request Body:**
```json
{
  "membership_id": 1,
  "amount": 250000,
  "payment_method": "transfer"
}
```

**Response Success (200):**
```json
{
  "success": true,
  "message": "Transaksi berhasil dibuat. Silakan lakukan pembayaran.",
  "data": {
    "transaction_id": 1
  }
}
```

---

#### 5.4 Confirm Payment
Konfirmasi pembayaran (untuk admin atau webhook payment gateway).

**Endpoint:** `POST /transactions/confirm`

**Request Body:**
```json
{
  "transaction_id": 1
}
```

**Response Success (200):**
```json
{
  "success": true,
  "message": "Pembayaran berhasil dikonfirmasi"
}
```

---

### 6. Promos

#### 6.1 Get All Promos
Mendapatkan semua promo yang aktif.

**Endpoint:** `GET /promos`

**Response Success (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "judul": "Promo Tahun Baru",
      "deskripsi": "Diskon 30% untuk membership tahunan",
      "gambar": null,
      "diskon_persen": 30,
      "tanggal_mulai": "2024-01-01",
      "tanggal_berakhir": "2024-01-31",
      "is_active": true,
      "is_valid": true,
      "days_remaining": 15
    }
  ]
}
```

---

#### 6.2 Get Promo Detail
Mendapatkan detail promo.

**Endpoint:** `GET /promos/:id`

**Response Success (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "judul": "Promo Tahun Baru",
    "deskripsi": "Diskon 30% untuk membership tahunan",
    "gambar": null,
    "diskon_persen": 30,
    "tanggal_mulai": "2024-01-01",
    "tanggal_berakhir": "2024-01-31",
    "is_active": true,
    "is_valid": true,
    "days_remaining": 15
  }
}
```

---

## Error Responses

### 400 Bad Request
```json
{
  "success": false,
  "message": "Semua field harus diisi"
}
```

### 401 Unauthorized
```json
{
  "success": false,
  "message": "Token tidak ditemukan. Silakan login terlebih dahulu."
}
```

### 404 Not Found
```json
{
  "success": false,
  "message": "Data tidak ditemukan"
}
```

### 500 Internal Server Error
```json
{
  "success": false,
  "message": "Terjadi kesalahan pada server"
}
```

---

## Status Codes

- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `500` - Internal Server Error

---

## Notes

1. Semua response menggunakan format JSON
2. Timestamp menggunakan format ISO 8601
3. Token JWT expired dalam 7 hari (configurable)
4. OTP expired dalam 5 menit
5. Pagination menggunakan limit & offset
