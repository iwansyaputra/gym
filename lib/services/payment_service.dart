import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_storage.dart';

class PaymentService {
  // Create payment transaction via backend (E-Smartlink)
  // [promoId] adalah ID promo aktif (opsional). Jika ada, dikirim ke backend
  // sehingga backend bisa memvalidasi harga setelah diskon dengan benar.
  static Future<Map<String, dynamic>> createPayment({
    required String paket,
    required int harga,
    int? promoId,
  }) async {
    try {
      final token = await AuthStorage.getToken();

      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      // Susun body — sertakan promo_id hanya jika ada promo aktif
      final Map<String, dynamic> body = {
        'paket': paket,
        'harga': harga,
      };
      if (promoId != null) {
        body['promo_id'] = promoId;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/payment/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal membuat pembayaran',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Check payment status
  static Future<Map<String, dynamic>> checkPaymentStatus(String orderId) async {
    try {
      final token = await AuthStorage.getToken();

      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/payment/status/$orderId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengecek status pembayaran',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get payment history
  static Future<Map<String, dynamic>> getPaymentHistory() async {
    try {
      final token = await AuthStorage.getToken();

      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/payment/history'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil riwayat pembayaran',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Buat transaksi top up saldo via E-Smartlink payment
  /// Input: jumlah — nominal top up dalam Rupiah (min 10.000)
  /// Output: payment_url untuk dibuka di WebView, order_id untuk tracking
  /// Setelah user bayar, E-Smartlink callback ke backend → saldo otomatis bertambah
  static Future<Map<String, dynamic>> createTopUpPayment({
    required int jumlah,
  }) async {
    try {
      final token = await AuthStorage.getToken();

      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/payment/topup'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'jumlah': jumlah}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal membuat pembayaran top up',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Konfirmasi top up ke backend setelah WebView mendeteksi sukses.
  /// Backend akan polling E-Smartlink untuk verifikasi lalu kredit saldo.
  /// Diperlukan karena callback URL tidak bisa diakses dari environment lokal.
  static Future<Map<String, dynamic>> confirmTopUpPayment({
    required String orderId,
  }) async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/payment/topup/confirm/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data['data'], 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengkonfirmasi pembayaran',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}

