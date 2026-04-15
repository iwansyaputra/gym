-- Script untuk update semua user existing agar punya role
-- Jalankan di phpMyAdmin

-- 1. Tambah kolom role jika belum ada
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'user' AFTER is_verified;

-- 2. Update semua user yang role-nya NULL atau kosong jadi 'user'
UPDATE users 
SET role = 'user' 
WHERE role IS NULL OR role = '';

-- 3. Verifikasi hasilnya
SELECT id, nama, email, role, is_verified 
FROM users 
ORDER BY id;

-- 4. Cek berapa user yang sudah punya role
SELECT 
    role,
    COUNT(*) as jumlah
FROM users
GROUP BY role;
