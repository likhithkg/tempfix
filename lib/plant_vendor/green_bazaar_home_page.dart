import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'plant_vendor_model.dart';
import 'plant_vendor_service.dart';
import 'plant_detail_page.dart';
import 'plant_list_page.dart';
import 'plant_list_form_page.dart';
import 'plant_vendor_nearby_page.dart';
import 'nursery_profile_page.dart';
import 'cart_page.dart';
import 'wishlist_page.dart';
import 'ai_plant_assistant_page.dart';
import 'green_bazaar_service.dart';
import 'green_bazaar_models.dart';

// ─── Category data ────────────────────────────────────────────────────────────

class _Cat {
  final String key, label, emoji;
  final Color color;
  const _Cat(this.key, this.label, this.emoji, this.color);
}

const _kCategories = [
  _Cat('all', 'All Plants', '🌿', Color(0xFF2E7D32)),
  _Cat('fruit', 'Fruit', '🍎', Color(0xFFE67E22)),
  _Cat('flower', 'Flower', '🌸', Color(0xFFE91E8C)),
  _Cat('vegetable', 'Vegetable', '🥦', Color(0xFF27AE60)),
  _Cat('medicinal', 'Medicinal', '💊', Color(0xFF16A085)),
  _Cat('ornamental', 'Ornamental', '🪴', Color(0xFF8E44AD)),
  _Cat('timber', 'Timber', '🌳', Color(0xFF795548)),
  _Cat('aromatic', 'Aromatic', '🌿', Color(0xFF00897B)),
  _Cat('seeds', 'Seeds', '🌾', Color(0xFFF39C12)),
];

// ─── Banner data ──────────────────────────────────────────────────────────────

class _Banner {
  final String title, subtitle, cta;
  final List<Color> colors;
  final String emoji;
  const _Banner(this.title, this.subtitle, this.cta, this.colors, this.emoji);
}

const _kBanners = [
  _Banner('Fresh from the Nursery', 'Handpicked plants delivered to your door',
      'Shop Now', [Color(0xFF1B5E20), Color(0xFF388E3C)], '🌿'),
  _Banner('Seasonal Picks', 'Best plants for the current season',
      'Explore', [Color(0xFF4A148C), Color(0xFF7B1FA2)], '🌸'),
  _Banner('Organic Collection', 'Certified organic plants & seeds',
      'View All', [Color(0xFF1565C0), Color(0xFF1976D2)], '🌱'),
  _Banner('Flash Deals', 'Up to 20% off on select plants today',
      'Grab Now', [Color(0xFFBF360C), Color(0xFFE64A19)], '⚡'),
];

// ─── Section model ────────────────────────────────────────────────────────────

class _Section {
  final String title, emoji, filterKey;
  final List<PlantVendor> Function(List<PlantVendor>) filter;
  const _Section(this.title, this.emoji, this.filterKey, this.filter);
}

// ─── Home page ────────────────────────────────────────────────────────────────

class GreenBazaarHomePage extends StatefulWidget {
  const GreenBazaarHomePage({super.key});

  @override
  State<GreenBazaarHomePage> createState() => _GreenBazaarHomePageState();
}

class _GreenBazaarHomePageState extends State<GreenBazaarHomePage> {
  final _service = PlantVendorService();
  final _gbService = GreenBazaarService();
  late final Stream<List<PlantVendor>> _stream;

  final _searchCtrl = TextEditingController();
  final _bannerCtrl = PageController();
  String _search = '';
  String _selectedCat = 'all';
  int _bannerPage = 0;
  Timer? _bannerTimer;

  // Cart badge
  late final Stream<List<CartItem>> _cartStream;
  int _cartCount = 0;
  StreamSubscription<List<CartItem>>? _cartSub;

  @override
  void initState() {
    super.initState();
    _stream = _service.streamVendors();
    _cartStream = _gbService.streamCart();
    _cartSub = _cartStream.listen((items) {
      if (mounted) {
        setState(() {
          _cartCount =
              items.fold(0, (sum, i) => sum + i.orderQty);
        });
      }
    });
    _startBannerTimer();
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final next = (_bannerPage + 1) % _kBanners.length;
      _bannerCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerCtrl.dispose();
    _searchCtrl.dispose();
    _cartSub?.cancel();
    super.dispose();
  }

