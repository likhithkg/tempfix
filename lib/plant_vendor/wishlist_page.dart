import 'package:flutter/material.dart';

import 'green_bazaar_service.dart';
import 'green_bazaar_models.dart';
import 'cart_page.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});
  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final _svc = GreenBazaarService();
  late final Stream<List<WishlistItem>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = _svc.streamWishlist();
  }

  Future<void> _moveToCart(WishlistItem wi) async {
    try {
      await _svc.moveWishlistToCart(wi);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${wi.plantName} moved to cart'),
          backgroundColor: const Color(0xFF2E7D32),
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const CartPage())),
          ),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to move to cart. Please try again.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Color _accent(String type) {
    final t = type.toLowerCase();
    if (t.contains('fruit')) return const Color(0xFFE67E22);
    if (t.contains('flower')) return const Color(0xFFE91E8C);
    if (t.contains('vegetable')) return const Color(0xFF27AE60);
    if (t.contains('medicinal')) return const Color(0xFF16A085);
    if (t.contains('ornamental')) return const Color(0xFF8E44AD);
    return const Color(0xFF2E7D32);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text('My Wishlist',
            style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
      ),
      body: StreamBuilder<List<WishlistItem>>(
        stream: _stream,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('💚', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                const Text('Your wishlist is empty',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('Save plants you love to buy later',
                    style: TextStyle(color: Color(0xFF9E9E9E))),
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

          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(children: [
                Text('${items.length} saved plants',
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF757575),
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    try {
                      for (final wi in items) {
                        await _svc.moveWishlistToCart(wi);
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text('All items moved to cart'),
                          backgroundColor: const Color(0xFF2E7D32),
                          action: SnackBarAction(
                            label: 'View Cart',
                            textColor: Colors.white,
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const CartPage())),
                          ),
                        ));
                      }
                    } catch (_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to move items to cart'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Add All to Cart',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E7D32))),
                ),
              ]),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final wi = items[i];
                  final accent = _accent(wi.type);
                  final hasImg = (wi.imageUrl ?? '').isNotEmpty;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.07),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(18)),
                            child: hasImg
                                ? Image.network(wi.imageUrl!,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _Placeholder(
                                            accent: accent))
                                : _Placeholder(accent: accent),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () async {
                                try {
                                  await _svc.removeFromWishlist(wi.vendorId);
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to remove from wishlist'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    Icons.favorite_rounded,
                                    size: 15,
                                    color: Color(0xFFE53935)),
                              ),
                            ),
                          ),
                        ]),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(9),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(wi.plantName,
                                    style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                Text(wi.vendorName,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF9E9E9E)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const Spacer(),
                                Row(children: [
                                  Text(
                                    '₹${wi.price.toStringAsFixed(0)}',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: accent),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () => _moveToCart(wi),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: accent,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: const Text('Add',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800)),
                                    ),
                                  ),
                                ]),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ]);
        },
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final Color accent;
  const _Placeholder({required this.accent});
  @override
  Widget build(BuildContext context) => Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.3),
              accent.withValues(alpha: 0.6)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Icon(Icons.local_florist_rounded,
              size: 36, color: Colors.white.withValues(alpha: 0.5)),
        ),
      );
}
