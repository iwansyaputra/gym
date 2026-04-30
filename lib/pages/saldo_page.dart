import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'membership_packages_page.dart';
import 'topup_payment_page.dart';

/// Halaman Saldo / Wallet untuk member
/// Member bisa melihat saldo, riwayat top up/debit,
/// dan perpanjang membership menggunakan saldo yang tersedia.
class SaldoPage extends StatefulWidget {
  const SaldoPage({super.key});

  @override
  State<SaldoPage> createState() => _SaldoPageState();
}

class _SaldoPageState extends State<SaldoPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Map<String, dynamic>? _walletData;
  List<dynamic> _historyData = [];
  bool _isLoadingWallet = true;
  bool _isLoadingHistory = true;

  // Format mata uang Rupiah
  final _currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadWallet();
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWallet() async {
    setState(() => _isLoadingWallet = true);
    final result = await ApiService.getMyWallet();
    if (mounted) {
      setState(() {
        _isLoadingWallet = false;
        if (result['success'] == true) {
          _walletData = result['data'];
        }
      });
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    final result = await ApiService.getMyWalletHistory();
    if (mounted) {
      setState(() {
        _isLoadingHistory = false;
        if (result['success'] == true) {
          _historyData = result['data'] ?? [];
        }
      });
    }
  }

  Future<void> _refresh() async {
    await Future.wait([_loadWallet(), _loadHistory()]);
  }

  /// Perpanjang membership pakai saldo — buka halaman pilih paket
  void _goExtendWithWallet() async {
    final saldo = double.tryParse(_walletData?['saldo']?.toString() ?? '0') ?? 0;
    if (saldo <= 0) {
      _showSnack('Saldo Anda kosong. Silakan top up saldo terlebih dahulu.', isError: true);
      return;
    }

    // Buka halaman pilih paket, kirim flag useWallet = true
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MembershipPackagesPage(useWallet: true),
      ),
    );

    if (result == true && mounted) {
      _showSnack('Membership berhasil diperpanjang via saldo!');
      await _refresh();
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Saldo',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.2,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2196F3),
          labelColor: const Color(0xFF2196F3),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Saldo Saya'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSaldoTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  // ─── Tab Saldo ────────────────────────────────────────────────────────────
  Widget _buildSaldoTab() {
    if (_isLoadingWallet) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2196F3)),
      );
    }

    final saldo = double.tryParse(_walletData?['saldo']?.toString() ?? '0') ?? 0;

    return RefreshIndicator(
      color: const Color(0xFF2196F3),
      backgroundColor: const Color(0xFF1A1A1A),
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kartu Saldo Utama
            _buildSaldoCard(saldo),

            const SizedBox(height: 24),

            // Tombol Perpanjang via Saldo (hanya tampil kalau ada saldo)
            if (saldo > 0) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _goExtendWithWallet,
                  icon: const Icon(Icons.autorenew),
                  label: const Text(
                    'Perpanjang Membership via Saldo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ─── Section Top Up ─────────────────────────────────────────────
            const Text(
              'Top Up Saldo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pilih nominal atau masukkan jumlah lain. Pembayaran via Virtual Account.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Preset nominal
            _buildAmountPresets(),

            const SizedBox(height: 16),

            // Input nominal custom
            _buildCustomAmountInput(),

            const SizedBox(height: 20),

            // Tombol bayar
            _buildTopUpButton(),

            const SizedBox(height: 24),

            // Info virtual account
            _buildInfoCard(
              icon: Icons.info_outline,
              title: 'Cara Bayar',
              content:
                  'Setelah memilih nominal dan klik "Top Up Sekarang", Anda akan diarahkan ke halaman Virtual Account E-Smartlink. Saldo akan otomatis masuk setelah pembayaran terkonfirmasi.',
              color: const Color(0xFF2196F3),
            ),
          ],
        ),
      ),
    );
  }

  // ─── State untuk top up amount picker ─────────────────────────────────────
  int? _selectedPreset;       // preset yang dipilih
  final _customController = TextEditingController(); // input custom
  bool _isCustomActive = false; // apakah pakai custom input

  static const List<int> _presets = [50000, 100000, 500000];

  Widget _buildAmountPresets() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _presets.map((amount) {
        final isSelected = !_isCustomActive && _selectedPreset == amount;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedPreset = amount;
              _isCustomActive = false;
              _customController.clear();
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF2196F3).withOpacity(0.15)
                  : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF2196F3) : Colors.white12,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              _currencyFormat.format(amount),
              style: TextStyle(
                color: isSelected ? const Color(0xFF2196F3) : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCustomAmountInput() {
    return TextField(
      controller: _customController,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Nominal lain (min. Rp 10.000)',
        hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        prefixText: 'Rp  ',
        prefixStyle: const TextStyle(color: Colors.white70, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
        ),
      ),
      onChanged: (v) {
        setState(() {
          _isCustomActive = v.isNotEmpty;
          if (v.isNotEmpty) _selectedPreset = null;
        });
      },
    );
  }

  Widget _buildTopUpButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _handleTopUp,
        icon: const Icon(Icons.account_balance_wallet),
        label: const Text(
          'Top Up Sekarang',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  void _handleTopUp() async {
    // Tentukan nominal
    int? nominal;
    if (_isCustomActive) {
      final raw = _customController.text.replaceAll(RegExp(r'[^0-9]'), '');
      nominal = int.tryParse(raw);
    } else {
      nominal = _selectedPreset;
    }

    if (nominal == null || nominal < 10000) {
      _showSnack('Pilih nominal atau masukkan minimal Rp 10.000', isError: true);
      return;
    }

    // Buka halaman pembayaran top up
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TopUpPaymentPage(jumlah: nominal!),
      ),
    );

    if (result == true && mounted) {
      // Reset pilihan
      setState(() {
        _selectedPreset = null;
        _isCustomActive = false;
        _customController.clear();
      });
      _showSnack('Saldo berhasil ditambahkan!');
      await _refresh();
    }
  }



  Widget _buildSaldoCard(double saldo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: saldo > 0
              ? [const Color(0xFF1565C0), const Color(0xFF0D47A1)]
              : [const Color(0xFF2C2C2C), const Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (saldo > 0 ? const Color(0xFF0D47A1) : Colors.black)
                .withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SALDO DOMPET',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _currencyFormat.format(saldo),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            saldo > 0
                ? 'Saldo tersedia untuk perpanjang membership'
                : 'Saldo kosong — minta top up ke admin',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab Riwayat ──────────────────────────────────────────────────────────
  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2196F3)),
      );
    }

    if (_historyData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 60, color: Colors.grey.shade700),
            const SizedBox(height: 16),
            Text(
              'Belum ada riwayat transaksi',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF2196F3),
      backgroundColor: const Color(0xFF1A1A1A),
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _historyData.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _buildHistoryItem(_historyData[i]),
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final jenis = item['jenis'] as String? ?? 'topup';
    final jumlah = double.tryParse(item['jumlah']?.toString() ?? '0') ?? 0;
    final saldoAkhir =
        double.tryParse(item['saldo_akhir']?.toString() ?? '0') ?? 0;
    final keterangan = item['keterangan'] as String? ?? '-';
    final createdAt = item['created_at'] as String?;

    final isCredit = jenis == 'topup' || jenis == 'refund';
    final color = isCredit ? Colors.green : Colors.red;
    final sign = isCredit ? '+' : '-';
    final label = jenis == 'topup'
        ? 'Top Up'
        : jenis == 'refund'
            ? 'Refund'
            : 'Debit';

    String formattedDate = '-';
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        formattedDate =
            DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt);
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // Ikon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  keterangan,
                  style:
                      TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  formattedDate,
                  style:
                      TextStyle(color: Colors.grey.shade700, fontSize: 11),
                ),
              ],
            ),
          ),

          // Jumlah & saldo akhir
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${_currencyFormat.format(jumlah)}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sisa: ${_currencyFormat.format(saldoAkhir)}',
                style:
                    TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
