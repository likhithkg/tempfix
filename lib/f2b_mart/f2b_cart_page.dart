import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'f2b_models.dart';
import 'f2b_cart_service.dart';

class F2BCartPage extends StatefulWidget {
  const F2BCartPage({super.key});
  @override
  State<F2BCartPage> createState() => _F2BCartPageState();
}

class _F2BCartPageState extends State<F2BCartPage> {
  final _svc = F2BCartService();
  bool _placing = false;

  Future<void> _confirmTakeAway(
      List<F2BCartItem> items, double total) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _TakeAwaySheet(items: items, total: total),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _placing = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final name = user?.displayName ?? user?.email ?? 'Buyer';
      await _svc.placeTakeAwayOrder(items: items, buyerName: name);
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const _SuccessDialog(),
        );
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Order failed: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text('My Cart',
            style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
      ),
      body: StreamBuilder<List<F2BCartItem>>(
        stream: _svc.streamCart(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('🛒', style: TextStyle(fontSize: 60)),
                const SizedBox(height: 16),
                const Text('Your cart is empty',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('Add products from GreenBazaar F2B Mart',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Browse Products'),
                ),
              ]),
            );
          }

          final total =
              items.fold(0.0, (s, i) => s + i.price * i.qty);

          return Column(children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                itemCount: items.length,
                itemBuilder: (_, i) =>
                    _CartItemCard(item: items[i], svc: _svc),
              ),
            ),
            // Summary + Takeaway
            Container(
              padding: EdgeInsets.fromLTRB(
                  16, 14, 16,
                  MediaQuery.of(context).padding.bottom + 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.09),
                      blurRadius: 12,
                      offset: const Offset(0, -3))
                ],
              ),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Items Total',
                        style: TextStyle(
                            fontSize: 14, color: Color(0xFF757575))),
                    Text('₹${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Grand Total',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    Text('₹${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1B5E20))),
                  ],
                ),
                const SizedBox(height: 14),
                // Takeaway block
                GestureDetector(
                  onTap: _placing
                      ? null
                      : () => _confirmTakeAway(items, total),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF1B5E20)
                                .withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: _placing
                        ? const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('🏪',
                                  style: TextStyle(fontSize: 22)),
                              SizedBox(width: 10),
                              Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Take Away',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white)),
                                    Text('Pick up from the farm/seller',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.white70)),
                                  ]),
                            ],
                          ),
                  ),
                ),
              ]),
            ),
          ]);
        },
      ),
    );
  }
}

// ─── Cart item card ───────────────────────────────────────────────────────────

class _CartItemCard extends StatelessWidget {
  final F2BCartItem item;
  final F2BCartService svc;
  const _CartItemCard({required this.item, required this.svc});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
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
      child: Row(children: [
        // Product image
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 64,
            height: 64,
            color: const Color(0xFFE8F5E9),
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? Image.network(item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.agriculture_rounded,
                            size: 28, color: Color(0xFF2E7D32)))
                : const Icon(Icons.agriculture_rounded,
                    size: 28, color: Color(0xFF2E7D32)),
          ),
        ),
        const SizedBox(width: 12),
        // Info
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.productName,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(item.farmerName,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF9E9E9E))),
            const SizedBox(height: 6),
            Text('₹${item.price.toStringAsFixed(2)} / ${item.priceUnit}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B5E20))),
          ]),
        ),
        const SizedBox(width: 8),
        // Quantity controls
        Column(children: [
          Row(children: [
            _QtyBtn(
              icon: Icons.remove_rounded,
              onTap: () => svc.updateQty(item.productId, item.qty - 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('${item.qty}',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800)),
            ),
            _QtyBtn(
              icon: Icons.add_rounded,
              onTap: () => svc.updateQty(item.productId, item.qty + 1),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            '₹${(item.price * item.qty).toStringAsFixed(2)}',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B5E20)),
          ),
        ]),
      ]),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF1B5E20)),
      ),
    );
  }
}

// ─── Takeaway confirmation sheet ──────────────────────────────────────────────

class _TakeAwaySheet extends StatelessWidget {
  final List<F2BCartItem> items;
  final double total;
  const _TakeAwaySheet({required this.items, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40, height: 4,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2)),
        ),
        const Text('🏪', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 8),
        const Text('Confirm Takeaway Order',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        const Text('Visit the farm/seller to collect your order',
            style: TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              ...items.map((i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Expanded(
                          child: Text(i.productName,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600))),
                      Text('×${i.qty}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      const SizedBox(width: 10),
                      Text(
                          '₹${(i.price * i.qty).toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B5E20))),
                    ]),
                  )),
              const Divider(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  Text('₹${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: Color(0xFF1B5E20))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10)),
          child: const Row(children: [
            Icon(Icons.info_outline_rounded,
                size: 14, color: Colors.amber),
            SizedBox(width: 8),
            Expanded(
                child: Text(
              'Payment: Cash on pickup at the farm/seller',
              style: TextStyle(fontSize: 11, color: Color(0xFF795548)),
            )),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('Confirm Takeaway',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ─── Success dialog ───────────────────────────────────────────────────────────

class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9), shape: BoxShape.circle),
          child: const Icon(Icons.check_circle_rounded,
              color: Color(0xFF2E7D32), size: 52),
        ),
        const SizedBox(height: 16),
        const Text('Order Placed!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text(
          'The seller has been notified.\nVisit the farm/seller to collect.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
        ),
      ]),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Great!',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}
