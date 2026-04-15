# Flutter Integration Guide

Panduan untuk mengintegrasikan API dengan aplikasi Flutter Membership Gym.

## 📦 Dependencies

Tambahkan dependencies berikut di `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.1.0
  shared_preferences: ^2.2.2
  provider: ^6.1.1  # untuk state management (optional)
```

Jalankan:
```bash
flutter pub get
```

## 🔧 Setup API Service

### 1. Buat file `lib/services/api_service.dart`

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Ganti dengan IP server Anda
  // Untuk Android Emulator: http://10.0.2.2:3000
  // Untuk iOS Simulator: http://localhost:3000
  // Untuk device fisik: http://YOUR_COMPUTER_IP:3000
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  
  // Get token from storage
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
  
  // Save token to storage
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }
  
  // Remove token (logout)
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
  
  // Get headers with token
  Future<Map<String, String>> getHeaders({bool needsAuth = false}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    
    if (needsAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }
  
  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: await getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        // Save token
        await saveToken(data['data']['token']);
      }
      
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
  
  // Register
  Future<Map<String, dynamic>> register({
    required String nama,
    required String email,
    required String hp,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: await getHeaders(),
        body: jsonEncode({
          'nama': nama,
          'email': email,
          'hp': hp,
          'password': password,
        }),
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
  
  // Verify OTP
  Future<Map<String, dynamic>> verifyOTP(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: await getHeaders(),
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
  
  // Get Profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: await getHeaders(needsAuth: true),
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
  
  // Update Profile
  Future<Map<String, dynamic>> updateProfile({
    required String nama,
    required String hp,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user/profile'),
        headers: await getHeaders(needsAuth: true),
        body: jsonEncode({
          'nama': nama,
          'hp': hp,
        }),
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
  
  // Check-in NFC
  Future<Map<String, dynamic>> checkInNFC(String nfcId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/check-in/nfc'),
        headers: await getHeaders(),
        body: jsonEncode({
          'nfc_id': nfcId,
        }),
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
  
  // Get Check-in History
  Future<Map<String, dynamic>> getCheckInHistory({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/check-in/history?limit=$limit&offset=$offset'),
        headers: await getHeaders(needsAuth: true),
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
  
  // Get Membership Info
  Future<Map<String, dynamic>> getMembershipInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/membership/info'),
        headers: await getHeaders(needsAuth: true),
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
  
  // Get Membership Packages
  Future<Map<String, dynamic>> getMembershipPackages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/membership/packages'),
        headers: await getHeaders(needsAuth: true),
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
  
  // Extend Membership
  Future<Map<String, dynamic>> extendMembership({
    required int packageId,
    required String paymentMethod,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/membership/extend'),
        headers: await getHeaders(needsAuth: true),
        body: jsonEncode({
          'package_id': packageId,
          'payment_method': paymentMethod,
        }),
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
  
  // Get Transaction History
  Future<Map<String, dynamic>> getTransactionHistory({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/history?limit=$limit&offset=$offset'),
        headers: await getHeaders(needsAuth: true),
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
  
  // Get Promos
  Future<Map<String, dynamic>> getPromos() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/promos'),
        headers: await getHeaders(),
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
  
  // Logout
  Future<void> logout() async {
    await removeToken();
  }
}
```

## 📝 Contoh Penggunaan

### 1. Login Page

```dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  
  Future<void> _login() async {
    setState(() => _isLoading = true);
    
    final result = await _apiService.login(
      _emailController.text,
      _passwordController.text,
    );
    
    setState(() => _isLoading = false);
    
    if (result['success']) {
      // Navigate to home
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 2. Update Check-in NFC Page

Modifikasi `lib/pages/check_in_nfc_page.dart`:

```dart
import '../services/api_service.dart';

// Di dalam class _CheckInNfcPageState

final _apiService = ApiService();

void startScan() async {
  if (isScanning) return;

  setState(() {
    isScanning = true;
    statusText = "Menyiapkan NFC...";
  });

  // ... existing NFC code ...

  // Listen command dari reader NFC eksternal
  NfcHce.stream.listen((command) async {
    setState(() {
      statusText = "Reader terhubung! Mengirim ID...";
    });

    // Send to API
    final result = await _apiService.checkInNFC(gymId);

    if (result['success']) {
      setState(() {
        statusText = result['message'];
      });
    } else {
      setState(() {
        statusText = "Check-in gagal: ${result['message']}";
      });
    }
  });
}
```

### 3. Load Profile Data

```dart
import '../services/api_service.dart';

class BerandaPage extends StatefulWidget {
  @override
  _BerandaPageState createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  final _apiService = ApiService();
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }
  
  Future<void> _loadProfile() async {
    final result = await _apiService.getProfile();
    
    setState(() {
      _isLoading = false;
      if (result['success']) {
        _profileData = result['data'];
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    final user = _profileData?['user'];
    final membership = _profileData?['membership'];
    
    // Use the data in your UI
    return Scaffold(
      body: Column(
        children: [
          Text(user?['nama'] ?? 'User'),
          Text(user?['email'] ?? ''),
          // ... rest of UI
        ],
      ),
    );
  }
}
```

## 🔐 Authentication Flow

1. **Login** → Simpan token
2. **Setiap request** → Sertakan token di header
3. **Logout** → Hapus token

## 🌐 Network Configuration

### Android Emulator
```dart
static const String baseUrl = 'http://10.0.2.2:3000/api';
```

### iOS Simulator
```dart
static const String baseUrl = 'http://localhost:3000/api';
```

### Physical Device (Same WiFi)
```dart
static const String baseUrl = 'http://192.168.1.100:3000/api';
// Ganti dengan IP komputer Anda
```

Untuk cek IP komputer:
- Windows: `ipconfig`
- Mac/Linux: `ifconfig` atau `ip addr`

## 🐛 Error Handling

Selalu handle error dengan try-catch dan tampilkan pesan yang user-friendly:

```dart
try {
  final result = await apiService.login(email, password);
  if (result['success']) {
    // Success
  } else {
    // Show error message
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(result['message']),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
} catch (e) {
  // Network error
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Error'),
      content: Text('Tidak dapat terhubung ke server'),
    ),
  );
}
```

## 📱 Testing

1. Pastikan API server running di `http://localhost:3000`
2. Jalankan Flutter app di emulator/device
3. Test login dengan sample user:
   - Email: `budi@example.com`
   - Password: `password123`

## 🚀 Production

Untuk production, ganti `baseUrl` dengan URL server production Anda:

```dart
static const String baseUrl = 'https://your-api-domain.com/api';
```

Happy coding! 🎉
