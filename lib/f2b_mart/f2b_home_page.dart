// lib/f2b_mart/f2b_home_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../exporter_hub/exporter_model.dart';
import '../exporter_hub/exporter_service.dart';
import '../exporter_hub/exporter_form_page.dart';
import '../exporter_hub/nearby_farmers_map_page.dart';
import 'f2b_farmer_dashboard.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../services/content_translation_service.dart';
import 'f2b_product_detail_page.dart';
import 'f2b_search_page.dart';
import 'f2b_shimmer.dart';
import 'f2b_wishlist_page.dart';
import 'f2b_wishlist_service.dart';
import 'f2b_models.dart';
import 'f2b_cart_service.dart';
import 'f2b_cart_page.dart';
import 'f2b_seller_orders_page.dart';

// ─── Data classes ──────────────────────────────────────────────────────────

class _BannerData {
  final String title, subtitle, tag;
  final Color color1, color2;
  final IconData icon;
  const _BannerData({
    required this.title, required this.subtitle, required this.tag,
    required this.color1, required this.color2, required this.icon,
  });
}

class _CatData {
  final String key, label, emoji;
  final Color color1, color2;
  const _CatData(this.key, this.label, this.emoji, this.color1, this.color2);
}

class _FarmerData {
  final String id, name, location;
  final int productCount;
  const _FarmerData({required this.id, required this.name,
      required this.location, required this.productCount});
}

// ─── Page ──────────────────────────────────────────────────────────────────

class F2BHomePage extends StatefulWidget {
  const F2BHomePage({super.key});
  @override
  State<F2BHomePage> createState() => _F2BHomePageState();
}

class _F2BHomePageState extends State<F2BHomePage> {
  final _service = ExporterService();
  final _cartSvc = F2BCartService();
  final _bannerCtrl = PageController();

  String _selectedCategory = 'all';
  int _currentBanner = 0;
  Timer? _bannerTimer;
  Set<String> _wishlistIds = {};
  Set<String> _cartProductIds = {};
  int _cartCount = 0;
  int _newOrderCount = 0;
  StreamSubscription<Set<String>>? _wishlistSub;
  StreamSubscription<List<F2BCartItem>>? _cartSub;
  StreamSubscription<List<F2BOrder>>? _sellerOrderSub;

  static const _banners = [
    _BannerData(
      title: 'Fresh Organic Produce',
      subtitle: 'Farm to table • Verified farmers only',
      tag: '🌿 Organic',
      color1: KMColors.primaryDark, color2: KMColors.primary,
      icon: Icons.eco_rounded,
    ),
    _BannerData(
      title: 'Direct from Farmers',
      subtitle: 'No middlemen • Best prices guaranteed',
      tag: '🤝 Fair Trade',
      color1: KMColors.weatherDark, color2: KMColors.weatherPrimary,
      icon: Icons.handshake_rounded,
    ),
    _BannerData(
      title: 'Seasonal Harvest',
      subtitle: 'Best produce at peak freshness',
      tag: '🌾 Seasonal',
      color1: Color(0xFFBF360C), color2: Color(0xFFE64A19),
      icon: Icons.wb_sunny_rounded,
    ),
    _BannerData(
      title: 'Export Quality Crops',
      subtitle: 'Grade A certified for global markets',
      tag: '⭐ Grade A',
      color1: KMColors.labourDark, color2: KMColors.labourPrimary,
      icon: Icons.verified_rounded,
    ),
    _BannerData(
      title: 'Nearby Farm Fresh',
      subtitle: 'Products from farmers near you',
      tag: '📍 Nearby',
      color1: Color(0xFF006064), color2: Color(0xFF00838F),
      icon: Icons.location_on_rounded,
    ),
  ];

  static const _cats = [
    _CatData('vegetables', 'Vegetables', '🥦', Color(0xFF2E7D32), Color(0xFF66BB6A)),
    _CatData('fruits',     'Fruits',     '🍎', Color(0xFFC62828), Color(0xFFEF5350)),
    _CatData('grains',     'Grains',     '🌾', KMColors.rentPrimary, Color(0xFFFF8F00)),
    _CatData('spices',     'Spices',     '🌶', Color(0xFF880E4F), Color(0xFFAD1457)),
    _CatData('pulses',     'Pulses',     '🫘', Color(0xFF4E342E), Color(0xFF6D4C41)),
    _CatData('crops',      'Crops',      '🌿', KMColors.weatherPrimary, Color(0xFF1976D2)),
    _CatData('flowers',    'Flowers',    '🌸', Color(0xFF880E4F), Color(0xFFE91E63)),
    _CatData('other',      'Other',      '📦', Color(0xFF37474F), Color(0xFF546E7A)),
  ];

