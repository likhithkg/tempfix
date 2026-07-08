import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'green_bazaar_service.dart';
import 'green_bazaar_models.dart';

class OrderTrackingPage extends StatefulWidget {
  final String orderId;
  const OrderTrackingPage({super.key, required this.orderId});
  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  final _svc = GreenBazaarService();
  PlantOrder? _order;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final o = await _svc.getOrder(widget.orderId);
    if (mounted) {
      setState(() {
        _order = o;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text('Order Tracking',
            style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('Order not found'))
              : _buildBody(_order!),
    );
  }

  Widget _buildBody(PlantOrder order) {
    final isCancelled = order.status == 'cancelled';
    final steps = PlantOrder.statusStepsForType(order.orderType);
    final currentIdx = isCancelled ? -1 : steps.indexOf(order.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order placed confirmation
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(children: [
              const Text('🌱',
                  style: TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(
                isCancelled ? 'Order Cancelled' : 'Order Placed!',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                'Order ID: #${order.id.substring(0, 8).toUpperCase()}',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd MMM yyyy, h:mm a').format(order.createdAt),
                style: const TextStyle(
                    color: Colors.white60, fontSize: 11),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          // Status timeline
          _card([
            const _SH(icon: Icons.local_shipping_rounded, title: 'Delivery Status'),
            const SizedBox(height: 16),
            if (isCancelled)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(children: [
                  Icon(Icons.cancel_rounded, color: Color(0xFFD32F2F)),
                  SizedBox(width: 8),
                  Text('This order has been cancelled',
                      style: TextStyle(
                          color: Color(0xFFD32F2F),
                          fontWeight: FontWeight.w600)),
                ]),
              )
            else
              Column(
                children: List.generate(steps.length, (i) {
                  final label = PlantOrder.statusLabel(steps[i]);
                  final done = i <= currentIdx;
                  final active = i == currentIdx;
                  return _TimelineStep(
                    label: label,
                    done: done,
                    active: active,
                    isLast: i == steps.length - 1,
                  );
                }),
              ),
          ]),

          const SizedBox(height: 16),

          // Delivery address (only for delivery orders with an address)
          if (order.address != null) ...[
            _card([
              const _SH(icon: Icons.location_on_rounded, title: 'Delivery Address'),
              const SizedBox(height: 10),
              Text(order.address!.name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(order.address!.phone,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF757575))),
              const SizedBox(height: 4),
              Text(order.address!.formatted,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF757575), height: 1.4)),
            ]),
            const SizedBox(height: 16),
          ],

          // Order items
          _card([
            const _SH(icon: Icons.shopping_bag_rounded, title: 'Order Items'),
            const SizedBox(height: 10),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                          child: Text('🌿',
                              style: TextStyle(fontSize: 18))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.plantName,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text(item.vendorName,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF9E9E9E))),
                        ],
                      ),
                    ),
                    Text(
                      'x${item.quantity}  ₹${(item.price * item.quantity).toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ]),
                )),
            const Divider(height: 16),
            _priceRow('Items Total', '₹${order.itemsTotal.toStringAsFixed(2)}'),
            const SizedBox(height: 4),
            _priceRow('Delivery', '₹${order.deliveryCharge.toStringAsFixed(0)}'),
            const SizedBox(height: 4),
            _priceRow('Grand Total', '₹${order.grandTotal.toStringAsFixed(2)}',
                bold: true),
            const SizedBox(height: 4),
            _priceRow(
              'Payment',
              order.paymentMethod == 'cod'
                  ? 'Cash on Delivery'
                  : 'Online Payment',
            ),
          ]),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              icon: const Icon(Icons.local_florist_rounded),
              label: const Text('Continue Shopping'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2E7D32)),
                foregroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(List<Widget> children) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _priceRow(String label, String value, {bool bold = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
                  color: bold ? null : const Color(0xFF757575))),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
                  color: bold ? const Color(0xFF2E7D32) : null)),
        ],
      );
}

class _TimelineStep extends StatelessWidget {
  final String label;
  final bool done, active, isLast;
  const _TimelineStep(
      {required this.label,
      required this.done,
      required this.active,
      required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: done
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFE0E0E0),
              shape: BoxShape.circle,
              border: active
                  ? Border.all(color: const Color(0xFF2E7D32), width: 2)
                  : null,
            ),
            child: done
                ? const Icon(Icons.check_rounded,
                    color: Colors.white, size: 14)
                : null,
          ),
          if (!isLast)
            Container(
              width: 2,
              height: 32,
              color: done
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFE0E0E0),
            ),
        ]),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  active ? FontWeight.w800 : FontWeight.w500,
              color: done
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFF9E9E9E),
            ),
          ),
        ),
      ],
    );
  }
}

class _SH extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SH({required this.icon, required this.title});
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 18, color: const Color(0xFF2E7D32)),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800)),
      ]);
}
