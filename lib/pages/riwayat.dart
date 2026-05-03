import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/payment_service.dart';
import '../services/api_service.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTransactions();
    _loadCheckIns();
  }

  @override
  void dispose() {
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
    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'success':
      case 'paid':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time_filled;
        break;
      case 'failed':
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_outlined, color: Color(0xFF2196F3), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction['paket'] ?? 'Membership',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(transaction['tanggal_transaksi']),
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
                    _formatCurrency(transaction['jumlah']),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Payment method
          if (transaction['metode_pembayaran'] != null) ...[
            const SizedBox(height: 16),
            Divider(color: Colors.white.withOpacity(0.1), height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.payment, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Metode: ${transaction['metode_pembayaran']}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }
}