  @override
  void initState() {
    super.initState();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      _bannerCtrl.animateToPage(
        (_currentBanner + 1) % _banners.length,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
    _startWishlistListener();
    _cartSub = _cartSvc.streamCart().listen((items) {
      if (mounted) {
        setState(() {
          _cartProductIds = items.map((i) => i.productId).toSet();
          _cartCount = items.length;
        });
      }
    });
    _sellerOrderSub = _cartSvc.streamSellerOrders().listen((orders) {
      if (mounted) {
        setState(() {
          _newOrderCount =
              orders.where((o) => o.status == 'placed').length;
        });
      }
    });
  }

  void _startWishlistListener() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _wishlistSub = WishlistService.stream(uid)
        .listen((ids) { if (mounted) setState(() => _wishlistIds = ids); });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerCtrl.dispose();
    _wishlistSub?.cancel();
    _cartSub?.cancel();
    _sellerOrderSub?.cancel();
    super.dispose();
  }

  List<ExportProduct> _filter(List<ExportProduct> all) {
    if (_selectedCategory == 'all') return all;
    return all.where(
        (p) => p.category.toLowerCase() == _selectedCategory).toList();
  }

  List<_FarmerData> _deriveFarmers(List<ExportProduct> all) {
    final map = <String, _FarmerData>{};
    for (final p in all) {
      if (!map.containsKey(p.farmerId)) {
        map[p.farmerId] = _FarmerData(id: p.farmerId, name: p.farmerName,
            location: p.location, productCount: 1);
      } else {
        final e = map[p.farmerId]!;
        map[p.farmerId] = _FarmerData(id: e.id, name: e.name,
            location: e.location, productCount: e.productCount + 1);
      }
    }
    return (map.values.toList()
          ..sort((a, b) => b.productCount.compareTo(a.productCount)))
        .take(10)
        .toList();
  }

