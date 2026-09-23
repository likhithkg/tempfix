// lib/exporter_hub/purchase_order_list_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'exporter_service.dart';
import 'po_detail_page.dart';
import '../theme.dart';

/// My Orders — shows direct orders for the current user.
/// isAdmin: true shows ALL direct orders across all users.
class PurchaseOrderListPage extends StatefulWidget {
  final String? buyerId;
  final bool isAdmin;
  const PurchaseOrderListPage({super.key, this.buyerId, this.isAdmin = false});

  @override
  State<PurchaseOrderListPage> createState() => _PurchaseOrderListPageState();
}

class _PurchaseOrderListPageState extends State<PurchaseOrderListPage> {
  final _svc = ExporterService();
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    FirebaseAuth.instance.authStateChanges().listen((u) {
      if (mounted) setState(() => _user = u);
    });
  }

  String? get _effectiveBuyerId => widget.buyerId ?? _user?.uid;

  String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'pending':
      case 'issued':
      case 'listed':
        return 'Waiting for Farmer';
      case 'confirmed':
      case 'farmer_accepted':
      case 'accepted':
        return 'Confirmed';
      case 'preparing':
      case 'collection_scheduled':
      case 'collected':
        return 'Preparing';
      case 'ready':
      case 'qc_approved':
      case 'ready_for_export':
        return 'Ready';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
      case 'exported':
      case 'completed':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'rejected':
      case 'qc_rejected':
        return 'Rejected';
      default:
        return s;
    }
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'pending':
      case 'issued':
      case 'listed':
        return Colors.orange;
      case 'confirmed':
      case 'farmer_accepted':
      case 'accepted':
        return Colors.blue;
      case 'preparing':
      case 'collection_scheduled':
      case 'collected':
        return Colors.indigo;
      case 'ready':
      case 'qc_approved':
      case 'ready_for_export':
        return Colors.teal;
      case 'out_for_delivery':
        return Colors.purple;
      case 'delivered':
      case 'exported':
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'rejected':
      case 'qc_rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic ts) {
    try {
      DateTime? dt;
      if (ts is Timestamp) {
        dt = ts.toDate();
      } else if (ts is int) {
        dt = DateTime.fromMillisecondsSinceEpoch(ts);
      } else if (ts is String) {
        dt = DateTime.tryParse(ts);
      }
      if (dt != null) return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {}
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final buyerId = _effectiveBuyerId;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF7),
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'All Orders' : 'My Orders'),
        backgroundColor: KMColors.primary,
        foregroundColor: Colors.white,
      ),
      body: buyerId == null && !widget.isAdmin
          ? const Center(child: Text('Sign in to see your orders'))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: widget.isAdmin
                  ? _svc.streamAllDirectOrders()
                  : _svc.streamBuyerOrders(buyerId!),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final orders = snap.data ?? [];
                if (orders.isEmpty) {
                  return _EmptyOrders(isAdmin: widget.isAdmin);
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  itemBuilder: (context, i) {
                    final o = orders[i];
                    final status = (o['status'] ?? 'pending').toString();
                    return _OrderCard(
                      order: o,
                      statusLabel: _statusLabel(status),
                      statusColor: _statusColor(status),
                      dateLabel: _formatDate(o['createdAt']),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PODetailPage(
                              poId: o['id'], isAdmin: widget.isAdmin),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

// ── Order Card ────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final String statusLabel;
  final Color statusColor;
  final String dateLabel;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.statusLabel,
    required this.statusColor,
    required this.dateLabel,
    required this.onTap,
  });

  String _productName() {
    final n = (order['productName'] ?? '').toString().trim();
    if (n.isNotEmpty) return n;
    try {
      final items = (order['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (items.isNotEmpty) {
        return (items.first['productName'] ?? items.first['name'] ?? 'Product').toString();
      }
    } catch (_) {}
    return 'Product';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = (order['productImage'] ?? '').toString();
    final quantity = order['quantity'];
    final unit = (order['unit'] ?? '').toString();
    final total = order['totalAmount'] ?? 0;
    final farmerName = (order['farmerName'] ?? '').toString();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 68,
                  height: 68,
                  child: imageUrl.isNotEmpty
                      ? Image.network(imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const _ImgFallback())
                      : const _ImgFallback(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _productName(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    if (quantity != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        '${quantity.toString()} ${unit.isNotEmpty ? unit : 'units'}',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                    if (farmerName.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.agriculture,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(farmerName,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ]),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _StatusBadge(
                            label: statusLabel, color: statusColor),
                        const Spacer(),
                        Text(
                          '₹${total is double ? total.toStringAsFixed(0) : total}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: KMColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _ImgFallback extends StatelessWidget {
  const _ImgFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
          child: Icon(Icons.grain, color: Colors.white54, size: 24)),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  final bool isAdmin;
  const _EmptyOrders({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_bag_outlined,
              size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(isAdmin ? 'No orders yet' : 'No orders yet',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            isAdmin
                ? 'Orders placed by buyers will appear here'
                : 'Browse products and tap Buy Now to place an order',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
