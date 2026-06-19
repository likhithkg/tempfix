// lib/f2b_mart/f2b_home_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../exporter_hub/exporter_model.dart';
import '../exporter_hub/exporter_service.dart';
import '../exporter_hub/exporter_form_page.dart';
import '../exporter_hub/nearby_farmers_map_page.dart';
import 'f2b_farmer_dashboard.dart';
import '../exporter_hub/purchase_order_list_page.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../services/content_translation_service.dart';
import 'f2b_product_detail_page.dart';
import 'f2b_search_page.dart';
import 'f2b_shimmer.dart';
import 'f2b_wishlist_page.dart';
import 'f2b_wishlist_service.dart';

// ─── Data holders ──────────────────────────────────────────────────────────

class _BannerData {
  final String title;
  final String subtitle;
  final Color color1;
  final Color color2;
  final IconData icon;
  const _BannerData({
    required this.title, required this.subtitle,
    required this.color1, required this.color2, required this.icon,
  });
}

class _CatData {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  const _CatData(this.key, this.label, this.icon, this.color);
}

// ─── Page ──────────────────────────────────────────────────────────────────

class F2BHomePage extends StatefulWidget {
  const F2BHomePage({super.key});
  @override
  State<F2BHomePage> createState() => _F2BHomePageState();
}

class _F2BHomePageState extends State<F2BHomePage> {
  final _service = ExporterService();
  final _bannerCtrl = PageController();

  String _selectedCategory = 'all';
  int _currentBanner = 0;
  Timer? _bannerTimer;

  // Wishlist
  Set<String> _wishlistIds = {};
  StreamSubscription<Set<String>>? _wishlistSub;

  static const _banners = [
    _BannerData(
      title: 'Fresh From the Farm',
      subtitle: 'Buy directly from verified farmers',
      color1: Color(0xFF1B5E20), color2: Color(0xFF43A047),
      icon: Icons.agriculture_rounded,
    ),
    _BannerData(
      title: 'Direct Trade, Fair Prices',
      subtitle: 'No middlemen. Best price guaranteed',
      color1: Color(0xFFBF360C), color2: Color(0xFFFF7043),
      icon: Icons.handshake_rounded,
    ),
    _BannerData(
      title: 'Organic Certified',
      subtitle: 'Eco-friendly certified produce',
      color1: Color(0xFF006064), color2: Color(0xFF00ACC1),
      icon: Icons.eco_rounded,
    ),
  ];

  static const _cats = [
    _CatData('all',        'All',        Icons.grid_view_rounded,    Color(0xFF388E3C)),
    _CatData('vegetables', 'Vegetables', Icons.eco_outlined,         Color(0xFF2E7D32)),
    _CatData('fruits',     'Fruits',     Icons.apple_rounded,        Color(0xFFD84315)),
    _CatData('grains',     'Grains',     Icons.grass_rounded,        Color(0xFFF57F17)),
    _CatData('spices',     'Spices',     Icons.spa_rounded,          Color(0xFFAD1457)),
    _CatData('pulses',     'Pulses',     Icons.scatter_plot_rounded, Color(0xFF6D4C41)),
    _CatData('crops',      'Crops',      Icons.agriculture_rounded,  Color(0xFF1565C0)),
    _CatData('other',      'Other',      Icons.more_horiz_rounded,   Color(0xFF546E7A)),
  ];

  @override
  void initState() {
    super.initState();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_currentBanner + 1) % _banners.length;
      _bannerCtrl.animateToPage(next,
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
    _startWishlistListener();
  }

  void _startWishlistListener() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _wishlistSub = WishlistService.stream(uid).listen((ids) {
      if (mounted) setState(() => _wishlistIds = ids);
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerCtrl.dispose();
    _wishlistSub?.cancel();
    super.dispose();
  }

  List<ExportProduct> _filter(List<ExportProduct> all) {
    if (_selectedCategory == 'all') return all;
    return all
        .where((p) => p.category.toLowerCase() == _selectedCategory)
        .toList();
  }

  bool _isOwner(ExportProduct p) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return uid.isNotEmpty && uid == p.ownerId;
  }

