-- Create Database
CREATE DATABASE IF NOT EXISTS membership_gym;
USE membership_gym;

-- Users Table
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nama VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  hp VARCHAR(20) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  foto_profil VARCHAR(255) DEFAULT NULL,
  is_verified BOOLEAN DEFAULT FALSE,
  alamat VARCHAR(255) DEFAULT NULL,
  jenis_kelamin VARCHAR(20) DEFAULT NULL,
  tanggal_lahir DATE DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Membership Table
CREATE TABLE IF NOT EXISTS memberships (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  paket VARCHAR(50) NOT NULL, -- 'bulanan', 'tahunan', etc
  tanggal_mulai DATE NOT NULL,
  tanggal_berakhir DATE NOT NULL,
  status ENUM('active', 'expired', 'pending') DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Member Cards Table (for NFC)
CREATE TABLE IF NOT EXISTS member_cards (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  card_number VARCHAR(50) UNIQUE NOT NULL,
  nfc_id VARCHAR(100) UNIQUE NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Check-ins Table
CREATE TABLE IF NOT EXISTS check_ins (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  check_in_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  check_in_method ENUM('nfc', 'qr', 'manual') DEFAULT 'nfc',
  location VARCHAR(100) DEFAULT 'Main Gym',
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Transactions Table
CREATE TABLE IF NOT EXISTS transactions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  membership_id INT,
  jenis_transaksi VARCHAR(50) NOT NULL, -- 'membership', 'perpanjangan', 'upgrade'
  jumlah DECIMAL(10, 2) NOT NULL,
  metode_pembayaran VARCHAR(50) NOT NULL, -- 'transfer', 'ewallet', 'cash'
  status ENUM('pending', 'success', 'failed') DEFAULT 'pending',
  tanggal_transaksi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  bukti_pembayaran VARCHAR(255) DEFAULT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (membership_id) REFERENCES memberships(id) ON DELETE SET NULL
);

-- Promos Table
CREATE TABLE IF NOT EXISTS promos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  judul VARCHAR(100) NOT NULL,
  deskripsi TEXT,
  gambar VARCHAR(255) DEFAULT NULL,
  diskon_persen INT DEFAULT 0,
  tanggal_mulai DATE NOT NULL,
  tanggal_berakhir DATE NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- OTP Table (for verification)
CREATE TABLE IF NOT EXISTS otps (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(100) NOT NULL,
  otp_code VARCHAR(6) NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  is_used BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO users (nama, email, hp, password) VALUES
('Budi Santoso', 'budi@example.com', '08123456789', '$2a$10$XqZ9YvH.VqZ9YvH.VqZ9YuO8K7Y9YvH.VqZ9YvH.VqZ9YvH.VqZ9Y'),
('Siti Aminah', 'siti@example.com', '08234567890', '$2a$10$XqZ9YvH.VqZ9YvH.VqZ9YuO8K7Y9YvH.VqZ9YvH.VqZ9YvH.VqZ9Y');

INSERT INTO memberships (user_id, paket, tanggal_mulai, tanggal_berakhir, status) VALUES
(1, 'bulanan', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 3 DAY), 'active'),
(2, 'tahunan', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 YEAR), 'active');

INSERT INTO member_cards (user_id, card_number, nfc_id) VALUES
(1, 'GYM123456', 'NFC-GYM123456'),
(2, 'GYM789012', 'NFC-GYM789012');

INSERT INTO promos (judul, deskripsi, diskon_persen, tanggal_mulai, tanggal_berakhir) VALUES
('Promo Tahun Baru', 'Diskon 30% untuk membership tahunan', 30, '2024-01-01', '2024-01-31'),
('Promo Ramadan', 'Diskon 20% untuk semua paket', 20, '2024-03-01', '2024-04-30');

INSERT INTO check_ins (user_id, check_in_method) VALUES
(1, 'nfc'),
(1, 'nfc'),
(2, 'nfc');

INSERT INTO transactions (user_id, membership_id, jenis_transaksi, jumlah, metode_pembayaran, status) VALUES
(1, 1, 'membership', 250000, 'transfer', 'success'),
(2, 2, 'membership', 2500000, 'ewallet', 'success');
