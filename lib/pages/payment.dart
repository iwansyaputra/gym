import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/payment_service.dart';

/// Halaman Pembayaran Membership via E-Smartlink
/// Alur:
///   - Android Native : WebView embedded, deteksi redirect URL → auto aktivasi membership
///   - Flutter Web    : Auto-launch browser tab + polling tiap 5 detik → auto aktivasi
/// Tidak ada popup/dialog — langsung kembali ke halaman sebelumnya saat sukses.
class PaymentPage extends StatefulWidget {
  final String paket;
  final int harga;
  final int? promoId;
  final String channel;

  const PaymentPage({
    super.key,
    required this.paket,
    required this.harga,
    this.promoId,
    required this.channel,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isLoading = true;
  String? _paymentUrl;
  String? _orderId;
  bool _isResultHandled = false;
  bool _isConfirming = false;
  WebViewController? _webViewController;

  // Polling (Flutter Web)
  Timer? _pollTimer;
  int _pollCount = 0;
  static const int _maxPollCount = 120; // max 10 menit

  @override
  void initState() {
    super.initState();
    _initializePayment();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // ─── Buat order dan langsung buka payment page ────────────────────────────────
  Future<void> _initializePayment() async {
    try {
      final result = await PaymentService.createPayment(
        paket: widget.paket,
        harga: widget.harga,
        promoId: widget.promoId,
        channel: widget.channel,
      );

      if (result['success'] == true) {
        final paymentData = result['data'] as Map<String, dynamic>;
        final paymentUrl =
            paymentData['payment_url']?.toString() ??
            paymentData['redirect_url']?.toString();
        final orderId = paymentData['order_id']?.toString();

        if (paymentUrl == null || paymentUrl.isEmpty) {
          _showError('Payment URL tidak tersedia dari server.');
          return;
        }

        if (!kIsWeb) {
          _webViewController = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setNavigationDelegate(
              NavigationDelegate(
                onPageStarted: (url) => debugPrint('[Pay] Load: $url'),
                onPageFinished: (url) {
                  debugPrint('[Pay] Done: $url');
                  _checkUrl(url);
                },
                onWebResourceError: (err) =>
                    debugPrint('[Pay] Error: ${err.description}'),
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
          // Flutter Web: langsung buka browser + start polling
          await launchUrl(Uri.parse(paymentUrl), mode: LaunchMode.externalApplication);
          _startPolling();
        }
      } else {
        _showError(result['message'] ?? 'Gagal membuat pembayaran');
      }
    } catch (e) {
      _showError('Gagal membuat pembayaran: $e');
    }
  }

  // ─── Deteksi URL sukses/gagal dari WebView (Android) ────────────────────────
  void _checkUrl(String url) {
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

    final isPending = url.contains('/payment/pending') ||
        url.contains('status=PENDING');

    if (isSuccess) {
      _isResultHandled = true;
      _handleSuccess();
    } else if (isFailed) {
      _isResultHandled = true;
      _onPaymentFailed();
    } else if (isPending) {
      // Pending: tampilkan SnackBar, WebView tetap terbuka
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pembayaran masih diproses, silakan selesaikan.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ─── Polling (Flutter Web) ────────────────────────────────────────────────────
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

    try {
      final result = await PaymentService.checkPaymentStatus(_orderId!);
      if (result['success'] == true) {
        final status = result['data']?['status']?.toString();
        if (status == 'success') {
          _isResultHandled = true;
          _pollTimer?.cancel();
          if (mounted) _onPaymentSuccess();
        } else if (status == 'failed') {
          _isResultHandled = true;
          _pollTimer?.cancel();
          if (mounted) _onPaymentFailed();
        }
        // pending: lanjut polling
      }
    } catch (_) {
      // network error sementara, lanjut polling
    }
  }

  // ─── Konfirmasi ke backend setelah WebView redirect (Android) ───────────────
  Future<void> _handleSuccess() async {
    setState(() => _isConfirming = true);
    await Future.delayed(const Duration(seconds: 3));

    if (_orderId != null) {
      await PaymentService.checkPaymentStatus(_orderId!);
    }

    if (!mounted) return;
    setState(() => _isConfirming = false);
    _onPaymentSuccess();
  }

  // ─── Navigasi tanpa popup ────────────────────────────────────────────────────
  void _onPaymentSuccess() {
    if (!mounted) return;
    Navigator.of(context).pop(true); // parent tampilkan SnackBar "Membership aktif"
  }

  void _onPaymentFailed() {
    if (!mounted) return;
    Navigator.of(context).pop(false);
  }

  // ─── Error membuat order ──────────────────────────────────────────────────────
  void _showError(String message) {
    setState(() => _isLoading = false);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Gagal Memuat Pembayaran',
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

  // ─── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text(
          'Bayar Paket ${widget.paket}',
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
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
          if (_isLoading)
            _buildLoadingScreen()
          else if (kIsWeb)
            _buildWebWaitingScreen()
          else if (_webViewController != null)
            WebViewWidget(controller: _webViewController!),

          // Overlay saat konfirmasi (Android, setelah WebView redirect sukses)
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
                      'Mengaktifkan membership...',
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

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF2196F3)),
          SizedBox(height: 20),
          Text(
            'Menyiapkan halaman pembayaran...',
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildWebWaitingScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                Icons.credit_card_rounded,
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
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Halaman pembayaran sudah dibuka di browser.\nSelesaikan pembayaran — membership akan\notomatis aktif tanpa perlu tombol apapun.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 36),
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
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
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
