import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'green_bazaar_service.dart';
import 'green_bazaar_models.dart';
import 'checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});
  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _svc = GreenBazaarService();
  late final Stream<List<CartItem>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = _svc.streamCart();
  }

  double _total(List<CartItem> items) =>
      items.fold(0, (s, i) => s + i.price * i.orderQty);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text('My Cart',
            style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
        actions: [
          StreamBuilder<List<CartItem>>(
            stream: _stream,
            builder: (_, snap) {
              final items = snap.data ?? [];
              if (items.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Clear Cart?'),
                      content: const Text(
                          'All items will be removed from the cart.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD32F2F)),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    try {
                      await _svc.clearCart();
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Failed to clear cart'),
                          backgroundColor: Colors.red,
                        ));
                      }
                    }
                  }
                },
                child: const Text('Clear',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<CartItem>>(
        stream: _stream,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                const Text('Failed to load cart',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('${snap.error}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                    textAlign: TextAlign.center),
              ]),
            );
          }
          final items = snap.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('🛒',
                    style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                const Text('Your cart is empty',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('Add plants to get started',
                    style: TextStyle(
                        color: Color(0xFF9E9E9E))),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.local_florist_rounded),
                  label: const Text('Browse Plants'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white),
                ),
              ]),
            );
          }

          final total = _total(items);
          const delivery = 49.0;
          final grand = total + delivery;

          return Column(children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  return _CartTile(item: item, svc: _svc);
                },
              ),
            ),

            // Price summary + checkout
            Container(
              padding: EdgeInsets.fromLTRB(
                  16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4))
                ],
              ),
              child: Column(children: [
                _priceRow('Items total', '₹${total.toStringAsFixed(2)}',
                    isBold: false),
                const SizedBox(height: 4),
                _priceRow('Delivery charge', '₹${delivery.toStringAsFixed(0)}',
                    isBold: false,
                    valueColor: const Color(0xFF2E7D32)),
                const Divider(height: 16),
                _priceRow('Grand Total', '₹${grand.toStringAsFixed(2)}',
                    isBold: true),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: uid.isEmpty
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CheckoutPage(
                                  items: items,
                                  itemsTotal: total,
                                  deliveryCharge: delivery,
                                ),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_bag_rounded),
                        const SizedBox(width: 8),
                        Text(
                          'Proceed to Checkout  ₹${grand.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
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

  Widget _priceRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isBold ? FontWeight.w800 : FontWeight.w400,
                color: isBold ? null : const Color(0xFF616161))),
        Text(value,
            style: TextStyle(
                fontSize: isBold ? 15 : 13,
                fontWeight:
                    isBold ? FontWeight.w900 : FontWeight.w600,
                color: valueColor ?? (isBold ? const Color(0xFF2E7D32) : null))),
      ],
    );
  }
}

class _CartTile extends StatelessWidget {
  final CartItem item;
  final GreenBazaarService svc;
  const _CartTile({required this.item, required this.svc});

  Color _accent() {
    final t = item.type.toLowerCase();
    if (t.contains('fruit')) return const Color(0xFFE67E22);
    if (t.contains('flower')) return const Color(0xFFE91E8C);
    if (t.contains('vegetable')) return const Color(0xFF27AE60);
    return const Color(0xFF2E7D32);
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent();
    final hasImg = (item.imageUrl ?? '').isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        // Image
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: hasImg
              ? Image.network(item.imageUrl!,
                  width: 70, height: 70, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imgPlaceholder(accent))
              : _imgPlaceholder(accent),
        ),
        const SizedBox(width: 12),
        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.plantName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(item.vendorName,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9E9E9E)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Row(children: [
                Text('₹${item.price.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: accent)),
                const Spacer(),
                // Qty stepper
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    _stepBtn(
                      icon: Icons.remove_rounded,
                      onTap: () async {
                        try {
                          await svc.updateCartQty(
                              item.vendorId, item.orderQty - 1);
                        } catch (_) {
                          if (context.mounted) {
                            _showError(context, 'Could not update quantity');
                          }
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('${item.orderQty}',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800)),
                    ),
                    _stepBtn(
                      icon: Icons.add_rounded,
                      onTap: () async {
                        try {
                          await svc.updateCartQty(
                              item.vendorId, item.orderQty + 1);
                        } catch (_) {
                          if (context.mounted) {
                            _showError(context, 'Could not update quantity');
                          }
                        }
                      },
                    ),
                  ]),
                ),
              ]),
            ],
          ),
        ),
        // Delete
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              color: Color(0xFF9E9E9E), size: 20),
          onPressed: () async {
            try {
              await svc.removeFromCart(item.vendorId);
            } catch (_) {
              if (context.mounted) {
                _showError(context, 'Could not remove item');
              }
            }
          },
        ),
      ]),
    );
  }

  Widget _stepBtn({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: const Color(0xFF2E7D32)),
      ),
    );
  }

  Widget _imgPlaceholder(Color accent) => Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent.withValues(alpha: 0.3), accent.withValues(alpha: 0.6)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.local_florist_rounded,
            size: 30, color: Colors.white.withValues(alpha: 0.6)),
      );
}
