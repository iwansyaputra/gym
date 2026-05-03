import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'otp_page.dart';

/// Halaman Registrasi - Untuk user baru mendaftar akun
/// Flow: User input form (nama, email, password, dll) -> klik Daftar ->
/// API proses registrasi -> Pindah ke OTP page untuk verifikasi
class RegistrasiPage extends StatefulWidget {
  const RegistrasiPage({super.key});

  @override
  State<RegistrasiPage> createState() => _RegistrasiPageState();
}

class _RegistrasiPageState extends State<RegistrasiPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _teleponController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();

  bool _obscurePassword = true; // Untuk sembunyikan password
  bool _isLoading = false; // Loading state saat proses registrasi

  String? _gender; // Jenis kelamin yang dipilih
  DateTime? _tanggalLahir; // Tanggal lahir yang dipilih

  // ================= DATE PICKER =================
  /// Method untuk membuka date picker saat user klik tanggal lahir field
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      helpText: "Pilih Tanggal Lahir",
      cancelText: "Batal",
      confirmText: "Pilih",
    );

    // Simpan tanggal yang dipilih
    if (picked != null) {
      setState(() => _tanggalLahir = picked);
    }
  }

  // ================= SUBMIT REGISTRASI =================
  /// Method untuk submit form registrasi
  /// Proses:
  /// 1. Validasi form (semua field harus terisi)
  /// 2. Check apakah gender dan tanggal lahir sudah dipilih
  /// 3. Call ApiService.register() dengan data form
  /// 4. Jika berhasil, pindah ke OTP page untuk verifikasi
  /// 5. Jika gagal, tampilkan error message
  void _submit() async {
    if (_isLoading) return; // Cegah double submit
    if (!_formKey.currentState!.validate()) return;
    if (_gender == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Pilih jenis kelamin")));
      return;
    }
    if (_tanggalLahir == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Pilih tanggal lahir")));
      return;
    }

    setState(() => _isLoading = true);

    // Format tanggal lahir ke format YYYY-MM-DD
    final formattedDate = DateFormat('yyyy-MM-dd').format(_tanggalLahir!);

    // Call API register
    final result = await ApiService.register(
      nama: _namaController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      hp: _teleponController.text.trim(),
      jenisKelamin: _gender!,
      tanggalLahir: formattedDate,
      alamat: _alamatController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Registrasi berhasil! Silakan verifikasi OTP'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Navigate to OTP page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpPage(email: _emailController.text.trim()),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Registrasi gagal'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text(
          "Registrasi Akun",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= NAMA =================
              TextFormField(
                controller: _namaController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Nama Lengkap"),
                validator: (value) =>
                    value == null || value.isEmpty ? "Nama wajib diisi" : null,
              ),
              const SizedBox(height: 20),

              // ================= NOMOR TELEPON =================
              TextFormField(
                controller: _teleponController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Nomor Telepon"),
                validator: (value) => value == null || value.isEmpty
                    ? "Nomor telepon wajib diisi"
                    : null,
              ),
              const SizedBox(height: 20),

              // ================= EMAIL =================
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Email"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Email wajib diisi";
                  }
                  if (!value.contains("@")) {
                    return "Format email tidak valid";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ================= PASSWORD =================
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Password",
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Password wajib diisi";
                  }
                  if (value.length < 6) {
                    return "Password minimal 6 karakter";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ================= JENIS KELAMIN =================
              DropdownButtonFormField<String>(
                decoration: _inputDecoration("Jenis Kelamin"),
                dropdownColor: const Color(0xFF1A1A1A),
                style: const TextStyle(color: Colors.white),
                initialValue: _gender,
                items: const [
                  DropdownMenuItem(
                    value: "Laki-laki",
                    child: Text("Laki-laki", style: TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: "Perempuan",
                    child: Text("Perempuan", style: TextStyle(color: Colors.white)),
                  ),
                ],
                onChanged: (value) => setState(() => _gender = value),
                validator: (value) =>
                    value == null ? "Pilih jenis kelamin" : null,
              ),
              const SizedBox(height: 20),

              // ================= TANGGAL LAHIR =================
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: _inputDecoration("Tanggal Lahir"),
                  child: Text(
                    _tanggalLahir == null
                        ? "Pilih tanggal"
                        : DateFormat("dd MMMM yyyy").format(_tanggalLahir!),
                    style: TextStyle(
                      color: _tanggalLahir == null
                          ? Colors.grey.shade500
                          : Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ================= ALAMAT =================
              TextFormField(
                controller: _alamatController,
                minLines: 3,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Alamat"),
                validator: (value) => value == null || value.isEmpty
                    ? "Alamat wajib diisi"
                    : null,
              ),
              const SizedBox(height: 30),

              // ================= BUTTON DAFTAR =================
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          "Daftar",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= DECORATION REUSABLE =================
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
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
    );
  }
}
