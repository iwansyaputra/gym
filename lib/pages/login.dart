import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

/// Halaman Login - Untuk user masuk ke aplikasi dengan email dan password
/// Flow: User input email & password -> klik Login -> API verify ->
/// Jika valid, save token dan pindah ke Beranda page
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true; // Untuk sembunyikan/tampilkan password
  bool _isLoading = false; // Untuk tampilkan loading indicator saat API call

  // ================= LOGIN LOGIC =================
  /// Method untuk proses login
  /// 1. Validasi form (email & password tidak boleh kosong)
  /// 2. Call ApiService.login() dengan email & password
  /// 3. Jika berhasil: simpan token -> pindah ke /beranda
  /// 4. Jika gagal: tampilkan error snackbar
  void _login() async {
    // Validasi form terlebih dahulu
    if (!_formKey.currentState!.validate()) return;

    // Set loading indicator
    setState(() => _isLoading = true);

    // Call API login endpoint
    final result = await ApiService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    // Check if widget still mounted (jangan update UI jika widget sudah ditutup)
    if (!mounted) return;
    setState(() => _isLoading = false);

    // Jika login berhasil
    if (result['success'] == true) {
      // Tampilkan success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Login Berhasil!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Pindah ke halaman Beranda (Home)
      Navigator.pushReplacementNamed(context, '/beranda');
    } else {
      // Tampilkan error snackbar
      _showErrorSnackBar(result['message'] ?? 'Login gagal');
    }
  }

  // Helper untuk parsing pesan error agar user friendly
  String _parseErrorMessage(String message) {
    if (message.contains("FormatException") ||
        message.contains("<DOCTYPE html>")) {
      return "Gagal terhubung ke server. Pastikan server aktif atau cek koneksi internet.";
    } else if (message.contains("SocketException") ||
        message.contains("Connection refused")) {
      return "Tidak dapat terhubung ke server. Cek IP/koneksi WiFi.";
    } else if (message.contains("TimeoutException")) {
      return "Server tidak merespons dalam waktu 30 detik. Pastikan API server sudah jalan dan IP benar.";
    }
    return message;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_parseErrorMessage(message)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ================= WHATSAPP LUPA PASSWORD =================
  Future<void> _forgotPassword() async {
    final String phoneNumber = '6281995136012';
    final String message =
        'Halo admin, saya lupa password akun gym saya. Mohon dibantu ya.';

    final Uri url = Uri.parse(
      "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}",
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('WhatsApp tidak dapat dibuka');
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFF0A0A0A),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // ================= Logo =================
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2196F3).withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      size: 60,
                      color: Color(0xFF2196F3),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ================= Card Form =================
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Welcome Back! 💪",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Mari lanjutkan perjalanan fitness Anda",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade400,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ================= Email =================
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: "Email",
                              labelStyle: const TextStyle(color: Colors.grey),
                              prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                              filled: true,
                              fillColor: const Color(0xFF2A2A2A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFF2196F3),
                                  width: 2,
                                ),
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email tidak boleh kosong';
                              }
                              if (!value.contains('@')) {
                                return 'Format email tidak valid';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // ================= Password =================
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: "Password",
                              labelStyle: const TextStyle(color: Colors.grey),
                              prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(0xFF2A2A2A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFF2196F3),
                                  width: 2,
                                ),
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password tidak boleh kosong';
                              }
                              if (value.length < 6) {
                                return 'Minimal 6 karakter';
                              }
                              return null;
                            },
                          ),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _forgotPassword,
                              child: const Text(
                                "Lupa Password?",
                                style: TextStyle(
                                  color: Color(0xFF2196F3),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ================= Button Login =================
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2196F3),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _isLoading ? null : _login,
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    )
                                  : const Text(
                                      "Login",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ================= Divider =================
                          Row(
                            children: [
                              Expanded(
                                child: Divider(color: Colors.white.withOpacity(0.1)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  "atau",
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ),
                              Expanded(
                                child: Divider(color: Colors.white.withOpacity(0.1)),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // ================= Registrasi =================
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Belum punya akun? ",
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 15,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/registrasi');
                                },
                                child: const Text(
                                  "Registrasi",
                                  style: TextStyle(
                                    color: Color(0xFF2196F3),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ================= Footer =================
                  Text(
                    "© 2025 GymFit Membership",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
