import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';

class CardMemberPage extends StatefulWidget {
  const CardMemberPage({super.key});

  @override
  State<CardMemberPage> createState() => _CardMemberPageState();
}

class _CardMemberPageState extends State<CardMemberPage> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // 1. Coba load dari Local Storage dulu (biar instan muncul)
    final localData = await AuthStorage.getUserData();
    if (localData != null && mounted) {
      setState(() {
        _profileData = {
          'user': {
            'nama': localData['name'],
            'email': localData['email'],
            'hp': localData['hp'],
            'jenis_kelamin': localData['gender'],
            'alamat': localData['address'],
            'tanggal_lahir': localData['dob'],
          },
          'card': {'card_number': localData['cardNumber']},
          'membership': localData['membershipStatus'] == 'Active'
              ? {'status': 'active'}
              : null,
        };
        _isLoading = false; // Tampilkan data local dulu
      });
    }

    // 2. Fetch data terbaru dari API (Background update)
    // Jangan set _isLoading = true jika sudah ada data local, biar gak flickering
    if (_profileData == null) {
      setState(() => _isLoading = true);
    }

    final result = await ApiService.getProfile();

    if (mounted) {
      setState(() {
        if (result['success'] == true) {
          _profileData = result['data'];
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8CEDA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8CEDA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF8CEDA),
        centerTitle: true,
        title: const Text(
          "Card Member",
          style: TextStyle(
            color: Color(0xFFE26D88),
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.3,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFE26D88)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProfile),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: _buildMemberCard(),
        ),
      ),
    );
  }

  Widget _buildMemberCard() {
    final user = _profileData?['user'];
    final card = _profileData?['card'];
    final membership = _profileData?['membership'];

    /// DATA MEMBER
    String nama = user?['nama'] ?? 'User';
    String email = user?['email'] ?? '-';
    String telepon = user?['hp'] ?? '-';
    String idMemberRaw = card?['card_number'] ?? '';
    // Format 10 digit: XXXX XXX XXX (mudah dibaca, seperti kartu ATM)
    String idMember = idMemberRaw.isEmpty
        ? 'Belum ada kartu'
        : idMemberRaw.length == 10
            ? '${idMemberRaw.substring(0, 4)} ${idMemberRaw.substring(4, 7)} ${idMemberRaw.substring(7, 10)}'
            : idMemberRaw;
    String gender = user?['jenis_kelamin'] ?? '-';
    String alamat = user?['alamat'] ?? '-';

    /// TANGGAL LAHIR
    DateTime tanggalLahir;
    if (user?['tanggal_lahir'] != null) {
      try {
        tanggalLahir = DateTime.parse(user['tanggal_lahir']);
      } catch (e) {
        tanggalLahir = DateTime(2000, 1, 1);
      }
    } else {
      tanggalLahir = DateTime(2000, 1, 1);
    }

    String tglLahirFormatted = DateFormat("dd MMMM yyyy").format(tanggalLahir);

    /// HITUNG UMUR
    int umur = DateTime.now().year - tanggalLahir.year;
    if (DateTime.now().month < tanggalLahir.month ||
        (DateTime.now().month == tanggalLahir.month &&
            DateTime.now().day < tanggalLahir.day)) {
      umur--;
    }

    /// SISA MASA AKTIF DALAM HARI
    int sisaHari = 0;
    String membershipStatus = "Non-Aktif";

    if (membership != null && membership['tanggal_berakhir'] != null) {
      try {
        final endDate = DateTime.parse(membership['tanggal_berakhir']);
        sisaHari = endDate.difference(DateTime.now()).inDays;
        membershipStatus = membership['status'] == 'active'
            ? 'Premium Member'
            : 'Expired';
        if (sisaHari < 0) sisaHari = 0;
      } catch (e) {
        sisaHari = 0;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFFF1F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.18),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: const Color(0xFFE26D88),
            child: const Icon(Icons.person, color: Colors.white, size: 55),
          ),

          const SizedBox(height: 16),

          Text(
            nama,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE26D88),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),

          Text(
            membershipStatus,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 22),
          const Divider(thickness: .9, color: Color(0xFFE26D88)),
          const SizedBox(height: 18),

          // ===== MASA AKTIF =====
          _masaAktifBox(sisaHari),

          const SizedBox(height: 20),
          const Divider(thickness: 1, color: Color(0xFFE26D88)),
          const SizedBox(height: 14),

          _infoRow(Icons.credit_card, "ID Member", idMember),
          _infoRow(Icons.phone, "Nomor Telepon", telepon),
          _infoRow(Icons.email, "Email", email),
          _infoRow(Icons.male, "Jenis Kelamin", gender),

          _infoRow(Icons.cake, "Tanggal Lahir", tglLahirFormatted),

          _infoRow(Icons.timeline, "Umur", "$umur Tahun"),

          _infoRow(Icons.home, "Alamat", alamat),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _masaAktifBox(int sisaHari) {
    String warning = "";
    if (sisaHari <= 7) {
      warning = "⚠ Masa aktif hampir habis!";
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFE6EE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE26D88), width: 1),
      ),
      child: Column(
        children: [
          const Text(
            "Masa Aktif Member",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE26D88),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "Sisa $sisaHari Hari",
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (warning.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              warning,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE26D88), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFFE26D88),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