  Future<void> _toggleWishlist(BuildContext ctx, String productId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Sign in to save products')));
      return;
    }
    await WishlistService.toggle(uid, productId);
  }

  Future<void> _addToCart(BuildContext ctx, ExportProduct p) async {
    try {
      await _cartSvc.addToCart(p);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('${p.productName} added to cart'),
          backgroundColor: KMColors.primaryDark,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () => Navigator.push(ctx,
                MaterialPageRoute(builder: (_) => const F2BCartPage())),
          ),
        ));
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('Failed to add to cart: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _editProduct(BuildContext ctx, ExportProduct p) {
    Navigator.push(ctx,
        MaterialPageRoute(
            builder: (_) => ExporterFormPage(
                existingProduct: p, listingSource: 'f2b_mart')));
  }

  Future<void> _deleteProduct(BuildContext ctx, ExportProduct p) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Listing?'),
        content: Text(
            '"${p.productName}" will be permanently removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ExporterService().deleteExportProduct(p.id);
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text('"${p.productName}" deleted'),
            backgroundColor: Colors.red,
          ));
        }
      } catch (e) {
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: Colors.red,
          ));
        }
      }
    }
  }

  void _showRfqDialog(BuildContext ctx) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Sign in to post a requirement')));
      return;
    }
    HapticFeedback.lightImpact();
    final productCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool submitting = false;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (bCtx, setSheet) => Container(
          margin: EdgeInsets.only(
              bottom: MediaQuery.of(bCtx).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              )),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: KMColors.primaryDark.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('📋', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Post Buying Requirement',
                        style: TextStyle(fontSize: 17,
                            fontWeight: FontWeight.w800)),
                    Text('Farmers will respond with offers',
                        style: TextStyle(fontSize: 12,
                            color: KMColors.textSecondary)),
                  ],
                ),
              ]),
              const SizedBox(height: 18),
              TextField(
                controller: productCtrl,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  hintText: 'e.g. Cardamom, Tomato, Rice',
                  prefixIcon: const Icon(Icons.agriculture_rounded),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: qtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: InputDecoration(
                  labelText: 'Quantity Required (Kg / MT)',
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Additional Notes (Grade, Quality, etc.)',
                  prefixIcon: const Icon(Icons.notes_rounded),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: submitting
                      ? null
                      : () async {
                          if (productCtrl.text.trim().isEmpty) return;
                          setSheet(() => submitting = true);
                          try {
                            await FirebaseFirestore.instance
                                .collection('rfq_listings')
                                .add({
                              'buyerId': uid,
                              'productName': productCtrl.text.trim(),
                              'quantity': qtyCtrl.text.trim(),
                              'notes': notesCtrl.text.trim(),
                              'status': 'open',
                              'createdAt': Timestamp.now(),
                            });
                            if (bCtx.mounted) {
                              Navigator.pop(bCtx);
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Requirement posted! Farmers will respond.'),
                                  backgroundColor: Color(0xFF2E7D32),
                                ),
                              );
                            }
                          } catch (_) {
                            setSheet(() => submitting = false);
                          }
                        },
                  icon: submitting
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded),
                  label: const Text('Post Requirement'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KMColors.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final langCode = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor:
          isDark ? KMColors.backgroundDark : const Color(0xFFF3F6F3),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(
                builder: (_) =>
                    const ExporterFormPage(listingSource: 'f2b_mart'))),
        icon: const Icon(Icons.add_rounded),
        label: Text(l.listProduce),
        backgroundColor: KMColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _GBHeader(
            topPad: topPad,
            cartCount: _cartCount,
            newOrderCount: _newOrderCount,
            onBack: Navigator.canPop(context)
                ? () => Navigator.pop(context)
                : null,
            onWishlist: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const F2BWishlistPage())),
            onCart: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const F2BCartPage())),
            onSellerOrders: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const F2BSellerOrdersPage())),
            onDashboard: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const F2BFarmerDashboard())),
            onMap: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const NearbyFarmersMapPage())),
          ),
          _SearchBarTap(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const F2BSearchPage())),
          ),
          Expanded(
            child: StreamBuilder<List<ExportProduct>>(
              stream: _service.getF2BProducts(),
              builder: (ctx, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: KMColors.error),
                      const SizedBox(height: 8),
                      const Text('Could not load products'),
                      TextButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Retry'),
                      ),
                    ]),
                  );
                }
                if (!snap.hasData) {
                  return const SingleChildScrollView(
                      child: F2BShimmerHome());
                }

                final all = snap.data!;
                final trending  = all.take(12).toList();
                final organic   = all.where((p) => p.isOrganic).take(12).toList();
                final exportRdy = all
                    .where((p) => p.grade?.toUpperCase() == 'A')
                    .take(12)
                    .toList();
                final farmers  = _deriveFarmers(all);
                final filtered = _filter(all);

                return RefreshIndicator(
                  color: KMColors.primary,
                  onRefresh: () async => setState(() {}),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _BannerCarousel(
                          banners: _banners,
                          controller: _bannerCtrl,
                          currentIndex: _currentBanner,
                          onPageChanged: (i) =>
                              setState(() => _currentBanner = i),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _CategoryGrid(
                          cats: _cats,
                          selected: _selectedCategory,
                          onSelect: (k) =>
                              setState(() => _selectedCategory = k),
                        ),
                      ),
                      // Trending Now
                      if (trending.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: _SectionHeader(
                            title: 'Trending Now',
                            subtitle: 'Most popular listings',
                            icon: Icons.trending_up_rounded,
                            onSeeAll: () => Navigator.push(ctx,
                                MaterialPageRoute(
                                    builder: (_) => const F2BSearchPage())),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: _HScrollSection(
                            items: trending, langCode: langCode,
                            wishlistIds: _wishlistIds,
                            cartProductIds: _cartProductIds,
                            currentUid: FirebaseAuth.instance.currentUser?.uid ?? '',
                            onTap: (p) => Navigator.push(ctx,
                                MaterialPageRoute(builder: (_) =>
                                    F2BProductDetailPage(product: p))),
                            onWishlist: (p) => _toggleWishlist(ctx, p.id),
                            onAddToCart: (p) => _addToCart(ctx, p),
                            onEdit: (p) => _editProduct(ctx, p),
                            onDelete: (p) => _deleteProduct(ctx, p),
                          ),
                        ),
                      ],
                      // Organic Products
                      if (organic.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: _SectionHeader(
                            title: 'Organic Products',
                            subtitle: 'Certified chemical-free produce',
                            icon: Icons.eco_rounded,
                            iconColor: const Color(0xFF2E7D32),
                            onSeeAll: () => Navigator.push(ctx,
                                MaterialPageRoute(
                                    builder: (_) => const F2BSearchPage())),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: _HScrollSection(
                            items: organic, langCode: langCode,
                            wishlistIds: _wishlistIds,
                            cartProductIds: _cartProductIds,
                            currentUid: FirebaseAuth.instance.currentUser?.uid ?? '',
                            onTap: (p) => Navigator.push(ctx,
                                MaterialPageRoute(builder: (_) =>
                                    F2BProductDetailPage(product: p))),
                            onWishlist: (p) => _toggleWishlist(ctx, p.id),
                            onAddToCart: (p) => _addToCart(ctx, p),
                            onEdit: (p) => _editProduct(ctx, p),
                            onDelete: (p) => _deleteProduct(ctx, p),
                          ),
                        ),
                      ],
                      // Export Ready
                      if (exportRdy.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: _SectionHeader(
                            title: 'Export Ready',
                            subtitle: 'Grade A certified for global markets',
                            icon: Icons.verified_rounded,
                            iconColor: KMColors.weatherPrimary,
                            onSeeAll: () => Navigator.push(ctx,
                                MaterialPageRoute(
                                    builder: (_) => const F2BSearchPage())),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: _HScrollSection(
                            items: exportRdy, langCode: langCode,
                            wishlistIds: _wishlistIds,
                            cartProductIds: _cartProductIds,
                            currentUid: FirebaseAuth.instance.currentUser?.uid ?? '',
                            onTap: (p) => Navigator.push(ctx,
                                MaterialPageRoute(builder: (_) =>
                                    F2BProductDetailPage(product: p))),
                            onWishlist: (p) => _toggleWishlist(ctx, p.id),
                            onAddToCart: (p) => _addToCart(ctx, p),
                            onEdit: (p) => _editProduct(ctx, p),
                            onDelete: (p) => _deleteProduct(ctx, p),
                          ),
                        ),
                      ],
                      // RFQ Banner
                      SliverToBoxAdapter(
                        child: _RfqBanner(
                            onTap: () => _showRfqDialog(ctx)),
                      ),
                      // Featured Farmers
                      if (farmers.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: _SectionHeader(
                            title: 'Featured Farmers',
                            subtitle: 'Top verified suppliers',
                            icon: Icons.people_rounded,
                            iconColor: KMColors.rentPrimary,
                          ),
                        ),
                        SliverToBoxAdapter(
                            child: _FarmersList(farmers: farmers)),
                      ],
                      // All Products + filter
                      SliverToBoxAdapter(
                        child: _AllProductsHeader(
                          cats: _cats,
                          selected: _selectedCategory,
                          count: filtered.length,
                          onSelect: (k) =>
                              setState(() => _selectedCategory = k),
                        ),
                      ),
                      if (filtered.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.storefront_outlined,
                                    size: 60, color: KMColors.textSecondary),
                                const SizedBox(height: 12),
                                Text(
                                  _selectedCategory == 'all'
                                      ? 'No products listed yet'
                                      : 'No $_selectedCategory products yet',
                                  style: const TextStyle(fontSize: 15,
                                      color: KMColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding:
                              const EdgeInsets.fromLTRB(12, 0, 12, 100),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.56,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) {
                                final p = filtered[i];
                                final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                                final isOwner = p.farmerId == uid;
                                return _GridCard(
                                  product: p, langCode: langCode,
                                  isWishlisted: _wishlistIds.contains(p.id),
                                  isInCart: _cartProductIds.contains(p.id),
                                  isOwner: isOwner,
                                  onTap: () => Navigator.push(ctx,
                                      MaterialPageRoute(builder: (_) =>
                                          F2BProductDetailPage(product: p))),
                                  onWishlist: () => _toggleWishlist(ctx, p.id),
                                  onAddToCart: () => _addToCart(ctx, p),
                                  onEdit: () => _editProduct(ctx, p),
                                  onDelete: () => _deleteProduct(ctx, p),
                                );
                              },
                              childCount: filtered.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── GreenBazaar header ────────────────────────────────────────────────────

class _GBHeader extends StatelessWidget {
  final double topPad;
  final int cartCount;
  final int newOrderCount;
  final VoidCallback onWishlist, onCart, onSellerOrders,
      onDashboard, onMap;
  final VoidCallback? onBack;
  const _GBHeader({
    required this.topPad,
    required this.cartCount,
    required this.newOrderCount,
    required this.onWishlist,
    required this.onCart,
    required this.onSellerOrders,
    required this.onDashboard,
    required this.onMap,
    this.onBack,
  });

  Widget _badgeIcon(
      {required IconData icon,
      required VoidCallback onTap,
      required String tooltip,
      int badge = 0}) {
    return Stack(clipBehavior: Clip.none, children: [
      IconButton(
          icon: Icon(icon, size: 22),
          color: Colors.white,
          tooltip: tooltip,
          onPressed: onTap),
      if (badge > 0)
        Positioned(
          top: 6,
          right: 4,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
                color: Colors.amber, shape: BoxShape.circle),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text('$badge',
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.black),
                textAlign: TextAlign.center),
          ),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, topPad + 8, 8, 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [KMColors.primaryDark, Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(children: [
        if (onBack != null)
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 22),
            color: Colors.white,
            tooltip: 'Back',
            onPressed: onBack,
            padding: const EdgeInsets.only(right: 4),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Text('🌿', style: TextStyle(fontSize: 18)),
            SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('GreenBazaar',
                    style: TextStyle(fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white, letterSpacing: -0.3)),
                Text('F2B Mart',
                    style: TextStyle(fontSize: 9.5, color: Colors.white70,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ]),
        ),
        const Spacer(),
        // Seller orders badge (receipt icon)
        _badgeIcon(
            icon: Icons.receipt_long_rounded,
            tooltip: 'My Orders (Seller)',
            badge: newOrderCount,
            onTap: onSellerOrders),
        // Cart badge
        _badgeIcon(
            icon: Icons.shopping_cart_outlined,
            tooltip: 'Cart',
            badge: cartCount,
            onTap: onCart),
        IconButton(
            icon: const Icon(Icons.favorite_border_rounded, size: 22),
            color: Colors.white, tooltip: 'Wishlist', onPressed: onWishlist),
        IconButton(
            icon: const Icon(Icons.storefront_outlined, size: 22),
            color: Colors.white, tooltip: 'Dashboard', onPressed: onDashboard),
        IconButton(
            icon: const Icon(Icons.map_outlined, size: 22),
            color: Colors.white, tooltip: 'Map', onPressed: onMap),
      ]),
    );
  }
}

