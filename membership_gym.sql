-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: May 02, 2026 at 01:08 PM
-- Server version: 8.0.30
-- PHP Version: 8.1.10

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `gym`
--

-- --------------------------------------------------------

--
-- Table structure for table `check_ins`
--

CREATE TABLE `check_ins` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `check_in_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `check_in_method` enum('nfc','qr','manual') DEFAULT 'nfc',
  `location` varchar(100) DEFAULT 'Main Gym'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `check_ins`
--

INSERT INTO `check_ins` (`id`, `user_id`, `check_in_time`, `check_in_method`, `location`) VALUES
(1, 1, '2026-04-16 08:56:38', 'nfc', 'Main Gym'),
(2, 1, '2026-04-16 08:56:38', 'nfc', 'Main Gym'),
(3, 2, '2026-04-16 08:56:38', 'nfc', 'Main Gym'),
(4, 3, '2026-04-18 15:43:03', 'nfc', 'Main Gym'),
(5, 3, '2026-04-19 09:59:18', 'nfc', 'Main Gym'),
(6, 3, '2026-04-19 09:59:22', 'nfc', 'Main Gym'),
(7, 3, '2026-04-19 10:25:49', 'nfc', 'Main Gym'),
(8, 3, '2026-04-19 10:25:53', 'nfc', 'Main Gym'),
(9, 3, '2026-04-19 10:26:01', 'nfc', 'Main Gym'),
(10, 3, '2026-04-19 10:26:04', 'nfc', 'Main Gym'),
(11, 3, '2026-04-19 10:26:52', 'nfc', 'Main Gym'),
(12, 3, '2026-04-19 10:26:55', 'nfc', 'Main Gym'),
(13, 3, '2026-04-19 10:28:31', 'nfc', 'Main Gym'),
(14, 3, '2026-04-19 10:28:34', 'nfc', 'Main Gym'),
(15, 4, '2026-04-19 10:30:24', 'nfc', 'Main Gym'),
(16, 4, '2026-04-19 10:30:31', 'nfc', 'Main Gym'),
(17, 4, '2026-04-19 10:31:03', 'nfc', 'Main Gym'),
(18, 4, '2026-04-19 10:31:06', 'nfc', 'Main Gym'),
(19, 4, '2026-04-19 10:32:21', 'nfc', 'Main Gym'),
(20, 4, '2026-04-19 10:32:23', 'nfc', 'Main Gym'),
(21, 4, '2026-04-19 10:33:07', 'nfc', 'Main Gym'),
(22, 4, '2026-04-19 10:33:12', 'nfc', 'Main Gym'),
(23, 3, '2026-04-19 10:33:30', 'nfc', 'Main Gym'),
(24, 3, '2026-04-19 10:33:34', 'nfc', 'Main Gym'),
(25, 3, '2026-04-19 10:33:50', 'nfc', 'Main Gym'),
(26, 3, '2026-04-19 10:33:56', 'nfc', 'Main Gym'),
(27, 3, '2026-04-19 12:35:59', 'nfc', 'Main Gym'),
(28, 3, '2026-04-19 12:36:04', 'nfc', 'Main Gym'),
(29, 3, '2026-04-19 12:36:15', 'nfc', 'Main Gym'),
(30, 3, '2026-04-19 12:36:19', 'nfc', 'Main Gym'),
(31, 3, '2026-04-19 12:36:25', 'nfc', 'Main Gym'),
(32, 3, '2026-04-19 12:41:47', 'nfc', 'Main Gym'),
(33, 3, '2026-04-19 12:41:49', 'nfc', 'Main Gym'),
(34, 3, '2026-04-19 12:41:49', 'nfc', 'Main Gym'),
(35, 3, '2026-04-19 12:41:51', 'nfc', 'Main Gym'),
(36, 3, '2026-04-19 12:41:53', 'nfc', 'Main Gym'),
(37, 3, '2026-04-19 12:41:54', 'nfc', 'Main Gym'),
(38, 3, '2026-04-19 12:41:55', 'nfc', 'Main Gym'),
(39, 3, '2026-04-19 12:41:56', 'nfc', 'Main Gym'),
(40, 3, '2026-04-19 12:41:57', 'nfc', 'Main Gym'),
(41, 3, '2026-04-19 12:41:57', 'nfc', 'Main Gym'),
(42, 3, '2026-04-19 12:41:59', 'nfc', 'Main Gym'),
(43, 3, '2026-04-19 15:05:27', 'nfc', 'Main Gym'),
(44, 3, '2026-04-19 15:05:29', 'nfc', 'Main Gym'),
(45, 3, '2026-04-19 15:05:33', 'nfc', 'Main Gym'),
(46, 3, '2026-04-24 16:10:21', 'nfc', 'Main Gym'),
(47, 4, '2026-04-24 16:27:35', 'nfc', 'Main Gym'),
(48, 3, '2026-04-24 16:27:57', 'nfc', 'Main Gym'),
(49, 3, '2026-04-24 16:31:17', 'nfc', 'Main Gym'),
(50, 7, '2026-04-24 16:34:29', 'nfc', 'Main Gym'),
(51, 3, '2026-04-24 16:34:42', 'nfc', 'Main Gym'),
(52, 3, '2026-04-28 04:26:44', 'nfc', 'Main Gym'),
(53, 3, '2026-04-28 04:26:53', 'nfc', 'Main Gym'),
(54, 3, '2026-04-28 04:26:59', 'nfc', 'Main Gym'),
(55, 3, '2026-04-28 04:27:06', 'nfc', 'Main Gym'),
(56, 3, '2026-04-28 04:27:10', 'nfc', 'Main Gym'),
(57, 4, '2026-04-28 04:28:59', 'nfc', 'Main Gym'),
(58, 4, '2026-04-28 04:29:02', 'nfc', 'Main Gym'),
(59, 4, '2026-04-28 04:30:33', 'nfc', 'Main Gym'),
(60, 4, '2026-04-28 04:30:36', 'nfc', 'Main Gym'),
(61, 4, '2026-04-28 04:30:54', 'nfc', 'Main Gym'),
(62, 4, '2026-04-28 04:31:10', 'nfc', 'Main Gym'),
(63, 4, '2026-04-28 04:31:14', 'nfc', 'Main Gym'),
(64, 4, '2026-04-28 04:31:25', 'nfc', 'Main Gym'),
(65, 4, '2026-04-28 04:31:31', 'nfc', 'Main Gym'),
(66, 4, '2026-04-28 04:37:42', 'nfc', 'Main Gym'),
(67, 4, '2026-04-28 04:37:42', 'nfc', 'Main Gym'),
(68, 4, '2026-04-28 04:39:08', 'nfc', 'Main Gym'),
(69, 4, '2026-04-28 04:39:08', 'nfc', 'Main Gym'),
(70, 4, '2026-04-28 04:39:35', 'nfc', 'Main Gym'),
(71, 4, '2026-04-28 04:39:35', 'nfc', 'Main Gym'),
(72, 4, '2026-04-28 04:40:04', 'nfc', 'Main Gym'),
(73, 4, '2026-04-28 04:40:04', 'nfc', 'Main Gym'),
(74, 3, '2026-04-28 09:02:27', 'nfc', 'Main Gym'),
(75, 3, '2026-05-01 07:20:42', 'nfc', 'Main Gym'),
(76, 3, '2026-05-01 07:21:46', 'nfc', 'Main Gym'),
(77, 3, '2026-05-01 07:27:22', 'nfc', 'Main Gym'),
(78, 3, '2026-05-01 07:29:06', 'nfc', 'Main Gym'),
(79, 3, '2026-05-01 08:33:04', 'nfc', 'Main Gym'),
(80, 11, '2026-05-01 08:43:00', 'nfc', 'Main Gym'),
(81, 11, '2026-05-01 08:44:17', 'nfc', 'Main Gym'),
(82, 11, '2026-05-01 08:47:11', 'nfc', 'Main Gym'),
(83, 11, '2026-05-01 08:48:21', 'nfc', 'Main Gym'),
(84, 3, '2026-05-01 15:16:34', 'nfc', 'Main Gym'),
(85, 11, '2026-05-01 15:17:24', 'nfc', 'Main Gym'),
(86, 3, '2026-05-02 04:22:42', 'nfc', 'Main Gym'),
(87, 3, '2026-05-02 04:25:11', 'nfc', 'Main Gym'),
(88, 3, '2026-05-02 04:26:14', 'nfc', 'Main Gym'),
(89, 3, '2026-05-02 04:27:41', 'nfc', 'Main Gym'),
(90, 3, '2026-05-02 04:31:42', 'nfc', 'Main Gym'),
(91, 3, '2026-05-02 07:01:20', 'nfc', 'Main Gym');

-- --------------------------------------------------------

--
-- Table structure for table `memberships`
--

CREATE TABLE `memberships` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `paket` varchar(50) NOT NULL,
  `tanggal_mulai` date NOT NULL,
  `tanggal_berakhir` date NOT NULL,
  `status` enum('active','expired','pending') DEFAULT 'pending',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `memberships`
--

INSERT INTO `memberships` (`id`, `user_id`, `paket`, `tanggal_mulai`, `tanggal_berakhir`, `status`, `created_at`, `updated_at`) VALUES
(1, 1, 'bulanan', '2026-04-16', '2026-04-19', 'active', '2026-04-16 08:56:38', '2026-04-16 08:56:38'),
(2, 2, 'tahunan', '2026-04-16', '2027-04-16', 'active', '2026-04-16 08:56:38', '2026-04-16 08:56:38'),
(4, 3, 'bulanan', '2026-04-16', '2026-05-16', 'expired', '2026-04-16 09:03:26', '2026-04-16 09:32:06'),
(5, 4, 'bulanan', '2026-04-16', '2026-05-16', 'active', '2026-04-16 09:13:03', '2026-04-16 09:14:06'),
(15, 3, 'bulanan', '2026-04-16', '2026-05-16', 'expired', '2026-04-16 11:28:20', '2026-04-18 14:43:03'),
(18, 3, 'bulanan', '2026-04-16', '2026-05-16', 'expired', '2026-04-16 11:33:49', '2026-04-18 14:43:03'),
(19, 3, 'bulanan', '2026-04-16', '2026-05-16', 'expired', '2026-04-16 11:34:05', '2026-04-18 14:43:03'),
(62, 3, 'bulanan', '2026-05-01', '2026-05-31', 'active', '2026-05-01 15:40:23', '2026-05-01 15:41:34'),
(63, 3, 'bulanan', '2026-05-31', '2026-06-30', 'active', '2026-05-02 09:28:29', '2026-05-02 09:29:24'),
(64, 3, 'bulanan', '2026-06-30', '2026-07-30', 'active', '2026-05-02 09:38:37', '2026-05-02 09:39:16'),
(65, 3, 'bulanan', '2026-07-30', '2026-08-29', 'active', '2026-05-02 09:46:14', '2026-05-02 09:46:50'),
(66, 3, 'bulanan', '2026-08-29', '2026-09-28', 'active', '2026-05-02 10:00:27', '2026-05-02 10:00:27'),
(67, 3, 'bulanan', '2026-09-28', '2026-10-28', 'active', '2026-05-02 11:43:15', '2026-05-02 12:06:05');

-- --------------------------------------------------------

--
-- Table structure for table `member_cards`
--

CREATE TABLE `member_cards` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `card_number` char(10) NOT NULL,
  `nfc_id` char(10) NOT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `member_cards`
--

INSERT INTO `member_cards` (`id`, `user_id`, `card_number`, `nfc_id`, `is_active`, `created_at`) VALUES
(1, 1, '0001847291', '0001847291', 1, '2026-04-16 08:56:38'),
(2, 2, '0002563810', '0002563810', 1, '2026-04-16 08:56:38'),
(3, 3, '0435451138', '0435451138', 1, '2026-04-16 09:01:26'),
(4, 4, '0416449029', '0416449029', 1, '2026-04-16 09:12:28'),
(5, 7, '0007663879', '0007663879', 1, '2026-04-20 11:40:36'),
(6, 9, '0009894330', '0009894330', 1, '2026-04-24 16:53:45'),
(7, 10, '0010757012', '0010757012', 0, '2026-05-01 08:35:31'),
(8, 11, '0011533598', '0011533598', 1, '2026-05-01 08:37:39');

-- --------------------------------------------------------

--
-- Table structure for table `otps`
--

CREATE TABLE `otps` (
  `id` int NOT NULL,
  `email` varchar(100) NOT NULL,
  `otp_code` varchar(6) NOT NULL,
  `expires_at` timestamp NOT NULL,
  `is_used` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `otps`
--

INSERT INTO `otps` (`id`, `email`, `otp_code`, `expires_at`, `is_used`, `created_at`) VALUES
(1, 'iwansyaputra031204@gmail.com', '788289', '2026-04-16 09:06:26', 1, '2026-04-16 09:01:26'),
(2, 'alyadwirahma603@gmail.com', '587941', '2026-04-16 09:17:28', 1, '2026-04-16 09:12:28'),
(3, 'iwan@gmail.com', '733316', '2026-04-20 11:45:37', 0, '2026-04-20 11:40:37'),
(4, 'iwan@gmail.com', '186202', '2026-04-20 11:45:38', 0, '2026-04-20 11:40:38'),
(5, 'iwan@gmail.com', '101108', '2026-04-20 11:45:38', 0, '2026-04-20 11:40:38'),
(6, 'iwan@gmail.com', '831466', '2026-04-20 11:45:41', 0, '2026-04-20 11:40:41'),
(7, 'iwan@gmail.com', '917897', '2026-04-20 11:45:42', 0, '2026-04-20 11:40:42'),
(8, 'iwan@gmail.com', '756782', '2026-04-20 11:45:45', 0, '2026-04-20 11:40:45'),
(9, 'iwan@gmail.com', '391259', '2026-04-20 11:45:50', 0, '2026-04-20 11:40:50'),
(10, 'iwan@gmail.com', '811078', '2026-04-20 11:45:53', 0, '2026-04-20 11:40:53'),
(11, 'iwan@gmail.com', '220943', '2026-04-24 15:27:20', 1, '2026-04-24 15:22:20'),
(12, 'tugasnaela@gmail.com', '826195', '2026-04-24 16:58:45', 1, '2026-04-24 16:53:45'),
(13, 'faiz@gmail.com', '993582', '2026-05-01 08:40:31', 0, '2026-05-01 08:35:31'),
(14, 'faiz@gmail.com', '751357', '2026-05-01 08:41:04', 0, '2026-05-01 08:36:04'),
(15, 'fais@gmail.com', '578535', '2026-05-01 08:42:39', 1, '2026-05-01 08:37:39');

-- --------------------------------------------------------

--
-- Table structure for table `promos`
--

CREATE TABLE `promos` (
  `id` int NOT NULL,
  `judul` varchar(100) NOT NULL,
  `deskripsi` text,
  `gambar` varchar(255) DEFAULT NULL,
  `diskon_persen` int DEFAULT '0',
  `tanggal_mulai` date NOT NULL,
  `tanggal_berakhir` date NOT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `promos`
--

INSERT INTO `promos` (`id`, `judul`, `deskripsi`, `gambar`, `diskon_persen`, `tanggal_mulai`, `tanggal_berakhir`, `is_active`, `created_at`) VALUES
(4, 'Promo Awal Mei', '', NULL, 10, '2026-05-02', '2026-06-01', 1, '2026-05-02 09:11:05');

-- --------------------------------------------------------

--
-- Table structure for table `transactions`
--

CREATE TABLE `transactions` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `membership_id` int DEFAULT NULL,
  `order_id` varchar(100) DEFAULT NULL,
  `jenis_transaksi` varchar(50) NOT NULL,
  `jumlah` decimal(10,2) NOT NULL,
  `metode_pembayaran` varchar(50) NOT NULL,
  `status` enum('pending','success','failed') DEFAULT 'pending',
  `tanggal_transaksi` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `bukti_pembayaran` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `transactions`
--

INSERT INTO `transactions` (`id`, `user_id`, `membership_id`, `order_id`, `jenis_transaksi`, `jumlah`, `metode_pembayaran`, `status`, `tanggal_transaksi`, `bukti_pembayaran`) VALUES
(1, 1, 1, NULL, 'membership', '250000.00', 'transfer', 'success', '2026-04-16 08:56:38', NULL),
(2, 2, 2, NULL, 'membership', '2500000.00', 'ewallet', 'success', '2026-04-16 08:56:38', NULL),
(4, 3, 4, 'GYM-1776330206853-3', 'membership', '250000.00', 'esmartlink', 'success', '2026-04-16 09:03:26', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"46064a12-297a-4c10-8886-3a04ffd15577\"}'),
(5, 4, 5, 'GYM-1776330783297-4', 'membership', '250000.00', 'esmartlink', 'success', '2026-04-16 09:13:03', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"89f17ed6-db3e-4529-a113-d48a289882e0\"}'),
(15, 3, 15, 'GYM-1776338900900-3', 'membership', '175000.00', 'esmartlink', 'failed', '2026-04-16 11:28:20', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"c4e5bd2e-eb5c-4ef0-a5d2-075d86c82f4f\"}'),
(18, 3, 18, 'GYM-1776339229160-3', 'membership', '175000.00', 'esmartlink', 'failed', '2026-04-16 11:33:49', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"12f08fe8-50d3-4000-a975-13a5203b1ee8\"}'),
(19, 3, 19, 'GYM-1776339245416-3', 'membership', '175000.00', 'esmartlink', 'failed', '2026-04-16 11:34:05', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"099f5a2b-0b95-4750-b1e3-17005ebfb6d7\"}'),
(20, 3, NULL, 'GYM-1776339509226-3', 'membership', '175000.00', 'esmartlink', 'failed', '2026-04-16 11:38:29', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"d6a7d0bf-031f-473c-be09-24ac167add0c\"}'),
(22, 3, NULL, 'GYM-1776339813801-3', 'membership', '175000.00', 'esmartlink', 'failed', '2026-04-16 11:43:33', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"3e7a7f07-3f0b-411f-83c8-4468fe021ea6\"}'),
(23, 3, NULL, 'GYM-1776339846273-3', 'membership', '175000.00', 'esmartlink', 'failed', '2026-04-16 11:44:06', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"4186a198-e20f-49e2-8c3a-515d6c90d7e6\"}'),
(24, 3, NULL, 'GYM-1776340188033-3', 'membership', '175000.00', 'esmartlink', 'failed', '2026-04-16 11:49:48', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"b22f140e-36a5-4aa5-9558-203e9f3b0a0c\"}'),
(28, 3, NULL, 'GYM-1776340904392-3', 'membership', '175000.00', 'esmartlink', 'pending', '2026-04-16 12:01:44', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"SIMULATION-1776340906658\"}'),
(36, 3, NULL, 'GYM-1776345828558-3', 'membership', '250000.00', 'esmartlink', 'success', '2026-04-16 13:23:48', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"95f5105a-8f13-4fea-869e-87af6f9d108d\"}'),
(37, 3, NULL, 'GYM-1776347497915-3', 'membership', '175000.00', 'esmartlink', 'failed', '2026-04-16 13:51:37', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"0a69b151-740a-44a4-babc-a7f91146024e\"}'),
(38, 3, NULL, 'GYM-1776347730191-3', 'membership', '175000.00', 'esmartlink', 'success', '2026-04-16 13:55:30', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"f7b2d310-8967-4bc6-9458-62947ff44017\"}'),
(39, 3, NULL, 'GYM-1776349187713-3', 'membership', '175000.00', 'esmartlink', 'success', '2026-04-16 14:19:47', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"ef4cd6ab-fa58-4316-b5b2-aeed680df298\"}'),
(40, 3, NULL, 'GYM-1776349497878-3', 'membership', '175000.00', 'esmartlink', 'success', '2026-04-16 14:24:57', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"8878790e-8ff1-418a-a0b2-ba46cec3470e\"}'),
(46, 3, NULL, 'GYM-1776523403394-3', 'membership', '175000.00', 'esmartlink', 'success', '2026-04-18 14:43:23', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"4a5e408c-fc73-4b32-836b-45a1f70a389b\"}'),
(47, 3, NULL, 'GYM-1776526421722-3', 'membership', '175000.00', 'esmartlink', 'success', '2026-04-18 15:33:41', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"5ce73c8b-fecd-47cc-985f-55c5200f291f\"}'),
(48, 3, NULL, 'GYM-1776527357311-3', 'membership', '175000.00', 'esmartlink', 'success', '2026-04-18 15:49:17', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"126ddffd-484b-436c-8b9f-8e2be3bc47a9\"}'),
(49, 3, NULL, 'GYM-1776527870131-3', 'membership', '180000.00', 'esmartlink', 'success', '2026-04-18 15:57:50', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"692c5d95-b4ef-4efa-91aa-2c8a95983ac5\"}'),
(52, 3, NULL, 'GYM-1776683473338-3', 'membership', '180000.00', 'esmartlink', 'failed', '2026-04-20 11:11:13', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"b79423e9-1d22-4cc2-8312-da8a611fd50d\"}'),
(53, 7, NULL, 'GYM-1777048348569-7', 'membership', '180000.00', 'esmartlink', 'success', '2026-04-24 16:32:28', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"ff634d47-b9db-4301-8f91-2db9ff0acf71\"}'),
(54, 4, NULL, 'GYM-1777351614094-4', 'membership', '180000.00', 'esmartlink', 'pending', '2026-04-28 04:46:54', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"bb181fce-8b6d-4243-811d-375148c74151\"}'),
(56, 3, NULL, 'TOPUP-1777528301090-3', 'topup_saldo', '100000.00', 'esmartlink', 'failed', '2026-04-30 05:51:41', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"5f49baaa-a275-449d-8ffa-d301e11f5b2b\"}'),
(57, 3, NULL, 'TOPUP-1777528313201-3', 'topup_saldo', '100000.00', 'esmartlink', 'success', '2026-04-30 05:51:53', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"8a6a9aad-7971-43f8-b6c7-f9ded0e189ed\"}'),
(58, 3, NULL, 'TOPUP-1777528823006-3', 'topup_saldo', '100000.00', 'esmartlink', 'success', '2026-04-30 06:00:23', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"210d3334-2412-4849-b75b-c82343a5fac5\",\"confirmed_by\":\"client_polling\",\"confirmed_at\":\"2026-04-30T06:00:36.047Z\"}'),
(59, 3, NULL, 'TOPUP-1777529904052-3', 'topup_saldo', '50000.00', 'esmartlink', 'success', '2026-04-30 06:18:24', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"87a49c39-0706-450b-bb11-32936a2d9a13\",\"confirmed_by\":\"client_polling\",\"confirmed_at\":\"2026-04-30T06:18:39.805Z\"}'),
(60, 3, NULL, 'TOPUP-1777533231033-3', 'topup_saldo', '500000.00', 'esmartlink', 'success', '2026-04-30 07:13:51', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"278c715e-a09b-4b18-ac51-b91f82248dc6\",\"confirmed_by\":\"client_polling\",\"confirmed_at\":\"2026-04-30T07:13:57.255Z\"}'),
(61, 3, NULL, 'GYM-1777533353750-3', 'membership', '180000.00', 'esmartlink', 'failed', '2026-04-30 07:15:53', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"bd829871-bec6-4f81-88a9-2a570f5683a3\"}'),
(62, 3, NULL, 'WALLET-1777533916505-3', 'membership', '185000.00', 'wallet', 'success', '2026-04-30 07:25:16', NULL),
(63, 3, NULL, 'TOPUP-1777619679102-3', 'topup_saldo', '50000.00', 'esmartlink', 'failed', '2026-05-01 07:14:39', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"98600f84-ec67-4cf3-9dff-f29596d7d141\"}'),
(64, 3, NULL, 'TOPUP-1777619725475-3', 'topup_saldo', '50000.00', 'esmartlink', 'success', '2026-05-01 07:15:25', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"4eaa3e86-9208-449c-9827-4dc1dd498176\",\"confirmed_by\":\"client_polling\",\"confirmed_at\":\"2026-05-01T07:15:58.305Z\"}'),
(65, 3, NULL, 'TOPUP-1777619806924-3', 'topup_saldo', '50000.00', 'esmartlink', 'success', '2026-05-01 07:16:46', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"8981638e-943e-4c29-8b63-c2e4da60212b\"}'),
(66, 3, NULL, 'WALLET-1777619865418-3', 'membership', '185000.00', 'wallet', 'success', '2026-05-01 07:17:45', NULL),
(67, 3, NULL, 'TOPUP-1777619879952-3', 'topup_saldo', '50000.00', 'esmartlink', 'success', '2026-05-01 07:17:59', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"3b87c599-2eee-4f27-9501-e1bc631c73f4\"}'),
(68, 3, NULL, 'TOPUP-1777620792759-3', 'topup_saldo', '50000.00', 'esmartlink', 'success', '2026-05-01 07:33:12', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"53bf10b5-3c75-4d75-b8fd-008dc92b95b9\",\"confirmed_by\":\"client_polling\",\"confirmed_at\":\"2026-05-01T07:33:19.228Z\"}'),
(69, 3, NULL, 'TOPUP-1777624273931-3', 'topup_saldo', '50000.00', 'esmartlink', 'pending', '2026-05-01 08:31:13', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"ceb78704-01b5-411f-b2a0-4b4ba7a8b9ee\"}'),
(70, 3, NULL, 'TOPUP-1777624334622-3', 'topup_saldo', '50000.00', 'esmartlink', 'success', '2026-05-01 08:32:14', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"d0e49eaf-c16b-4646-8c03-031a297f29b5\",\"confirmed_by\":\"client_polling\",\"confirmed_at\":\"2026-05-01T08:32:22.660Z\"}'),
(71, 3, NULL, 'TOPUP-1777624335123-3', 'topup_saldo', '50000.00', 'esmartlink', 'success', '2026-05-01 08:32:15', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"053d0130-24e2-4c09-a3a9-706d5ea7698f\"}'),
(72, 3, NULL, 'WALLET-1777624460059-3', 'membership', '185000.00', 'wallet', 'success', '2026-05-01 08:34:20', NULL),
(73, 11, NULL, 'TOPUP-1777624763989-11', 'topup_saldo', '500000.00', 'esmartlink', 'success', '2026-05-01 08:39:23', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"5fd75569-efdb-40ec-9ffb-22f5feaec065\",\"confirmed_by\":\"client_polling\",\"confirmed_at\":\"2026-05-01T08:39:29.827Z\"}'),
(74, 11, NULL, 'TOPUP-1777624827560-11', 'topup_saldo', '200000.00', 'esmartlink', 'success', '2026-05-01 08:40:27', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"19ac90d9-220e-46fe-8cb9-62832dd0b5fb\",\"confirmed_by\":\"client_polling\",\"confirmed_at\":\"2026-05-01T08:40:35.621Z\"}'),
(75, 11, NULL, 'TOPUP-1777624845302-11', 'topup_saldo', '1000000.00', 'esmartlink', 'success', '2026-05-01 08:40:45', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"d2d00305-c650-46e2-bfc7-fbc85e042bfe\",\"confirmed_by\":\"client_polling\",\"confirmed_at\":\"2026-05-01T08:40:51.255Z\"}'),
(76, 11, NULL, 'TOPUP-1777624860512-11', 'topup_saldo', '3000000.00', 'esmartlink', 'success', '2026-05-01 08:41:00', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"5ec6d7ef-6c77-404a-9f9f-b0682306460f\",\"confirmed_by\":\"client_polling\",\"confirmed_at\":\"2026-05-01T08:41:10.730Z\"}'),
(77, 11, NULL, 'WALLET-1777624882084-11', 'membership', '2500000.00', 'wallet', 'success', '2026-05-01 08:41:22', NULL),
(78, 3, NULL, 'WALLET-1777649150475-3', 'membership', '185000.00', 'wallet', 'success', '2026-05-01 15:25:50', NULL),
(79, 3, 62, 'GYM-1777650023944-3', 'membership', '185000.00', 'esmartlink', 'success', '2026-05-01 15:40:23', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"8dfe7dc4-056e-41d2-93d2-28509ecbd990\"}'),
(80, 3, NULL, 'TOPUP-1777713022645-3', 'topup_saldo', '100000.00', 'esmartlink', 'success', '2026-05-02 09:10:22', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"e4e0df06-fc4a-40a1-8fd3-cb96ff34ac4c\",\"confirmed_by\":\"client_polling\",\"confirmed_at\":\"2026-05-02T09:10:29.792Z\"}'),
(81, 3, 63, 'GYM-1777714109263-3', 'membership', '166500.00', 'esmartlink', 'success', '2026-05-02 09:28:29', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"5faef6ff-dff2-4cff-8846-4d4183ce8ff7\"}'),
(82, 3, 64, 'GYM-1777714717846-3', 'membership', '166500.00', 'esmartlink', 'success', '2026-05-02 09:38:37', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"b296cd3d-60d9-41aa-ba1a-bc0d2de8b1e1\"}'),
(83, 3, 65, 'GYM-1777715174551-3', 'membership', '166500.00', 'esmartlink', 'success', '2026-05-02 09:46:14', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"ac319e82-c1eb-4fda-945a-eb458e8a55ed\"}'),
(84, 3, NULL, 'TOPUP-1777716013095-3', 'topup_saldo', '50000.00', 'esmartlink', 'success', '2026-05-02 10:00:13', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"8d3a996e-b403-45a6-9566-37358ae1f847\",\"confirmed_by\":\"client_polling\",\"confirmed_at\":\"2026-05-02T10:00:19.508Z\"}'),
(85, 3, 66, 'WALLET-1777716027380-3', 'membership', '166500.00', 'wallet', 'success', '2026-05-02 10:00:27', NULL),
(86, 3, 67, 'GYM-1777722195767-3', 'membership', '166500.00', 'esmartlink', 'success', '2026-05-02 11:43:15', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"5eb6cbc8-6e03-4f12-b61d-d7d2f4bedc62\"}'),
(87, 3, NULL, 'TOPUP-1777723576771-3', 'topup_saldo', '50000.00', 'esmartlink', 'success', '2026-05-02 12:06:16', '{\"gateway\":\"esmartlink\",\"transaction_id\":\"b0675e68-7b8b-4148-a72d-968fb5401421\"}');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int NOT NULL,
  `nama` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `hp` varchar(20) NOT NULL,
  `password` varchar(255) NOT NULL,
  `foto_profil` varchar(255) DEFAULT NULL,
  `is_verified` tinyint(1) DEFAULT '0',
  `role` varchar(20) DEFAULT 'user',
  `alamat` varchar(255) DEFAULT NULL,
  `jenis_kelamin` varchar(20) DEFAULT NULL,
  `tanggal_lahir` date DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `nama`, `email`, `hp`, `password`, `foto_profil`, `is_verified`, `role`, `alamat`, `jenis_kelamin`, `tanggal_lahir`, `created_at`, `updated_at`) VALUES
(1, 'Budi Santoso', 'budi@example.com', '08123456789', '$2a$10$XqZ9YvH.VqZ9YvH.VqZ9YuO8K7Y9YvH.VqZ9YvH.VqZ9YvH.VqZ9Y', NULL, 0, 'user', NULL, NULL, NULL, '2026-04-16 08:56:37', '2026-04-16 08:56:37'),
(2, 'Siti Aminah', 'siti@example.com', '08234567890', '$2a$10$XqZ9YvH.VqZ9YvH.VqZ9YuO8K7Y9YvH.VqZ9YvH.VqZ9YvH.VqZ9Y', NULL, 0, 'user', NULL, NULL, NULL, '2026-04-16 08:56:37', '2026-04-16 08:56:37'),
(3, 'Iwan Syaputra', 'iwansyaputra031204@gmail.com', '081995136012', '$2a$10$I0NiZt63/yIgykXB1R1Vau54VRWTt23JQZWeiJezt0dET5GHTTHN6', NULL, 1, 'user', 'tegal', 'Laki-laki', '1999-12-31', '2026-04-16 09:01:26', '2026-04-18 16:11:30'),
(4, 'Alya', 'alyadwirahma603@gmail.com', '0852816304685', '$2a$10$LOUAyge6x3V2ko/J.AcpCufquNNQlzSGo5mqX9RN1SsbRCAzKIaJK', NULL, 1, 'user', 'tegal', 'Perempuan', '2000-01-01', '2026-04-16 09:12:28', '2026-04-16 09:12:52'),
(6, 'Admin Gym', 'admin@gym.com', '08999999999', '$2a$10$QI9EXeuPurnZlrWOaVu1yOxhwH1iKInqUkacZaZYvT.LSczNSOeAW', NULL, 1, 'admin', NULL, NULL, NULL, '2026-04-18 14:58:29', '2026-04-18 14:58:29'),
(7, 'iw', 'iwan@gmail.com', '0888885555', '$2a$10$LGmeoQKqrBdrBwZfwD/5beDZUtBC5Ozm4ZHIT/ngvLYyvyK5PsiQC', NULL, 1, 'user', 'tegal', 'Laki-laki', '2000-01-01', '2026-04-20 11:40:36', '2026-04-24 15:23:40'),
(9, 'ell', 'tugasnaela@gmail.com', '0999886666353', '$2a$10$eFn0z3zNFj/N.DlNgEn3j.UqsfeWaOATw8522lOh7YRezYJ/2mqDK', NULL, 1, 'user', 'tegal', 'Perempuan', '2000-01-01', '2026-04-24 16:53:45', '2026-04-24 16:54:31'),
(10, 'Faiz', 'faiz@gmail.com', '081234567890', '$2a$10$VvytXK7cY/bmpZ9z7SqhK./1zjPSQalRyqsXq36MZjTOfRrmsMQGC', NULL, 0, 'user', 'Tegal', 'Laki-laki', '2000-01-01', '2026-05-01 08:35:31', '2026-05-01 08:36:04'),
(11, 'faiz', 'fais@gmail.com', '0987778888', '$2a$10$TWvbE/Odl0LbH9ogeiaSruOuox1V8CscwiWS9Eg/00oZjr8OXo5KS', NULL, 1, 'user', 'tegal', 'Laki-laki', '2000-01-01', '2026-05-01 08:37:39', '2026-05-01 08:38:13');

-- --------------------------------------------------------

--
-- Table structure for table `wallets`
--

CREATE TABLE `wallets` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `saldo` decimal(15,2) NOT NULL DEFAULT '0.00',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `wallets`
--

INSERT INTO `wallets` (`id`, `user_id`, `saldo`, `created_at`, `updated_at`) VALUES
(1, 3, '78500.00', '2026-04-30 06:00:36', '2026-05-02 10:04:20'),
(68, 11, '2200000.00', '2026-05-01 08:38:14', '2026-05-01 08:41:22');

-- --------------------------------------------------------

--
-- Table structure for table `wallet_transactions`
--

CREATE TABLE `wallet_transactions` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `jenis` enum('topup','debit','refund') COLLATE utf8mb4_general_ci NOT NULL,
  `jumlah` decimal(15,2) NOT NULL,
  `saldo_awal` decimal(15,2) NOT NULL,
  `saldo_akhir` decimal(15,2) NOT NULL,
  `keterangan` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `ref_id` int DEFAULT NULL COMMENT 'transaction_id jika debit untuk membership',
  `created_by` int DEFAULT NULL COMMENT 'admin_id jika topup oleh admin',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `wallet_transactions`
--

INSERT INTO `wallet_transactions` (`id`, `user_id`, `jenis`, `jumlah`, `saldo_awal`, `saldo_akhir`, `keterangan`, `ref_id`, `created_by`, `created_at`) VALUES
(1, 3, 'topup', '100000.00', '0.00', '100000.00', 'Top up 100.000 via E-Smartlink (TOPUP-1777528823006-3)', NULL, NULL, '2026-04-30 06:00:36'),
(2, 3, 'topup', '50000.00', '100000.00', '150000.00', 'Top up 50.000 via E-Smartlink (TOPUP-1777529904052-3)', NULL, NULL, '2026-04-30 06:18:39'),
(3, 3, 'topup', '500000.00', '150000.00', '650000.00', 'Top up 500.000 via E-Smartlink (TOPUP-1777533231033-3)', NULL, NULL, '2026-04-30 07:13:57'),
(4, 3, 'debit', '185000.00', '650000.00', '465000.00', 'Perpanjang membership Paket Bulanan (WALLET-1777533916505-3)', NULL, NULL, '2026-04-30 07:25:16'),
(5, 3, 'topup', '50000.00', '465000.00', '515000.00', 'Top up 50.000 via E-Smartlink (TOPUP-1777619725475-3)', NULL, NULL, '2026-05-01 07:15:58'),
(6, 3, 'debit', '185000.00', '515000.00', '330000.00', 'Perpanjang membership Paket Bulanan (WALLET-1777619865418-3)', NULL, NULL, '2026-05-01 07:17:45'),
(7, 3, 'topup', '50000.00', '330000.00', '380000.00', 'Top up 50.000 via E-Smartlink (TOPUP-1777620792759-3)', NULL, NULL, '2026-05-01 07:33:19'),
(8, 3, 'topup', '50000.00', '380000.00', '430000.00', 'Top up 50.000 via E-Smartlink (TOPUP-1777624334622-3)', NULL, NULL, '2026-05-01 08:32:22'),
(9, 3, 'debit', '185000.00', '430000.00', '245000.00', 'Perpanjang membership Paket Bulanan (WALLET-1777624460059-3)', NULL, NULL, '2026-05-01 08:34:20'),
(10, 11, 'topup', '500000.00', '0.00', '500000.00', 'Top up 500.000 via E-Smartlink (TOPUP-1777624763989-11)', NULL, NULL, '2026-05-01 08:39:29'),
(11, 11, 'topup', '200000.00', '500000.00', '700000.00', 'Top up 200.000 via E-Smartlink (TOPUP-1777624827560-11)', NULL, NULL, '2026-05-01 08:40:35'),
(12, 11, 'topup', '1000000.00', '700000.00', '1700000.00', 'Top up 1.000.000 via E-Smartlink (TOPUP-1777624845302-11)', NULL, NULL, '2026-05-01 08:40:51'),
(13, 11, 'topup', '3000000.00', '1700000.00', '4700000.00', 'Top up 3.000.000 via E-Smartlink (TOPUP-1777624860512-11)', NULL, NULL, '2026-05-01 08:41:10'),
(14, 11, 'debit', '2500000.00', '4700000.00', '2200000.00', 'Perpanjang membership Paket Tahunan (WALLET-1777624882084-11)', NULL, NULL, '2026-05-01 08:41:22'),
(15, 3, 'debit', '185000.00', '245000.00', '60000.00', 'Perpanjang membership Paket Bulanan (WALLET-1777649150475-3)', NULL, NULL, '2026-05-01 15:25:50'),
(16, 3, 'topup', '100000.00', '60000.00', '160000.00', 'Top up 100.000 via E-Smartlink (TOPUP-1777713022645-3)', NULL, NULL, '2026-05-02 09:10:29'),
(17, 3, 'topup', '50000.00', '160000.00', '210000.00', 'Top up 50.000 via E-Smartlink (TOPUP-1777716013095-3)', NULL, NULL, '2026-05-02 10:00:19'),
(18, 3, 'debit', '166500.00', '210000.00', '43500.00', 'Membership Paket Bulanan (Diskon 10%) via saldo (WALLET-1777716027380-3)', NULL, NULL, '2026-05-02 10:00:27'),
(19, 3, 'topup', '35000.00', '43500.00', '78500.00', 'Top up admin', NULL, NULL, '2026-05-02 10:04:20');

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
-- Indexes for table `wallets`
--
ALTER TABLE `wallets`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `user_id` (`user_id`);

--
-- Indexes for table `wallet_transactions`
--
ALTER TABLE `wallet_transactions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `check_ins`
--
ALTER TABLE `check_ins`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=92;

--
-- AUTO_INCREMENT for table `memberships`
--
ALTER TABLE `memberships`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=68;

--
-- AUTO_INCREMENT for table `member_cards`
--
ALTER TABLE `member_cards`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `otps`
--
ALTER TABLE `otps`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `promos`
--
ALTER TABLE `promos`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `transactions`
--
ALTER TABLE `transactions`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=88;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `wallets`
--
ALTER TABLE `wallets`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=170;

--
-- AUTO_INCREMENT for table `wallet_transactions`
--
ALTER TABLE `wallet_transactions`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

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

--
-- Constraints for table `wallets`
--
ALTER TABLE `wallets`
  ADD CONSTRAINT `wallets_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `wallet_transactions`
--
ALTER TABLE `wallet_transactions`
  ADD CONSTRAINT `wt_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
