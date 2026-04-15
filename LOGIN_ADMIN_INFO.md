# 🔑 LOGIN ADMIN - INFORMASI AKUN

> **Update:** 12 Februari 2026

---

## ✅ EMAIL ADMIN YANG BENAR

**EMAIL:**  
```
admin@gymku.com
```

**BUKAN** `admin@gym.com` ❌  
**YANG BENAR** `admin@gymku.com` ✅

---

## 🔐 KREDENSIAL LOGIN ADMIN

```
Email:    admin@gymku.com
Password: admin123
Role:     admin
```

---

## 📝 CARA LOGIN

### **1. Buka Halaman Login**

**Pilihan 1: Login Simple (Recommended)**
```
File: admin_web/login_simple.html
```

**Pilihan 2: Login Original**
```
File: admin_web/index.html
```

### **2. Masukkan Kredensial**

1. **Email:** `admin@gymku.com` (tanpa spasi!)
2. **Password:** `admin123`
3. Klik tombol **"Masuk"**

### **3. Jika Berhasil**

- ✅ Muncul pesan "Login berhasil!"
- ✅ Otomatis redirect ke `dashboard.html`
- ✅ Dashboard menampilkan data statistik

---

## 🐛 TROUBLESHOOTING

### **Problem: "Email atau password salah"**

**Penyebab:**
- ❌ Salah ketik email
- ❌ Menggunakan `admin@gym.com` (salah!)
- ❌ Password tidak match

**Solusi:**
1. **Copy-paste email yang benar:**
   ```
   admin@gymku.com
   ```

2. **Cek CAPSLOCK:**
   - Email harus huruf kecil semua
   - Password case-sensitive: `admin123` (bukan `Admin123`)

3. **Cek spasi:**
   - Jangan ada spasi di awal/akhir
   - Copy-paste dari sini untuk memastikan

---

### **Problem: "Akun belum diverifikasi"**

**Solusi:**

Jalankan script setup admin:

```bash
cd api
node setup_admin.js
```

Atau manual via MySQL:

```sql
UPDATE users 
SET is_verified = TRUE, role = 'admin' 
WHERE email = 'admin@gymku.com';
```

---

### **Problem: "User tidak ditemukan"**

**Solusi:**

Buat akun admin baru:

```bash
cd api
node setup_admin.js
```

Script ini akan:
- ✅ Cek apakah admin sudah ada
- ✅ Jika belum, buat akun baru
- ✅ Set role = 'admin'
- ✅ Set is_verified = TRUE
- ✅ Password = 'admin123'

---

## 🧪 TEST KONEKSI

### **1. Test Backend Running**

```
Buka browser:
http://192.168.25.62:3000/health

Harus return:
{
  "success": true,
  "status": "healthy"
}
```

### **2. Test Login API**

```
Buka browser:
admin_web/test.html

Klik "Test Login"
Harus muncul status: ✓ Sukses
```

---

## 📊 VERIFIKASI DATABASE

### **Cek Akun Admin di Database**

```sql
-- Login ke MySQL (via phpMyAdmin atau MySQL Workbench)

-- Cek akun admin
SELECT 
    id, 
    nama, 
    email, 
    role, 
    is_verified 
FROM users 
WHERE email = 'admin@gymku.com';
```

**Hasil yang diharapkan:**
```
id  | nama  | email            | role  | is_verified
----|-------|------------------|-------|-------------
1   | admin | admin@gymku.com  | admin | 1
```

**Jika hasil berbeda:**

```sql
-- Update role & verified status
UPDATE users 
SET 
    role = 'admin',
    is_verified = TRUE
WHERE email = 'admin@gymku.com';
```

---

## 🔄 RESET PASSWORD ADMIN

Jika lupa password, reset via MySQL:

```sql
-- Password baru: admin123
-- Hash bcrypt untuk 'admin123':
-- $2a$10$rM0YKkvVMXvWqx.VsKZOVeQ9.YqGhKBnVMiHpGqHWHZKzUz6Dk7im

UPDATE users 
SET password = '$2a$10$rM0YKkvVMXvWqx.VsKZOVeQ9.YqGhKBnVMiHpGqHWHZKzUz6Dk7im'
WHERE email = 'admin@gymku.com';
```

Atau jalankan:
```bash
node setup_admin.js
```

---

## 📧 EMAIL ADMIN ALTERNATIVES

Jika ingin ubah email admin ke email lain:

### **Via Database:**

```sql
UPDATE users 
SET email = 'email_baru@domain.com'
WHERE email = 'admin@gymku.com';
```

### **Via Script:**

Edit `api/setup_admin.js` baris 28:
```javascript
// Ganti email di sini
const adminEmail = 'email_baru@domain.com';
```

Lalu jalankan:
```bash
node setup_admin.js
```

---

## ✅ CHECKLIST LOGIN

Sebelum login, pastikan:

- [ ] Backend running (`npm start` di folder `api`)
- [ ] MySQL (Laragon) running
- [ ] Database `membership_gym` sudah diimport
- [ ] Email yang digunakan: `admin@gymku.com` (BUKAN `admin@gym.com`)
- [ ] Password: `admin123`
- [ ] Browser sudah di-refresh (Ctrl + Shift + R)

---

## 🎯 QUICK REFERENCE

| Item | Value |
|------|-------|
| **Email** | `admin@gymku.com` |
| **Password** | `admin123` |
| **Role** | `admin` |
| **Backend URL** | `http://192.168.25.62:3000` |
| **Login Page** | `admin_web/login_simple.html` |
| **Test Page** | `admin_web/test.html` |

---

## 📞 BANTUAN

**Jika masih error setelah mencoba semua solusi di atas:**

1. Screenshot halaman login
2. Screenshot console browser (F12)
3. Screenshot terminal backend
4. Kirim ke developer

---

**Terakhir diupdate:** 12 Februari 2026, 12:41 WIB