// ─── Search bar tap target ─────────────────────────────────────────────────

class _SearchBarTap extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchBarTap({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          const Icon(Icons.search_rounded,
              color: Color(0xFF2E7D32), size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Search crops, farmers, location...',
                style: TextStyle(fontSize: 14, color: KMColors.textSecondary)),
          ),
          Container(width: 1, height: 20,
              color: KMColors.divider,
              margin: const EdgeInsets.symmetric(horizontal: 10)),
          const Icon(Icons.mic_rounded, color: Color(0xFF2E7D32), size: 22),
        ]),
      ),
    );
  }
}

// ─── Banner carousel ───────────────────────────────────────────────────────

class _BannerCarousel extends StatelessWidget {
  final List<_BannerData> banners;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  const _BannerCarousel({required this.banners, required this.controller,
      required this.currentIndex, required this.onPageChanged});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: 178,
        child: PageView.builder(
          controller: controller,
          onPageChanged: onPageChanged,
          itemCount: banners.length,
          itemBuilder: (_, i) {
            final b = banners[i];
            return Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                    colors: [b.color1, b.color2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
              ),
              child: Stack(children: [
                Positioned(right: -20, bottom: -20,
                    child: Icon(b.icon, size: 130,
                        color: Colors.white.withValues(alpha: 0.09))),
                Positioned(top: -30, right: 60,
                    child: Container(width: 100, height: 100,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.06)))),
                Positioned(bottom: -10, left: 40,
                    child: Container(width: 60, height: 60,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.06)))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 90, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(b.tag,
                            style: const TextStyle(color: Colors.white,
                                fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 9),
                      Text(b.title,
                          style: const TextStyle(color: Colors.white,
                              fontSize: 21, fontWeight: FontWeight.w900,
                              height: 1.1)),
                      const SizedBox(height: 5),
                      Text(b.subtitle,
                          style: const TextStyle(color: Colors.white70,
                              fontSize: 12)),
                      const SizedBox(height: 11),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(color: Colors.white,
                            borderRadius: BorderRadius.circular(20)),
                        child: const Text('Explore Now',
                            style: TextStyle(fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: KMColors.primaryDark)),
                      ),
                    ],
                  ),
                ),
              ]),
            );
          },
        ),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(banners.length, (i) =>
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            width: i == currentIndex ? 20 : 6, height: 6,
            decoration: BoxDecoration(
              color: i == currentIndex
                  ? KMColors.primaryDark
                  : KMColors.primaryDark.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(3),
            ),
          )),
      ),
      const SizedBox(height: 2),
    ]);
  }
}

