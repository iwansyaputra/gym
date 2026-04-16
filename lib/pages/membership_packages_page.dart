import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'payment.dart';

class MembershipPackagesPage extends StatefulWidget {
  const MembershipPackagesPage({super.key});

  @override
  State<MembershipPackagesPage> createState() => _MembershipPackagesPageState();
}

class _MembershipPackagesPageState extends State<MembershipPackagesPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _packages = const [
    {
      'slug': 'bulanan',
      'title': 'Bulanan',
      'price': 250000,
      'duration': '30 Hari',
      'features': [
        'Akses semua alat gym',
        'Akses ruang cardio',
        'Loker pribadi',
        'Shower & toilet',
        'Free WiFi',
      ],
      'color': 0xFF00D4FF,
      'isPopular': false,
      'discount': null,
    },
    {
      'slug': 'tahunan',
      'title': 'Tahunan',
      'price': 2500000,
      'duration': '365 Hari',
      'features': [
        'Semua benefit Bulanan',
        'Free 1x personal training',
        'Diskon 20% merchandise',
        'Priority booking class',
        'Guest pass 2x/bulan',
      ],
      'color': 0xFFFFD700,
      'isPopular': true,
      'discount': '2 bulan gratis!',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    final result = await ApiService.getMembershipPackages();

    if (!mounted) return;

    if (result['success'] == true && result['data'] is List) {
      final rawList = (result['data'] as List).cast<dynamic>();
      final parsed = <Map<String, dynamic>>[];

      for (final item in rawList) {
        if (item is! Map) continue;
        final data = Map<String, dynamic>.from(item as Map);
        final nama = (data['nama'] ?? '').toString().toLowerCase();

        if (nama.contains('bulanan')) {
          parsed.add({
            'slug': 'bulanan',
            'title': 'Bulanan',
            'price': _asInt(data['harga']) ?? 250000,
            'duration': '${_asInt(data['durasi']) ?? 30} Hari',
            'features': _toStringList(data['fitur']),
            'color': 0xFF00D4FF,
            'isPopular': false,
            'discount': null,
          });
        } else if (nama.contains('tahunan')) {
          parsed.add({
            'slug': 'tahunan',
            'title': 'Tahunan',
            'price': _asInt(data['harga']) ?? 2500000,
            'duration': '${_asInt(data['durasi']) ?? 365} Hari',
            'features': _toStringList(data['fitur']),
            'color': 0xFFFFD700,
            'isPopular': true,
            'discount': '2 bulan gratis!',
          });
        }
      }

      if (parsed.isNotEmpty) {
        parsed.sort(
          (a, b) => (a['slug'] == 'bulanan' ? 0 : 1).compareTo(
            b['slug'] == 'bulanan' ? 0 : 1,
          ),
        );
        _packages = parsed;
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  List<String> _toStringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paket Membership'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Color(0xFF1a1a1a)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Paket Membership',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Dapatkan akses penuh ke semua fasilitas gym',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 32),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _packages.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 20),
                          itemBuilder: (context, index) {
                            final item = _packages[index];
                            return _buildPackageCard(
                              context: context,
                              title: item['title'] as String,
                              price: item['price'] as int,
                              duration: item['duration'] as String,
                              slug: item['slug'] as String,
                              features: (item['features'] as List<String>),
                              color: Color(item['color'] as int),
                              isPopular: item['isPopular'] as bool,
                              discount: item['discount'] as String?,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPackageCard({
    required BuildContext context,
    required String title,
    required String slug,
    required int price,
    required String duration,
    required List<String> features,
    required Color color,
    required bool isPopular,
    String? discount,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPopular ? color : color.withOpacity(0.3),
          width: isPopular ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    if (discount != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          discount,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  duration,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rp ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _formatPrice(price),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Benefit:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                ...features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: color, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handlePayment(context, slug, price),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Pilih Paket',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isPopular)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
                child: const Text(
                  'POPULER',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Future<void> _handlePayment(
    BuildContext context,
    String paket,
    int harga,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text(
          'Konfirmasi Pembayaran',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Anda akan membeli paket $paket seharga Rp ${_formatPrice(harga)}. Lanjutkan ke pembayaran?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4FF),
              foregroundColor: Colors.black,
            ),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPage(paket: paket, harga: harga),
        ),
      );

      if (result == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran berhasil! Membership Anda sudah aktif.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        Navigator.pop(context, true);
      }
    }
  }
}
