import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/payment_service.dart';

/// Halaman Top Up Saldo via E-Smartlink (Virtual Account / QRIS)
/// Alur:
///   - Android Native : WebView embedded, deteksi redirect URL sukses → auto kredit
///   - Flutter Web    : Auto-launch browser tab + polling tiap 5 detik → auto kredit
/// Tidak ada popup/dialog — langsung kembali ke halaman sebelumnya saat sukses.
class TopUpPaymentPage extends StatefulWidget {
  final int jumlah;
  final String channel;

  const TopUpPaymentPage({super.key, required this.jumlah, required this.channel});

  @override
  State<TopUpPaymentPage> createState() => _TopUpPaymentPageState();
}

class _TopUpPaymentPageState extends State<TopUpPaymentPage> {
  bool _isLoading = true;
  String? _paymentUrl;
  String? _orderId;
  bool _isResultHandled = false;
  bool _isConfirming = false;
  WebViewController? _webViewController;

  // Auto-polling (Flutter Web — tidak ada WebView)
  Timer? _pollTimer;
  int _pollCount = 0;
  static const int _maxPollCount = 120; // max 10 menit

  @override
  void initState() {
    super.initState();
    _initializeTopUpPayment();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // ─── Inisialisasi: buat order dan langsung buka halaman payment ─────────────
  Future<void> _initializeTopUpPayment() async {
    try {
      final result = await PaymentService.createTopUpPayment(
        jumlah: widget.jumlah,
        channel: widget.channel,
      );

      if (result['success'] == true) {
        final paymentData = result['data'] as Map<String, dynamic>;
        final paymentUrl = paymentData['payment_url']?.toString() ??
            paymentData['redirect_url']?.toString();
        final orderId = paymentData['order_id']?.toString();

        if (paymentUrl == null || paymentUrl.isEmpty) {
          _showError('Payment URL tidak tersedia dari server.');
          return;
        }

        if (!kIsWeb) {
          // Android/iOS: tampilkan WebView embedded
          _webViewController = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setNavigationDelegate(
              NavigationDelegate(
                onPageStarted: (url) => debugPrint('[TopUp] Load: $url'),
                onPageFinished: (url) {
                  debugPrint('[TopUp] Done: $url');
                  _onUrlChanged(url);
                },
                onWebResourceError: (err) =>
                    debugPrint('[TopUp] Error: ${err.description}'),
              ),
            )
            ..loadRequest(Uri.parse(paymentUrl));
        }

        setState(() {
          _paymentUrl = paymentUrl;
          _orderId = orderId;
          _isLoading = false;
        });

        if (kIsWeb && orderId != null) {
          // Flutter Web: langsung buka browser tab dan mulai polling
          await launchUrl(Uri.parse(paymentUrl), mode: LaunchMode.externalApplication);
          _startPolling();
        }
      } else {
        _showError(result['message'] ?? 'Gagal membuat pembayaran');
      }
    } catch (e) {
      _showError('Gagal inisialisasi pembayaran: $e');
    }
  }

  // ─── Deteksi URL sukses/gagal dari WebView (Android) ────────────────────────
  void _onUrlChanged(String url) {
    if (_isResultHandled || _isConfirming) return;

    final uri = Uri.tryParse(url);
    final isSuccess = url.contains('/payment/finish') ||
        url.contains('status=SUCCESS') ||
        url.contains('payment_status=success') ||
        url.contains('api.gymku.motalindo.com/api/payment/finish') ||
        (uri?.queryParameters['status']?.toUpperCase() == 'SUCCESS');

    final isFailed = url.contains('/payment/error') ||
        url.contains('status=FAILED') ||
        url.contains('payment_status=failed') ||
        url.contains('api.gymku.motalindo.com/api/payment/error');

    if (isSuccess) {
      _isResultHandled = true;
      _confirmAndCredit();
    } else if (isFailed) {
      _isResultHandled = true;
      _onPaymentFailed();
    }
  }

  // ─── Polling tiap 5 detik (Flutter Web) ─────────────────────────────────────
  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted || _isResultHandled || _pollCount >= _maxPollCount) {
        _pollTimer?.cancel();
        return;
      }
      _pollCount++;
      await _pollOnce();
    });
  }

  Future<void> _pollOnce() async {
    if (_orderId == null || _isResultHandled || _isConfirming) return;

    final result = await PaymentService.confirmTopUpPayment(orderId: _orderId!);

    if (result['success'] == true) {
      _isResultHandled = true;
      _pollTimer?.cancel();
      if (mounted) _onPaymentSuccess();
    } else if (result['pending'] == true) {
      debugPrint('[TopUp Poll] #$_pollCount masih pending...');
    }
    // Error lain: lanjut polling sampai timeout
  }

  // ─── Konfirmasi ke backend (dari WebView Android) ────────────────────────────
  Future<void> _confirmAndCredit() async {
    if (_orderId == null) return;

    setState(() => _isConfirming = true);
    await Future.delayed(const Duration(seconds: 2)); // beri jeda E-Smartlink proses

    final result = await PaymentService.confirmTopUpPayment(orderId: _orderId!);

    if (!mounted) return;
    setState(() => _isConfirming = false);

    if (result['success'] == true || result['pending'] == true) {
      _onPaymentSuccess();
    } else {
      _onPaymentFailed();
    }
  }

  // ─── Navigasi kembali langsung (tanpa popup) ─────────────────────────────────
  void _onPaymentSuccess() {
    if (!mounted) return;
    Navigator.of(context).pop(true); // parent akan refresh saldo + tampil SnackBar
  }

  void _onPaymentFailed() {
    if (!mounted) return;
    Navigator.of(context).pop(false);
  }

  // ─── Error saat membuat order (sebelum VA terbuka) ───────────────────────────
  void _showError(String message) {
    setState(() => _isLoading = false);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Terjadi Kesalahan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(message,
            style: const TextStyle(color: Colors.grey, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(false);
            },
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2196F3)),
            child: const Text('Kembali'),
          ),
        ],
      ),
    );
  }

  String _formatRupiah(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  // ─── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text(
          'Top Up ${_formatRupiah(widget.jumlah)}',
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        // Cegah user kembali saat proses pembayaran berjalan (belum bayar)
        automaticallyImplyLeading: !_isLoading,
        leading: _isLoading
            ? const SizedBox.shrink()
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(false),
                tooltip: 'Batalkan',
              ),
      ),
      body: Stack(
        children: [
          // ── Konten utama ──
          if (_isLoading)
            _buildLoadingScreen()
          else if (kIsWeb)
            _buildWebWaitingScreen()
          else if (_webViewController != null)
            WebViewWidget(controller: _webViewController!),

          // ── Overlay konfirmasi (saat WebView sudah detect sukses, Android) ──
          if (_isConfirming)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF2196F3)),
                    SizedBox(height: 20),
                    Text(
                      'Mengkredit saldo...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Loading awal saat membuat order ke backend ────────────────────────────────
  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF2196F3)),
          SizedBox(height: 20),
          Text(
            'Menyiapkan Virtual Account...',
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ],
      ),
    );
  }

  // ── Layar tunggu untuk Flutter Web (setelah browser tab terbuka) ─────────────
  Widget _buildWebWaitingScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon wallet animasi
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2196F3).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Color(0xFF2196F3),
                size: 44,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Menunggu Pembayaran',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Halaman Virtual Account sudah dibuka di browser.\nSelesaikan pembayaran — saldo akan otomatis\nmasuk tanpa perlu menekan tombol apapun.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 36),

            // Indikator polling
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Memeriksa status pembayaran...',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Tombol buka ulang jika browser tertutup tidak sengaja
            TextButton.icon(
              onPressed: _paymentUrl != null
                  ? () => launchUrl(
                        Uri.parse(_paymentUrl!),
                        mode: LaunchMode.externalApplication,
                      )
                  : null,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Buka Ulang Halaman Bayar'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
