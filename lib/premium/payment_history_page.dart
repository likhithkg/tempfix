import 'package:flutter/material.dart';

import '../theme.dart';
import 'premium_service.dart';

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  List<Map<String, dynamic>> _payments = [];
  bool _loading = true;
  String? _error;
  int _page = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await PremiumService.instance.getHistory(page: _page);
      if (mounted) {
        setState(() {
          _payments = List<Map<String, dynamic>>.from(data['payments'] ?? []);
          _totalPages = (data['pages'] as num? ?? 1).toInt();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? KMColors.backgroundDark : KMColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: KMColors.primaryDark,
        foregroundColor: Colors.white,
        title: const Text('Payment History',
            style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _payments.isEmpty
                  ? const Center(
                      child: Text('No payment history yet.',
                          style: TextStyle(fontSize: 15)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _payments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _PaymentCard(
                          payment: _payments[i], isDark: isDark),
                    ),
      bottomNavigationBar: _totalPages > 1
          ? _PaginationBar(
              page: _page,
              totalPages: _totalPages,
              onPrev: _page > 1 ? () { setState(() => _page--); _load(); } : null,
              onNext: _page < _totalPages
                  ? () { setState(() => _page++); _load(); }
                  : null,
            )
          : null,
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Map<String, dynamic> payment;
  final bool isDark;

  const _PaymentCard({required this.payment, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final status = payment['status'] as String? ?? 'unknown';
    final amount = payment['amount'];
    final features = List<String>.from(payment['features'] ?? []);
    final createdAt = payment['createdAt'] as String?;

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'success':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        break;
      case 'cancelled':
        statusColor = Colors.orange;
        statusIcon = Icons.remove_circle_rounded;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.hourglass_top_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? KMColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  features.map(_featureName).join(', '),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(createdAt),
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black45),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${amount ?? '–'}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                status.toUpperCase(),
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _featureName(String id) {
    switch (id) {
      case 'renthub_premium':      return 'RentHub';
      case 'plant_vendor_premium': return 'Plant Vendor';
      case 'crop_disease_premium': return 'Crop Disease AI';
      default:                     return id;
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '–';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _PaginationBar extends StatelessWidget {
  final int page, totalPages;
  final VoidCallback? onPrev, onNext;

  const _PaginationBar({
    required this.page,
    required this.totalPages,
    this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text('$page / $totalPages',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
      );
}
