import 'package:flutter/material.dart';
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
  late WebViewController _webViewController;

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
        setState(() {
          _paymentUrl = result['data']['redirect_url'];
          _isLoading = false;
        });

        // Initialize WebView Controller
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
          ..loadRequest(Uri.parse(_paymentUrl!));
      } else {
        _showError(result['message']);
      }
    } catch (e) {
      _showError('Gagal membuat pembayaran: $e');
    }
  }

  void _checkPaymentStatus(String url) {
    // Check if payment is finished based on URL callback
    if (url.contains('/payment/finish') || url.contains('status_code=200')) {
      _handlePaymentSuccess();
    } else if (url.contains('/payment/error') ||
        url.contains('status_code=201')) {
      // 201 biasanya pending di Midtrans Snap
      _handlePaymentPending();
    } else if (url.contains('/payment/pending')) {
      _handlePaymentPending();
    }
  }

  Future<void> _handlePaymentSuccess() async {
    // Wait a bit to ensure webhook is processed
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Pembayaran Berhasil! 🥳'),
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
    if (!mounted) return;

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
              Navigator.of(context).pop(); // Close dialog
              // Jangan pop page, biarkan user menyelesaikan di webview
            },
            child: const Text('Lanjut Bayar'),
          ),
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
        title: const Text('Midtrans Payment'),
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
          : _paymentUrl != null
          ? WebViewWidget(controller: _webViewController)
          : const Center(child: Text('Gagal memuat halaman pembayaran')),
    );
  }
}
