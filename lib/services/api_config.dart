/// Konfigurasi API untuk koneksi ke backend server
/// File ini berisi semua konfigurasi yang diperlukan untuk komunikasi dengan API
/// seperti base URL, endpoints, dan headers HTTP
class ApiConfig {
  // ==================== BASE URL ====================
  // URL dasar server API yang digunakan untuk semua request

  // 🔧 CARA GANTI IP SAAT PINDAH WIFI:
  // 1. Jalankan 'ipconfig' di CMD laptop
  // 2. Cari "IPv4 Address" di adapter WiFi yang aktif
  // 3. Ganti IP di bawah dengan IP baru
  // 4. Hot reload app (tekan 'r' di terminal Flutter)

  // 📱 KONFIGURASI IP (Pilih salah satu):

  // Opsi 1: IP Saat Ini (Ganti sesuai ipconfig)
  static const String _currentIP = '192.168.100.98'; // ✅ IP WiFi Aktif (ipconfig)

  // HOSTING (Tidak Aktif - Error 503)
  // static const String _currentIP = 'https://www.bahariinn.com/gym';

  // Opsi 2: Localhost (untuk emulator Android atau Windows Desktop)
  static const String _localhost = 'localhost';

  // Opsi 3: IP 10.0.2.2 (khusus untuk Android Emulator)
  static const String _emulatorIP = '10.0.2.2';

  // 🎯 PILIH MODE (true/false):
  static const bool _useLocalhost =
      false; // ✅ NONAKTIF - Pakai IP WiFi untuk HP
  static const bool _useEmulator =
      false; // Set true jika pakai Android Emulator

  // Base URL otomatis sesuai mode
  static String get baseUrl {
    if (_useEmulator) {
      return 'http://$_emulatorIP:3000/api';
    } else if (_useLocalhost) {
      return 'http://$_localhost:3000/api';
    } else {
      if (_currentIP.startsWith('http')) {
        return '$_currentIP/api';
      }
      return 'http://$_currentIP:3000/api';
    }
  }

  // 📋 Daftar IP yang pernah digunakan (untuk referensi):
  // - WiFi Rumah: 192.168.1.xxx
  // - WiFi Kampus: 192.168.100.203
  // - Hotspot HP: 192.168.43.xxx
  // Cek dengan: ipconfig (Windows) atau ifconfig (Mac/Linux)

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
