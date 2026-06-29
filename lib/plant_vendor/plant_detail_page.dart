// lib/plant_vendor/plant_detail_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:krishimithra/plant_vendor/plant_vendor_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../services/content_translation_service.dart';
import 'green_bazaar_service.dart';
import 'green_bazaar_models.dart';
import 'cart_page.dart';
import 'nursery_profile_page.dart';

class PlantDetailPage extends StatefulWidget {
  final PlantVendor vendor;
  const PlantDetailPage({super.key, required this.vendor});
  @override
  State<PlantDetailPage> createState() => _PlantDetailPageState();
}

class _PlantDetailPageState extends State<PlantDetailPage> {
  final _gbSvc = GreenBazaarService();
  bool _wishlisted = false;
  bool _inCart = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final w = await _gbSvc.isWishlisted(widget.vendor.id);
    final c = await _gbSvc.isInCart(widget.vendor.id);
    if (mounted) setState(() { _wishlisted = w; _inCart = c; });
  }

  Future<void> _toggleWish() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final wi = WishlistItem(
      id: widget.vendor.id,
      vendorId: widget.vendor.id,
      plantName: widget.vendor.plantName,
      vendorName: widget.vendor.vendorName,
      price: widget.vendor.price,
      imageUrl: widget.vendor.imageUrl,
      type: widget.vendor.type,
      userId: uid,
      savedAt: DateTime.now(),
    );
    await _gbSvc.toggleWishlist(wi);
    if (mounted) setState(() => _wishlisted = !_wishlisted);
  }

  Future<void> _addToCart() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to add to cart')));
      }
      return;
    }
    final ci = CartItem(
      id: widget.vendor.id,
      vendorId: widget.vendor.id,
      plantName: widget.vendor.plantName,
      vendorName: widget.vendor.vendorName,
      price: widget.vendor.price,
      imageUrl: widget.vendor.imageUrl,
      type: widget.vendor.type,
      orderQty: 1,
      userId: uid,
      addedAt: DateTime.now(),
    );
    await _gbSvc.addToCart(ci);
    if (mounted) {
      setState(() => _inCart = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${widget.vendor.plantName} added to cart'),
        backgroundColor: const Color(0xFF2E7D32),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CartPage())),
        ),
      ));
    }
  }

  // Keeps original static helpers but now delegated
  PlantVendor get vendor => widget.vendor;

  String _formatDate(DateTime date) => DateFormat.yMMMEd().add_jm().format(date);

  // Plant care data derived from type
  Map<String, String> _careInfo() {
    final lower = vendor.type.toLowerCase();
    if (lower.contains('fruit')) {
      return {
        'Sunlight': 'Full Sun (6-8 hrs)',
        'Watering': 'Deep water weekly',
        'Soil': 'Well-drained, loamy',
        'Fertilizer': 'NPK monthly in growing season',
        'Growth': '2-5 years to fruit',
        'Temperature': '18-35°C',
      };
    }
    if (lower.contains('vegetable')) {
      return {
        'Sunlight': 'Full Sun (5-6 hrs)',
        'Watering': '2-3 times per week',
        'Soil': 'Rich compost mix',
        'Fertilizer': 'Organic compost biweekly',
        'Growth': '30-90 days to harvest',
        'Temperature': '15-30°C',
      };
    }
    if (lower.contains('medicinal') || lower.contains('aromatic')) {
      return {
        'Sunlight': 'Partial to Full Sun',
        'Watering': 'Moderate, avoid waterlogging',
        'Soil': 'Sandy loam, well-drained',
        'Fertilizer': 'Light compost quarterly',
        'Growth': 'Perennial, harvest leaves anytime',
        'Temperature': '20-38°C',
      };
    }
    if (lower.contains('ornamental') || lower.contains('flower')) {
      return {
        'Sunlight': 'Bright indirect light',
        'Watering': 'Keep soil moist, not soggy',
        'Soil': 'Peat-rich potting mix',
        'Fertilizer': 'Liquid fertilizer monthly',
        'Growth': 'Blooms seasonally',
        'Temperature': '16-28°C',
      };
    }
    return {
      'Sunlight': 'Full to Partial Sun',
      'Watering': 'Moderate watering',
      'Soil': 'Well-drained garden soil',
      'Fertilizer': 'Balanced NPK quarterly',
      'Growth': 'Varies by variety',
      'Temperature': '15-35°C',
    };
  }

  Future<void> _call(BuildContext context, String? phone) async {
    final p = (phone ?? '').trim();
    if (p.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.notProvided)),
      );
      return;
    }
    final uri = Uri.parse('tel:$p');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.cannotOpenDialer)),
      );
    }
  }

  Future<void> _whatsapp(BuildContext context, String? phone) async {
    final p = (phone ?? '').trim();
    if (p.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.notProvided)),
      );
      return;
    }
    final uri = Uri.parse(
        'https://wa.me/$p?text=Hi, I am interested in ${vendor.plantName}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.couldNotOpenWhatsApp)),
      );
    }
  }

  Future<void> _openMap(BuildContext context, double? lat, double? lng) async {
    if (lat == null || lng == null || (lat == 0.0 && lng == 0.0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.locationNotAvailable)),
      );
      return;
    }
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.locationNotAvailable)),
      );
    }
  }

  // Category-specific accent color
  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'fruit':       return const Color(0xFFE67E22);
      case 'flowering':   return const Color(0xFFE91E8C);
      case 'vegetable':   return const Color(0xFF27AE60);
      case 'medicinal':   return const Color(0xFF16A085);
      case 'ornamental':  return const Color(0xFF8E44AD);
      case 'timber':      return const Color(0xFF795548);
      case 'aromatic':    return const Color(0xFF00897B);
      case 'seeds':       return const Color(0xFFF39C12);
      default:            return const Color(0xFF2E7D32);
    }
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fruit':       return Icons.apple;
      case 'flowering':   return Icons.local_florist;
      case 'vegetable':   return Icons.eco;
      case 'medicinal':   return Icons.healing;
      case 'ornamental':  return Icons.yard;
      case 'timber':      return Icons.forest;
      case 'aromatic':    return Icons.spa;
      case 'seeds':       return Icons.grass;
      default:            return Icons.local_florist;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final langCode = Localizations.localeOf(context).languageCode;

    final plantName = vendor.plantName.isNotEmpty ? vendor.plantName : l.unknownVendor;
    final rawType = vendor.type.isNotEmpty ? vendor.type : l.plant;
    final typeParts = rawType.split(' - ');
    final category = typeParts.first;
    final translatedCategory =
        ContentTranslationService.translatePlantCategory(category, langCode);
    final translatedType =
        ContentTranslationService.translatePlantCategory(rawType, langCode);

    final vendorName =
        vendor.vendorName.isNotEmpty ? vendor.vendorName : l.unknownVendor;
    final phone = vendor.phone;
    final location = vendor.location.isNotEmpty
        ? ContentTranslationService.translateLocation(vendor.location, langCode)
        : l.notProvided;
    final imageUrl = (vendor.imageUrl ?? '').trim();
    final hasImage = imageUrl.isNotEmpty;
    final listedOn = _formatDate(vendor.timestamp);
    final description = vendor.description.isNotEmpty
        ? vendor.description
        : l.noDescriptionProvided;

    final accent = _categoryColor(category);
    final catIcon = _categoryIcon(category);
    final care = _careInfo();
    final discountPct = (vendor.id.hashCode.abs() % 3 + 1) * 5;
    final mrp = (vendor.price * (1 + discountPct / 100)).roundToDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      body: Stack(
        children: [
          // ── Scrollable content ───────────────────────────────────────
          CustomScrollView(
            slivers: [
              // ── Hero image sliver app bar ──────────────────────────
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: accent,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor: Colors.black38,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                actions: [
                  // Wishlist button
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircleAvatar(
                      backgroundColor: Colors.black38,
                      child: IconButton(
                        icon: Icon(
                          _wishlisted
                              ? Icons.favorite_rounded
                              : Icons.favorite_outline_rounded,
                          color: _wishlisted
                              ? const Color(0xFFFF5252)
                              : Colors.white,
                        ),
                        onPressed: _toggleWish,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircleAvatar(
                      backgroundColor: Colors.black38,
                      child: IconButton(
                        icon: const Icon(Icons.map_outlined, color: Colors.white),
                        onPressed: () =>
                            _openMap(context, vendor.latitude, vendor.longitude),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      hasImage
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _placeholder(accent, catIcon),
                            )
                          : _placeholder(accent, catIcon),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.65),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(catIcon, size: 13, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    translatedCategory.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              plantName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                              ),
                            ),
                            // Nursery name chip
                            if (vendorName.isNotEmpty)
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => NurseryProfilePage(
                                      nurseryName: vendorName,
                                      allPlants: [],
                                    ),
                                  ),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    const Icon(Icons.store_rounded,
                                        size: 10, color: Colors.white70),
                                    const SizedBox(width: 4),
                                    Text(vendorName,
                                        style: const TextStyle(
                                            color: Colors.white70, fontSize: 10)),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified_rounded,
                                        size: 10, color: Color(0xFF90CAF9)),
                                  ]),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Body content ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 130),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Price card ──────────────────────────────────
                      Row(children: [
                        Expanded(
                          child: _statCard(
                            icon: Icons.currency_rupee,
                            iconColor: accent,
                            label: l.priceLabel,
                            value: '₹${vendor.price.toStringAsFixed(0)}',
                            valueBig: true,
                            accent: accent,
                            subtitle: 'MRP ₹${mrp.toStringAsFixed(0)} ($discountPct% off)',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            icon: Icons.inventory_2_outlined,
                            iconColor: vendor.quantity <= 5
                                ? const Color(0xFFE53935)
                                : Colors.blueGrey,
                            label: l.quantityLabel,
                            value: vendor.quantity > 0
                                ? '${vendor.quantity} left'
                                : 'Out of stock',
                            valueBig: true,
                            accent: vendor.quantity <= 5
                                ? const Color(0xFFE53935)
                                : Colors.blueGrey,
                          ),
                        ),
                      ]),

                      const SizedBox(height: 20),

                      // ── Details card ────────────────────────────────
                      _sectionCard(
                        children: [
                          _infoTile(
                            icon: catIcon,
                            iconColor: accent,
                            label: l.typeLabel,
                            value: translatedType,
                          ),
                          _divider(),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NurseryProfilePage(
                                    nurseryName: vendorName, allPlants: []),
                              ),
                            ),
                            child: _infoTile(
                              icon: Icons.store_rounded,
                              iconColor: const Color(0xFF1565C0),
                              label: l.vendorLabel,
                              value: vendorName,
                              trailing: const Icon(Icons.chevron_right,
                                  size: 16, color: Color(0xFF9E9E9E)),
                            ),
                          ),
                          _divider(),
                          _infoTile(
                            icon: Icons.location_on_outlined,
                            iconColor: const Color(0xFFC62828),
                            label: l.locationLabel,
                            value: location,
                          ),
                          _divider(),
                          _infoTile(
                            icon: Icons.calendar_today_outlined,
                            iconColor: Colors.grey.shade600,
                            label: l.listedOnLabel,
                            value: listedOn,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Plant care guide ────────────────────────────
                      _sectionCard(
                        children: [
                          Row(children: [
                            Icon(Icons.eco_rounded, color: accent, size: 20),
                            const SizedBox(width: 8),
                            Text('Plant Care Guide',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: accent)),
                          ]),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: care.entries.map((e) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(e.key,
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: accent,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text(e.value,
                                        style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Description card ────────────────────────────
                      _sectionCard(
                        children: [
                          Row(children: [
                            Icon(Icons.description_outlined,
                                color: accent, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              l.descriptionHeader,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: accent),
                            ),
                          ]),
                          const SizedBox(height: 10),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              height: 1.5,
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

          // ── Fixed bottom action bar ──────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(children: [
                // Cart button
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: vendor.quantity == 0 ? null : _addToCart,
                    icon: Icon(_inCart
                        ? Icons.shopping_cart_rounded
                        : Icons.add_shopping_cart_rounded),
                    label: Text(
                      _inCart ? 'In Cart' : 'Add to Cart',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _inCart ? const Color(0xFF1565C0) : accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Call button
                _iconBtn(
                  Icons.call_rounded,
                  accent,
                  () => _call(context, phone),
                ),
                const SizedBox(width: 8),
                // WhatsApp button
                _iconBtn(
                  Icons.chat_rounded,
                  const Color(0xFF25D366),
                  () => _whatsapp(context, phone),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _placeholder(Color accent, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.3),
            accent.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Center(
        child: Icon(icon, size: 100, color: Colors.white.withValues(alpha: 0.8)),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool valueBig = false,
    required Color accent,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: valueBig ? 20 : 15,
              fontWeight: FontWeight.w800,
              color: iconColor,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF9E9E9E))),
          ],
        ],
      ),
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _divider() => Divider(
        height: 1,
        color: Colors.grey.shade100,
        indent: 44,
      );
}
