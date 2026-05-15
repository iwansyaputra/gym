import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/payment_service.dart';
import '../services/api_service.dart';
import 'payment_detail_page.dart';
import 'dart:async';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> with SingleTickerProviderStateMixin {
  List<dynamic> _transactions = [];
  List<dynamic> _checkIns = [];
  bool _isLoadingTransactions = true;
  bool _isLoadingCheckIns = true;
  late TabController _tabController;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTransactions();
    _loadCheckIns();
    
    // Timer untuk auto-refresh data check-in setiap 5 detik (simulasi realtime)
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // Hanya refresh jika sedang di tab Check-in
      if (mounted && _tabController.index == 1) {
        _refreshCheckInsSilently();
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoadingTransactions = true);

    final result = await PaymentService.getPaymentHistory();

    if (mounted) {
      setState(() {
        if (result['success'] == true) {
          _transactions = result['data'] as List;
        }
        _isLoadingTransactions = false;
      });
    }
  }

  Future<void> _loadCheckIns() async {
    setState(() => _isLoadingCheckIns = true);

    final result = await ApiService.getCheckInHistory();

    if (mounted) {
      setState(() {
        if (result['success'] == true && result['data'] != null && result['data']['check_ins'] != null) {
          _checkIns = result['data']['check_ins'] as List;
        }
        _isLoadingCheckIns = false;
      });
    }
  }

  // Refresh data tanpa mengubah state _isLoadingCheckIns (supaya tidak muncul loading muter-muter)
  Future<void> _refreshCheckInsSilently() async {
    final result = await ApiService.getCheckInHistory();

    if (mounted) {
      if (result['success'] == true && result['data'] != null && result['data']['check_ins'] != null) {
        final newCheckIns = result['data']['check_ins'] as List;
        // Hanya update UI jika ada perubahan jumlah data (misal ada checkin baru)
        if (newCheckIns.length != _checkIns.length) {
          setState(() {
            _checkIns = newCheckIns;
          });
        } else if (newCheckIns.isNotEmpty && _checkIns.isNotEmpty) {
          // Atau jika data paling atas berbeda (id atau waktunya berbeda)
          final latestNew = newCheckIns[0];
          final latestOld = _checkIns[0];
          if (latestNew['id'] != latestOld['id'] || latestNew['check_in_time'] != latestOld['check_in_time']) {
            setState(() {
              _checkIns = newCheckIns;
            });
          }
        }
      }
    }
  }

  String _formatCurrency(dynamic amount) {
    try {
      final numericAmount = amount is num
          ? amount
          : double.parse(amount?.toString() ?? '0');
      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );
      return formatter.format(numericAmount);
    } catch (e) {
      return 'Rp $amount';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      DateTime date = DateTime.parse(dateStr);
      if (date.isUtc) {
        date = date.add(const Duration(hours: 7));
      } else {
        // Anggap UTC jika tanpa Z
        date = DateTime.utc(date.year, date.month, date.day, date.hour, date.minute, date.second).add(const Duration(hours: 7));
      }
      return DateFormat('dd MMMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0A0A0A),
        centerTitle: true,
        title: const Text(
          "Riwayat",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.2,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2196F3),
          labelColor: const Color(0xFF2196F3),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "Transaksi"),
            Tab(text: "Check-in"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTransaksiTab(),
          _buildCheckInTab(),
        ],
      ),
    );
  }

  Widget _buildTransaksiTab() {
    return _isLoadingTransactions
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2196F3)))
        : RefreshIndicator(
            color: const Color(0xFF2196F3),
            backgroundColor: const Color(0xFF1A1A1A),
            onRefresh: _loadTransactions,
            child: _transactions.isEmpty
                ? _buildEmptyState('Belum ada riwayat transaksi', Icons.receipt_long)
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final raw = _transactions[index];
                      if (raw is! Map) {
                        return const SizedBox.shrink();
                      }
                      final transaction = Map<String, dynamic>.from(raw);
                      return _buildRiwayatCard(transaction);
                    },
                  ),
          );
  }

  Widget _buildCheckInTab() {
    return _isLoadingCheckIns
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2196F3)))
        : RefreshIndicator(
            color: const Color(0xFF2196F3),
            backgroundColor: const Color(0xFF1A1A1A),
            onRefresh: _loadCheckIns,
            child: _checkIns.isEmpty
                ? _buildEmptyState('Belum ada riwayat check-in', Icons.how_to_reg)
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    itemCount: _checkIns.length,
                    itemBuilder: (context, index) {
                      final raw = _checkIns[index];
                      if (raw is! Map) {
                        return const SizedBox.shrink();
                      }
                      final checkIn = Map<String, dynamic>.from(raw);
                      return _buildCheckInCard(checkIn);
                    },
                  ),
          );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCheckInCard(Map<String, dynamic> checkIn) {
    final String dateStr = checkIn['check_in_time']?.toString() ?? '';
    String formattedDate = dateStr.isEmpty ? 'Tanggal tidak diketahui' : dateStr;
    String formattedTime = '--:--';

    if (dateStr.isNotEmpty) {
      try {
        // Paksa konversi ke WIB (UTC+7) mengabaikan zona waktu emulator
        DateTime date = DateTime.parse(dateStr);
        if (date.isUtc) {
          date = date.add(const Duration(hours: 7));
        } else {
          date = DateTime.utc(date.year, date.month, date.day, date.hour, date.minute, date.second).add(const Duration(hours: 7));
        }
        
        formattedDate = DateFormat('dd MMMM yyyy').format(date);
        formattedTime = DateFormat('HH:mm').format(date);
      } catch (e) {
        // Fallback jika DateTime.parse tetap gagal
        final parts = dateStr.split(RegExp(r'[T\s]'));
        if (parts.length > 1) {
          formattedDate = parts[0];
          
          final timePart = parts[1].replaceAll('Z', '');
          final timeParts = timePart.split(':');
          if (timeParts.length >= 2) {
            formattedTime = '${timeParts[0]}:${timeParts[1]}';
          } else {
            formattedTime = timePart;
          }
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.how_to_reg, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Check-in Berhasil',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formattedTime,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'WIB',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayatCard(Map<String, dynamic> transaction) {
    final String status = transaction['status'] ?? '';
    final String jenis = transaction['jenis_transaksi'] ?? 'membership';
    final String paket = transaction['paket'] ?? '';
    final String? channel = transaction['channel']?.toString();
    final String? vaNumber = transaction['virtual_account']?.toString() ??
        transaction['payment_code']?.toString();

    final String bankName = channel != null
        ? channel.replaceAll('VA_', '').replaceAll('_', ' ').toUpperCase()
        : '';

    final String jenisLabel = jenis == 'topup_saldo'
        ? 'Top Up Saldo'
        : paket.isNotEmpty
            ? 'Membership ${paket[0].toUpperCase()}${paket.substring(1)}'
            : 'Pembayaran';

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (status.toLowerCase()) {
      case 'success':
      case 'paid':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusLabel = 'SUKSES';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time_filled;
        statusLabel = 'MENUNGGU';
        break;
      case 'failed':
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusLabel = 'GAGAL';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
        statusLabel = status.toUpperCase();
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentDetailPage(transaction: transaction),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: status == 'pending'
                ? Colors.orange.withOpacity(0.35)
                : Colors.white.withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              // Icon jenis transaksi
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (jenis == 'topup_saldo'
                          ? Colors.green
                          : const Color(0xFF2196F3))
                      .withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  jenis == 'topup_saldo'
                      ? Icons.account_balance_wallet
                      : Icons.card_membership,
                  color: jenis == 'topup_saldo'
                      ? Colors.green
                      : const Color(0xFF2196F3),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Nama + tanggal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jenisLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(transaction['tanggal_transaksi']),
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                    // VA preview jika pending
                    if (status == 'pending' && vaNumber != null) ...
                      [
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.account_balance,
                                size: 12, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              bankName.isNotEmpty
                                  ? 'VA $bankName'
                                  : 'Virtual Account',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange.shade400),
                            ),
                          ],
                        ),
                      ],
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Nominal + status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatCurrency(transaction['jumlah']),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: jenis == 'topup_saldo'
                          ? Colors.green
                          : const Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: statusColor.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 10, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Arrow indicator → bisa di-tap
                  Icon(Icons.arrow_forward_ios,
                      size: 12, color: Colors.grey.shade600),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