  Future<void> _toggleWishlist(
      BuildContext context, AppLocalizations l, String productId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.loginToSave)));
      return;
    }
    final added = await WishlistService.toggle(uid, productId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(added ? l.addedToWishlist : l.removedFromWishlist),
        duration: const Duration(seconds: 1),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final langCode = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? KMColors.backgroundDark : const Color(0xFFF0F7F0),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.f2bMart,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text(l.f2bTagline,
                style: const TextStyle(
                    fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l.yourWishlist,
            icon: const Icon(Icons.favorite_border_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const F2BWishlistPage()),
            ),
          ),
          IconButton(
            tooltip: l.myOrders,
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PurchaseOrderListPage())),
          ),
          IconButton(
            tooltip: l.farmerDashboard,
            icon: const Icon(Icons.storefront_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const F2BFarmerDashboard())),
          ),
          IconButton(
            tooltip: l.nearbyFarmersList,
            icon: const Icon(Icons.map_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NearbyFarmersMapPage())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
              context, MaterialPageRoute(builder: (_) => const ExporterFormPage()));
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(l.listProduce),
      ),
      body: Column(
        children: [
          // ── Pinned green zone ───────────────────────────────────────
          Container(
            color: KMColors.primary,
            child: Column(
              children: [
                // Tappable search bar → navigates to F2BSearchPage
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const F2BSearchPage()),
                  ),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(children: [
                      const Icon(Icons.search_rounded,
                          color: Colors.white70, size: 20),
                      const SizedBox(width: 10),
                      Text(l.searchProducts,
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 14)),
                      const Spacer(),
                      const Icon(Icons.tune_rounded,
                          color: Colors.white70, size: 18),
                    ]),
                  ),
                ),
                // Category row
                _CategoryRow(
                  cats: _cats,
                  selected: _selectedCategory,
                  onSelect: (k) => setState(() => _selectedCategory = k),
                ),
              ],
            ),
          ),
          // ── Scrollable content ──────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<ExportProduct>>(
              stream: _service.getExportProducts(),
              builder: (ctx, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: KMColors.error),
                      const SizedBox(height: 8),
                      const Text('Could not load products',
                          style: TextStyle(color: KMColors.textSecondary)),
                      TextButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Retry'),
                      ),
                    ]),
                  );
                }
                if (!snap.hasData) {
                  return const SingleChildScrollView(
                    child: F2BShimmerGrid(count: 6),
                  );
                }

                final all = snap.data!;
                final filtered = _filter(all);
                final featured = all.take(6).toList();
                final catLabel = _cats
                    .firstWhere((c) => c.key == _selectedCategory,
                        orElse: () => _cats[0])
                    .label;

                return RefreshIndicator(
                  color: KMColors.primary,
                  onRefresh: () async => setState(() {}),
                  child: CustomScrollView(
                    slivers: [
                      // Banner
                      SliverToBoxAdapter(
                        child: _BannerCarousel(
                          banners: _banners,
                          controller: _bannerCtrl,
                          currentIndex: _currentBanner,
                          onPageChanged: (i) =>
                              setState(() => _currentBanner = i),
                        ),
                      ),
                      // Featured
                      if (featured.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: _SectionHeader(title: l.featuredProduce),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 215,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: featured.length,
                              itemBuilder: (ctx, i) => _FeaturedCard(
                                product: featured[i],
                                langCode: langCode,
                                isWishlisted: _wishlistIds.contains(featured[i].id),
                                onTap: () => Navigator.push(
                                  ctx,
                                  MaterialPageRoute(builder: (_) =>
                                      F2BProductDetailPage(product: featured[i])),
                                ),
                                onWishlist: () => _toggleWishlist(
                                    context, l, featured[i].id),
                              ),
                            ),
                          ),
                        ),
                      ],
                      // Section header
                      SliverToBoxAdapter(
                        child: _SectionHeader(
                          title: _selectedCategory == 'all'
                              ? l.allProducts
                              : catLabel,
                          subtitle: '${filtered.length} products',
                        ),
                      ),
                      // Grid or empty
                      if (filtered.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.storefront_outlined,
                                    size: 60,
                                    color: KMColors.textSecondary),
                                const SizedBox(height: 12),
                                Text(l.noProductsAvailable,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        color: KMColors.textSecondary),
                                    textAlign: TextAlign.center),
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
                              childAspectRatio: 0.57,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) {
                                final p = filtered[i];
                                return _ProductCard(
                                  product: p,
                                  langCode: langCode,
                                  l: l,
                                  isOwner: _isOwner(p),
                                  isWishlisted: _wishlistIds.contains(p.id),
                                  onTap: () => Navigator.push(
                                    ctx,
                                    MaterialPageRoute(builder: (_) =>
                                        F2BProductDetailPage(product: p)),
                                  ),
                                  onWishlist: () =>
                                      _toggleWishlist(context, l, p.id),
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

// ─── Category row ──────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  final List<_CatData> cats;
  final String selected;
  final ValueChanged<String> onSelect;
  const _CategoryRow(
      {required this.cats, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: cats.length,
        itemBuilder: (_, i) {
          final c = cats[i];
          final sel = selected == c.key;
          return GestureDetector(
            onTap: () => onSelect(c.key),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: sel
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(c.icon,
                        color: sel ? c.color : Colors.white70, size: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(c.label,
                      style: TextStyle(
                          fontSize: 10,
                          color: sel ? Colors.white : Colors.white70,
                          fontWeight: sel
                              ? FontWeight.w700
                              : FontWeight.w400)),
                ],
              ),
            ),
          );
        },
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
  const _BannerCarousel({
    required this.banners, required this.controller,
    required this.currentIndex, required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 155,
          child: PageView.builder(
            controller: controller,
            onPageChanged: onPageChanged,
            itemCount: banners.length,
            itemBuilder: (_, i) {
              final b = banners[i];
              return Container(
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                      colors: [b.color1, b.color2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                ),
                child: Stack(children: [
                  Positioned(
                    right: -15, bottom: -15,
                    child: Icon(b.icon, size: 110,
                        color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(20)),
                          child: const Text('KrishiMithra F2B',
                              style: TextStyle(color: Colors.white,
                                  fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 8),
                        Text(b.title,
                            style: const TextStyle(color: Colors.white,
                                fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(b.subtitle,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
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
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == currentIndex ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == currentIndex
                    ? KMColors.primary
                    : KMColors.primary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            )),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ─── Section header ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                  color: KMColors.textPrimary)),
          if (subtitle != null)
            Text(subtitle!,
                style: const TextStyle(fontSize: 12,
                    color: KMColors.textSecondary)),
        ],
      ),
    );
  }
}

// ─── Category + image color helpers ───────────────────────────────────────

Color _categoryAccent(String cat) {
  switch (cat.toLowerCase()) {
    case 'fruits':     return const Color(0xFFD84315);
    case 'vegetables': return const Color(0xFF2E7D32);
    case 'grains':     return const Color(0xFFF57F17);
    case 'spices':     return const Color(0xFFAD1457);
    case 'pulses':     return const Color(0xFF6D4C41);
    case 'crops':      return const Color(0xFF1565C0);
    default:           return KMColors.primaryDark;
  }
}

Widget _imgPlaceholder(Color accent, double height) => Container(
  height: height,
  color: accent.withValues(alpha: 0.12),
  child: Center(child: Icon(Icons.agriculture_rounded,
      size: 44, color: accent.withValues(alpha: 0.55))),
);

// ─── Featured card (horizontal scroll) ────────────────────────────────────

class _FeaturedCard extends StatelessWidget {
  final ExportProduct product;
  final String langCode;
  final bool isWishlisted;
  final VoidCallback onTap;
  final VoidCallback onWishlist;
  const _FeaturedCard({
    required this.product, required this.langCode,
    required this.isWishlisted, required this.onTap, required this.onWishlist,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _categoryAccent(product.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 155,
        margin: const EdgeInsets.only(right: 12, bottom: 4),
        decoration: BoxDecoration(
          color: isDark ? KMColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: KMShadow.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + heart
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(children: [
                SizedBox(
                  width: 155, height: 105,
                  child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? Image.network(product.imageUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imgPlaceholder(accent, 105))
                      : _imgPlaceholder(accent, 105),
                ),
                Positioned(
                  top: 6, right: 6,
                  child: GestureDetector(
                    onTap: onWishlist,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20)),
                      child: Icon(
                        isWishlisted ? Icons.favorite : Icons.favorite_border,
                        size: 15,
                        color: isWishlisted ? Colors.red : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ContentTranslationService.translateCropName(
                        product.productName, langCode),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, height: 1.2),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text('₹${product.pricePerUnit}',
                      style: const TextStyle(fontSize: 15,
                          fontWeight: FontWeight.w800, color: KMColors.primary)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 11, color: KMColors.textSecondary),
                    const SizedBox(width: 2),
                    Expanded(child: Text(
                      ContentTranslationService.translateLocation(
                          product.location, langCode),
                      overflow: TextOverflow.ellipsis, maxLines: 1,
                      style: const TextStyle(
                          fontSize: 10, color: KMColors.textSecondary),
                    )),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Product card (2-col grid) ─────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final ExportProduct product;
  final String langCode;
  final AppLocalizations l;
  final bool isOwner;
  final bool isWishlisted;
  final VoidCallback onTap;
  final VoidCallback onWishlist;
  const _ProductCard({
    required this.product, required this.langCode, required this.l,
    required this.isOwner, required this.isWishlisted,
    required this.onTap, required this.onWishlist,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _categoryAccent(product.category);
    final translatedName = ContentTranslationService.translateCropName(
        product.productName, langCode);
    final translatedLoc = ContentTranslationService.translateLocation(
        product.location, langCode);
    final translatedCat = ContentTranslationService.translateExportCategory(
        product.category, langCode);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? KMColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: KMShadow.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + badges
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(children: [
                SizedBox(
                  height: 125, width: double.infinity,
                  child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? Image.network(product.imageUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imgPlaceholder(accent, 125))
                      : _imgPlaceholder(accent, 125),
                ),
                // Category badge (top-right)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(translatedCat,
                        style: const TextStyle(color: Colors.white,
                            fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
                ),
                // Wishlist heart (top-left)
                Positioned(
                  top: 8, left: 8,
                  child: GestureDetector(
                    onTap: onWishlist,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.90),
                          borderRadius: BorderRadius.circular(20)),
                      child: Icon(
                        isWishlisted ? Icons.favorite : Icons.favorite_border,
                        size: 14,
                        color: isWishlisted ? Colors.red : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ]),
            ),
            // Text info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(translatedName,
                        style: const TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w700, height: 1.2),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('₹${product.pricePerUnit}',
                        style: const TextStyle(fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: KMColors.primary)),
                    Text(product.quantity,
                        style: const TextStyle(
                            fontSize: 11, color: KMColors.textSecondary)),
                    const Spacer(),
                    Row(children: [
                      const Icon(Icons.person_outline,
                          size: 11, color: KMColors.textSecondary),
                      const SizedBox(width: 3),
                      Expanded(child: Text(product.farmerName,
                          overflow: TextOverflow.ellipsis, maxLines: 1,
                          style: const TextStyle(
                              fontSize: 11, color: KMColors.textSecondary))),
                    ]),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 11, color: KMColors.textSecondary),
                      const SizedBox(width: 3),
                      Expanded(child: Text(translatedLoc,
                          overflow: TextOverflow.ellipsis, maxLines: 1,
                          style: const TextStyle(
                              fontSize: 11, color: KMColors.textSecondary))),
                    ]),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KMColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: Text(l.buyNow,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
