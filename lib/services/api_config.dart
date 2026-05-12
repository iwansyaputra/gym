/// Konfigurasi API untuk koneksi ke backend server
/// File ini berisi semua konfigurasi yang diperlukan untuk komunikasi dengan API
/// seperti base URL, endpoints, dan headers HTTP
class ApiConfig {
  // ==================== BASE URL ====================
  // URL dasar server API yang digunakan untuk semua request

  // 🌐 MODE PRODUCTION — API sudah di-hosting di:
  static const String _productionUrl = 'https://api.gymku.motalindo.com';

  // 🎯 Base URL — Mengarah ke server production
  static String get baseUrl => '$_productionUrl/api';

  // ==================== AUTH ENDPOINTS ====================
  /// Endpoint untuk register user baru
  static const String register = '/auth/register';

  /// Endpoint untuk login user
  static const String login = '/auth/login';

  /// Endpoint untuk verifikasi kode OTP
  static const String verifyOtp = '/auth/verify-otp';

  /// Endpoint untuk mengirim ulang kode OTP
  static const String resendOtp = '/auth/resend-otp';

  // ==================== USER ENDPOINTS ====================
  /// Endpoint untuk mendapatkan profil user
  static const String profile = '/user/profile';

  /// Endpoint untuk update profil user
  static const String updateProfile = '/user/profile';

  /// Endpoint untuk change password user
  static const String changePassword = '/user/change-password';

  // ==================== MEMBERSHIP ENDPOINTS ====================
  /// Endpoint untuk mendapatkan informasi membership
  static const String membershipInfo = '/membership/info';

  /// Endpoint untuk mendapatkan paket membership
  static const String membershipPackages = '/membership/packages';

  /// Endpoint untuk mendapatkan history membership
  static const String membershipHistory = '/membership/history';

  // ==================== CHECK-IN ENDPOINTS ====================
  /// Endpoint untuk check-in dengan NFC card reader
  static const String checkInNfc = '/check-in/nfc';

  /// Endpoint untuk mendapatkan history check-in
  static const String checkInHistory = '/check-in/history';

  // ==================== PROMO ENDPOINTS ====================
  /// Endpoint untuk mendapatkan daftar semua promo
  static const String promos = '/promos';

  /// Endpoint untuk mendapatkan detail promo (ID ditambahkan di method)
  static const String promoDetail = '/promos';

  // ==================== TRANSACTION ENDPOINTS ====================
  /// Endpoint untuk mendapatkan history transaksi
  static const String transactions = '/transactions/history';

  /// Endpoint untuk membuat transaksi pembayaran baru
  static const String createTransaction = '/transactions/create';

  // ==================== WALLET / SALDO ENDPOINTS ====================
  /// Endpoint untuk melihat saldo wallet sendiri
  static const String walletMy = '/wallet/my';

  /// Endpoint untuk riwayat wallet sendiri
  static const String walletMyHistory = '/wallet/my/history';

  /// Endpoint untuk perpanjang membership pakai saldo
  static const String walletExtend = '/wallet/extend';

  /// Endpoint untuk mendapatkan diskon promo aktif tertinggi (untuk sync harga di membership packages)
  static const String activePromoDiscount = '/promos/active-discount';


  // ==================== HTTP HEADERS ====================

  /// Header standar tanpa autentikasi (untuk public endpoints)
  /// Menggunakan format JSON untuk request dan response
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Header dengan JWT token untuk private endpoints
  /// Token digunakan untuk autentikasi user yang sudah login
  /// Berisi Authorization header dengan format "Bearer {token}"
  static Map<String, String> headersWithAuth(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };
}
