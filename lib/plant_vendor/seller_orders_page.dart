import 'package:flutter/material.dart';
import 'green_bazaar_service.dart';
import 'green_bazaar_models.dart';

class SellerOrdersPage extends StatefulWidget {
  const SellerOrdersPage({super.key});
  @override
  State<SellerOrdersPage> createState() => _SellerOrdersPageState();
}

class _SellerOrdersPageState extends State<SellerOrdersPage>
    with SingleTickerProviderStateMixin {
  final _svc = GreenBazaarService();
  late final TabController _tab;

  static const _tabs = ['New', 'Confirmed', 'Ready', 'Collected'];
  static const _statuses = ['placed', 'confirmed', 'ready', 'collected'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  List<PlantOrder> _forStatus(List<PlantOrder> all, String status) =>
      all.where((o) => o.status == status).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text('My Orders',
            style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
        bottom: TabBar(
          controller: _tab,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.white,
          labelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<List<PlantOrder>>(
        stream: _svc.streamSellerOrders(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('Error: ${snap.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          }
          final all = snap.data ?? [];

          return TabBarView(
            controller: _tab,
            children: _statuses
                .map((s) => _OrderList(
                      orders: _forStatus(all, s),
                      status: s,
                      svc: _svc,
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

// ─── Order list per tab ───────────────────────────────────────────────────────

class _OrderList extends StatelessWidget {
  final List<PlantOrder> orders;
  final String status;
  final GreenBazaarService svc;
  const _OrderList(
      {required this.orders, required this.status, required this.svc});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_emptyEmoji(status),
              style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 14),
          Text(_emptyLabel(status),
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(_emptySubLabel(status),
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF9E9E9E))),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: orders.length,
      itemBuilder: (_, i) =>
          _OrderCard(order: orders[i], svc: svc),
    );
  }

  String _emptyEmoji(String s) {
    switch (s) {
      case 'placed':    return '📭';
      case 'confirmed': return '⏳';
      case 'ready':     return '📦';
      default:          return '✅';
    }
  }

  String _emptyLabel(String s) {
    switch (s) {
      case 'placed':    return 'No new orders';
      case 'confirmed': return 'Nothing to confirm';
      case 'ready':     return 'No orders ready';
      default:          return 'No collected orders yet';
    }
  }

  String _emptySubLabel(String s) {
    switch (s) {
      case 'placed':    return 'New takeaway orders will appear here';
      case 'confirmed': return 'Confirm new orders to see them here';
      case 'ready':     return 'Mark confirmed orders as ready for pickup';
      default:          return 'Completed orders appear here';
    }
  }
}

// ─── Order card ───────────────────────────────────────────────────────────────

class _OrderCard extends StatefulWidget {
  final PlantOrder order;
  final GreenBazaarService svc;
  const _OrderCard({required this.order, required this.svc});
  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _updating = false;

  Future<void> _advance(String nextStatus) async {
    setState(() => _updating = true);
    try {
      await widget.svc.updateOrderStatus(widget.order.id, nextStatus);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Update failed: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final statusColor = _statusColor(order.status);
    final createdStr = _formatDate(order.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(children: [
              Text('🏪', style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                      Text(createdStr,
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFF9E9E9E))),
                    ]),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.4), width: 1),
                ),
                child: Text(
                  PlantOrder.statusLabel(order.status),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: statusColor),
                ),
              ),
            ]),
          ),

          // Items
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(
              children: order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: item.imageUrl != null &&
                              item.imageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(item.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.local_florist_rounded,
                                      size: 18,
                                      color: Color(0xFF2E7D32))),
                            )
                          : const Icon(Icons.local_florist_rounded,
                              size: 18, color: Color(0xFF2E7D32)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${item.plantName}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('×${item.quantity}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF9E9E9E))),
                    const SizedBox(width: 8),
                    Text(
                      '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E7D32)),
                    ),
                  ]),
                );
              }).toList(),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Divider(height: 20),
          ),

          // Total + action
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Total',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFF9E9E9E))),
                Text(
                  '₹${order.itemsTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2E7D32)),
                ),
                const Text('Cash on pickup',
                    style: TextStyle(
                        fontSize: 10, color: Color(0xFF9E9E9E))),
              ]),
              const Spacer(),
              if (_nextStatus(order.status) != null)
                _updating
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : ElevatedButton(
                        onPressed: () =>
                            _advance(_nextStatus(order.status)!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: statusColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: Text(
                          _actionLabel(order.status),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                      )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(children: [
                    Icon(Icons.check_circle_rounded,
                        size: 14, color: Color(0xFF2E7D32)),
                    SizedBox(width: 4),
                    Text('Done',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E7D32))),
                  ]),
                ),
            ]),
          ),
        ],
      ),
    );
  }

  String? _nextStatus(String current) {
    const flow = {
      'placed': 'confirmed',
      'confirmed': 'ready',
      'ready': 'collected',
    };
    return flow[current];
  }

  String _actionLabel(String status) {
    switch (status) {
      case 'placed':    return 'Confirm Order';
      case 'confirmed': return 'Mark Ready';
      case 'ready':     return 'Mark Collected';
      default:          return '';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'placed':    return const Color(0xFFF39C12);
      case 'confirmed': return const Color(0xFF1565C0);
      case 'ready':     return const Color(0xFF6A1B9A);
      case 'collected': return const Color(0xFF2E7D32);
      case 'cancelled': return const Color(0xFFD32F2F);
      default:          return const Color(0xFF2E7D32);
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
