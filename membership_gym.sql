-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3307
-- Generation Time: Feb 20, 2026 at 05:39 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `membership_gym`
--

-- --------------------------------------------------------

--
-- Table structure for table `check_ins`
--

CREATE TABLE `check_ins` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `check_in_time` timestamp NOT NULL DEFAULT current_timestamp(),
  `check_in_method` enum('nfc','qr','manual') DEFAULT 'nfc',
  `location` varchar(100) DEFAULT 'Main Gym'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `memberships`
--

CREATE TABLE `memberships` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `paket` varchar(50) NOT NULL,
  `tanggal_mulai` date NOT NULL,
  `tanggal_berakhir` date NOT NULL,
  `status` enum('active','expired','pending') DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `memberships`
--

INSERT INTO `memberships` (`id`, `user_id`, `paket`, `tanggal_mulai`, `tanggal_berakhir`, `status`, `created_at`, `updated_at`) VALUES
(4, 13, 'bulanan', '2026-02-12', '2026-03-12', 'pending', '2026-02-12 05:10:38', '2026-02-12 05:10:38'),
(5, 11, 'bulanan', '2026-02-12', '2026-03-12', 'pending', '2026-02-12 05:36:57', '2026-02-12 05:36:57');

-- --------------------------------------------------------

--
-- Table structure for table `member_cards`
--

CREATE TABLE `member_cards` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `card_number` varchar(50) NOT NULL,
  `nfc_id` varchar(100) NOT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `member_cards`
--

INSERT INTO `member_cards` (`id`, `user_id`, `card_number`, `nfc_id`, `is_active`, `created_at`) VALUES
(10, 11, 'HELIOZ2512I11', 'NFC-HELIOZ2512I11', 1, '2025-12-18 09:13:28'),
(11, 13, 'HELIOZ2602I13', 'NFC-HELIOZ2602I13', 1, '2026-02-12 05:08:07');

-- --------------------------------------------------------

--
-- Table structure for table `otps`
--

