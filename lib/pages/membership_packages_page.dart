import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'payment.dart';
import '../widgets/payment_channel_sheet.dart';

class MembershipPackagesPage extends StatefulWidget {
  /// [useWallet] jika true, tombol "Pilih Paket" akan memotong saldo
  /// bukan redirect ke payment gateway
  final bool useWallet;
  const MembershipPackagesPage({super.key, this.useWallet = false});

  @override
  State<MembershipPackagesPage> createState() => _MembershipPackagesPageState();
}

class _MembershipPackagesPageState extends State<MembershipPackagesPage> {
  bool _isLoading = true;
  int _activePromoDiskon = 0;   // % diskon dari promo aktif (0 = tidak ada promo)
  String _activePromoJudul = '';
  int? _activePromoId;          // ID promo aktif untuk validasi di backend
  List<Map<String, dynamic>> _packages = const [
    {
      'slug': 'bulanan',
      'title': 'Bulanan',
      'price': 175000,
      'duration': '30 Hari',
      'features': [
        'Akses semua alat gym',
        'Akses ruang cardio',
        'Loker pribadi',
        'Shower & toilet',
        'Free WiFi',
      ],
      'color': 0xFF2196F3,
      'isPopular': false,
      'discount': null,
    },
    {
      'slug': '3bulan',
      'title': '3 Bulan',
      'price': 472500,
      'duration': '90 Hari',
      'features': [
        'Semua benefit Bulanan',
        'Free 1x personal training',
        'Diskon 10% (Hemat Rp 52.500)',
        'Priority booking class',
        'Guest pass 1x/bulan',
      ],
      'color': 0xFF1976D2,
      'isPopular': true,
      'discount': 'DISKON 10%',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadPackages();
    _loadActivePromo();  // Sinkronisasi diskon promo aktif
  }

  Future<void> _loadPackages() async {
    final result = await ApiService.getMembershipPackages();

    if (!mounted) return;

    if (result['success'] == true && result['data'] is List) {
      final rawList = (result['data'] as List).cast<dynamic>();
      final parsed = <Map<String, dynamic>>[];

      for (final item in rawList) {
        if (item is! Map) continue;
        final data = Map<String, dynamic>.from(item);
        final slug = (data['slug'] ?? '').toString();
        final title = (data['nama'] ?? '').toString().replaceAll('Paket ', '');
        final featuresList = _toStringList(data['fitur']);

        // Default popular tag if it's the 3 month or 6 month
        bool isPopular = slug.contains('3') || slug.contains('6');
        int colorHex = isPopular ? 0xFF1976D2 : 0xFF2196F3;
        String? discount = isPopular ? 'PILIHAN FAVORIT' : null;

        parsed.add({
          'slug': slug,
          'title': title,
          'price': _asInt(data['harga']) ?? 0,
          'duration': '${_asInt(data['durasi']) ?? 30} Hari',
          'features': featuresList,
          'color': colorHex,
          'isPopular': isPopular,
          'discount': discount,
          'sortValue': _asInt(data['harga']) ?? 0,
        });
      }

      if (parsed.isNotEmpty) {
        parsed.sort((a, b) => (a['sortValue'] as int).compareTo(b['sortValue'] as int));
        _packages = parsed;
      }
    }

    setState(() {
      _isLoading = false;
    });
  }
  // Ambil diskon promo aktif dari backend — dipanggil parallel dengan _loadPackages
  Future<void> _loadActivePromo() async {
    final result = await ApiService.getActivePromoDiscount();
    if (!mounted) return;
    final promoData = result['data'];
    if (promoData != null) {
      setState(() {
        _activePromoDiskon = (promoData['diskon_persen'] as num?)?.toInt() ?? 0;
        _activePromoJudul = promoData['judul']?.toString() ?? '';
        // Simpan ID promo agar bisa diteruskan ke backend saat checkout
        final rawId = promoData['id'];
        _activePromoId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
      });
    }
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
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text(
          'Paket Membership',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF2196F3)))
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih Paket\nMembership',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Dapatkan akses tak terbatas ke semua fasilitas dan kelas.',
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                    const SizedBox(height: 30),
                    Expanded(
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _packages.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 24),
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
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPopular ? color.withOpacity(0.8) : Colors.white.withOpacity(0.05),
          width: isPopular ? 2 : 1,
        ),
        boxShadow: isPopular
            ? [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
      ),
      child: Stack(
        children: [
          if (isPopular)
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                padding: const EdgeInsets.all(50),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.05),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: isPopular ? color : Colors.white,
                      ),
                    ),
                    if (discount != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          border: Border.all(color: Colors.red.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          discount,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  duration,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Harga asli dicoret jika ada promo diskon aktif
                        if (_activePromoDiskon > 0)
                          Text(
                            'Rp ${_formatPrice(price)}',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rp ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            Text(
                              _formatPrice(_activePromoDiskon > 0
                                  ? (price * (100 - _activePromoDiskon) ~/ 100)
                                  : price),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_activePromoDiskon > 0) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withOpacity(0.4)),
                        ),
                        child: Text(
                          '-$_activePromoDiskon%',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (_activePromoDiskon > 0 && _activePromoJudul.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '🏷 $_activePromoJudul',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade400,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Divider(color: Colors.white.withOpacity(0.1), height: 1),
                const SizedBox(height: 24),
                ...features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: isPopular ? color : Colors.grey.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Gunakan harga setelah diskon jika ada promo aktif
                      final finalPrice = _activePromoDiskon > 0
                          ? (price * (100 - _activePromoDiskon) ~/ 100)
                          : price;
                      _handlePayment(
                        context,
                        slug,
                        finalPrice,
                        promoId: _activePromoId,
                        packageData: _packages.firstWhere((p) => p['slug'] == slug, orElse: () => {}),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular ? color : const Color(0xFF2A2A2A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      widget.useWallet ? 'Bayar via Saldo' : 'Pilih Paket $title',
                      style: const TextStyle(
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
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: const Text(
                  'POPULER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
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
    int harga, {
    int? promoId,
    Map<String, dynamic> packageData = const {},
  }) async {
    // Mode bayar via saldo
    if (widget.useWallet) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Bayar via Saldo',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Saldo Anda akan dipotong Rp ${_formatPrice(harga)} untuk paket $paket.\nLanjutkan?',
            style: const TextStyle(color: Colors.grey, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Bayar Sekarang'),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;

      // Cari package_id dari data
      // fallback ke mapping manual jika id dari API kosong / null
      int? packageIdInt;
      final rawId = packageData['id'];
      if (rawId != null) {
        packageIdInt = rawId is int ? rawId : int.tryParse(rawId.toString());
      }
      if (packageIdInt == null) {
        // Fallback mapping slug to ID (sesuai package.json bawaan sistem)
        if (paket == 'bulanan') {
          packageIdInt = 1;
        } else if (paket == '3bulan') packageIdInt = 2;
        else if (paket == '6bulan') packageIdInt = 3;
        else if (paket == 'tahunan') packageIdInt = 4;
      }

      if (packageIdInt == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal: ID paket tidak valid'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Kirim id paket dan promo_id aktif ke backend
      final result = await ApiService.extendWithWallet(
        packageId: packageIdInt,
        promoId: promoId, // TERUSKAN PROMO ID AGAR POTONG SALDO SESUAI DISKON
      );

      if (!context.mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Membership berhasil diperpanjang!'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal membayar via saldo'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Mode bayar normal (payment gateway)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Konfirmasi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Anda akan membeli paket $paket seharga Rp ${_formatPrice(harga)}.\nLanjutkan pembayaran?',
          style: const TextStyle(color: Colors.grey, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final channel = await PaymentChannelSheet.show(context);
      if (channel == null || !context.mounted) return;

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPage(
            paket: paket,
            harga: harga,
            promoId: promoId, // teruskan promo_id agar backend bisa validasi
            channel: channel,
          ),
        ),
      );

      if (result == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran berhasil! Membership Anda sudah aktif.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context, true);
      }
    }
  }
}