  List<PlantVendor> _filterByType(List<PlantVendor> all, String key) {
    if (key == 'all') return all;
    return all
        .where((v) => v.type.toLowerCase().contains(key))
        .toList();
  }

  List<PlantVendor> _filterBySearch(List<PlantVendor> all, String q) {
    if (q.isEmpty) return all;
    return all
        .where((v) =>
            v.plantName.toLowerCase().contains(q) ||
            v.vendorName.toLowerCase().contains(q) ||
            v.type.toLowerCase().contains(q) ||
            v.location.toLowerCase().contains(q))
        .toList();
  }

  // Deterministic fake rating for each plant
  double _rating(PlantVendor v) =>
      4.0 + (v.id.hashCode.abs() % 10) / 10.0;

  // Sections definition
  List<_Section> _buildSections() => [
        _Section('Best Sellers', '⭐', 'all',
            (all) => (List.of(all)..sort((a, b) => b.quantity.compareTo(a.quantity))).take(10).toList()),
        _Section('Seasonal Picks', '🌦️', 'seasonal',
            (all) => all.where((v) => v.type.toLowerCase().contains('vegetable') || v.type.toLowerCase().contains('herb')).take(10).toList()),
        _Section('Indoor Plants', '🏠', 'indoor',
            (all) => all.where((v) => v.type.toLowerCase().contains('ornamental') || v.type.toLowerCase().contains('aromatic')).take(10).toList()),
        _Section('Outdoor Plants', '🌳', 'outdoor',
            (all) => all.where((v) => v.type.toLowerCase().contains('timber') || v.type.toLowerCase().contains('fruit')).take(10).toList()),
        _Section('Fruit Plants', '🍎', 'fruit',
            (all) => all.where((v) => v.type.toLowerCase().contains('fruit')).take(10).toList()),
        _Section('Flower Plants', '🌸', 'flower',
            (all) => all.where((v) => v.type.toLowerCase().contains('flower') || v.type.toLowerCase().contains('flowering')).take(10).toList()),
        _Section('Vegetable Seedlings', '🥦', 'vegetable',
            (all) => all.where((v) => v.type.toLowerCase().contains('vegetable')).take(10).toList()),
        _Section('Medicinal Plants', '💊', 'medicinal',
            (all) => all.where((v) => v.type.toLowerCase().contains('medicinal')).take(10).toList()),
        _Section('Organic Collection', '🌱', 'organic',
            (all) => all.where((v) => v.description.toLowerCase().contains('organic')).take(10).toList()),
        _Section('Flash Deals', '⚡', 'deals',
            (all) => all.where((v) => v.quantity > 0 && v.quantity <= 5).take(10).toList()),
        _Section('Recently Added', '🆕', 'recent',
            (all) => (List.of(all)..sort((a, b) => b.timestamp.compareTo(a.timestamp))).take(10).toList()),
      ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF1F8F1);

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.push<bool>(
              context, MaterialPageRoute(builder: (_) => const PlantListFormPage()));
          if (added == true && mounted) setState(() {});
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('List Plant'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<PlantVendor>>(
        stream: _stream,
        builder: (ctx, snap) {
          final allPlants = snap.data ?? [];
          final searching = _search.isNotEmpty;
          final catFiltered = _filterByType(allPlants, _selectedCat);
          final displayList = _filterBySearch(catFiltered, _search);

          return CustomScrollView(
            slivers: [
              // ── App bar ────────────────────────────────────────────────
              SliverAppBar(
                floating: true,
                snap: true,
                pinned: false,
                backgroundColor: const Color(0xFF1B5E20),
                automaticallyImplyLeading: false,
                title: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.maybePop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  const Text('🌿', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 6),
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('GreenBazaar',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.3)),
                    Text('Nursery Marketplace',
                        style: TextStyle(fontSize: 9, color: Colors.white70)),
                  ]),
                  const Spacer(),
                  // AI assistant
                  IconButton(
                    icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                    tooltip: 'AI Plant Advisor',
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AiPlantAssistantPage())),
                  ),
                  // Wishlist
                  IconButton(
                    icon: const Icon(Icons.favorite_outline_rounded, color: Colors.white),
                    tooltip: 'Wishlist',
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const WishlistPage())),
                  ),
                  // Cart with badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const CartPage())),
                      ),
                      if (_cartCount > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE53935),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$_cartCount',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                    ],
                  ),
                ]),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(52),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: _SearchBar(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _search = v.toLowerCase()),
                      onClear: () {
                        _searchCtrl.clear();
                        setState(() => _search = '');
                      },
                      onTapNearby: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const PlantVendorNearbyPage())),
                    ),
                  ),
                ),
              ),

              // ── Body ───────────────────────────────────────────────────
              if (snap.connectionState == ConnectionState.waiting && allPlants.isEmpty)
                const SliverFillRemaining(child: _Shimmer())
              else if (searching || _selectedCat != 'all')
                // Search / filter results as grid
                ..._buildFilteredResults(displayList, uid, isDark)
              else
                // Discovery home
                ..._buildDiscoveryHome(allPlants, uid, isDark),
            ],
          );
        },
      ),
    );
  }

  // ── Filtered results (grid) ────────────────────────────────────────────────

  List<Widget> _buildFilteredResults(
      List<PlantVendor> plants, String uid, bool isDark) {
    if (plants.isEmpty) {
      return [
        const SliverFillRemaining(
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('🌿', style: TextStyle(fontSize: 52)),
              SizedBox(height: 12),
              Text('No plants found',
                  style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 15)),
            ]),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              final v = plants[i];
              final isOwner =
                  (v.createdBy.isNotEmpty ? v.createdBy : v.ownerId) == uid;
              return _PlantCard(
                vendor: v,
                rating: _rating(v),
                isOwner: isOwner,
                onTap: () => _openDetail(v),
                gbService: _gbService,
              );
            },
            childCount: plants.length,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.60,
          ),
        ),
      ),
    ];
  }

  // ── Discovery home ─────────────────────────────────────────────────────────

  List<Widget> _buildDiscoveryHome(
      List<PlantVendor> all, String uid, bool isDark) {
    final sections = _buildSections();
    final nurseries = _buildNurseries(all);

    return [
      SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner carousel
            _BannerCarousel(
              controller: _bannerCtrl,
              onPageChanged: (p) => setState(() => _bannerPage = p),
              currentPage: _bannerPage,
            ),

            const SizedBox(height: 16),

            // Category chips
            _CategoryRow(
              selected: _selectedCat,
              onSelect: (k) => setState(() => _selectedCat = k),
            ),

            const SizedBox(height: 16),

            // Featured nurseries
            if (nurseries.isNotEmpty) ...[
              _SectionHeader(
                title: 'Featured Nurseries',
                emoji: '🏪',
                onSeeAll: null,
              ),
              _NurseryRow(nurseries: nurseries, allPlants: all),
              const SizedBox(height: 20),
            ],

            // All plant sections
            for (final sec in sections) ...[
              Builder(builder: (ctx) {
                final items = sec.filter(all);
                if (items.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      title: sec.title,
                      emoji: sec.emoji,
                      onSeeAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlantVendorListPage(
                              category: sec.filterKey == 'all'
                                  ? 'Plant'
                                  : sec.filterKey),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 250,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) {
                          final v = items[i];
                          final isOwner =
                              (v.createdBy.isNotEmpty ? v.createdBy : v.ownerId) ==
                                  uid;
                          return SizedBox(
                            width: 150,
                            child: _PlantCard(
                              vendor: v,
                              rating: _rating(v),
                              isOwner: isOwner,
                              onTap: () => _openDetail(v),
                              gbService: _gbService,
                              compact: true,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              }),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    ];
  }

  // Unique nursery names
  List<String> _buildNurseries(List<PlantVendor> all) {
    final seen = <String>{};
    final names = <String>[];
    for (final v in all) {
      if (v.vendorName.isNotEmpty && !seen.contains(v.vendorName)) {
        seen.add(v.vendorName);
        names.add(v.vendorName);
      }
    }
    return names.take(10).toList();
  }

  void _openDetail(PlantVendor v) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => PlantDetailPage(vendor: v)));
  }
}

