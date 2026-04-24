import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_storage.dart';

/// Service untuk menangani semua komunikasi dengan API backend
/// Berisi method-method untuk login, register, fetch data, dan update data
/// Setiap method mengembalikan Map dengan format:
/// {
///   'success': bool,
///   'message': string (opsional),
///   'data': dynamic (opsional)
/// }
class ApiService {
  // ==================== AUTH ENDPOINTS ====================
  // Bagian ini menangani autentikasi user (login, register, OTP verification)

  /// Method untuk login user
  /// Input: email dan password dari form login
  /// Output: token JWT dan user data jika berhasil
  /// Proses:
  /// 1. Send POST request ke /auth/login dengan email & password
  /// 2. Jika response 200 dan success=true:
  ///    - Save token ke SharedPreferences (AuthStorage)
  ///    - Save user data (ID, email, nama) ke SharedPreferences
  ///    - Return success dengan token & user data
  /// 3. Jika gagal: return error message
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Debug: print request info untuk memudahkan debugging
      print('== ApiService.login -> Request');
      print('URL: ${ApiConfig.baseUrl}${ApiConfig.login}');
      print('Payload: ${jsonEncode({'email': email, 'password': password})}');

      // Send POST request ke server API
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
            headers: ApiConfig.headers,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 30));

      // Debug: print response status dan body
      print('== ApiService.login -> Response');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      // Parse response JSON
      final data = jsonDecode(response.body);

      // Cek jika login berhasil (status 200 dan success=true)
      if (response.statusCode == 200 && data['success'] == true) {
        // Simpan token untuk autentikasi request berikutnya
        if (data['data'] != null && data['data']['token'] != null) {
          await AuthStorage.saveToken(data['data']['token']);

          // Simpan data user untuk ditampilkan di UI
          if (data['data']['user'] != null) {
            String? membershipStatus;
            String? membershipEndDate;
            if (data['data']['membership'] != null) {
              membershipStatus = 'Active';
              membershipEndDate = data['data']['membership']['tanggal_berakhir'];
            }

            await AuthStorage.saveUserData(
              userId: data['data']['user']['id'],
              email: data['data']['user']['email'],
              name: data['data']['user']['nama'],
              cardNumber: data['data']['user']['card_number'],
              membershipStatus: membershipStatus,
              hp: data['data']['user']['hp'],
              address: data['data']['user']['alamat'],
              dob: data['data']['user']['tanggal_lahir'],
              gender: data['data']['user']['jenis_kelamin'],
              membershipEndDate: membershipEndDate,
            );
          }
        }
        return {'success': true, 'data': data['data']};
      } else {
        // Jika login gagal, return error message dari server
        return {'success': false, 'message': data['message'] ?? 'Login gagal'};
      }
    } catch (e) {
      // Jika ada exception (network error, timeout, dll)
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  /// Daftar pengguna baru
  /// Input: nama, email, password, nomor HP, jenis kelamin, tanggal lahir, alamat
  /// Output: user data jika berhasil
  /// Proses:
  /// 1. Send POST request ke /auth/register dengan data user
  /// 2. Jika response 200 atau 201:
  ///    - Daftar berhasil, return user data
  /// 3. Jika gagal: return error message
  static Future<Map<String, dynamic>> register({
    required String nama,
    required String email,
    required String password,
    required String hp,
    required String jenisKelamin,
    required String tanggalLahir,
    String? alamat,
  }) async {
    try {
      // Debug: print request info
      print('== ApiService.register -> Request');
      print('URL: ${ApiConfig.baseUrl}${ApiConfig.register}');
      print('Email: $email, Nama: $nama');

      // Send POST request dengan data user yang baru
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.register}'),
            headers: ApiConfig.headers,
            body: jsonEncode({
              'nama': nama,
              'email': email,
              'password': password,
              'hp': hp,
              'jenis_kelamin': jenisKelamin,
              'tanggal_lahir': tanggalLahir,
              'alamat': alamat,
            }),
          )
          .timeout(const Duration(seconds: 30)); // Timeout 30 detik

      // Debug: print response
      print('== ApiService.register -> Response');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      final data = jsonDecode(response.body);

      // Jika registrasi berhasil (200 atau 201)
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        // Jika gagal, return error message dari server
        return {
          'success': false,
          'message': data['message'] ?? 'Registrasi gagal',
        };
      }
    } catch (e) {
      // Jika ada exception (network error, timeout, dll)
      print('== ApiService.register -> Error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  /// Verifikasi OTP yang dikirim ke email user
  /// Input: email dan kode OTP 6 digit dari email user
  /// Output: token JWT dan user data jika berhasil
  /// Proses:
  /// 1. Send POST request ke /auth/verify-otp dengan email & OTP
  /// 2. Jika response 200 dan success=true:
  ///    - Save token ke SharedPreferences
  ///    - Save user data ke SharedPreferences
  ///    - Return success
  /// 3. Jika gagal: return error message
  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      // Debug: print request info
      print('== ApiService.verifyOtp -> Request');
      print('URL: ${ApiConfig.baseUrl}${ApiConfig.verifyOtp}');
      print('Email: $email, OTP: $otp');

      // Send POST request untuk verifikasi OTP
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.verifyOtp}'),
            headers: ApiConfig.headers,
            body: jsonEncode({'email': email, 'otp': otp}),
          )
          .timeout(const Duration(seconds: 30));

      // Debug: print response
      print('== ApiService.verifyOtp -> Response');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      final data = jsonDecode(response.body);

      // Jika verifikasi berhasil (status 200 dan success=true)
      if (response.statusCode == 200 && data['success'] == true) {
        // Simpan token untuk autentikasi request berikutnya
        if (data['data'] != null && data['data']['token'] != null) {
          await AuthStorage.saveToken(data['data']['token']);

          // Simpan data user
          if (data['data']['user'] != null) {
            await AuthStorage.saveUserData(
              userId: data['data']['user']['id'],
              email: data['data']['user']['email'],
              name: data['data']['user']['nama'],
              cardNumber: data['data']['user']['card_number'],
              membershipStatus: 'Active',
              hp: data['data']['user']['hp'],
              address: data['data']['user']['alamat'],
              dob: data['data']['user']['tanggal_lahir'],
              gender: data['data']['user']['jenis_kelamin'],
              membershipEndDate: null, // Verifikasi OTP mungkin tidak ada data tgl akhir, bergantung profile update
            );
          }
        }
        return {'success': true, 'data': data['data']};
      } else {
        // Jika verifikasi gagal
        return {
          'success': false,
          'message': data['message'] ?? 'Verifikasi OTP gagal',
        };
      }
    } catch (e) {
      // Jika ada exception (network error, timeout, dll)
      print('== ApiService.verifyOtp -> Error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  /// Kirim ulang OTP ke email user
  /// Input: email user yang sudah didaftar
  /// Output: pesan sukses jika berhasil
  /// Proses:
  /// 1. Send POST request ke /auth/resend-otp dengan email
  /// 2. Server akan generate OTP baru dan kirim ke email
  /// 3. Return pesan dari server
  static Future<Map<String, dynamic>> resendOtp({required String email}) async {
    try {
      // Debug: print request info
      print('== ApiService.resendOtp -> Request');
      print('URL: ${ApiConfig.baseUrl}${ApiConfig.resendOtp}');
      print('Email: $email');

      // Send POST request untuk mengirim ulang OTP
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.resendOtp}'),
            headers: ApiConfig.headers,
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 10));

      // Debug: print response
      print('== ApiService.resendOtp -> Response');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      final data = jsonDecode(response.body);

      // Jika request berhasil (status 200)
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        // Jika gagal
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengirim ulang OTP',
        };
      }
    } catch (e) {
      // Jika ada exception
      print('== ApiService.resendOtp -> Error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  // ==================== USER ENDPOINTS ====================
  // Bagian ini menangani data profil user (get, update, change password)

  /// Ambil data profil user dari server
  /// Memerlukan token JWT yang sudah disimpan
  /// Output: data user (nama, email, HP, DOB, alamat, dsb)
  /// Proses:
  /// 1. Ambil token dari SharedPreferences (AuthStorage)
  /// 2. Jika token tidak ada, return error
  /// 3. Send GET request ke /user/profile dengan token di header
  /// 4. Jika response 200 dan success=true: return user data
  /// 5. Jika gagal: return error message
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      // Ambil token dari storage local
      final token = await AuthStorage.getToken();
      if (token == null) {
        print('== ApiService.getProfile -> Error: Token not found');
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      // Debug: print request info
      print('== ApiService.getProfile -> Request');
      print('URL: ${ApiConfig.baseUrl}${ApiConfig.profile}');

      // Send GET request dengan token di Authorization header
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profile}'),
            headers: ApiConfig.headersWithAuth(token),
          )
          .timeout(const Duration(seconds: 10));

      // Debug: print response
      print('== ApiService.getProfile -> Response');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      final data = jsonDecode(response.body);

      // Jika request berhasil dan response success=true
      if (response.statusCode == 200 && data['success'] == true) {
        // UPDATE LOCAL STORAGE dengan data terbaru
        if (data['data']['user'] != null) {
          final u = data['data']['user'];
          final c = data['data']['card'];
          final m = data['data']['membership'];

          await AuthStorage.saveUserData(
            userId: u['id'],
            email: u['email'],
            name: u['nama'],
            cardNumber: c != null ? c['card_number'] : (u['card_number']),
            membershipStatus: m != null ? 'Active' : 'Non-Member',
            hp: u['hp'],
            address: u['alamat'],
            dob: u['tanggal_lahir'],
            gender: u['jenis_kelamin'],
            membershipEndDate: m != null ? m['tanggal_berakhir'] : null,
          );
        }

        return {'success': true, 'data': data['data']};
      } else {
        // Jika gagal
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil profil',
        };
      }
    } catch (e) {
      // Jika ada exception
      print('== ApiService.getProfile -> Error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  /// Update data profil user (nama dan nomor HP)
  /// Memerlukan token JWT
  /// Input: nama dan nomor HP yang diinginkan
  /// Output: pesan sukses atau error
  /// Proses:
  /// 1. Ambil token dari SharedPreferences
  /// 2. Send PUT request ke /user/profile dengan data baru
  /// 3. Jika berhasil, return pesan sukses
  /// 4. Jika gagal, return error message
  static Future<Map<String, dynamic>> updateProfile({
    required String nama,
    required String hp,
  }) async {
    try {
      // Ambil token dari storage local
      final token = await AuthStorage.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      // Send PUT request untuk update profil
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateProfile}'),
        headers: ApiConfig.headersWithAuth(token),
        body: jsonEncode({'nama': nama, 'hp': hp}),
      );

      final data = jsonDecode(response.body);

      // Jika update berhasil (status 200)
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        // Jika gagal
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal update profil',
        };
      }
    } catch (e) {
      // Jika ada exception
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  /// Ubah password user
  /// Memerlukan token JWT
  /// Input: password lama dan password baru
  /// Output: pesan sukses atau error
  /// Proses:
  /// 1. Ambil token dari SharedPreferences
  /// 2. Send PUT request ke /user/change-password dengan password lama & baru
  /// 3. Server akan verify password lama, jika benar update ke password baru
  /// 4. Jika berhasil, return pesan sukses
  /// 5. Jika gagal, return error message
  static Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      // Ambil token dari storage local
      final token = await AuthStorage.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      // Send PUT request untuk ubah password
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.changePassword}'),
        headers: ApiConfig.headersWithAuth(token),
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      // Jika perubahan berhasil (status 200)
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        // Jika gagal (password lama salah atau validasi lainnya)
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengubah password',
        };
      }
    } catch (e) {
      // Jika ada exception
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  // ==================== MEMBERSHIP ENDPOINTS ====================
  // Bagian ini menangani data membership (info membership, riwayat)

  /// Ambil informasi membership user saat ini
  /// Memerlukan token JWT
  /// Output: data membership (paket, tanggal mulai, tanggal expired, status)
  /// Proses:
  /// 1. Ambil token dari SharedPreferences
  /// 2. Send GET request ke /membership/info dengan token di header
  /// 3. Jika berhasil, return data membership user
  /// 4. Jika gagal, return error message
  static Future<Map<String, dynamic>> getMembershipInfo() async {
    try {
      // Ambil token dari storage local
      final token = await AuthStorage.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      // Send GET request untuk ambil info membership
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.membershipInfo}'),
        headers: ApiConfig.headersWithAuth(token),
      );

      final data = jsonDecode(response.body);

      // Jika request berhasil (status 200)
      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        // Jika gagal
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil info membership',
        };
      }
    } catch (e) {
      // Jika ada exception
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  /// Ambil daftar paket membership yang tersedia
  static Future<Map<String, dynamic>> getMembershipPackages() async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.membershipPackages}'),
        headers: ApiConfig.headersWithAuth(token),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data'] ?? []};
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Gagal mengambil paket membership',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  /// Ambil riwayat semua membership yang pernah user miliki
  /// Memerlukan token JWT
  /// Output: list riwayat membership dengan status aktif/expired
  /// Proses:
  /// 1. Ambil token dari SharedPreferences
  /// 2. Send GET request ke /membership/history dengan token di header
  /// 3. Jika berhasil, return list riwayat membership
  /// 4. Jika gagal, return error message
  static Future<Map<String, dynamic>> getMembershipHistory() async {
    try {
      // Ambil token dari storage local
      final token = await AuthStorage.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      // Send GET request untuk ambil riwayat membership
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.membershipHistory}'),
        headers: ApiConfig.headersWithAuth(token),
      );

      final data = jsonDecode(response.body);

      // Jika request berhasil (status 200)
      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        // Jika gagal
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil riwayat membership',
        };
      }
    } catch (e) {
      // Jika ada exception
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  // ==================== CHECK-IN ENDPOINTS ====================
  // Bagian ini menangani check-in NFC dan riwayat check-in

  /// Check-in user menggunakan kartu NFC
  /// Input: NFC ID dari kartu yang di-scan
  /// Output: data check-in (waktu, nama user, status)
  /// Proses:
  /// 1. Send POST request ke /check-in/nfc dengan NFC ID
  /// 2. Server akan lookup user berdasarkan NFC ID
  /// 3. Jika user memiliki membership aktif, check-in berhasil
  /// 4. Return data check-in dengan timestamp
  /// 5. Jika gagal (membership expired atau NFC tidak valid), return error
  static Future<Map<String, dynamic>> checkInNfc({
    required String nfcId,
  }) async {
    try {
      // Debug: print request info
      print('== ApiService.checkInNfc -> Request');
      print('URL: ${ApiConfig.baseUrl}${ApiConfig.checkInNfc}');
      print('NFC ID: $nfcId');

      // Send POST request untuk check-in menggunakan NFC
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.checkInNfc}'),
            headers: ApiConfig.headers,
            body: jsonEncode({'nfc_id': nfcId}),
          )
          .timeout(const Duration(seconds: 10));

      // Debug: print response
      print('== ApiService.checkInNfc -> Response');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      final data = jsonDecode(response.body);

      // Jika check-in berhasil (status 200 dan success=true)
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data['data']};
      } else {
        // Jika gagal (NFC tidak valid, membership expired, dll)
        return {
          'success': false,
          'message': data['message'] ?? 'Check-in gagal',
        };
      }
    } catch (e) {
      // Jika ada exception
      print('== ApiService.checkInNfc -> Error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  /// Ambil riwayat semua check-in user
  /// Memerlukan token JWT
  /// Output: list check-in dengan tanggal, waktu, dan status
  /// Proses:
  /// 1. Ambil token dari SharedPreferences
  /// 2. Send GET request ke /check-in/history dengan token di header
  /// 3. Jika berhasil, return list riwayat check-in
  /// 4. Jika gagal, return error message
  static Future<Map<String, dynamic>> getCheckInHistory() async {
    try {
      // Ambil token dari storage local
      final token = await AuthStorage.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      // Send GET request untuk ambil riwayat check-in
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.checkInHistory}'),
        headers: ApiConfig.headersWithAuth(token),
      );

      final data = jsonDecode(response.body);

      // Jika request berhasil (status 200)
      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        // Jika gagal
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil riwayat check-in',
        };
      }
    } catch (e) {
      // Jika ada exception
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  // ==================== PROMO ENDPOINTS ====================
  // Bagian ini menangani promo/diskon dari gym

  /// Ambil semua promo/diskon yang tersedia
  /// Tidak memerlukan token (public endpoint)
  /// Output: list promo dengan deskripsi, diskon, periode berlaku
  /// Proses:
  /// 1. Send GET request ke /promos
  /// 2. Jika berhasil, return list promo (atau empty array jika tidak ada)
  /// 3. Jika gagal, return error message
  static Future<Map<String, dynamic>> getPromos() async {
    try {
      // Debug: print request info
      print('== ApiService.getPromos -> Request');
      print('URL: ${ApiConfig.baseUrl}${ApiConfig.promos}');

      // Send GET request untuk ambil semua promo
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.promos}'),
            headers: ApiConfig.headers,
          )
          .timeout(const Duration(seconds: 10));

      // Debug: print response
      print('== ApiService.getPromos -> Response');
      print('Status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      // Jika request berhasil (status 200)
      if (response.statusCode == 200) {
        // Return list promo atau empty array jika tidak ada
        return {'success': true, 'data': data['data'] ?? []};
      } else {
        // Jika gagal
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil promo',
        };
      }
    } catch (e) {
      // Jika ada exception
      print('== ApiService.getPromos -> Error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  /// Ambil detail promo berdasarkan ID
  /// Tidak memerlukan token (public endpoint)
  /// Input: ID promo yang ingin dilihat detailnya
  /// Output: data lengkap promo (deskripsi, syarat & ketentuan, periode berlaku)
  /// Proses:
  /// 1. Send GET request ke /promos/{promoId}
  /// 2. Jika berhasil, return data detail promo
  /// 3. Jika gagal atau promo tidak ditemukan, return error
  static Future<Map<String, dynamic>> getPromoDetail(int promoId) async {
    try {
      // Send GET request untuk ambil detail promo berdasarkan ID
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.promoDetail}/$promoId'),
        headers: ApiConfig.headers,
      );

      final data = jsonDecode(response.body);

      // Jika request berhasil (status 200)
      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        // Jika gagal atau promo tidak ditemukan
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil detail promo',
        };
      }
    } catch (e) {
      // Jika ada exception
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  // ==================== TRANSACTION ENDPOINTS ====================
  // Bagian ini menangani transaksi pembayaran membership

  /// Ambil riwayat semua transaksi user
  /// Memerlukan token JWT
  /// Output: list transaksi dengan tanggal, jumlah, status, metode pembayaran
  /// Proses:
  /// 1. Ambil token dari SharedPreferences
  /// 2. Send GET request ke /transactions dengan token di header
  /// 3. Jika berhasil, return list transaksi (atau empty array jika tidak ada)
  /// 4. Jika gagal, return error message
  static Future<Map<String, dynamic>> getTransactions() async {
    try {
      // Ambil token dari storage local
      final token = await AuthStorage.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      // Debug: print request info
      print('== ApiService.getTransactions -> Request');
      print('URL: ${ApiConfig.baseUrl}${ApiConfig.transactions}');

      // Send GET request untuk ambil riwayat transaksi
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.transactions}'),
            headers: ApiConfig.headersWithAuth(token),
          )
          .timeout(const Duration(seconds: 10));

      // Debug: print response
      print('== ApiService.getTransactions -> Response');
      print('Status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      // Jika request berhasil (status 200)
      if (response.statusCode == 200) {
        final payload = data['data'];
        if (payload is List) {
          return {'success': true, 'data': payload};
        }
        if (payload is Map<String, dynamic> && payload['transactions'] is List) {
          return {'success': true, 'data': payload['transactions']};
        }
        return {'success': true, 'data': []};
      } else {
        // Jika gagal
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil riwayat transaksi',
        };
      }
    } catch (e) {
      // Jika ada exception
      print('== ApiService.getTransactions -> Error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  /// Buat transaksi pembayaran membership baru
  /// Memerlukan token JWT
  /// Input: ID paket membership dan metode pembayaran (bank_transfer atau e_wallet)
  /// Output: data transaksi dengan invoice number, total harga, link pembayaran
  /// Proses:
  /// 1. Ambil token dari SharedPreferences
  /// 2. Send POST request ke /transactions dengan paket_id & metode_pembayaran
  /// 3. Server akan create transaksi baru dan generate link pembayaran
  /// 4. Jika berhasil, return data transaksi (bisa dibuka untuk bayar)
  /// 5. Jika gagal, return error message
  static Future<Map<String, dynamic>> createTransaction({
    required String paketId,
    required String metodePembayaran,
  }) async {
    try {
      // Ambil token dari storage local
      final token = await AuthStorage.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      // Send POST request untuk buat transaksi baru
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.createTransaction}'),
        headers: ApiConfig.headersWithAuth(token),
        body: jsonEncode({
          'paket_id': paketId,
          'metode_pembayaran': metodePembayaran,
        }),
      );

      final data = jsonDecode(response.body);

      // Jika transaksi berhasil dibuat (status 200 atau 201)
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        // Jika gagal
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal membuat transaksi',
        };
      }
    } catch (e) {
      // Jika ada exception
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  // ==================== LOGOUT ====================

  /// Logout user dengan menghapus semua data lokal
  /// Tidak memerlukan token
  /// Proses:
  /// 1. Panggil AuthStorage.clearAll() untuk hapus token & user data dari storage
  /// 2. User akan diarahkan kembali ke login page
  /// 3. Token dihapus sehingga tidak bisa akses API lagi sampai login ulang
  static Future<void> logout() async {
    await AuthStorage.clearAll();
  }
}
