import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'f2b_models.dart';
import 'f2b_cart_service.dart';

/// Buyer's purchase history — shows all f2b_orders where userId == currentUser.uid.
class F2BBuyerOrdersPage extends StatelessWidget {
  const F2BBuyerOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text('My Purchase Orders',
            style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
      ),
      body: StreamBuilder<List<F2BOrder>>(
        stream: F2BCartService().streamBuyerOrders(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('Could not load orders: ${snap.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red)),
              ]),
            );
          }
          final orders = snap.data ?? [];
          if (orders.isEmpty) {
            return const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.shopping_cart_rounded, size: 56, color: Color(0xFF9E9E9E)),
                SizedBox(height: 14),
                Text('No purchase orders yet',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text('Browse GreenBazaar and start shopping!',
                    style:
                        TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
              ]),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: orders.length,
            itemBuilder: (_, i) => _BuyerOrderCard(order: orders[i]),
          );
        },
      ),
    );
  }
}

// ─── Order card (buyer view) ──────────────────────────────────────────────────

class _BuyerOrderCard extends StatelessWidget {
  final F2BOrder order;
  const _BuyerOrderCard({required this.order});

  Color _statusColor(String s) {
    switch (s) {
      case 'placed':    return const Color(0xFFF39C12);
      case 'confirmed': return const Color(0xFF1565C0);
      case 'ready':     return const Color(0xFF6A1B9A);
      case 'collected': return const Color(0xFF1B5E20);
      case 'cancelled': return Colors.grey;
      default:          return const Color(0xFF757575);
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

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);

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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ───────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.08),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Row(children: [
            const Icon(Icons.receipt_outlined, size: 18),
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
                    Text(_formatDate(order.createdAt),
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
                F2BOrder.statusLabel(order.status),
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor),
              ),
            ),
          ]),
        ),

        // ── Items ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: Column(
            children: order.items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  // Thumbnail
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: item.imageUrl != null &&
                            item.imageUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.agriculture_rounded,
                                  size: 18,
                                  color: Color(0xFF2E7D32)),
                            ),
                          )
                        : const Icon(Icons.agriculture_rounded,
                            size: 18, color: Color(0xFF2E7D32)),
                  ),
                  const SizedBox(width: 10),
                  // Product + seller
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Seller: ${item.farmerName}',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF9E9E9E)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Qty × price
                  Text('×${item.qty}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF9E9E9E))),
                  const SizedBox(width: 8),
                  Text(
                    '₹${(item.price * item.qty).toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B5E20)),
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

        // ── Seller contact (always shown so buyer knows who they ordered from) ──
        if (order.status != 'cancelled')
          _SellerContactSection(
            sellerUid: order.sellerUids.isNotEmpty ? order.sellerUids.first : '',
            sellerName: order.items.isNotEmpty ? order.items.first.farmerName : 'Seller',
            embeddedPhone: order.sellerPhone,
            embeddedLocation: order.sellerLocation,
          ),

        // ── Total + buyer status hint ─────────────────────────────────
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
                    color: Color(0xFF1B5E20)),
              ),
              const Text('Cash on pickup',
                  style:
                      TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
            ]),
            const Spacer(),
            _StatusHint(status: order.status),
          ]),
        ),
      ]),
    );
  }
}

// ─── Buyer-facing status hint ─────────────────────────────────────────────────

class _StatusHint extends StatelessWidget {
  final String status;
  const _StatusHint({required this.status});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String label;
    Color color;
    switch (status) {
      case 'placed':
        icon = Icons.hourglass_empty_rounded;
        label = 'Awaiting confirmation';
        color = const Color(0xFFF39C12);
        break;
      case 'confirmed':
        icon = Icons.check_circle_outline_rounded;
        label = 'Being prepared';
        color = const Color(0xFF1565C0);
        break;
      case 'ready':
        icon = Icons.store_rounded;
        label = 'Ready for pickup!';
        color = const Color(0xFF6A1B9A);
        break;
      case 'collected':
        icon = Icons.done_all_rounded;
        label = 'Collected';
        color = const Color(0xFF1B5E20);
        break;
      case 'cancelled':
        icon = Icons.cancel_outlined;
        label = 'Cancelled';
        color = Colors.grey;
        break;
      default:
        icon = Icons.info_outline;
        label = status;
        color = Colors.grey;
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color)),
    ]);
  }
}

// ─── Seller contact card ──────────────────────────────────────────────────────

class _SellerContactSection extends StatelessWidget {
  final String sellerUid;
  final String sellerName;
  final String? embeddedPhone;
  final String? embeddedLocation;
  const _SellerContactSection({
    required this.sellerUid,
    required this.sellerName,
    this.embeddedPhone,
    this.embeddedLocation,
  });

  @override
  Widget build(BuildContext context) {
    // Use embedded data from order if available — no Firestore query needed
    if (embeddedPhone != null || embeddedLocation != null) {
      return _card(context, embeddedPhone, embeddedLocation, loading: false);
    }
    // Fallback: query export_products for old orders that lack embedded data
    if (sellerUid.isEmpty) return _card(context, null, null, loading: false);
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('export_products')
          .where('ownerId', isEqualTo: sellerUid)
          .limit(1)
          .get(),
      builder: (context, snap) {
        String? phone;
        String? location;
        if (snap.hasData && snap.data!.docs.isNotEmpty) {
          final data = snap.data!.docs.first.data() as Map<String, dynamic>;
          phone = (data['farmerMobile'] as String? ?? '').trim();
          location = (data['location'] as String? ?? '').trim();
          if (phone.isEmpty) phone = null;
          if (location.isEmpty) location = null;
        }
        return _card(context, phone, location,
            loading: snap.connectionState == ConnectionState.waiting);
      },
    );
  }

  Widget _card(BuildContext context, String? phone, String? location,
      {required bool loading}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.storefront_rounded,
                  size: 14, color: Color(0xFF1B5E20)),
              SizedBox(width: 6),
              Text('Seller Details',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B5E20))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.person_outline_rounded,
                  size: 14, color: Color(0xFF555555)),
              const SizedBox(width: 6),
              Text(sellerName,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
            if (loading)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF1B5E20))),
              ),
            if (location != null) ...[
              const SizedBox(height: 6),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: Color(0xFF555555)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(location,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF444444)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            ],
            if (phone != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('tel:$phone')),
                  icon: const Icon(Icons.call_rounded, size: 15),
                  label: Text(phone,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1B5E20),
                    side: const BorderSide(
                        color: Color(0xFF1B5E20), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
            if (!loading && phone == null && location == null)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Contact info not available',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFF9E9E9E))),
              ),
          ],
        ),
      ),
    );
  }
}