// ─── Category grid ─────────────────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  final List<_CatData> cats;
  final String selected;
  final ValueChanged<String> onSelect;
  const _CategoryGrid({required this.cats, required this.selected,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: KMShadow.card,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text('Shop by Category',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                  color: KMColors.textPrimary)),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cats.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.88,
          ),
          itemBuilder: (_, i) {
            final c = cats[i];
            final sel = selected == c.key;
            return GestureDetector(
              onTap: () => onSelect(c.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: sel
                        ? [c.color1, c.color2]
                        : [c.color1.withValues(alpha: 0.09),
                           c.color2.withValues(alpha: 0.13)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: sel
                      ? Border.all(color: c.color1, width: 1.5)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(c.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text(c.label,
                        style: TextStyle(fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: sel ? Colors.white : c.color1),
                        textAlign: TextAlign.center,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            );
          },
        ),
      ]),
    );
  }
}

// ─── Section header ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.subtitle, this.icon,
      this.iconColor, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? KMColors.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 12, 4),
      child: Row(children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: KMColors.textPrimary)),
            if (subtitle != null)
              Text(subtitle!,
                  style: const TextStyle(fontSize: 11,
                      color: KMColors.textSecondary)),
          ],
        )),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('See All',
                  style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: KMColors.primary)),
              Icon(Icons.chevron_right_rounded,
                  size: 16, color: KMColors.primary),
            ]),
          ),
      ]),
    );
  }
}

// ─── Horizontal scroll section ─────────────────────────────────────────────

