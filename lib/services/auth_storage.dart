import 'package:shared_preferences/shared_preferences.dart';

/// Class untuk menyimpan dan mengambil data autentikasi (token & user data)
/// Menggunakan SharedPreferences untuk penyimpanan lokal di device
class AuthStorage {
  // Key-key untuk SharedPreferences
  static const String _tokenKey = 'auth_token'; // Menyimpan JWT token
  static const String _userIdKey = 'user_id'; // Menyimpan ID user
  static const String _userEmailKey = 'user_email'; // Menyimpan email user
  static const String _userNameKey = 'user_name'; // Menyimpan nama user
  static const String _userCardKey = 'user_card'; // Menyimpan nomor kartu
  static const String _membershipStatusKey =
      'membership_status'; // Status member

  // NEW KEYS untuk profil lengkap
  static const String _userHpKey = 'user_hp';
  static const String _userAddressKey = 'user_address';
  static const String _userDobKey = 'user_dob';
  static const String _userGenderKey = 'user_gender';
  static const String _membershipEndDateKey = 'membership_end_date'; // Tgl expired

  // ==================== TOKEN METHODS ====================

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // ==================== USER DATA METHODS ====================

  /// Simpan semua data user termasuk HP, Alamat, dll
  static Future<void> saveUserData({
    required int userId,
    required String email,
    required String name,
    String? cardNumber,
    String? membershipStatus,
    String? hp,
    String? address,
    String? dob,
    String? gender,
    String? membershipEndDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userNameKey, name);

    if (cardNumber != null) await prefs.setString(_userCardKey, cardNumber);
    if (membershipStatus != null) {
      await prefs.setString(_membershipStatusKey, membershipStatus);
    }

    // Save New Fields
    if (hp != null) await prefs.setString(_userHpKey, hp);
    if (address != null) await prefs.setString(_userAddressKey, address);
    if (dob != null) await prefs.setString(_userDobKey, dob);
    if (gender != null) await prefs.setString(_userGenderKey, gender);
    if (membershipEndDate != null) await prefs.setString(_membershipEndDateKey, membershipEndDate);
  }

  /// Ambil data user lengkap
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_userIdKey);
    final email = prefs.getString(_userEmailKey);
    final name = prefs.getString(_userNameKey);
    final cardNumber = prefs.getString(_userCardKey);
    final membershipStatus = prefs.getString(_membershipStatusKey);

    // New Fields retrieval
    final hp = prefs.getString(_userHpKey);
    final address = prefs.getString(_userAddressKey);
    final dob = prefs.getString(_userDobKey);
    final gender = prefs.getString(_userGenderKey);
    final membershipEndDate = prefs.getString(_membershipEndDateKey);

    if (userId == null || email == null || name == null) {
      return null;
    }

    return {
      'userId': userId,
      'email': email,
      'name': name,
      'cardNumber': cardNumber ?? '-',
      'membershipStatus': membershipStatus ?? 'Non-Member',
      'hp': hp ?? '-',
      'address': address ?? '-',
      'dob': dob,
      'gender': gender ?? '-',
      'membershipEndDate': membershipEndDate,
    };
  }

  // ==================== SESSION CHECK METHODS ====================

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