// ─── Search bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear, onTapNearby;
  const _SearchBar(
      {required this.controller,
      required this.onChanged,
      required this.onClear,
      required this.onTapNearby});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(children: [
        const SizedBox(width: 14),
        const Icon(Icons.search_rounded, size: 20, color: Color(0xFF9E9E9E)),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: const InputDecoration(
              hintText: 'Search plant, nursery, location...',
              hintStyle:
                  TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
        ),
        if (controller.text.isNotEmpty)
          GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close_rounded,
                  size: 18, color: Color(0xFF9E9E9E))),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onTapNearby,
          child: Container(
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.location_on_rounded, size: 12, color: Colors.white),
              SizedBox(width: 3),
              Text('Nearby',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ─── Banner carousel ──────────────────────────────────────────────────────────

class _BannerCarousel extends StatelessWidget {
  final PageController controller;
  final ValueChanged<int> onPageChanged;
  final int currentPage;
  const _BannerCarousel(
      {required this.controller,
      required this.onPageChanged,
      required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: 160,
        child: PageView.builder(
          controller: controller,
          onPageChanged: onPageChanged,
          itemCount: _kBanners.length,
          itemBuilder: (_, i) {
            final b = _kBanners[i];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: b.colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(b.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                height: 1.2)),
                        const SizedBox(height: 6),
                        Text(b.subtitle,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(b.cta,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: b.colors.first)),
                        ),
                      ]),
                ),
                Text(b.emoji, style: const TextStyle(fontSize: 64)),
              ]),
            );
          },
        ),
      ),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_kBanners.length, (i) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: currentPage == i ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: currentPage == i
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFBDBDBD),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    ]);
  }
}

