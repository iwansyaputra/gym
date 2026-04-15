import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import 'promo.dart';
import 'card.dart';
import 'riwayat.dart';
import 'akun.dart';
import 'check_in_nfc_page.dart';
import 'membership_packages_page.dart';

/// Halaman Beranda/Dashboard - Halaman utama setelah login
/// Menampilkan: Profile user, membership status, check-in option, riwayat transaksi singkat
/// Juga berfungsi sebagai main page dengan bottom navigation bar untuk akses halaman lain
class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  int _currentIndex = 0; // Index halaman yang sedang aktif di bottom nav
  Map<String, dynamic>? _profileData; // Data profil user dari API
  bool _isLoading = true; // Loading state untuk fetch data

  @override
  void initState() {
    super.initState();
    _loadData(); // Ambil data profil saat halaman dibuka
  }

  /// Method untuk fetch data profil user dari API
  /// Dipanggil saat initState dan bisa dipanggil ulang saat refresh
  Future<void> _loadData() async {
    // 1. Coba local storage dulu
    final localData = await AuthStorage.getUserData();
    if (localData != null && mounted) {
      setState(() {
        _profileData = {
          'user': {
            'nama': localData['name'],
            'email': localData['email'],
            'hp': localData['hp'] ?? '-',
          },
          'membership': localData['membershipStatus'] == 'Active'
              ? {
                  'tanggal_berakhir': DateTime.now()
                      .add(const Duration(days: 30))
                      .toString(),
                }
              : null,
          // Catatan: Tanggal expired sulit ditebak dari local storage sederhana,
          // tapi minimal nama muncul dulu.
        };
        _isLoading = false;
      });
    }

    // 2. Jika belum ada data local, set loading
    if (_profileData == null) {
      setState(() => _isLoading = true);
    }

    // 3. Call API untuk ambil profil user (Data Paling Update)
    final result = await ApiService.getProfile();

    // Update UI dengan data yang diterima dari API
    if (mounted) {
      setState(() {
        if (result['success'] == true) {
          _profileData = result['data']; // Simpan data profil
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8CEDA),
      body: _buildPage(), // Build halaman sesuai index bottom nav yang dipilih
      /// Bottom Navigation Bar - Menu untuk navigasi antar halaman
      /// 0 = Beranda, 1 = Promo, 2 = Check-in, 3 = Card, 4 = Riwayat, 5 = Akun
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFFE26D88),
        unselectedItemColor: Colors.grey.shade600,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: "Promo",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.credit_card), label: "Card"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Riwayat"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Akun"),
        ],
      ),
    );
  }

  Widget _buildPage() {
    switch (_currentIndex) {
      case 0:
        return _buildBeranda();
      case 1:
        return const PromoPage();
      case 2:
        return const CardMemberPage();
      case 3:
        return const RiwayatPage();
      case 4:
        return const AkunPage();
      default:
        return _buildBeranda();
    }
  }

  // ================= HALAMAN BERANDA =================
  Widget _buildBeranda() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildUserInfoCard(),
              const SizedBox(height: 20),

              // ======== CHECK IN CARD ========
              CheckInMethodCard(
                onMemberTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CheckInNfcPage()),
                  );
                },
              ),

              const SizedBox(height: 20),
              _buildTransaksiCard(context),
            ],
          ),
        ),
      ),
    );
  }

  // ================= USER CARD =================
  Widget _buildUserInfoCard() {
    final user = _profileData?['user'];
    final membership = _profileData?['membership'];

    String nama = user?['nama'] ?? 'User';
    String email = user?['email'] ?? '';
    String hp = user?['hp'] ?? '';

    // Hitung sisa hari membership
    int sisaHari = 0;
    if (membership != null && membership['tanggal_berakhir'] != null) {
      try {
        final endDate = DateTime.parse(membership['tanggal_berakhir']);
        sisaHari = endDate.difference(DateTime.now()).inDays;
        if (sisaHari < 0) sisaHari = 0;
      } catch (e) {
        sisaHari = 0;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: Color(0xFFE26D88),
                child: Icon(Icons.person, size: 40, color: Colors.white),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      email,
                      style: TextStyle(color: Colors.grey.shade700),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(hp, style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // MASA AKTIF
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFDE3EA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified, color: Color(0xFFE26D88)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Sisa masa aktif member: $sisaHari hari",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // WARNING
          if (sisaHari <= 5)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFDD9D9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Masa aktif member hampir habis. Segera perpanjang sekarang.",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (sisaHari <= 5) const SizedBox(height: 12),
          if (sisaHari <= 5)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MembershipPackagesPage(),
                    ),
                  );

                  if (result == true && mounted) {
                    await _loadData();
                  }
                },
                icon: const Icon(Icons.payment),
                label: const Text('Perpanjang Membership'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE26D88),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ================= CARD RIWAYAT =================
  Widget _buildTransaksiCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, size: 42, color: Color(0xFFE26D88)),
          const SizedBox(width: 18),
          const Expanded(
            child: Text(
              "Lihat transaksi atau pembayaran terbaru Anda",
              style: TextStyle(fontSize: 16),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE26D88),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RiwayatPage()),
              );
            },
            child: const Text("Riwayat"),
          ),
        ],
      ),
    );
  }
}

// ================= CHECK IN METHOD CARD WIDGET =================
class CheckInMethodCard extends StatelessWidget {
  final VoidCallback onMemberTap;

  const CheckInMethodCard({super.key, required this.onMemberTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: onMemberTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFDE3EA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE26D88).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: const [
              Icon(Icons.credit_card, size: 40, color: Color(0xFFE26D88)),
              SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Check-in dengan Member Card",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Tempelkan kartu member Anda untuk check-in",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 20, color: Color(0xFFE26D88)),
            ],
          ),
        ),
      ),
    );
  }
}