class _HScrollSection extends StatelessWidget {
  final List<ExportProduct> items;
  final String langCode;
  final Set<String> wishlistIds;
  final Set<String> cartProductIds;
  final String currentUid;
  final ValueChanged<ExportProduct> onTap;
  final ValueChanged<ExportProduct> onWishlist;
  final ValueChanged<ExportProduct> onAddToCart;
  final ValueChanged<ExportProduct> onEdit;
  final ValueChanged<ExportProduct> onDelete;
  const _HScrollSection({
    required this.items,
    required this.langCode,
    required this.wishlistIds,
    required this.cartProductIds,
    required this.currentUid,
    required this.onTap,
    required this.onWishlist,
    required this.onAddToCart,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 228,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final p = items[i];
          final isOwner = p.farmerId == currentUid;
          return _PremiumCard(
            product: p, langCode: langCode,
            isWishlisted: wishlistIds.contains(p.id),
            isInCart: cartProductIds.contains(p.id),
            isOwner: isOwner,
            onTap: () => onTap(p),
            onWishlist: () => onWishlist(p),
            onAddToCart: () => onAddToCart(p),
            onEdit: () => onEdit(p),
            onDelete: () => onDelete(p),
          );
        },
      ),
    );
  }
}

// ─── Shared helpers ────────────────────────────────────────────────────────

Color _catAccent(String cat) {
  switch (cat.toLowerCase()) {
    case 'fruits':     return const Color(0xFFD84315);
    case 'vegetables': return const Color(0xFF2E7D32);
    case 'grains':     return KMColors.rentPrimary;
    case 'spices':     return const Color(0xFF880E4F);
    case 'pulses':     return const Color(0xFF4E342E);
    case 'crops':      return KMColors.weatherPrimary;
    case 'flowers':    return const Color(0xFFE91E63);
    default:           return KMColors.primaryDark;
  }
}

Widget _imgPlaceholder(Color accent) => Container(
  color: accent.withValues(alpha: 0.10),
  child: Center(child: Icon(Icons.agriculture_rounded,
      size: 40, color: accent.withValues(alpha: 0.45))),
);

// ─── Premium card (horizontal scroll) ─────────────────────────────────────

class _PremiumCard extends StatelessWidget {
  final ExportProduct product;
  final String langCode;
  final bool isWishlisted;
  final bool isInCart;
  final bool isOwner;
  final VoidCallback onTap;
  final VoidCallback onWishlist;
  final VoidCallback onAddToCart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _PremiumCard({
    required this.product, required this.langCode,
    required this.isWishlisted, required this.isInCart, required this.isOwner,
    required this.onTap, required this.onWishlist,
    required this.onAddToCart, required this.onEdit, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _catAccent(product.category);
    final name = ContentTranslationService.translateCropName(
        product.productName, langCode);
    final loc = ContentTranslationService.translateLocation(
        product.location, langCode);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: isDark ? KMColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox(
              height: 112, width: 150,
              child: Stack(fit: StackFit.expand, children: [
                product.primaryImage.isNotEmpty
                    ? Image.network(product.primaryImage, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _imgPlaceholder(accent))
                    : _imgPlaceholder(accent),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x55000000)],
                      stops: [0.55, 1.0],
                    ),
                  ),
                ),
                // Top-right: ⋮ for owner, wishlist for others
                Positioned(
                  top: 6, right: 6,
                  child: GestureDetector(
                    onTap: isOwner
                        ? () => _showOwnerSheet(context, onEdit, onDelete)
                        : onWishlist,
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isOwner
                            ? Icons.more_vert_rounded
                            : (isWishlisted ? Icons.favorite : Icons.favorite_border),
                        size: 14,
                        color: isOwner
                            ? KMColors.primaryDark
                            : (isWishlisted ? Colors.red : Colors.grey),
                      ),
                    ),
                  ),
                ),
                // Top-left: My Listing badge (owner) or Organic
                if (isOwner)
                  Positioned(
                    top: 6, left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                          color: KMColors.primaryDark,
                          borderRadius: BorderRadius.circular(8)),
                      child: const Text('My Listing',
                          style: TextStyle(color: Colors.white,
                              fontSize: 8, fontWeight: FontWeight.w700)),
                    ),
                  )
                else if (product.isOrganic)
                  Positioned(
                    top: 6, left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Text('🌿 Organic',
                          style: TextStyle(color: Colors.white,
                              fontSize: 8, fontWeight: FontWeight.w700)),
                    ),
                  ),
                if (product.grade?.toUpperCase() == 'A')
                  Positioned(
                    bottom: 6, right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFF8F00),
                          borderRadius: BorderRadius.circular(6)),
                      child: const Text('⭐ Grade A',
                          style: TextStyle(color: Colors.white,
                              fontSize: 8, fontWeight: FontWeight.w700)),
                    ),
                  ),
              ]),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(fontSize: 12.5,
                          fontWeight: FontWeight.w700, height: 1.2),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (isOwner)
                    const Text('You listed this',
                        style: TextStyle(
                            fontSize: 9,
                            color: KMColors.primaryDark,
                            fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('₹${product.pricePerUnit}',
                      style: const TextStyle(fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: KMColors.primaryDark)),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 10, color: KMColors.textSecondary),
                    const SizedBox(width: 2),
                    Expanded(child: Text(loc,
                        style: const TextStyle(fontSize: 9.5,
                            color: KMColors.textSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                  // Add to cart / edit button
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: isOwner ? onEdit : onAddToCart,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: isOwner
                            ? KMColors.primaryDark.withValues(alpha: 0.10)
                            : (isInCart
                                ? KMColors.weatherPrimary.withValues(alpha: 0.10)
                                : KMColors.primaryDark),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isOwner
                                ? Icons.edit_rounded
                                : (isInCart
                                    ? Icons.shopping_cart_rounded
                                    : Icons.add_shopping_cart_rounded),
                            size: 12,
                            color: isOwner
                                ? KMColors.primaryDark
                                : (isInCart
                                    ? KMColors.weatherPrimary
                                    : Colors.white),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOwner
                                ? 'Edit'
                                : (isInCart ? 'In Cart' : 'Add'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isOwner
                                  ? KMColors.primaryDark
                                  : (isInCart
                                      ? KMColors.weatherPrimary
                                      : Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  void _showOwnerSheet(
      BuildContext ctx, VoidCallback onEdit, VoidCallback onDelete) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: KMColors.primaryDark.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.edit_rounded,
                  color: KMColors.primaryDark, size: 18),
            ),
            title: const Text('Edit Listing',
                style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () { Navigator.pop(ctx); onEdit(); },
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.delete_rounded,
                  color: Colors.red, size: 18),
            ),
            title: const Text('Delete Listing',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w600)),
            onTap: () { Navigator.pop(ctx); onDelete(); },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

// ─── RFQ Banner ────────────────────────────────────────────────────────────

class _RfqBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _RfqBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 16, 12, 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [KMColors.weatherDark, KMColors.weatherPrimary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(
            color: KMColors.weatherPrimary.withValues(alpha: 0.32),
            blurRadius: 12, offset: const Offset(0, 4),
          )],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('📋', style: TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Looking for specific produce?',
                  style: TextStyle(color: Colors.white,
                      fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              const Text('Post a requirement. Farmers send offers.',
                  style: TextStyle(color: Colors.white70,
                      fontSize: 11, height: 1.4)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: const Text('Post Requirement',
                    style: TextStyle(color: KMColors.weatherDark,
                        fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ],
          )),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded,
              color: Colors.white70, size: 22),
        ]),
      ),
    );
  }
}

