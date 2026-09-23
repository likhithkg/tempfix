import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'green_bazaar_service.dart';
import 'green_bazaar_models.dart';
import 'order_detail_page.dart';

class BuyerOrdersPage extends StatefulWidget {
  const BuyerOrdersPage({super.key});
  @override
  State<BuyerOrdersPage> createState() => _BuyerOrdersPageState();
}

class _BuyerOrdersPageState extends State<BuyerOrdersPage> {
  final _svc = GreenBazaarService();
  late final Stream<List<PlantOrder>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = _svc.streamMyOrders();
  }

  Future<void> _cancelOrder(PlantOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Order',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
            'Cancel order ${_shortId(order.id)}? The seller will be notified.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Yes, Cancel')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _svc.cancelOrder(order.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteOrder(PlantOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Order',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
            'Remove order ${_shortId(order.id)} from your history? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _svc.deleteOrder(order.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _shortId(String id) =>
      '#${(id.length > 8 ? id.substring(0, 8) : id).toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text('My Purchases',
            style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
      ),
      body: StreamBuilder<List<PlantOrder>>(
        stream: _stream,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Unable to load orders. Please try again.',
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center),
              ),
            );
          }
          final orders = snap.data ?? [];
          if (orders.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _OrderCard(
              order: orders[i],
              onCancel: () => _cancelOrder(orders[i]),
              onDelete: () => _deleteOrder(orders[i]),
            ),
          );
        },
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.shopping_bag_rounded, size: 40, color: Color(0xFF2E7D32)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('No purchases yet',
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Browse GreenBazaar and start shopping!',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Order card ───────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final PlantOrder order;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  const _OrderCard({
    required this.order,
    required this.onCancel,
    required this.onDelete,
  });

  static const _statusColor = {
    'placed': Color(0xFFFFA000),
    'confirmed': Color(0xFF1565C0),
    'ready': Color(0xFF6A1B9A),
    'collected': Color(0xFF2E7D32),
    'packed': Color(0xFF00838F),
    'out_for_delivery': Color(0xFF1565C0),
    'delivered': Color(0xFF2E7D32),
    'cancelled': Color(0xFFB71C1C),
  };

  static const _buyerHint = {
    'placed': 'Waiting for seller to confirm your order.',
    'confirmed': 'Your order is confirmed! Seller is preparing it.',
    'ready': 'Ready for pickup! Head to the vendor.',
    'collected': 'You\'ve collected your order. Enjoy!',
    'packed': 'Your order is packed and being prepared for delivery.',
    'out_for_delivery': 'Your order is on the way!',
    'delivered': 'Your order has been delivered. Enjoy!',
    'cancelled': 'This order was cancelled.',
  };

  Color get _color =>
      _statusColor[order.status] ?? const Color(0xFF757575);

  String get _dateStr =>
      DateFormat('d MMM yyyy, h:mm a').format(order.createdAt);

  String get _shortId => order.id.length > 8
      ? '#${order.id.substring(0, 8).toUpperCase()}'
      : '#${order.id.toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    final steps = PlantOrder.statusStepsForType(order.orderType);
    final currentStep = steps.indexOf(order.status);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => OrderDetailPage(order: order)),
      ),
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // ── Header strip ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_shortId,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text(_dateStr,
                          style: const TextStyle(
                              fontSize: 10.5, color: Color(0xFF757575))),
                    ]),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  PlantOrder.statusLabel(order.status),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ]),
          ),

          // ── Status progress tracker ───────────────────────────────────
          if (order.status != 'cancelled')
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
              child: _StatusTracker(
                  steps: steps,
                  currentStep: currentStep,
                  color: _color),
            ),

          // ── Buyer hint ────────────────────────────────────────────────
          if (_buyerHint[order.status] != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded,
                      size: 13, color: _color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _buyerHint[order.status]!,
                      style: TextStyle(
                          fontSize: 11,
                          color: _color,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
              ),
            ),

          // ── Items ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: order.items.map((item) => _ItemRow(item: item)).toList(),
            ),
          ),

          // ── Footer: order type + total ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: order.isTakeaway
                      ? const Color(0xFF1B5E20).withValues(alpha: 0.10)
                      : const Color(0xFF1565C0).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    order.isTakeaway
                        ? Icons.store_rounded
                        : Icons.local_shipping_outlined,
                    size: 10,
                    color: order.isTakeaway
                        ? const Color(0xFF1B5E20)
                        : const Color(0xFF1565C0),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    order.isTakeaway ? 'Takeaway' : 'Delivery',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: order.isTakeaway
                            ? const Color(0xFF1B5E20)
                            : const Color(0xFF1565C0)),
                  ),
                ]),
              ),
              const Spacer(),
              Text('Total: ',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600)),
              Text('₹${order.grandTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B5E20))),
            ]),
          ),

          // ── Action buttons ────────────────────────────────────────────
          if (order.status == 'placed') ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel_outlined, size: 15),
                  label: const Text('Cancel Order'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
          ] else if (order.status == 'cancelled' ||
              order.status == 'collected' ||
              order.status == 'delivered') ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline_rounded,
                      size: 15, color: Colors.grey.shade500),
                  label: Text('Remove from History',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ),
          ] else
            const SizedBox(height: 14),
        ],
      ),
    ),
    );
  }
}

