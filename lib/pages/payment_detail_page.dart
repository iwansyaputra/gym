import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/payment_service.dart';

/// Halaman detail transaksi — menampilkan:
/// - Nomor Virtual Account + tombol salin
/// - Bank tujuan transfer
/// - Cara pembayaran step-by-step
/// - Status & nominal tagihan
/// - Auto-refresh status tiap 5 detik jika pending
class PaymentDetailPage extends StatefulWidget {
  final Map<String, dynamic> transaction;

  const PaymentDetailPage({super.key, required this.transaction});

  @override
  State<PaymentDetailPage> createState() => _PaymentDetailPageState();
}

class _PaymentDetailPageState extends State<PaymentDetailPage> {
  late Map<String, dynamic> _tx;
  Timer? _refreshTimer;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tx = Map<String, dynamic>.from(widget.transaction);
    // Auto-refresh status jika masih pending
    if (_tx['status'] == 'pending') {
      _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) _refreshStatus();
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    if (_isRefreshing) return;
    final orderId = _tx['order_id']?.toString();
    if (orderId == null) return;

    setState(() => _isRefreshing = true);
    try {
      final result = await PaymentService.checkPaymentStatus(orderId);
      if (result['success'] == true && mounted) {
        final newStatus = result['data']?['status']?.toString();
        if (newStatus != null && newStatus != _tx['status']) {
          setState(() {
            _tx['status'] = newStatus;
          });
          if (newStatus == 'success') {
            _refreshTimer?.cancel();
            _showPaidSnackBar();
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isRefreshing = false);
  }

  void _showPaidSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Pembayaran dikonfirmasi! ✅'),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label disalin ke clipboard'),
        backgroundColor: const Color(0xFF1976D2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────
  String _formatCurrency(dynamic amount) {
    try {
      final value = amount is num ? amount : double.parse(amount.toString());
      return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
          .format(value);
    } catch (_) {
      return 'Rp $amount';
    }
  }

  String _formatDate(String? d) {
    if (d == null) return '-';
    try {
      DateTime date = DateTime.parse(d);
      if (date.isUtc) date = date.add(const Duration(hours: 7));
      else date = DateTime.utc(date.year, date.month, date.day, date.hour, date.minute, date.second).add(const Duration(hours: 7));
      return DateFormat('dd MMMM yyyy, HH:mm', 'id').format(date) + ' WIB';
    } catch (_) {
      return d;
    }
  }

  String _bankName(String? channel) {
    if (channel == null) return 'Virtual Account';
    return channel.replaceAll('VA_', '').replaceAll('_', ' ').toUpperCase();
  }

  List<String> _howToPay(String bank) {
    final b = bank.toLowerCase();
    if (b.contains('bca')) {
      return [
        'Login ke KlikBCA / BCA Mobile',
        'Pilih Transfer → BCA Virtual Account',
        'Masukkan Nomor Virtual Account',
        'Masukkan nominal sesuai tagihan',
        'Konfirmasi dan selesaikan pembayaran',
      ];
    } else if (b.contains('bni')) {
      return [
        'Login ke BNI Mobile Banking / ATM BNI',
        'Pilih Transfer → Virtual Account',
        'Masukkan Nomor Virtual Account',
        'Periksa detail dan nominal',
        'Masukkan PIN dan konfirmasi',
      ];
    } else if (b.contains('bri')) {
      return [
        'Login ke BRImo / ATM BRI',
        'Pilih Pembayaran → BRIVA',
        'Masukkan Nomor Virtual Account',
        'Periksa detail pembayaran',
        'Masukkan PIN dan konfirmasi',
      ];
    } else if (b.contains('mandiri')) {
      return [
        'Login ke Livin by Mandiri / ATM Mandiri',
        'Pilih Bayar → Multi Payment',
        'Masukkan kode perusahaan dan nomor VA',
        'Periksa detail tagihan',
        'Konfirmasi pembayaran',
      ];
    } else if (b.contains('cimb')) {
      return [
        'Login ke OCTO Mobile / ATM CIMB',
        'Pilih Transfer → Virtual Account',
        'Masukkan Nomor Virtual Account',
        'Periksa dan konfirmasi nominal',
        'Masukkan PIN untuk selesai',
      ];
    } else if (b.contains('permata')) {
      return [
        'Login ke PermataMobile / ATM Permata',
        'Pilih Pembayaran → Virtual Account',
        'Masukkan Nomor Virtual Account',
        'Ikuti instruksi di layar',
        'Konfirmasi transaksi',
      ];
    } else {
      return [
        'Buka aplikasi mobile banking atau ATM',
        'Pilih menu Transfer / Virtual Account',
        'Masukkan Nomor Virtual Account di bawah',
        'Periksa nominal sesuai tagihan',
        'Konfirmasi dan selesaikan pembayaran',
      ];
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final String status = _tx['status'] ?? '';
    final String jenis = _tx['jenis_transaksi'] ?? 'membership';
    final String? channel = _tx['channel']?.toString();
    final String? vaNumber = _tx['virtual_account']?.toString() ??
        _tx['payment_code']?.toString();
    final String bank = _bankName(channel);
    final bool isPending = status == 'pending';
    final bool isSuccess = status == 'success' || status == 'paid';

    Color statusColor = isPending
        ? Colors.orange
        : isSuccess
            ? Colors.green
            : Colors.red;
    IconData statusIcon = isPending
        ? Icons.access_time_filled
        : isSuccess
            ? Icons.check_circle
            : Icons.cancel;
    String statusLabel = isPending
        ? 'Menunggu Pembayaran'
        : isSuccess
            ? 'Pembayaran Berhasil'
            : 'Pembayaran Gagal';

    final String jenisLabel = jenis == 'topup_saldo'
        ? 'Top Up Saldo'
        : 'Membership ${(_tx['paket'] ?? '').toString().isNotEmpty ? _tx['paket'][0].toUpperCase() + _tx['paket'].substring(1) : ''}';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Detail Pembayaran',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (isPending)
            IconButton(
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _refreshStatus,
              tooltip: 'Refresh status',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // ── Status Card ────────────────────────────────────────────────────
          _StatusBanner(
            statusColor: statusColor,
            statusIcon: statusIcon,
            statusLabel: statusLabel,
            jenisLabel: jenisLabel,
            amount: _formatCurrency(_tx['jumlah']),
            date: _formatDate(_tx['tanggal_transaksi']),
            orderId: _tx['order_id']?.toString(),
            isPending: isPending,
          ),

          const SizedBox(height: 20),

          // ── Nomor Virtual Account (hanya jika ada VA dan status pending/info) ─
          if (vaNumber != null && vaNumber.isNotEmpty && !isSuccess)
            _VaCard(
              bank: bank,
              vaNumber: vaNumber,
              amount: _formatCurrency(_tx['jumlah']),
              onCopy: () => _copy(vaNumber, 'Nomor VA'),
            ),

          if (vaNumber != null && vaNumber.isNotEmpty && !isSuccess)
            const SizedBox(height: 20),

          // ── Cara Pembayaran ────────────────────────────────────────────────
          if (isPending && vaNumber != null && vaNumber.isNotEmpty)
            _HowToPayCard(bank: bank, steps: _howToPay(bank)),

          if (isPending && vaNumber != null && vaNumber.isNotEmpty)
            const SizedBox(height: 20),

          // ── Info Sukses ────────────────────────────────────────────────────
          if (isSuccess)
            _SuccessInfoCard(
              bank: bank,
              jenisLabel: jenisLabel,
              date: _formatDate(_tx['tanggal_transaksi']),
            ),

          // ── Info Transaksi ─────────────────────────────────────────────────
          _InfoCard(tx: _tx, formatDate: _formatDate, orderId: _tx['order_id']?.toString()),
        ],
      ),
    );
  }
}

// ─── Status Banner ─────────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final Color statusColor;
  final IconData statusIcon;
  final String statusLabel;
  final String jenisLabel;
  final String amount;
  final String date;
  final String? orderId;
  final bool isPending;