// ─── Featured Farmers ──────────────────────────────────────────────────────

class _FarmersList extends StatelessWidget {
  final List<_FarmerData> farmers;
  const _FarmersList({required this.farmers});

  static const _colors = [
    KMColors.primaryDark, Color(0xFFBF360C), KMColors.weatherDark,
    KMColors.labourDark, Color(0xFF006064), Color(0xFF880E4F),
    Color(0xFF4E342E), Color(0xFF37474F),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 112,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        itemCount: farmers.length,
        itemBuilder: (_, i) {
          final f = farmers[i];
          final color = _colors[i % _colors.length];
          final initial =
              f.name.isNotEmpty ? f.name[0].toUpperCase() : '?';
          return Container(
            width: 90,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              color: isDark ? KMColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: KMShadow.card,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.65)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(child: Text(initial,
                      style: const TextStyle(fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white))),
                ),
                const SizedBox(height: 5),
                Text(f.name,
                    style: const TextStyle(fontSize: 10,
                        fontWeight: FontWeight.w700),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center),
                Text('${f.productCount} items',
                    style: const TextStyle(fontSize: 9,
                        color: KMColors.textSecondary)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── All Products header with filter chips ─────────────────────────────────

class _AllProductsHeader extends StatelessWidget {
  final List<_CatData> cats;
  final String selected;
  final int count;
  final ValueChanged<String> onSelect;
  const _AllProductsHeader({required this.cats, required this.selected,
      required this.count, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: KMColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.grid_view_rounded,
                size: 16, color: KMColors.primary),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('All Products',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                    color: KMColors.textPrimary)),
            Text('$count products available',
                style: const TextStyle(fontSize: 11,
                    color: KMColors.textSecondary)),
          ]),
        ]),
      ),
      SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            _FilterChip(label: 'All', selected: selected == 'all',
                color: KMColors.primary, onTap: () => onSelect('all')),
            ...cats.map((c) => _FilterChip(
              label: c.label, selected: selected == c.key,
              color: c.color1, onTap: () => onSelect(c.key),
            )),
          ],
        ),
      ),
      const SizedBox(height: 10),
    ]);
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color : KMColors.divider),
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.25),
                  blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                color: selected ? Colors.white : KMColors.textSecondary)),
      ),
    );
  }
}

// ─── Grid product card ─────────────────────────────────────────────────────

