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
    // 1. Coba load dari Local Storage
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
              ? {'tanggal_berakhir': localData['membershipEndDate']}
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
        elevation: 0,
        backgroundColor: const Color(0xFF0A0A0A),
        centerTitle: true,
        title: const Text(
          "DIGITAL CARD",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 2.0,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProfile),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF2196F3),
        backgroundColor: const Color(0xFF1A1A1A),
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildDigitalCard(),
              const SizedBox(height: 40),
              _buildInfoDetails(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDigitalCard() {
    final user = _profileData?['user'];
    final card = _profileData?['card'];
    final membership = _profileData?['membership'];

    String nama = user?['nama'] ?? 'MEMBER';
    String idMemberRaw = card?['card_number'] ?? '';
    String idMember = idMemberRaw.isEmpty
        ? 'XXX XXX XXXX'
        : idMemberRaw.length == 10
            ? '${idMemberRaw.substring(0, 4)} ${idMemberRaw.substring(4, 7)} ${idMemberRaw.substring(7, 10)}'
            : idMemberRaw;

    bool isActive = membership != null;

    int sisaHari = 0;
    if (isActive && membership['tanggal_berakhir'] != null) {
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
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D47A1).withOpacity(0.5),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background accents
          Positioned(
            right: -50,
            top: -50,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: Colors.white.withOpacity(0.05),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: CircleAvatar(
              radius: 70,
              backgroundColor: Colors.white.withOpacity(0.05),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "GYMKU MEMBER",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.fitness_center,
                      color: Colors.white.withOpacity(0.8),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  idMember,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    letterSpacing: 6,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "CARD HOLDER",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nama.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive ? Colors.green : Colors.red,
                        ),
                      ),
                      child: Text(
                        isActive ? "ACTIVE" : "INACTIVE",
                        style: TextStyle(
                          color: isActive ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDetails() {
    final user = _profileData?['user'];
    final membership = _profileData?['membership'];

    String email = user?['email'] ?? '-';
    String telepon = user?['hp'] ?? '-';
    String gender = user?['jenis_kelamin'] ?? '-';
    String alamat = user?['alamat'] ?? '-';
    
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

    String tanggalBerakhirFormatted = "-";
    if (membership != null && membership['tanggal_berakhir'] != null) {
      try {
        final endDate = DateTime.parse(membership['tanggal_berakhir']).toLocal();
        tanggalBerakhirFormatted = DateFormat("dd MMMM yyyy").format(endDate);
      } catch (e) {
        tanggalBerakhirFormatted = "-";
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Account Details",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _detailRow(Icons.email_outlined, "Email", email),
          _divider(),
          _detailRow(Icons.phone_outlined, "Phone", telepon),
          _divider(),
          _detailRow(Icons.calendar_today_outlined, "Date of Birth", tglLahirFormatted),
          _divider(),
          _detailRow(Icons.person_outline, "Gender", gender),
          _divider(),
          _detailRow(Icons.location_on_outlined, "Address", alamat),
          _divider(),
          _detailRow(Icons.date_range, "Valid Until", tanggalBerakhirFormatted, isHighlight: true),
        ],
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(color: Colors.white.withOpacity(0.1), height: 1),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {bool isHighlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: isHighlight ? const Color(0xFF2196F3) : Colors.grey.shade500, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: isHighlight ? const Color(0xFF2196F3) : Colors.white,
                  fontSize: 15,
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
