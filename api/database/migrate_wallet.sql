-- ============================================================
-- Migration: Wallet & Top Up Support
-- Jalankan di phpMyAdmin atau MySQL CLI
-- Database: gym  (sesuaikan dengan DB_NAME di .env)
-- ============================================================

USE gym;

-- 1. Tambahkan nilai 'topup_saldo' ke kolom jenis_transaksi
--    (kolom ini VARCHAR(50) bukan ENUM, jadi nilai apapun bisa masuk)
--    Verifikasi tipe kolom:
-- SHOW COLUMNS FROM transactions LIKE 'jenis_transaksi';

-- 2. Buat tabel wallets jika belum ada
CREATE TABLE IF NOT EXISTS wallets (
    id        INT AUTO_INCREMENT PRIMARY KEY,
    user_id   INT NOT NULL UNIQUE,
    saldo     DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 3. Buat tabel wallet_transactions jika belum ada
CREATE TABLE IF NOT EXISTS wallet_transactions (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    user_id     INT NOT NULL,
    jenis       ENUM('topup', 'debit', 'refund') NOT NULL DEFAULT 'topup',
    jumlah      DECIMAL(15, 2) NOT NULL,
    saldo_awal  DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    saldo_akhir DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    keterangan  VARCHAR(255) DEFAULT NULL,
    ref_id      INT DEFAULT NULL,   -- referensi ke transactions.id (opsional)
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 4. Verifikasi kolom bukti_pembayaran di transactions
--    Pastikan tipe VARCHAR(255) cukup (E-Smartlink JSON bisa panjang)
ALTER TABLE transactions
    MODIFY COLUMN bukti_pembayaran TEXT DEFAULT NULL;

-- 5. Cek hasil
SELECT 'wallets' AS tabel, COUNT(*) AS jumlah_row FROM wallets
UNION ALL
SELECT 'wallet_transactions', COUNT(*) FROM wallet_transactions;