class _GridCard extends StatelessWidget {
  final ExportProduct product;
  final String langCode;
  final bool isWishlisted;
  final bool isInCart;
  final bool isOwner;
  final VoidCallback onTap;
  final VoidCallback onWishlist;
  final VoidCallback onAddToCart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _GridCard({
    required this.product, required this.langCode,
    required this.isWishlisted, required this.isInCart, required this.isOwner,
    required this.onTap, required this.onWishlist,
    required this.onAddToCart, required this.onEdit, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _catAccent(product.category);
    final name = ContentTranslationService.translateCropName(
        product.productName, langCode);
    final loc = ContentTranslationService.translateLocation(
        product.location, langCode);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? KMColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox(
              height: 128, width: double.infinity,
              child: Stack(fit: StackFit.expand, children: [
                product.primaryImage.isNotEmpty
                    ? Image.network(product.primaryImage, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _imgPlaceholder(accent))
                    : _imgPlaceholder(accent),
                if (product.imageUrls.length > 1)
                  Positioned(
                    bottom: 6, left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.photo_library_rounded,
                            size: 9, color: Colors.white),
                        const SizedBox(width: 3),
                        Text('${product.imageUrls.length}',
                            style: const TextStyle(color: Colors.white,
                                fontSize: 9, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                // Top-right: ⋮ for owner, wishlist for others
                Positioned(
                  top: 7, right: 7,
                  child: GestureDetector(
                    onTap: isOwner
                        ? () => _showOwnerSheet(context, onEdit, onDelete)
                        : onWishlist,
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle),
                      child: Icon(
                        isOwner
                            ? Icons.more_vert_rounded
                            : (isWishlisted ? Icons.favorite : Icons.favorite_border),
                        size: 15,
                        color: isOwner
                            ? KMColors.primaryDark
                            : (isWishlisted ? Colors.red : Colors.grey),
                      ),
                    ),
                  ),
                ),
                // Top-left: My Listing badge (owner) or Organic
                if (isOwner)
                  Positioned(
                    top: 7, left: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                          color: KMColors.primaryDark,
                          borderRadius: BorderRadius.circular(8)),
                      child: const Text('My Listing',
                          style: TextStyle(color: Colors.white,
                              fontSize: 8, fontWeight: FontWeight.w700)),
                    ),
                  )
                else if (product.isOrganic)
                  Positioned(
                    top: 7, left: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Text('🌿 Organic',
                          style: TextStyle(color: Colors.white,
                              fontSize: 8, fontWeight: FontWeight.w800)),
                    ),
                  ),
                if (product.grade?.toUpperCase() == 'A')
                  Positioned(
                    bottom: 6, right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFF8F00),
                          borderRadius: BorderRadius.circular(6)),
                      child: const Text('⭐ A',
                          style: TextStyle(color: Colors.white,
                              fontSize: 8, fontWeight: FontWeight.w800)),
                    ),
                  ),
              ]),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w700, height: 1.2,
                          color: KMColors.textPrimary),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (isOwner)
                    const Text('You listed this',
                        style: TextStyle(
                            fontSize: 10,
                            color: KMColors.primaryDark,
                            fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('₹${product.pricePerUnit}',
                      style: const TextStyle(fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: KMColors.primaryDark)),
                  Text(product.quantity,
                      style: const TextStyle(fontSize: 10,
                          color: KMColors.textSecondary)),
                  const Spacer(),
                  Row(children: [
                    const Icon(Icons.person_outline_rounded,
                        size: 10, color: KMColors.textSecondary),
                    const SizedBox(width: 3),
                    Expanded(child: Text(product.farmerName,
                        style: const TextStyle(fontSize: 10,
                            color: KMColors.textSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 10, color: KMColors.textSecondary),
                    const SizedBox(width: 3),
                    Expanded(child: Text(loc,
                        style: const TextStyle(fontSize: 10,
                            color: KMColors.textSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity, height: 30,
                    child: ElevatedButton.icon(
                      onPressed: isOwner ? onEdit : onAddToCart,
                      icon: Icon(
                        isOwner
                            ? Icons.edit_rounded
                            : (isInCart
                                ? Icons.shopping_cart_rounded
                                : Icons.add_shopping_cart_rounded),
                        size: 13,
                      ),
                      label: Text(
                        isOwner
                            ? 'Edit'
                            : (isInCart ? 'In Cart' : 'Add to Cart'),
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOwner
                            ? const Color(0xFF2E7D32)
                            : (isInCart
                                ? KMColors.weatherPrimary
                                : KMColors.primaryDark),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero, elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  void _showOwnerSheet(
      BuildContext ctx, VoidCallback onEdit, VoidCallback onDelete) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: KMColors.primaryDark.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.edit_rounded,
                  color: KMColors.primaryDark, size: 18),
            ),
            title: const Text('Edit Listing',
                style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () { Navigator.pop(ctx); onEdit(); },
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.delete_rounded,
                  color: Colors.red, size: 18),
            ),
            title: const Text('Delete Listing',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w600)),
            onTap: () { Navigator.pop(ctx); onDelete(); },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}