// ─── Category row ─────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _CategoryRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Text('Browse by Category',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      ),
      SizedBox(
        height: 88,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          itemCount: _kCategories.length,
          itemBuilder: (_, i) {
            final c = _kCategories[i];
            final sel = selected == c.key;
            return GestureDetector(
              onTap: () => onSelect(c.key),
              child: Container(
                width: 70,
                margin: const EdgeInsets.only(right: 10),
                child: Column(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: sel
                          ? c.color
                          : c.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                  color: c.color.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3))
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(c.emoji,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    c.label,
                    style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: sel ? c.color : const Color(0xFF616161)),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title, emoji;
  final VoidCallback? onSeeAll;
  const _SectionHeader(
      {required this.title, required this.emoji, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 12, 10),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 6),
        Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        const Spacer(),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('See All',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E7D32))),
          ),
      ]),
    );
  }
}

// ─── Nursery row ──────────────────────────────────────────────────────────────

class _NurseryRow extends StatelessWidget {
  final List<String> nurseries;
  final List<PlantVendor> allPlants;
  const _NurseryRow({required this.nurseries, required this.allPlants});

  Color _color(int i) {
    const cols = [
      Color(0xFF2E7D32), Color(0xFF1565C0), Color(0xFF6A1B9A),
      Color(0xFFE65100), Color(0xFF00695C), Color(0xFFAD1457),
    ];
    return cols[i % cols.length];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        itemCount: nurseries.length,
        itemBuilder: (_, i) {
          final name = nurseries[i];
          final col = _color(i);
          final plantCount = allPlants.where((v) => v.vendorName == name).length;
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    NurseryProfilePage(nurseryName: name, allPlants: allPlants),
              ),
            ),
            child: Container(
              width: 120,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [col, col.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                        child: Text('🌿', style: TextStyle(fontSize: 18))),
                  ),
                  const Spacer(),
                  Text(
                    name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$plantCount plants',
                    style: const TextStyle(color: Colors.white70, fontSize: 9.5),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Premium plant card ───────────────────────────────────────────────────────

class _PlantCard extends StatefulWidget {
  final PlantVendor vendor;
  final double rating;
  final bool isOwner;
  final bool compact;
  final VoidCallback onTap;
  final GreenBazaarService gbService;
  const _PlantCard({
    required this.vendor,
    required this.rating,
    required this.isOwner,
    required this.onTap,
    required this.gbService,
    this.compact = false,
  });
  @override
  State<_PlantCard> createState() => _PlantCardState();
}

class _PlantCardState extends State<_PlantCard> {
  bool _wishlisted = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final v = await widget.gbService.isWishlisted(widget.vendor.id);
    if (mounted) setState(() => _wishlisted = v);
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
    await widget.gbService.toggleWishlist(wi);
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
    final item = CartItem(
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
    await widget.gbService.addToCart(item);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${widget.vendor.plantName} added to cart'),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 1),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CartPage())),
        ),
      ));
    }
  }

  Color _accentColor() {
    final lower = widget.vendor.type.toLowerCase();
    if (lower.contains('fruit')) return const Color(0xFFE67E22);
    if (lower.contains('flower') || lower.contains('flowering'))
      return const Color(0xFFE91E8C);
    if (lower.contains('vegetable')) return const Color(0xFF27AE60);
    if (lower.contains('medicinal')) return const Color(0xFF16A085);
    if (lower.contains('ornamental')) return const Color(0xFF8E44AD);
    if (lower.contains('timber')) return const Color(0xFF795548);
    if (lower.contains('aromatic')) return const Color(0xFF00897B);
    if (lower.contains('seed')) return const Color(0xFFF39C12);
    return const Color(0xFF2E7D32);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final v = widget.vendor;
    final accent = _accentColor();
    final hasImage = (v.imageUrl ?? '').isNotEmpty;
    final isFlashDeal = v.quantity > 0 && v.quantity <= 5;
    final discountPct = (v.id.hashCode.abs() % 3 + 1) * 5; // 5, 10, or 15%
    final mrp = (v.price * (1 + discountPct / 100)).roundToDouble();

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Stack(children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                child: hasImage
                    ? Image.network(v.imageUrl!,
                        height: widget.compact ? 120 : 130,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _Placeholder(accent: accent, height: widget.compact ? 120 : 130))
                    : _Placeholder(accent: accent, height: widget.compact ? 120 : 130),
              ),
              // Wishlist button
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: _toggleWish,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 4)
                      ],
                    ),
                    child: Icon(
                      _wishlisted
                          ? Icons.favorite_rounded
                          : Icons.favorite_outline_rounded,
                      size: 15,
                      color: _wishlisted
                          ? const Color(0xFFE53935)
                          : Colors.grey,
                    ),
                  ),
                ),
              ),
              // Flash deal badge
              if (isFlashDeal)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('⚡ Deal',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              // Verified badge
              if (v.vendorName.isNotEmpty)
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded,
                            size: 8, color: Colors.white),
                        SizedBox(width: 2),
                        Text('Verified',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 7.5,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
            ]),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(9, 7, 9, 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Plant name
                    Text(
                      v.plantName.isNotEmpty ? v.plantName : '—',
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Nursery
                    if (v.vendorName.isNotEmpty)
                      Text(
                        v.vendorName,
                        style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF9E9E9E)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 3),
                    // Rating row
                    Row(children: [
                      const Icon(Icons.star_rounded,
                          size: 11, color: Color(0xFFFFB300)),
                      const SizedBox(width: 2),
                      Text(
                        widget.rating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF616161)),
                      ),
                      const Spacer(),
                      if (v.quantity <= 5 && v.quantity > 0)
                        Text('Only ${v.quantity} left',
                            style: const TextStyle(
                                fontSize: 8.5,
                                color: Color(0xFFE53935),
                                fontWeight: FontWeight.w700)),
                    ]),
                    const Spacer(),
                    // Price row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${mrp.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 9.5,
                                  color: Color(0xFF9E9E9E),
                                  decoration:
                                      TextDecoration.lineThrough),
                            ),
                            Text(
                              '₹${v.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: accent),
                            ),
                          ],
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _addToCart,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add_rounded,
                                color: Colors.white, size: 16),
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
  }
}

