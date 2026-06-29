import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'plant_vendor_model.dart';
import 'plant_detail_page.dart';
import 'green_bazaar_service.dart';
import 'green_bazaar_models.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NurseryProfilePage extends StatelessWidget {
  final String nurseryName;
  final List<PlantVendor> allPlants;
  const NurseryProfilePage(
      {super.key, required this.nurseryName, required this.allPlants});

  List<PlantVendor> get _nurseryPlants =>
      allPlants.where((v) => v.vendorName == nurseryName).toList();

  Color _accentFor(PlantVendor v) {
    final lower = v.type.toLowerCase();
    if (lower.contains('fruit')) return const Color(0xFFE67E22);
    if (lower.contains('flower')) return const Color(0xFFE91E8C);
    if (lower.contains('vegetable')) return const Color(0xFF27AE60);
    if (lower.contains('medicinal')) return const Color(0xFF16A085);
    if (lower.contains('ornamental')) return const Color(0xFF8E44AD);
    return const Color(0xFF2E7D32);
  }

  Future<void> _call(BuildContext ctx, String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsapp(BuildContext ctx, String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plants = _nurseryPlants;
    final phone =
        plants.isNotEmpty ? plants.first.phone : '';
    final location =
        plants.isNotEmpty ? plants.first.location : '';
    final totalTypes =
        plants.map((v) => v.type.split(' - ').first).toSet().length;
    final gbService = GreenBazaarService();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      body: CustomScrollView(
        slivers: [
          // Cover + profile
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF1B5E20),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(fit: StackFit.expand, children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1A5E20), Color(0xFF66BB6A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F8F1),
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24)),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: const Center(
                          child: Text('🌿', style: TextStyle(fontSize: 32)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        nurseryName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(color: Colors.black38, blurRadius: 4)
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  Row(children: [
                    _stat('${plants.length}', 'Plants'),
                    const SizedBox(width: 16),
                    _stat('$totalTypes', 'Categories'),
                    const SizedBox(width: 16),
                    _stat('4.5⭐', 'Rating'),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              size: 12, color: Color(0xFF1565C0)),
                          SizedBox(width: 4),
                          Text('Verified Nursery',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1565C0))),
                        ],
                      ),
                    ),
                  ]),

                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      const Icon(Icons.location_on_rounded,
                          size: 16, color: Color(0xFF9E9E9E)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(location,
                            style: const TextStyle(
                                fontSize: 12.5, color: Color(0xFF757575))),
                      ),
                    ]),
                  ],

                  const SizedBox(height: 16),

                  // Contact buttons
                  if (phone.isNotEmpty)
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _call(context, phone),
                          icon: const Icon(Icons.call_rounded, size: 16),
                          label: const Text('Call'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2E7D32)),
                            foregroundColor: const Color(0xFF2E7D32),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _whatsapp(context, phone),
                          icon: const Icon(Icons.chat_rounded, size: 16),
                          label: const Text('WhatsApp'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ]),

                  const SizedBox(height: 24),

                  const Text('All Plants',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Plant grid
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final v = plants[i];
                  final accent = _accentFor(v);
                  final hasImage = (v.imageUrl ?? '').isNotEmpty;
                  return GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => PlantDetailPage(vendor: v))),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
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
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                            child: hasImage
                                ? Image.network(v.imageUrl!,
                                    height: 110,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _ImgPlaceholder(accent: accent))
                                : _ImgPlaceholder(accent: accent),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(v.plantName,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('₹${v.price.toStringAsFixed(0)}',
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                              color: accent)),
                                      GestureDetector(
                                        onTap: () async {
                                          final uid = FirebaseAuth
                                              .instance.currentUser?.uid ?? '';
                                          if (uid.isEmpty) return;
                                          final ci = CartItem(
                                            id: v.id,
                                            vendorId: v.id,
                                            plantName: v.plantName,
                                            vendorName: v.vendorName,
                                            price: v.price,
                                            imageUrl: v.imageUrl,
                                            type: v.type,
                                            orderQty: 1,
                                            userId: uid,
                                            addedAt: DateTime.now(),
                                          );
                                          await gbService.addToCart(ci);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                              content: Text(
                                                  '${v.plantName} added to cart'),
                                              backgroundColor:
                                                  const Color(0xFF2E7D32),
                                              duration:
                                                  const Duration(seconds: 1),
                                            ));
                                          }
                                        },
                                        child: Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            color: accent,
                                            borderRadius:
                                                BorderRadius.circular(7),
                                          ),
                                          child: const Icon(Icons.add_rounded,
                                              color: Colors.white, size: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: plants.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w900)),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: Color(0xFF9E9E9E))),
        ],
      );
}

class _ImgPlaceholder extends StatelessWidget {
  final Color accent;
  const _ImgPlaceholder({required this.accent});
  @override
  Widget build(BuildContext context) => Container(
        height: 110,
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