// ─── Item row ─────────────────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  final OrderLineItem item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        // Thumbnail
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: item.imageUrl != null && item.imageUrl!.isNotEmpty
              ? Image.network(item.imageUrl!,
                  width: 42, height: 42, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _thumb())
              : _thumb(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.plantName,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text('${item.vendorName} • ×${item.quantity}',
                  style: const TextStyle(
                      fontSize: 10.5, color: Color(0xFF9E9E9E))),
            ],
          ),
        ),
        Text('₹${(item.price * item.quantity).toStringAsFixed(0)}',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2E7D32))),
      ]),
    );
  }

  Widget _thumb() => Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
            child: Icon(Icons.eco_rounded, size: 18, color: Color(0xFF2E7D32))),
      );
}

// ─── Status tracker ───────────────────────────────────────────────────────────

class _StatusTracker extends StatelessWidget {
  final List<String> steps;
  final int currentStep; // -1 if status not in steps (e.g. cancelled)
  final Color color;
  const _StatusTracker(
      {required this.steps,
      required this.currentStep,
      required this.color});

  static String _label(String s) {
    switch (s) {
      case 'placed':           return 'Placed';
      case 'confirmed':        return 'Confirmed';
      case 'ready':            return 'Ready';
      case 'collected':        return 'Collected';
      case 'packed':           return 'Packed';
      case 'out_for_delivery': return 'On the way';
      case 'delivered':        return 'Delivered';
      default:                 return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final lineIndex = i ~/ 2;
          final filled = currentStep > lineIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: filled ? color : const Color(0xFFE0E0E0),
            ),
          );
        }
        // Step circle
        final stepIndex = i ~/ 2;
        final done = currentStep >= stepIndex;
        final active = currentStep == stepIndex;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: active ? 22 : 18,
              height: active ? 22 : 18,
              decoration: BoxDecoration(
                color: done ? color : const Color(0xFFE0E0E0),
                shape: BoxShape.circle,
                boxShadow: active
                    ? [
                        BoxShadow(
                            color: color.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2))
                      ]
                    : null,
              ),
              child: done
                  ? Icon(
                      active
                          ? Icons.radio_button_checked_rounded
                          : Icons.check_rounded,
                      size: active ? 13 : 12,
                      color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              _label(steps[stepIndex]),
              style: TextStyle(
                  fontSize: 8,
                  fontWeight:
                      active ? FontWeight.w800 : FontWeight.w500,
                  color: done ? color : const Color(0xFFBDBDBD)),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }),
    );
  }
}
