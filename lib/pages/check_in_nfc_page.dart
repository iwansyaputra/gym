import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nfc_host_card_emulation/nfc_host_card_emulation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import 'membership_packages_page.dart';

/// CheckInNfcPage — HCE mode untuk semua merek HP Android
///
/// Perbaikan cross-device:
///   - HCE diinisialisasi OTOMATIS saat kartu berhasil dimuat (bukan saat tombol ditekan)
///   - Dengan begitu HP sudah siap merespons reader ACR122U sebelum user tap tombol
///   - Bekerja di Huawei, Oppo, Samsung, Xiaomi, Vivo, dll.
class CheckInNfcPage extends StatefulWidget {
  const CheckInNfcPage({super.key});

  @override
  State<CheckInNfcPage> createState() => _CheckInNfcPageState();
}

class _CheckInNfcPageState extends State<CheckInNfcPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String statusText = 'Memuat data kartu...';
  bool isLoading = true;
  bool isCardLoaded = false;
  bool isActive = false; // true = HCE sudah aktif, siap di-tap

  final int _port = 0;
  String nfcPayload = '';
  static const _channel = MethodChannel('com.motalindo.gymku/hce');

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(_pulseController);

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onHceTapped') {
        debugPrint('[HCE] Native APDU tapped received!');
        if (!isCardLoaded) return;
        if (mounted) {
          setState(() {
            statusText =
                'Kartu terkirim ke reader! ✅\nCheck-in dicatat oleh sistem.';
          });
          _showSuccessSnackBar();
        }
      }
      return null;
    });

    _loadUserCard();
  }

  // ── Load kartu & langsung inisialisasi HCE ─────────────────────────────────
  Future<void> _loadUserCard() async {
    if (mounted)
      setState(() {
        isLoading = true;
        isCardLoaded = false;
      });

    try {
      final result = await ApiService.getProfile();

      String? payload;
      bool memberActive = false;

      if (result['success'] == true && result['data'] != null) {
        final card = result['data']['card'];
        final user = result['data']['user'];
        final m = result['data']['membership'];

        memberActive = (m != null && m['status'] == 'active');

        if (memberActive) {
          if (card != null && card['nfc_id'] != null) {
            payload = card['nfc_id'].toString();
          } else if (user != null && user['id'] != null) {
            payload = user['id'].toString();
          }
        }
      } else {
        // Fallback local storage
        final local = await AuthStorage.getUserData();
        memberActive = local?['membershipStatus'] == 'Active';
        if (memberActive) {
          final cn = local?['cardNumber'];
          if (cn != null && cn.isNotEmpty && cn != '-') payload = cn;
        }
      }

      if (!memberActive) {
        if (mounted) {
          setState(() {
            isLoading = false;
            isCardLoaded = false;
            statusText =
                'Membership tidak aktif.\nSilakan beli paket terlebih dahulu.';
          });
          _showFailureSnackBar('Membership tidak aktif. Silakan beli paket terlebih dahulu.');
          _showMembershipDialog();
        }
        return;
      }

      if (payload == null || payload.isEmpty) {
        if (mounted) {
          setState(() {
            isLoading = false;
            statusText = 'Data kartu tidak ditemukan.\nHubungi admin gym.';
          });
          _showFailureSnackBar('Data kartu NFC tidak ditemukan. Hubungi admin gym.');
        }
        return;
      }

      nfcPayload = payload;

      // Simpan payload secara offline untuk Native HCE
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nfc_payload', nfcPayload);
      await prefs.setBool('nfc_active', false); // Default: belum aktif scan

      if (mounted) {
        setState(() {
          isLoading = false;
          isCardLoaded = true;
          isActive = false; // Harus tekan tombol dulu untuk scan
          statusText = 'Kartu Siap ✅\nTekan tombol di bawah untuk mulai scan';
        });
      }
    } catch (e) {
      debugPrint('[NFC] _loadUserCard error: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          statusText = 'Gagal memuat kartu.\nPastikan koneksi internet aktif.';
        });
        _showFailureSnackBar('Gagal memuat kartu. Pastikan koneksi internet aktif.');
      }
    }
  }

  Future<bool> _initHce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nfc_payload', nfcPayload);
      await prefs.setBool('nfc_active', true);
      debugPrint('[HCE] HCE activated in SharedPreferences.');

      final nfcState = await NfcHce.checkDeviceNfcState();
      debugPrint('[HCE] Device NFC State check: $nfcState');
      if (nfcState == NfcState.disabled) {
        if (mounted) {
          setState(() {
            statusText = 'NFC tidak aktif.\nAktifkan NFC di Pengaturan HP Anda.';
          });
          _showFailureSnackBar('NFC tidak aktif. Aktifkan NFC di Pengaturan HP Anda.');
        }
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('[HCE] _initHce error: $e');
      return true;
    }
  }

  Future<void> _onTapActivate() async {
    if (!isCardLoaded) return;

    if (isActive) {
      // Matikan
      setState(() => statusText = 'Menonaktifkan kartu NFC...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('nfc_active', false);
      if (mounted) {
        setState(() {
          isActive = false;
          statusText = 'Kartu Siap ✅\nTekan tombol di bawah untuk mulai scan';
        });
      }
    } else {
      // Aktifkan
      setState(() => statusText = 'Mengaktifkan kartu NFC...');
      final ok = await _initHce();
      if (mounted) {
        setState(() {
          isActive = ok;
          if (ok) {
            statusText = 'Kartu Aktif ✅\nTempelkan HP ke NFC Reader di Gate Gym';
          }
        });
      }
    }
  }

  // ── Notifikasi SnackBar ───────────────────────────────────────────────────

  void _showSuccessSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        backgroundColor: const Color(0xFF1B5E20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.green.shade400.withOpacity(0.5), width: 1),
        ),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade400.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.greenAccent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Check-in Berhasil! 🎉',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Kartu NFC berhasil terbaca oleh reader gym.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFailureSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        backgroundColor: const Color(0xFF7F0000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.red.shade400.withOpacity(0.5), width: 1),
        ),
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade400.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_rounded,
                color: Colors.redAccent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Check-in Gagal ❌',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMembershipDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 26),
              SizedBox(width: 10),
              Text(
                'Akses Ditolak',
                style: TextStyle(color: Colors.white, fontSize: 17),
              ),
            ],
          ),
          content: const Text(
            'Anda belum memiliki membership aktif atau masa aktif sudah habis. '
            'Silakan beli paket untuk melakukan check-in.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text(
                'Kembali',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MembershipPackagesPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Beli Member',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('nfc_active', false);
    }).catchError((e) => debugPrint('[HCE] Clear active on dispose error: $e'));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'Check In NFC',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: isLoading ? null : _loadUserCard,
            tooltip: 'Refresh kartu',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2196F3)),
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Animasi ikon NFC ──────────────────────────────────────────────
            ScaleTransition(
              scale: isActive
                  ? _pulseAnimation
                  : const AlwaysStoppedAnimation(1.0),
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? const Color(0xFF2196F3).withOpacity(0.12)
                      : const Color(0xFF1A1A1A),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF2196F3).withOpacity(0.6)
                        : Colors.white.withOpacity(0.06),
                    width: 2,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2196F3).withOpacity(0.28),
                            blurRadius: 50,
                            spreadRadius: 18,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  Icons.nfc_rounded,
                  size: 95,
                  color: isActive
                      ? const Color(0xFF2196F3)
                      : Colors.grey.withOpacity(0.35),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ── Status text ───────────────────────────────────────────────────
            Text(
              statusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : Colors.grey.shade400,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 32),

            // ── Badge NFC ID ──────────────────────────────────────────────────
            if (isCardLoaded && nfcPayload.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.07)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      size: 15,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ID: $nfcPayload',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 52),

            // ── Tombol Aktifkan/Refresh ───────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isCardLoaded ? _onTapActivate : null,
                icon: const Icon(Icons.nfc_rounded),
                label: Text(
                  isActive ? 'Segarkan Kartu NFC' : 'Aktifkan Kartu NFC',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  disabledBackgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Catatan teknis ────────────────────────────────────────────────
            Text(
              'AID: A0 00 DA DA DA DA DA\nHP berfungsi sebagai kartu NFC virtual — tap ke reader ACR122U',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.18),
                fontSize: 10,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
