import 'package:flutter/material.dart';

class PaymentChannelSheet extends StatelessWidget {
  const PaymentChannelSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const PaymentChannelSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final channels = [
      {'id': 'VA_BCA', 'name': 'BCA Virtual Account', 'icon': Icons.account_balance, 'color': const Color(0xFF003EA0)},
      {'id': 'VA_BNI', 'name': 'BNI Virtual Account', 'icon': Icons.account_balance, 'color': const Color(0xFF004B87)},
      {'id': 'VA_BRI', 'name': 'BRI Virtual Account', 'icon': Icons.account_balance, 'color': const Color(0xFF00529C)},
      {'id': 'VA_MANDIRI', 'name': 'Mandiri Virtual Account', 'icon': Icons.account_balance, 'color': const Color(0xFF003D8F)},
      {'id': 'VA_CIMB', 'name': 'CIMB Virtual Account', 'icon': Icons.account_balance, 'color': const Color(0xFF7B0028)},
      {'id': 'VA_PERMATA', 'name': 'Permata Virtual Account', 'icon': Icons.account_balance, 'color': const Color(0xFF005398)},
      {'id': 'VA_BNC', 'name': 'BNC Virtual Account', 'icon': Icons.account_balance, 'color': const Color(0xFF2196F3)},
      {'id': 'OTC_ALFAMART', 'name': 'Alfamart', 'icon': Icons.storefront, 'color': Colors.red},
      {'id': 'OTC_INDOMARET', 'name': 'Indomaret', 'icon': Icons.storefront, 'color': Colors.blue},
    ];

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Pilih Metode Pembayaran',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              itemCount: channels.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final channel = channels[index];
                return InkWell(
                  onTap: () => Navigator.pop(context, channel['id']),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (channel['color'] as Color).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            channel['icon'] as IconData,
                            color: channel['color'] as Color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            channel['name'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
