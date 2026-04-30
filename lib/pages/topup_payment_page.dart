import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/payment_service.dart';

/// Halaman Top Up Saldo via E-Smartlink (Virtual Account / QRIS)
/// Alur: langsung buka WebView → deteksi URL sukses → panggil confirmTopUp
/// ke backend → saldo dikreditkan tanpa bergantung webhook/callback.
class TopUpPaymentPage extends StatefulWidget {
  final int jumlah;

  const TopUpPaymentPage({super.key, required this.jumlah});

  @override
  State<TopUpPaymentPage> createState() => _TopUpPaymentPageState();
}

class _TopUpPaymentPageState extends State<TopUpPaymentPage> {
  bool _isLoading = true;
  String? _paymentUrl;
  String? _orderId;
  bool _isConfirming = false;
  bool _isResultHandled = false;
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _initializeTopUpPayment();
  }

  Future<void> _initializeTopUpPayment() async {
    try {
      final result =
          await PaymentService.createTopUpPayment(jumlah: widget.jumlah);

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
          _webViewController = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setNavigationDelegate(
              NavigationDelegate(
                onPageStarted: (url) => print('[TopUp] Load: $url'),
                onPageFinished: (url) {
                  print('[TopUp] Done: $url');
                  _onUrlChanged(url);
                },
                onWebResourceError: (err) =>
                    print('[TopUp] Error: ${err.description}'),
              ),
            )
            ..loadRequest(Uri.parse(paymentUrl));
        }

        setState(() {
          _paymentUrl = paymentUrl;
          _orderId = orderId;
          _isLoading = false;
        });
      } else {
        _showError(result['message'] ?? 'Gagal membuat pembayaran');
      }
    } catch (e) {
      _showError('Gagal inisialisasi pembayaran: $e');
    }
  }

  /// Deteksi URL yang mengindikasikan pembayaran sukses lalu konfirmasi ke backend
  void _onUrlChanged(String url) {
    if (_isResultHandled || _isConfirming) return;

    final uri = Uri.tryParse(url);
    final isSuccess = url.contains('/payment/finish') ||
        url.contains('status=SUCCESS') ||
        url.contains('payment_status=success') ||
        (uri?.queryParameters['status']?.toUpperCase() == 'SUCCESS');

    final isFailed = url.contains('/payment/error') ||
        url.contains('status=FAILED') ||
        url.contains('payment_status=failed');

    if (isSuccess) {
      _isResultHandled = true;
      _confirmAndCreditSaldo();
    } else if (isFailed) {
      _isResultHandled = true;
      _handlePaymentFailed();
    }
  }

  /// Panggil backend untuk kredit saldo setelah WebView sukses
  Future<void> _confirmAndCreditSaldo() async {
    if (_orderId == null) {
      _showError('Order ID tidak ditemukan.');
      return;
    }

    setState(() => _isConfirming = true);

    // Tunggu sebentar agar E-Smartlink selesai memproses dari sisi mereka
    await Future.delayed(const Duration(seconds: 2));

    final result =
        await PaymentService.confirmTopUpPayment(orderId: _orderId!);

    setState(() => _isConfirming = false);

    if (!mounted) return;

    if (result['success'] == true) {
      final saldoBaru = result['data']?['saldo_baru'];
      _showSuccessDialog(saldoBaru);
    } else {
      // Jika gagal konfirmasi, tetap tampilkan dialog sukses dengan pesan
      // bahwa saldo mungkin sedang diproses (bisa karena inquiry masih pending)
      _showSuccessDialog(null, pending: true);
    }
  }

  void _showSuccessDialog(dynamic saldoBaru, {bool pending = false}) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          pending ? '✅ Pembayaran Diterima' : '🎉 Top Up Berhasil!',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              pending ? Icons.check_circle_outline : Icons.check_circle,
              color: pending ? Colors.amber : Colors.green,
              size: 56,
            ),
            const SizedBox(height: 14),
            Text(
              pending
                  ? 'Pembayaran Anda sebesar ${_formatRupiah(widget.jumlah)} telah diterima.\nSaldo akan masuk dalam beberapa saat.'
                  : 'Saldo sebesar ${_formatRupiah(widget.jumlah)} berhasil ditambahkan!${saldoBaru != null ? '\n\nSaldo sekarang: ${_formatRupiah((saldoBaru as num).toInt())}' : ''}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, height: 1.5),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Tutup dialog
              Navigator.of(context).pop(true); // Kembali ke SaldoPage dengan result=true
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Lihat Saldo'),
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
        title: const Text(
          'Pembayaran Gagal',
          style:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Transaksi tidak berhasil. Silakan coba lagi.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(false);
            },
            child:
                const Text('Tutup', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

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
          style:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text(
          'Top Up ${_formatRupiah(widget.jumlah)}',
          style: const TextStyle(
              fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // WebView atau loading awal
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF2196F3)),
                  SizedBox(height: 16),
                  Text(
                    'Menyiapkan halaman pembayaran...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          else if (_paymentUrl == null)
            const Center(
              child: Text(
                'Gagal memuat halaman pembayaran',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else if (kIsWeb)
            _buildWebFallback()
          else if (_webViewController != null)
            WebViewWidget(controller: _webViewController!),

          // Overlay konfirmasi saldo (setelah WebView sukses)
          if (_isConfirming)
            Container(
              color: Colors.black.withOpacity(0.75),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF2196F3)),
                    SizedBox(height: 20),
                    Text(
                      'Mengkonfirmasi pembayaran\ndan mengkredit saldo...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWebFallback() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.open_in_browser,
              size: 64, color: Color(0xFF1976D2)),
          const SizedBox(height: 16),
          const Text(
            'Buka halaman pembayaran di browser.\nSetelah selesai, kembali ke aplikasi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final uri = Uri.parse(_paymentUrl!);
              await launchUrl(uri, mode: LaunchMode.platformDefault);
            },
            icon: const Icon(Icons.launch),
            label: const Text('Buka Halaman Pembayaran'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          // Tombol konfirmasi manual jika user sudah bayar di browser
          OutlinedButton.icon(
            onPressed: () {
              if (!_isResultHandled) {
                _isResultHandled = true;
                _confirmAndCreditSaldo();
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Saya Sudah Bayar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green),
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
