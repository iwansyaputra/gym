import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import 'membership_packages_page.dart';

class AkunPage extends StatefulWidget {
  const AkunPage({super.key});
  
  @override
  State<AkunPage> createState() => _AkunPageState();
}

class _AkunPageState extends State<AkunPage> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // 1. Load Local
    final localData = await AuthStorage.getUserData();
    if (localData != null && mounted) {
      setState(() {
        _profileData = {
          'user': {'nama': localData['name'], 'email': localData['email']},
          'membership': localData['membershipStatus'] == 'Active'
              ? {'paket_nama': 'Active Member'}
              : null,
        };
        _isLoading = false;
      });
    }

    if (_profileData == null) {
      setState(() => _isLoading = true);
    }

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
  }

  Future<void> _chatAdmin() async {
    const phone = "6281995136012";
    const message = "Halo kak, saya ingin bertanya tentang Member GYM di Helius Tegal";

    final Uri url = Uri.parse("https://wa.me/$phone?text=$message");

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception("Tidak bisa membuka WhatsApp");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2196F3))),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Akun",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.2,
          ),
        ),
      ),

      body: RefreshIndicator(
        color: const Color(0xFF2196F3),
        backgroundColor: const Color(0xFF1A1A1A),
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _profileCard(),

              const SizedBox(height: 25),

              _menuItem(
                icon: Icons.chat_bubble_outline,
                title: "Chat Admin",
                subtitle: "Tanya langsung via WhatsApp",
                onTap: _chatAdmin,
              ),

              _menuItem(
                icon: Icons.payment_outlined,
                title: "Membership",
                subtitle: "Beli / perpanjang membership",
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MembershipPackagesPage(),
                    ),
                  );

                  if (result == true && mounted) {
                    await _loadProfile();
                  }
                },
              ),

              const SizedBox(height: 40),

              _logoutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileCard() {
    final user = _profileData?['user'];
    final membership = _profileData?['membership'];

    String name = user?['nama'] ?? 'Member';
    String email = user?['email'] ?? '';
    bool isActive = membership != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  border: Border.all(
                    color: const Color(0xFF2196F3),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.person, size: 40, color: Color(0xFF2196F3)),
              ),
              if (isActive)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 12, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            email,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive ? Colors.green : Colors.red,
              ),
            ),
            child: Text(
              isActive ? "STATUS: ACTIVE" : "STATUS: INACTIVE",
              style: TextStyle(
                color: isActive ? Colors.green : Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF2196F3), size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
      ),
    );
  }

  Widget _logoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          _showLogoutDialog(context);
        },
        icon: const Icon(Icons.logout, size: 20),
        label: const Text("Logout"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.withOpacity(0.1),
          foregroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.red),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Logout",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Yakin mau keluar?",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await AuthStorage.clearAll();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Keluar"),
          ),
        ],
      ),
    );
  }
}
