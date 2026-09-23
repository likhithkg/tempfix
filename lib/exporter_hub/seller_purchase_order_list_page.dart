// lib/exporter_hub/seller_purchase_order_list_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'exporter_service.dart';
import 'po_detail_page.dart';
import 'notifications_page.dart';
import '../theme.dart';

class SellerPurchaseOrderListPage extends StatefulWidget {
  const SellerPurchaseOrderListPage({super.key});

  @override
  State<SellerPurchaseOrderListPage> createState() =>
      _SellerPurchaseOrderListPageState();
}

class _SellerPurchaseOrderListPageState
    extends State<SellerPurchaseOrderListPage> {
  final _svc = ExporterService();
  User? _user;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    FirebaseAuth.instance.authStateChanges().listen((u) {
      if (mounted) setState(() => _user = u);
    });
  }

  bool _matchesFilter(String status) {
    if (_filter == 'all') return true;
    if (_filter == 'new') {
      return status == 'pending' ||
          status == 'issued' ||
          status == 'listed';
    }
    if (_filter == 'active') {
      return [
        'confirmed',
        'preparing',
        'ready',
        'out_for_delivery',
        'farmer_accepted',
        'collection_scheduled',
        'collected',
        'qc_pending',
        'qc_approved',
        'ready_for_export',
      ].contains(status);
    }
    if (_filter == 'done') {
      return [
        'delivered',
        'cancelled',
        'rejected',
        'exported',
        'qc_rejected',
        'completed',
      ].contains(status);
    }
    return true;
  }

  String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'pending':
      case 'issued':
      case 'listed':
        return 'New Order';
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
      }
      if (dt != null) return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {}
    return '—';
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  static const _nextStatus = {
    'confirmed': ('preparing', 'Mark as Preparing'),
    'preparing': ('ready', 'Mark as Ready'),
    'ready': ('out_for_delivery', 'Mark as Out for Delivery'),
    'out_for_delivery': ('delivered', 'Mark as Delivered'),
  };

  Future<void> _advanceStatus(
      String orderId, String currentStatus, String uid) async {
    final next = _nextStatus[currentStatus];
    if (next == null) return;
    await _svc.updatePOStatus(orderId, next.$1, uid,
        note: 'Status updated by farmer');
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(next.$2)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _user;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF7),
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: KMColors.primary,
        foregroundColor: Colors.white,
      ),
      body: current == null
          ? const Center(child: Text('Sign in to see your orders'))
          : Column(
              children: [
                // ── Filter tabs ──
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      for (final f in ['all', 'new', 'active', 'done'])
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _filter = f),
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _filter == f
                                    ? KMColors.primary
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                {'all': 'All', 'new': 'New', 'active': 'Active', 'done': 'Done'}[f]!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _filter == f
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Order list ──
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _svc.streamFarmerOrders(current.uid),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final all = snap.data ?? [];
                      final orders = all
                          .where((o) => _matchesFilter(
                              (o['status'] ?? 'pending').toString()))
                          .toList();
                      if (orders.isEmpty) {
                        return _EmptyFarmerOrders(filter: _filter);
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: orders.length,
                        itemBuilder: (context, i) {
                          final o = orders[i];
                          final status =
                              (o['status'] ?? 'pending').toString();
                          final isNew = status == 'pending' ||
                              status == 'issued' ||
                              status == 'listed';
                          final isActive = _nextStatus.containsKey(status);

                          return _FarmerOrderCard(
                            order: o,
                            statusLabel: _statusLabel(status),
                            statusColor: _statusColor(status),
                            dateLabel: _formatDate(o['createdAt']),
                            onViewDetail: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PODetailPage(poId: o['id'], isAdmin: false),
                              ),
                            ),
                            onAccept: isNew
                                ? () async {
                                    await _svc.updatePOStatus(
                                        o['id'], 'confirmed', current.uid,
                                        note: 'Farmer confirmed the order');
                                    final buyerId =
                                        (o['buyerId'] ?? '').toString();
                                    if (buyerId.isNotEmpty) {
                                      NotificationService.send(
                                        userId: buyerId,
                                        type: 'order_confirmed',
                                        title: 'Order Confirmed',
                                        body:
                                            'Your order has been confirmed by the farmer.',
                                        referenceId: o['id'],
                                        referenceType: 'order',
                                      ).catchError((_) {});
                                    }
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text('Order confirmed'),
                                              backgroundColor: Colors.green));
                                    }
                                  }
                                : null,
                            onReject: isNew
                                ? () async {
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Reject Order?'),
                                        content: const Text(
                                            'Are you sure you want to reject this order?'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancel')),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Reject',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (ok == true && context.mounted) {
                                      await _svc.updatePOStatus(
                                          o['id'], 'rejected', current.uid,
                                          note: 'Farmer rejected the order');
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content:
                                                    Text('Order rejected')));
                                      }
                                    }
                                  }
                                : null,
                            onUpdateStatus: isActive
                                ? () => _advanceStatus(
                                    o['id'], status, current.uid)
                                : null,
                            onCall: (o['buyerPhone'] ??
                                        o['buyerContact'] ??
                                        '')
                                    .toString()
                                    .isNotEmpty
                                ? () => _call(
                                    (o['buyerPhone'] ?? o['buyerContact'])
                                        .toString())
                                : null,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Farmer Order Card ─────────────────────────────────────────────────────────

