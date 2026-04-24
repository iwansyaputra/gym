import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nfc_host_card_emulation/nfc_host_card_emulation.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';

class CheckInNfcPage extends StatefulWidget {
  const CheckInNfcPage({super.key});

  @override
  State<CheckInNfcPage> createState() => _CheckInNfcPageState();
}

class _CheckInNfcPageState extends State<CheckInNfcPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  String statusText = "Tap tombol untuk mulai scan NFC";
  bool isScanning = false;
  bool apduAdded = false;

  final port = 0;
  String nfcPayload = "LOADING...";
  List<int> nfcData = [];
  bool isCardLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUserCard();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.85, end: 1.15).animate(_controller);

    NfcHce.stream.listen((command) {
      if (!isCardLoaded) return;

      setState(() {
        statusText = "Reader terhubung!\nMengirim Kartu Member...";
      });

      _sendCheckIn(nfcPayload);
    });
  }

  Future<void> _loadUserCard() async {
    try {
      final localData = await AuthStorage.getUserData();
      if (localData != null && localData['nfc_id'] != null) {
        setState(() {
          nfcPayload = localData['nfc_id'].toString();
          isCardLoaded = true;
          statusText = "ID Member Siap: $nfcPayload\n(Tap tombol di bawah)";
        });
      } else {
        final result = await ApiService.getProfile();
        if (result['success'] == true && result['data']['user'] != null) {
          setState(() {
            nfcPayload = result['data']['user']['id'].toString();
            isCardLoaded = true;
            statusText = "ID Member Siap: $nfcPayload\n(Tap tombol di bawah)";
          });
        } else {
          setState(() {
            statusText = "ID Member belum aktif / tidak ditemukan.";
          });
        }
      }
    } catch (e) {
      setState(() {
        statusText = "Gagal memuat kartu. Pastikan Anda login.";
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<int> convertIdToBytes(String id) {
    return Uint8List.fromList(id.codeUnits);
  }

  Future<void> _sendCheckIn(String nfcId) async {
    final result = await ApiService.checkInNfc(nfcId: nfcId);

    if (mounted) {
      if (result['success'] == true) {
        setState(() {
          statusText = "Check-in berhasil! 💪";
        });

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

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } else {
        setState(() {
          statusText = result['message'] ?? 'Check-in gagal';
          isScanning = false;
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

  void startScan() async {
    if (isScanning || !isCardLoaded) return;

    setState(() {
      isScanning = true;
      statusText = "Menyiapkan NFC...";
    });

    final nfcState = await NfcHce.checkDeviceNfcState();

    if (nfcState != NfcState.enabled) {
      setState(() {
        statusText = "NFC tidak aktif.\nAktifkan NFC terlebih dahulu.";
        isScanning = false;
      });
      return;
    }

    await NfcHce.init(
      aid: Uint8List.fromList([0xA0, 0x00, 0xDA, 0xDA, 0xDA, 0xDA, 0xDA]),
      permanentApduResponses: true,
      listenOnlyConfiguredPorts: false,
    );

    nfcData = convertIdToBytes(nfcPayload);

    if (!apduAdded) {
      await NfcHce.addApduResponse(port, nfcData);
      apduAdded = true;
    }

    setState(() {
      statusText = "Tempelkan HP Anda\nke NFC Reader di Gate Gym";
    });
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
          "Check In Gate",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isScanning 
                      ? const Color(0xFF2196F3).withOpacity(0.1) 
                      : const Color(0xFF1A1A1A),
                  border: Border.all(
                    color: isScanning 
                        ? const Color(0xFF2196F3).withOpacity(0.5) 
                        : Colors.white.withOpacity(0.05),
                    width: 2,
                  ),
                  boxShadow: isScanning ? [
                    BoxShadow(
                      color: const Color(0xFF2196F3).withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 10,
                    )
                  ] : null,
                ),
                child: ScaleTransition(
                  scale: isScanning ? _animation : const AlwaysStoppedAnimation(1.0),
                  child: Icon(
                    Icons.nfc_rounded,
                    size: 100,
                    color: isScanning ? const Color(0xFF2196F3) : Colors.grey.withOpacity(0.5),
                  ),
                ),
              ),
              const SizedBox(height: 50),

              Text(
                statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 60),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isScanning || !isCardLoaded ? null : startScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    disabledBackgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: isScanning || !isCardLoaded 
                          ? BorderSide(color: Colors.white.withOpacity(0.1)) 
                          : BorderSide.none,
                    ),
                    elevation: isScanning ? 0 : 5,
                  ),
                  child: Text(
                    isScanning ? "Scanning..." : "Mulai Scan NFC",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                "Info Teknis Reader:\nAID: A000DADADADADA",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.2), 
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
