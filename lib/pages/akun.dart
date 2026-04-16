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

    // 2. Load API
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

  // ====== FUNGSI WHATSAPP ======
  Future<void> _chatAdmin() async {
    const phone = "6281995136012";
    const message =
        "Halo kak, saya ingin bertanya tentang Member GYM di Helius Tegal";

    final Uri url = Uri.parse("https://wa.me/$phone?text=$message");

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception("Tidak bisa membuka WhatsApp");
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
        backgroundColor: const Color(0xFFF8CEDA),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Akun",
          style: TextStyle(
            color: Color(0xFFE26D88),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),

      // ================== BODY ==================
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _profileCard(),

              const SizedBox(height: 25),

              _menuItem(
                icon: Icons.chat_bubble,
                title: "Chat Admin",
                subtitle: "Tanya langsung via WhatsApp",
                onTap: _chatAdmin,
              ),

              _menuItem(
                icon: Icons.payment,
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

              const SizedBox(height: 30),

              _logoutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  // ================= PROFIL CARD =================
  Widget _profileCard() {
    final user = _profileData?['user'];
    final membership = _profileData?['membership'];

    String nama = user?['nama'] ?? 'User';
    String membershipType = membership != null
        ? (membership['paket'] ?? membership['paket_nama'] ?? 'Member Aktif')
        : 'Belum ada membership';
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFFE7EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: const Color(0xFFE26D88),
            child: const Icon(Icons.person, color: Colors.white, size: 42),
          ),

          const SizedBox(width: 20),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE26D88),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 6),
                Text(
                  membershipType,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= MENU ITEM =================
  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE26D88),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE26D88),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),

            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ================= LOGOUT BUTTON =================
  Widget _logoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Show confirmation dialog
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Apakah Anda yakin ingin keluar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Logout'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          // Logout and clear token
          await ApiService.logout();

          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE26D88),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            "Log Out",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              letterSpacing: 1,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