class _Placeholder extends StatelessWidget {
  final Color accent;
  final double height;
  const _Placeholder({required this.accent, required this.height});
  @override
  Widget build(BuildContext context) => Container(
        height: height,
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
              size: 40, color: Colors.white.withValues(alpha: 0.5)),
        ),
      );
}

// ─── Shimmer ──────────────────────────────────────────────────────────────────

class _Shimmer extends StatefulWidget {
  const _Shimmer();
  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final t = _anim.value;
        final shine = LinearGradient(
          begin: Alignment(-1.0 + t * 2, 0),
          end: Alignment(t * 2, 0),
          colors: const [Color(0xFFE8E8E8), Color(0xFFF5F5F5), Color(0xFFE8E8E8)],
          stops: const [0, 0.5, 1],
        );
        return SingleChildScrollView(
          child: Column(children: [
            Container(
              height: 160,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  gradient: shine, borderRadius: BorderRadius.circular(20)),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.60,
              ),
              itemCount: 6,
              itemBuilder: (_, __) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(children: [
                  Container(
                    height: 130,
                    decoration: BoxDecoration(
                        gradient: shine,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18))),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 12, decoration: BoxDecoration(gradient: shine, borderRadius: BorderRadius.circular(6))),
                        const SizedBox(height: 6),
                        Container(height: 10, width: 80, decoration: BoxDecoration(gradient: shine, borderRadius: BorderRadius.circular(6))),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        );
      },
    );
  }
}