  const _StatusBanner({
    required this.statusColor,
    required this.statusIcon,
    required this.statusLabel,
    required this.jenisLabel,
    required this.amount,
    required this.date,
    this.orderId,
    required this.isPending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.18),
            statusColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          // Icon status
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: statusColor.withOpacity(0.4), width: 2),
            ),
            child: Icon(statusIcon, color: statusColor, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            statusLabel,
            style: TextStyle(
              color: statusColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            jenisLabel,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
          const SizedBox(height: 20),

          // Nominal
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            date,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
          if (isPending) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.orange),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Menunggu konfirmasi',
                    style: TextStyle(color: Colors.orange.shade300, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Virtual Account Card ───────────────────────────────────────────────────────
class _VaCard extends StatelessWidget {
  final String bank;
  final String vaNumber;
  final String amount;
  final VoidCallback onCopy;

  const _VaCard({
    required this.bank,
    required this.vaNumber,
    required this.amount,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.12),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance, color: Color(0xFF42A5F5), size: 18),
                const SizedBox(width: 10),
                Text(
                  'Nomor Virtual Account',
                  style: TextStyle(
                    color: Colors.blue.shade300,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama Bank
                Row(
                  children: [
                    _bankLogo(bank),
                    const SizedBox(width: 12),
                    Text(
                      bank,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Nomor VA
                const Text(
                  'Nomor Virtual Account',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatVa(vaNumber),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onCopy,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1976D2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.copy, size: 16, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'Salin',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Nominal
                const Text(
                  'Total Tagihan',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  amount,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Peringatan
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pastikan transfer sesuai nominal tepat. Kelebihan/kekurangan 1 rupiah pun akan gagal.',
                          style: TextStyle(
                              color: Colors.orange.shade300, fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tambahkan spasi tiap 4 digit untuk readability
  String _formatVa(String va) {
    final clean = va.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }

  Widget _bankLogo(String bank) {
    final b = bank.toLowerCase();
    IconData icon = Icons.account_balance;
    Color color = const Color(0xFF2196F3);

    if (b.contains('bca')) color = const Color(0xFF003EA0);
    else if (b.contains('bni')) color = const Color(0xFF004B87);
    else if (b.contains('bri')) color = const Color(0xFF00529C);
    else if (b.contains('mandiri')) color = const Color(0xFF003D8F);
    else if (b.contains('cimb')) color = const Color(0xFF7B0028);
    else if (b.contains('permata')) color = const Color(0xFF005398);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

// ─── Cara Pembayaran Card ───────────────────────────────────────────────────────
class _HowToPayCard extends StatefulWidget {
  final String bank;
  final List<String> steps;

  const _HowToPayCard({required this.bank, required this.steps});

  @override
  State<_HowToPayCard> createState() => _HowToPayCardState();
}

class _HowToPayCardState extends State<_HowToPayCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          // Header — bisa diklik untuk collapse
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  const Icon(Icons.help_outline, color: Color(0xFF42A5F5), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cara Bayar via ${widget.bank}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          if (_expanded) ...[
            Divider(height: 1, color: Colors.white.withOpacity(0.06)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: List.generate(widget.steps.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1565C0),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              widget.steps[i],
                              style: TextStyle(
                                color: Colors.grey.shade300,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Sukses Info Card ──────────────────────────────────────────────────────────
class _SuccessInfoCard extends StatelessWidget {
  final String bank;
  final String jenisLabel;
  final String date;

  const _SuccessInfoCard({
    required this.bank,
    required this.jenisLabel,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 10),
              const Text(
                'Pembayaran Dikonfirmasi',
                style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (bank.isNotEmpty && bank != 'Virtual Account')
            _row('Bank', bank),
          _row('Jenis', jenisLabel),
          _row('Waktu', date),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}

// ─── Info Transaksi Card ────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final Map<String, dynamic> tx;
  final String Function(String?) formatDate;
  final String? orderId;

  const _InfoCard({
    required this.tx,
    required this.formatDate,
    this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rincian Transaksi',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          _infoRow('Order ID', orderId ?? '-'),
          if (tx['paket'] != null && tx['paket'].toString().isNotEmpty)
            _infoRow('Paket', tx['paket'].toString()),
          if (tx['jenis_transaksi'] != null)
            _infoRow('Jenis', tx['jenis_transaksi'].toString() == 'topup_saldo' ? 'Top Up Saldo' : 'Membership'),
          _infoRow('Tanggal', formatDate(tx['tanggal_transaksi'])),
          if (tx['metode_pembayaran'] != null)
            _infoRow('Metode', tx['metode_pembayaran'].toString()),
          if (tx['channel'] != null)
            _infoRow('Channel', tx['channel'].toString().replaceAll('VA_', '').toUpperCase()),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          const Text(' : ', style: TextStyle(color: Colors.grey, fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