class _FarmerOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final String statusLabel;
  final Color statusColor;
  final String dateLabel;
  final VoidCallback onViewDetail;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onUpdateStatus;
  final VoidCallback? onCall;

  const _FarmerOrderCard({
    required this.order,
    required this.statusLabel,
    required this.statusColor,
    required this.dateLabel,
    required this.onViewDetail,
    this.onAccept,
    this.onReject,
    this.onUpdateStatus,
    this.onCall,
  });

  String _productName() {
    final n = (order['productName'] ?? '').toString().trim();
    if (n.isNotEmpty) return n;
    try {
      final items =
          (order['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (items.isNotEmpty) {
        return (items.first['productName'] ?? 'Product').toString();
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
    final buyerName = (order['buyerName'] ?? '').toString();
    final deliveryAddress = (order['deliveryAddress'] ?? '').toString();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // Status header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(statusLabel,
                  style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              const Spacer(),
              Text(dateLabel,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: imageUrl.isNotEmpty
                          ? Image.network(imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const _ImgFallback())
                          : const _ImgFallback(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_productName(),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (quantity != null)
                          Text(
                              '${quantity.toString()} ${unit.isNotEmpty ? unit : 'units'}',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13)),
                        Text(
                          '₹${total is double ? total.toStringAsFixed(0) : total}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: KMColors.primary,
                              fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ]),

                const SizedBox(height: 12),

                // Buyer info
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Buyer',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(buyerName.isNotEmpty ? buyerName : '—',
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      if (deliveryAddress.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(deliveryAddress,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12),
                                maxLines: 2),
                          ),
                        ]),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Action buttons
                if (onAccept != null || onReject != null)
                  Row(children: [
                    if (onAccept != null)
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: onAccept,
                          child: const Text('Accept'),
                        ),
                      ),
                    if (onAccept != null && onReject != null)
                      const SizedBox(width: 10),
                    if (onReject != null)
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: onReject,
                          child: const Text('Reject'),
                        ),
                      ),
                  ])
                else if (onUpdateStatus != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: onUpdateStatus,
                      icon: const Icon(Icons.update, size: 18),
                      label: const Text('Update Status'),
                    ),
                  ),

                TextButton(
                  onPressed: onViewDetail,
                  child: const Text('View Full Details'),
                ),
              ],
            ),
          ),
        ],
      ),
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
          child: Icon(Icons.grain, color: Colors.white54, size: 22)),
    );
  }
}

class _EmptyFarmerOrders extends StatelessWidget {
  final String filter;
  const _EmptyFarmerOrders({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            filter == 'new'
                ? Icons.notifications_none
                : Icons.receipt_long_outlined,
            size: 72,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(filter == 'new' ? 'No new orders' : 'No orders here',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('When buyers place orders, they appear here',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