CREATE TABLE `otps` (
  `id` int(11) NOT NULL,
  `email` varchar(100) NOT NULL,
  `otp_code` varchar(6) NOT NULL,
  `expires_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `is_used` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `otps`
--

INSERT INTO `otps` (`id`, `email`, `otp_code`, `expires_at`, `is_used`, `created_at`) VALUES
(1, 'iwansyaputra031204@gmail.com', '851304', '2025-12-17 07:30:39', 1, '2025-12-17 07:29:58'),
(2, 'iwansyaputra031204@gmail.com', '414670', '2025-12-17 07:35:00', 0, '2025-12-17 07:30:00'),
(3, 'iwansyaputra031204@gmail.com', '186165', '2025-12-17 07:35:00', 0, '2025-12-17 07:30:00'),
(4, 'iwansyaputra031204@gmail.com', '187070', '2025-12-17 07:35:00', 0, '2025-12-17 07:30:00'),
(5, 'iwansyaputra031204@gmail.com', '480595', '2025-12-17 07:35:01', 0, '2025-12-17 07:30:01'),
(6, 'iwansyaputra031204@gmail.com', '447456', '2025-12-17 07:35:01', 0, '2025-12-17 07:30:01'),
(7, 'iwansyaputra031204@gmail.com', '953740', '2025-12-17 07:35:02', 0, '2025-12-17 07:30:02'),
(8, 'iwansyaputra031204@gmail.com', '923558', '2025-12-17 07:35:03', 0, '2025-12-17 07:30:03'),
(9, 'iwansyaputra031204@gmail.com', '181452', '2025-12-17 07:35:05', 0, '2025-12-17 07:30:05'),
(10, 'iwansyaputra031204@gmail.com', '796885', '2025-12-17 07:35:05', 0, '2025-12-17 07:30:05'),
(11, 'iwansyaputra031204@gmail.com', '425488', '2025-12-17 07:35:05', 0, '2025-12-17 07:30:05'),
(12, 'iwansyaputra031204@gmail.com', '623051', '2025-12-17 07:35:05', 0, '2025-12-17 07:30:05'),
(13, 'iwansyaputra031204@gmail.com', '690982', '2025-12-17 07:35:06', 0, '2025-12-17 07:30:06'),
(14, 'test_api_v1@email.com', '642185', '2025-12-17 08:16:20', 0, '2025-12-17 08:11:20'),
(15, 'alyadwirahma603@gmail.com', '320989', '2025-12-17 08:14:51', 1, '2025-12-17 08:13:43'),
(16, 'alyadwirahma1902@gmail.com', '105411', '2025-12-17 09:01:24', 1, '2025-12-17 09:00:29'),
(17, 'iwansyaputra031204@gmail.com', '933916', '2025-12-18 09:01:24', 1, '2025-12-18 09:00:46'),
(18, 'iwansyaputra031204@gmail.com', '786917', '2025-12-18 09:06:47', 0, '2025-12-18 09:01:47'),
(19, 'iwansyaputra031204@gmail.com', '139141', '2025-12-18 09:07:19', 0, '2025-12-18 09:02:19'),
(20, 'alyadwirahma603@gmail.com', '987747', '2025-12-18 09:08:57', 1, '2025-12-18 09:08:38'),
(21, 'aku@gmail.com', '109219', '2025-12-18 09:11:17', 1, '2025-12-18 09:10:53'),
(22, 'iwansyaputra031204@gmail.com', '665406', '2025-12-18 09:14:03', 1, '2025-12-18 09:13:28'),
(23, 'alyadwirahma603@gmail.com', '440675', '2026-02-12 05:08:37', 1, '2026-02-12 05:08:07');

-- --------------------------------------------------------

--
-- Table structure for table `promos`
--

CREATE TABLE `promos` (
  `id` int(11) NOT NULL,
  `judul` varchar(100) NOT NULL,
  `deskripsi` text DEFAULT NULL,
  `gambar` varchar(255) DEFAULT NULL,
  `diskon_persen` int(11) DEFAULT 0,
  `tanggal_mulai` date NOT NULL,
  `tanggal_berakhir` date NOT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `promos`
--

INSERT INTO `promos` (`id`, `judul`, `deskripsi`, `gambar`, `diskon_persen`, `tanggal_mulai`, `tanggal_berakhir`, `is_active`, `created_at`) VALUES
(1, 'Promo Tahun Baru', 'Diskon 30% untuk membership tahunan', NULL, 30, '2024-01-01', '2024-01-31', 1, '2025-12-17 06:45:59'),
(2, 'Promo Ramadan', 'Diskon 20% untuk semua paket', NULL, 20, '2024-03-01', '2024-04-30', 1, '2025-12-17 06:45:59');

-- --------------------------------------------------------

--
-- Table structure for table `transactions`
--

CREATE TABLE `transactions` (
  `id` int(11) NOT NULL,
  `order_id` varchar(100) DEFAULT NULL,
  `user_id` int(11) NOT NULL,
  `membership_id` int(11) DEFAULT NULL,
  `jenis_transaksi` varchar(50) NOT NULL,
  `jumlah` decimal(10,2) NOT NULL,
  `metode_pembayaran` varchar(50) NOT NULL,
  `status` enum('pending','success','failed') DEFAULT 'pending',
  `tanggal_transaksi` timestamp NOT NULL DEFAULT current_timestamp(),
  `bukti_pembayaran` varchar(255) DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `transactions`
--

INSERT INTO `transactions` (`id`, `order_id`, `user_id`, `membership_id`, `jenis_transaksi`, `jumlah`, `metode_pembayaran`, `status`, `tanggal_transaksi`, `bukti_pembayaran`, `updated_at`) VALUES
(4, 'GYM-1770873038619-13', 13, 4, 'membership', 185000.00, 'midtrans', 'pending', '2026-02-12 05:10:38', NULL, '2026-02-12 05:10:38'),
(5, 'GYM-1770874617295-11', 11, 5, 'membership', 185000.00, 'midtrans', 'pending', '2026-02-12 05:36:57', NULL, '2026-02-12 05:36:57');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `nama` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `hp` varchar(20) NOT NULL,
  `password` varchar(255) NOT NULL,
  `is_verified` tinyint(1) DEFAULT 0,
  `role` varchar(20) DEFAULT 'user',
  `alamat` varchar(255) DEFAULT NULL,
  `jenis_kelamin` varchar(20) DEFAULT NULL,
  `tanggal_lahir` date DEFAULT NULL,
  `foto_profil` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `nama`, `email`, `hp`, `password`, `is_verified`, `role`, `alamat`, `jenis_kelamin`, `tanggal_lahir`, `foto_profil`, `created_at`, `updated_at`) VALUES
(11, 'Iwan Syaputra', 'iwansyaputra031204@gmail.com', '081995136012', '$2a$10$RRKhmavOJsqaLJofx12LMuQI8P6tBtOsp2rfmL1FJ.ItuZV292Z2.', 1, 'user', 'tegal', 'Laki-laki', '2004-12-03', NULL, '2025-12-18 09:13:27', '2025-12-18 09:14:03'),
(13, 'iwan syaputra', 'alyadwirahma603@gmail.com', '000', '$2a$10$Bwo.hiVKKLICTE/TJu6c7.mXXWfJrSnvVdQDAdQLdLN8i6hfU5lFS', 1, 'user', 'tegal', 'Perempuan', '2000-01-01', NULL, '2026-02-12 05:08:07', '2026-02-13 04:12:05'),
(14, 'Admin GymKu', 'admin@gymku.com', '081234567890', '$2a$10$5edOlDSvmfYgRuDFEF090ugXgfEkZOmm28fH1wAZjARfdg/AjritK', 1, 'admin', NULL, NULL, NULL, NULL, '2026-02-12 05:45:54', '2026-02-12 05:45:54');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `check_ins`
--
ALTER TABLE `check_ins`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `memberships`
--
ALTER TABLE `memberships`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `member_cards`
--
ALTER TABLE `member_cards`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `card_number` (`card_number`),
  ADD UNIQUE KEY `nfc_id` (`nfc_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `otps`
--
ALTER TABLE `otps`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `promos`
--
ALTER TABLE `promos`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `transactions`
--
ALTER TABLE `transactions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `order_id` (`order_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `membership_id` (`membership_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `hp` (`hp`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `check_ins`
--
ALTER TABLE `check_ins`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `memberships`
--
ALTER TABLE `memberships`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `member_cards`
--
ALTER TABLE `member_cards`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `otps`
--
ALTER TABLE `otps`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- AUTO_INCREMENT for table `promos`
--
ALTER TABLE `promos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `transactions`
--
ALTER TABLE `transactions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `check_ins`
--
ALTER TABLE `check_ins`
  ADD CONSTRAINT `check_ins_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `memberships`
--
ALTER TABLE `memberships`
  ADD CONSTRAINT `memberships_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `member_cards`
--
ALTER TABLE `member_cards`
  ADD CONSTRAINT `member_cards_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `transactions`
--
ALTER TABLE `transactions`
  ADD CONSTRAINT `transactions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `transactions_ibfk_2` FOREIGN KEY (`membership_id`) REFERENCES `memberships` (`id`) ON DELETE SET NULL;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
