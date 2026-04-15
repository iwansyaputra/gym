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
        title: const Text('Pembayaran Berhasil'),
        content: const Text('Membership Anda telah aktif. Selamat berlatih!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(
                context,
              ).pop(true); // Return to previous page with success
            },
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
        title: const Text('Status Pending'),
        content: const Text(
          'Pembayaran Anda sedang diproses. Silakan selesaikan pembayaran.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              _isPendingDialogOpen = false;
              Navigator.of(context).pop(); // Close dialog
              // Jangan pop page, biarkan user menyelesaikan di webview
            },
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
        title: const Text('Pembayaran Gagal'),
        content: const Text(
          'Transaksi belum berhasil. Silakan coba lagi atau pilih metode lain.',
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
        title: const Text('Terjadi Kesalahan'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(false); // Return to previous page
            },
            child: const Text('Kembali'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Smartlink Payment'),
        backgroundColor: const Color(0xFFE26D88), // Warna tema
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(color: Color(0xFFE26D88)),
                  SizedBox(height: 16),
                  Text('Menyiapkan halaman pembayaran...'),
                ],
              ),
            )
          : _paymentUrl == null
          ? const Center(child: Text('Gagal memuat halaman pembayaran'))
          : kIsWeb
          ? _buildWebFallback()
          : _webViewController != null
          ? WebViewWidget(controller: _webViewController!)
          : const Center(child: Text('Menyiapkan WebView...')),
    );
  }

  Widget _buildWebFallback() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.open_in_browser, size: 64, color: Color(0xFFE26D88)),
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
              backgroundColor: const Color(0xFFE26D88),
              foregroundColor: Colors.white,
            ),
            child: const Text('Buka Halaman Pembayaran'),
          ),
        ],
      ),
    );
  }
}
