import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nfc_host_card_emulation/nfc_host_card_emulation.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';

/// Halaman Check-in dengan NFC - User dapat scan kartu NFC mereka di reader gym
/// Flow: Reader NFC scan kartu -> Kirim NFC ID ke API -> API verify membership & check-in
/// Jika sukses: tampilkan "Check-in Berhasil" -> kembali ke Beranda
class CheckInNfcPage extends StatefulWidget {
  const CheckInNfcPage({super.key});

  @override
  State<CheckInNfcPage> createState() => _CheckInNfcPageState();
}

class _CheckInNfcPageState extends State<CheckInNfcPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  String statusText =
      "Tap tombol untuk mulai scan NFC"; // Status text yang ditampilkan
  bool isScanning = false; // Apakah sedang scan?
  bool apduAdded = false; // Apakah APDU sudah ditambahkan?

  final port = 0;
  String nfcPayload = "LOADING..."; // ID yang akan dipancarkan/dikirim
  List<int> nfcData = [];
  bool isCardLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUserCard();

    // Setup animasi untuk pulsing effect tombol
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.85, end: 1.15).animate(_controller);

    /// Listen untuk command dari reader NFC eksternal
    /// Saat reader scan kartu, akan trigger listener ini
    NfcHce.stream.listen((command) {
      if (!isCardLoaded) return;

      setState(() {
        statusText = "Reader terhubung! Mengirim Kartu Member...";
      });

      // Kirim check-in request ke API dengan Member Card ID kita
      _sendCheckIn(nfcPayload);
    });
  }

  Future<void> _loadUserCard() async {
    try {
      // 1. Coba ambil dari AuthStorage (Local) - Lebih Cepat
      final localData = await AuthStorage.getUserData();
      if (localData != null && localData['cardNumber'] != null) {
        setState(() {
          nfcPayload =
              localData['cardNumber']!; // Gunakan Card Number sebagai ID
          isCardLoaded = true;
          statusText =
              "Kartu Siap: $nfcPayload\n(Tap tombol untuk pancarkan sinyal)";
        });
      } else {
        // 2. Jika local kosong, coba ambil dari API
        final result = await ApiService.getProfile();
        if (result['success'] == true && result['data']['card'] != null) {
          setState(() {
            nfcPayload = result['data']['card']['card_number'];
            isCardLoaded = true;
            statusText =
                "Kartu Siap: $nfcPayload\n(Tap tombol untuk pancarkan sinyal)";
          });
        } else {
          setState(() {
            statusText = "Kartu Member belum aktif / tidak ditemukan.";
          });
        }
      }
    } catch (e) {
      print("Error loading card: $e");
      setState(() {
        // Fallback jika error, gunakan ID default atau kosong
        statusText = "Gagal memuat kartu. Pastikan Anda login.";
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Convert ID string → bytes untuk transmit NFC
  List<int> convertIdToBytes(String id) {
    return Uint8List.fromList(id.codeUnits);
  }

  /// Method untuk send check-in ke API
  /// Input: NFC ID dari pembaca
  /// Proses:
  /// 1. Call ApiService.checkInNfc(nfcId)
  /// 2. Jika berhasil: tampilkan success message & kembali ke beranda setelah 2 detik
  /// 3. Jika gagal: tampilkan error message dan tetap di halaman check-in
  Future<void> _sendCheckIn(String nfcId) async {
    // Call API untuk check-in
    final result = await ApiService.checkInNfc(nfcId: nfcId);

    // Update UI hanya jika widget masih mounted (tidak ditutup)
    if (mounted) {
      if (result['success'] == true) {
        // Update status text
        setState(() {
          statusText = "Check-in berhasil! Selamat berlatih 💪";
        });

        // Tampilkan snackbar sukses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Check-in berhasil!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Kembali ke halaman beranda setelah 2 detik
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } else {
        // Check-in gagal, tampilkan error message
        setState(() {
          statusText = result['message'] ?? 'Check-in gagal';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Check-in gagal'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  /// Method untuk mulai scan NFC
  /// Proses: Check NFC state -> Init NFC HCE -> Listen untuk card
  void startScan() async {
    if (isScanning) return;

    // Set status ke "scanning"
    setState(() {
      isScanning = true;
      statusText = "Menyiapkan NFC...";
    });

    // Cek apakah NFC aktif di device
    final nfcState = await NfcHce.checkDeviceNfcState();

    if (nfcState != NfcState.enabled) {
      // NFC tidak aktif, tampilkan error
      setState(() {
        statusText = "NFC tidak aktif. Aktifkan NFC terlebih dahulu.";
        isScanning = false;
      });
      return;
    }

    // Initialize NFC HCE (Host Card Emulation)
    await NfcHce.init(
      aid: Uint8List.fromList([0xA0, 0x00, 0xDA, 0xDA, 0xDA, 0xDA, 0xDA]),
      permanentApduResponses: true,
      listenOnlyConfiguredPorts: false,
    );

    // Siapkan data ID
    nfcData = convertIdToBytes(nfcPayload);

    // Tambah APDU response
    if (!apduAdded) {
      await NfcHce.addApduResponse(port, nfcData);
      apduAdded = true;
    }

    setState(() {
      statusText = "Tempelkan kartu/handphone ke reader NFC...";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF1F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE26D88),
        title: const Text("Check In Member (NFC)"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _animation,
                child: const Icon(
                  Icons.nfc_rounded,
                  size: 150,
                  color: Color(0xFFE26D88),
                ),
              ),
              const SizedBox(height: 40),

              /// STATUS TEXT
              Text(
                statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 60),

              /// BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: startScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE26D88),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "Mulai Scan NFC",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Info Teknis Reader:\nAID: A000DADADADADA", // Hex of payload
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
