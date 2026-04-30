import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import 'promo.dart';
import 'card.dart';
import 'riwayat.dart';
import 'akun.dart';
import 'check_in_nfc_page.dart';
import 'membership_packages_page.dart';
import 'saldo_page.dart';

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  int _currentIndex = 0;
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _walletData; // data saldo
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 1. Local Storage First
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
                  'tanggal_berakhir': localData['membershipEndDate'] ??
                      DateTime.now().add(const Duration(days: 30)).toString(),
                }
              : null,
        };
        _isLoading = false;
      });
    }

    // 2. Set loading if no local data
    if (_profileData == null) {
      setState(() => _isLoading = true);
    }

    // 3. API Fetch
    final result = await ApiService.getProfile();

    if (mounted) {
      setState(() {
        if (result['success'] == true) {
          _profileData = result['data'];
          
          final u = result['data']['user'];
          final m = result['data']['membership'];
          final c = result['data']['card'];
          
          if (u != null) {
            AuthStorage.saveUserData(
              userId: u['id'],
              email: u['email'] ?? '',
              name: u['nama'] ?? 'Member',
              cardNumber: c != null ? c['card_number'] : '-',
              membershipStatus: (m != null && m['status'] == 'active') ? 'Active' : 'Non-Member',
              hp: u['hp'],
              address: u['alamat'],
              dob: u['tanggal_lahir'],
              gender: u['jenis_kelamin'],
              membershipEndDate: m != null ? m['tanggal_berakhir'] : null,
            );
          }
        }
        _isLoading = false;
      });
    }

    // 4. Load saldo wallet
    final walletResult = await ApiService.getMyWallet();
    if (mounted && walletResult['success'] == true) {
      setState(() => _walletData = walletResult['data']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // Black background
      body: _buildPage(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: const Color(0xFF2196F3),
          unselectedItemColor: Colors.grey.shade600,
          backgroundColor: const Color(0xFF1A1A1A), // Dark bottom nav
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

  Widget _buildBeranda() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF2196F3)));
    }

    return SafeArea(
      child: RefreshIndicator(
        color: const Color(0xFF2196F3),
        backgroundColor: const Color(0xFF1A1A1A),
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome Back,",
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _profileData?['user']?['nama'] ?? 'Member',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              _buildUserInfoCard(),
              const SizedBox(height: 25),
              CheckInMethodCard(
                onMemberTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CheckInNfcPage()),
                  );
                },
              ),
              const SizedBox(height: 25),
              _buildSaldoCard(),   // kartu saldo mini
              const SizedBox(height: 25),
              _buildTransaksiCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    final membership = _profileData?['membership'];

    int sisaHari = 0;
    if (membership != null && membership['tanggal_berakhir'] != null) {
      try {
        final endDate = DateTime.parse(membership['tanggal_berakhir']).toLocal();
        sisaHari = endDate.difference(DateTime.now()).inDays;
        if (sisaHari < 0) sisaHari = 0;
      } catch (e) {
        sisaHari = 0;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D47A1).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "MEMBERSHIP STATUS",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                membership != null ? Icons.verified : Icons.error_outline,
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            membership != null ? "Active Member" : "Non-Member",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          if (membership != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    "Sisa Aktif: $sisaHari Hari",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (sisaHari <= 5) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Masa aktif hampir habis. Perpanjang sekarang.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0D47A1),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Perpanjang Membership',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaldoCard() {
    final saldo = double.tryParse(_walletData?['saldo']?.toString() ?? '0') ?? 0;
    final formatted = saldo == 0
        ? 'Rp 0'
        : 'Rp ${saldo.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SaldoPage()),
        );
        _loadData(); // refresh setelah balik
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Color(0xFF2196F3),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saldo Dompet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatted,
                    style: TextStyle(
                      color: saldo > 0 ? const Color(0xFF2196F3) : Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTransaksiCard(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RiwayatPage()),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long, color: Color(0xFF2196F3)),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Riwayat Transaksi",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Lihat detail pembayaran Anda",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}

class CheckInMethodCard extends StatelessWidget {
  final VoidCallback onMemberTap;

  const CheckInMethodCard({super.key, required this.onMemberTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onMemberTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2196F3).withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.nfc, color: Color(0xFF2196F3), size: 32),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tap to Check-in",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Gunakan NFC untuk absen di gate gym",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF2196F3), size: 16),
          ],
        ),
      ),
    );
  }
}
