import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/payment_service.dart';

class PaymentPage extends StatefulWidget {
  final String paket;
  final int harga;

  const PaymentPage({super.key, required this.paket, required this.harga});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isLoading = true;
  String? _paymentUrl;
  String? _orderId;
  bool _isResultHandled = false;
  bool _isPendingDialogOpen = false;
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _initializePayment();
  }

  Future<void> _initializePayment() async {
    try {
      final result = await PaymentService.createPayment(
        paket: widget.paket,
        harga: widget.harga,
      );

      if (result['success']) {
        final paymentData = result['data'] as Map<String, dynamic>;
        final paymentUrl =
            paymentData['payment_url'] ?? paymentData['redirect_url'];

        if (paymentUrl == null || paymentUrl.toString().isEmpty) {
          _showError('Payment URL tidak tersedia dari server.');
          return;
        }

        if (!kIsWeb) {
          _webViewController = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setNavigationDelegate(
              NavigationDelegate(
                onPageStarted: (String url) {
                  print('Page started loading: $url');
                },
                onPageFinished: (String url) {
                  print('Page finished loading: $url');
                  _checkPaymentStatus(url);
                },
                onWebResourceError: (WebResourceError error) {
                  print('Web resource error: ${error.description}');
                },
              ),
            )
            ..loadRequest(Uri.parse(paymentUrl.toString()));
        }

        setState(() {
          _paymentUrl = paymentUrl.toString();
          _orderId = paymentData['order_id']?.toString();
          _isLoading = false;
        });
      } else {
        _showError(result['message']);
      }
    } catch (e) {
      _showError('Gagal membuat pembayaran: $e');
    }
  }

  void _checkPaymentStatus(String url) {
    if (_isResultHandled) return;

    // Check if payment is finished based on URL callback
    if (url.contains('/payment/finish') || url.contains('status=SUCCESS')) {
      _isResultHandled = true;
      _handlePaymentSuccess();
    } else if (url.contains('/payment/error') || url.contains('status=FAILED')) {
      _isResultHandled = true;
      _handlePaymentFailed();
    } else if (url.contains('status=PENDING')) {
      _handlePaymentPending();
    } else if (url.contains('/payment/pending')) {
      _handlePaymentPending();
    }
  }

  Future<void> _handlePaymentSuccess() async {
    // Beri waktu callback gateway diproses server
    await Future.delayed(const Duration(seconds: 2));

    if (_orderId != null) {
      await PaymentService.checkPaymentStatus(_orderId!);
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pembayaran Berhasil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Membership Anda telah aktif. Selamat berlatih!', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(
                context,
              ).pop(true); // Return to previous page with success
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF2196F3)),
            child: const Text('Mantap!'),
          ),
        ],
      ),
    );
  }

  void _handlePaymentPending() {
    if (!mounted || _isPendingDialogOpen) return;
    _isPendingDialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Status Pending', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Pembayaran Anda sedang diproses. Silakan selesaikan pembayaran.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _isPendingDialogOpen = false;
              Navigator.of(context).pop(); // Close dialog
              // Jangan pop page, biarkan user menyelesaikan di webview
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF2196F3)),
            child: const Text('Lanjut Bayar'),
          ),
          TextButton(
            onPressed: () {
              _isPendingDialogOpen = false;
              Navigator.of(context).pop();
              Navigator.of(context).pop(false);
            },
            child: const Text('Tutup', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handlePaymentFailed() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pembayaran Gagal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Transaksi belum berhasil. Silakan coba lagi atau pilih metode lain.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(false);
            },
            child: const Text('Tutup', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Terjadi Kesalahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(color: Colors.grey, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(false); // Return to previous page
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF2196F3)),
            child: const Text('Kembali'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text(
          'E-Smartlink Payment',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(color: Color(0xFF2196F3)),
                  SizedBox(height: 16),
                  Text('Menyiapkan halaman pembayaran...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : _paymentUrl == null
          ? const Center(child: Text('Gagal memuat halaman pembayaran', style: TextStyle(color: Colors.grey)))
          : kIsWeb
          ? _buildWebFallback()
          : _webViewController != null
          ? WebViewWidget(controller: _webViewController!)
          : const Center(child: Text('Menyiapkan WebView...', style: TextStyle(color: Colors.grey))),
    );
  }

  Widget _buildWebFallback() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.open_in_browser, size: 64, color: Color(0xFF1976D2)),
          const SizedBox(height: 16),
          const Text(
            'Mode Web Preview tidak mendukung WebView plugin.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Lanjutkan pembayaran dengan membuka halaman payment di tab browser.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final uri = Uri.parse(_paymentUrl!);
              await launchUrl(uri, mode: LaunchMode.platformDefault);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
            ),
            child: const Text('Buka Halaman Pembayaran'),
          ),
        ],
      ),
    );
  }
}
