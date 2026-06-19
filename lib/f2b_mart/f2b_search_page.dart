// lib/f2b_mart/f2b_search_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../exporter_hub/exporter_model.dart';
import '../exporter_hub/exporter_service.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../services/content_translation_service.dart';
import 'f2b_product_detail_page.dart';
import 'f2b_wishlist_service.dart';

class F2BSearchPage extends StatefulWidget {
  final String? initialQuery;
  const F2BSearchPage({super.key, this.initialQuery});

  @override
  State<F2BSearchPage> createState() => _F2BSearchPageState();
}

class _F2BSearchPageState extends State<F2BSearchPage> {
  final _service = ExporterService();
  late final TextEditingController _searchCtrl;
  final FocusNode _focus = FocusNode();

  String _query = '';
  String _selectedCategory = 'all';
  String _sortBy = 'newest';
  static const double _sliderMax = 10000;
  double _sliderValue = 10000;

  Set<String> _wishlistIds = {};

  // ── Categories ────────────────────────────────────────────────────────────

  static const _cats = [
    ('all', 'All'),
    ('vegetables', 'Vegetables'),
    ('fruits', 'Fruits'),
    ('grains', 'Grains'),
    ('spices', 'Spices'),
    ('pulses', 'Pulses'),
    ('crops', 'Crops'),
    ('other', 'Other'),
  ];

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery ?? '';
    _searchCtrl = TextEditingController(text: _query);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focus.requestFocus());
    _loadWishlist();
  }

  void _loadWishlist() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    WishlistService.stream(uid).listen((ids) {
      if (mounted) setState(() => _wishlistIds = ids);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ── Filter + sort ─────────────────────────────────────────────────────────

  List<ExportProduct> _apply(List<ExportProduct> all) {
    var r = all;

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      r = r.where((p) =>
        p.productName.toLowerCase().contains(q) ||
        p.farmerName.toLowerCase().contains(q) ||
        p.location.toLowerCase().contains(q) ||
        p.category.toLowerCase().contains(q)).toList();
    }

    if (_selectedCategory != 'all') {
      r = r.where((p) =>
          p.category.toLowerCase() == _selectedCategory).toList();
    }

    final priceLimit = _sliderValue >= _sliderMax ? 999999.0 : _sliderValue;
    if (priceLimit < 999999) {
      r = r.where((p) {
        final price = double.tryParse(
            p.pricePerUnit.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
        return price <= priceLimit;
      }).toList();
    }

    switch (_sortBy) {
      case 'price_low':
        r.sort((a, b) => _price(a).compareTo(_price(b)));
      case 'price_high':
        r.sort((a, b) => _price(b).compareTo(_price(a)));
      default:
        r.sort((a, b) => (b.createdAt ?? DateTime(0))
            .compareTo(a.createdAt ?? DateTime(0)));
    }

    return r;
  }

  double _price(ExportProduct p) =>
      double.tryParse(p.pricePerUnit.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;

  bool get _hasActiveFilter =>
      _selectedCategory != 'all' ||
      _sortBy != 'newest' ||
      _sliderValue < _sliderMax;

  void _clearFilters() => setState(() {
    _selectedCategory = 'all';
    _sortBy = 'newest';
    _sliderValue = _sliderMax;
  });

  // ── Filter bottom sheet ───────────────────────────────────────────────────

  void _showFilters(AppLocalizations l) {
    String tempCat = _selectedCategory;
    String tempSort = _sortBy;
    double tempSlider = _sliderValue;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (ctx, scrollCtrl) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              controller: scrollCtrl,
              children: [
                const SizedBox(height: 8),
                // Handle bar
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(l.filterProducts,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),

                // ── Sort ─────────────────────────────────────────
                Text(l.sortBy,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ...[
                  ('newest', l.newestFirst),
                  ('price_low', l.lowestPrice),
                  ('price_high', l.highestPrice),
                ].map((e) => RadioListTile<String>(
                  value: e.$1,
                  groupValue: tempSort,
                  onChanged: (v) => setModal(() => tempSort = v!),
                  title: Text(e.$2),
                  activeColor: KMColors.primary,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                )),
                const SizedBox(height: 16),

                // ── Category ─────────────────────────────────────
                Text(l.categoryLabel,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _cats.map((c) {
                    final sel = tempCat == c.$1;
                    return ChoiceChip(
                      label: Text(c.$2),
                      selected: sel,
                      onSelected: (_) => setModal(() => tempCat = c.$1),
                      selectedColor: KMColors.primary,
                      labelStyle: TextStyle(
                          color: sel ? Colors.white : KMColors.textPrimary),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // ── Price range ───────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l.priceRange,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(
                      tempSlider >= _sliderMax
                          ? 'Any'
                          : '≤ ₹${tempSlider.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: KMColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Slider(
                  value: tempSlider,
                  min: 0,
                  max: _sliderMax,
                  divisions: 100,
                  activeColor: KMColors.primary,
                  onChanged: (v) => setModal(() => tempSlider = v),
                ),
                const SizedBox(height: 24),

                // ── Buttons ───────────────────────────────────────
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setModal(() {
                          tempCat = 'all';
                          tempSort = 'newest';
                          tempSlider = _sliderMax;
                        });
                      },
                      child: Text(l.clearFilters),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = tempCat;
                          _sortBy = tempSort;
                          _sliderValue = tempSlider;
                        });
                        Navigator.pop(ctx);
                      },
                      child: Text(l.applyFilters),
                    ),
                  ),
                ]),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Wishlist toggle ───────────────────────────────────────────────────────

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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final langCode = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? KMColors.backgroundDark : const Color(0xFFF0F7F0),
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchCtrl,
          focusNode: _focus,
          onChanged: (v) => setState(() => _query = v),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: l.searchHint,
            hintStyle: const TextStyle(color: Colors.white60),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        actions: [
          if (_searchCtrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
            ),
          IconButton(
            tooltip: l.filterProducts,
            icon: Badge(
              isLabelVisible: _hasActiveFilter,
              child: const Icon(Icons.tune_rounded),
            ),
            onPressed: () => _showFilters(l),
          ),
        ],
      ),
      body: StreamBuilder<List<ExportProduct>>(
        stream: _service.getExportProducts(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: KMColors.primary));
          }

          final results = _apply(snap.data!);

          return Column(
            children: [
              // Active filter chips
              if (_hasActiveFilter)
                _ActiveFiltersBar(
                  category: _selectedCategory,
                  sortBy: _sortBy,
                  sliderValue: _sliderValue,
                  sliderMax: _sliderMax,
                  l: l,
                  onClear: _clearFilters,
                ),

              // Results count
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(
                  children: [
                    Text(
                      '${results.length} ${l.resultsFound}',
                      style: const TextStyle(
                          fontSize: 13,
                          color: KMColors.textSecondary,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              // Results
              Expanded(
                child: results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off_rounded,
                                size: 64, color: KMColors.textSecondary),
                            const SizedBox(height: 12),
                            Text(l.noSearchResults,
                                style: const TextStyle(
                                    fontSize: 15,
                                    color: KMColors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(12, 4, 12, 24),
                        itemCount: results.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final p = results[i];
                          return _SearchResultCard(
                            product: p,
                            langCode: langCode,
                            isWishlisted: _wishlistIds.contains(p.id),
                            onTap: () => Navigator.push(
                              ctx,
                              MaterialPageRoute(
                                builder: (_) =>
                                    F2BProductDetailPage(product: p),
                              ),
                            ),
                            onWishlist: () =>
                                _toggleWishlist(context, l, p.id),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Active filters chip bar ───────────────────────────────────────────────

class _ActiveFiltersBar extends StatelessWidget {
  final String category;
  final String sortBy;
  final double sliderValue;
  final double sliderMax;
  final AppLocalizations l;
  final VoidCallback onClear;
  const _ActiveFiltersBar({
    required this.category, required this.sortBy,
    required this.sliderValue, required this.sliderMax,
    required this.l, required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: Theme.of(context).brightness == Brightness.dark
          ? KMColors.cardDark
          : Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          if (category != 'all')
            _chip(category, context),
          if (sortBy != 'newest')
            _chip(sortBy == 'price_low' ? l.lowestPrice : l.highestPrice,
                context),
          if (sliderValue < sliderMax)
            _chip('≤ ₹${sliderValue.toStringAsFixed(0)}', context),
          ActionChip(
            label: Text(l.clearFilters,
                style: const TextStyle(
                    fontSize: 11, color: KMColors.textSecondary)),
            onPressed: onClear,
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 6),
    child: Chip(
      label: Text(label,
          style: const TextStyle(
              fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: KMColors.primary,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
  );
}

// ─── Search result card (horizontal) ──────────────────────────────────────

Color _accentFor(String cat) {
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

class _SearchResultCard extends StatelessWidget {
  final ExportProduct product;
  final String langCode;
  final bool isWishlisted;
  final VoidCallback onTap;
  final VoidCallback onWishlist;
  const _SearchResultCard({
    required this.product, required this.langCode,
    required this.isWishlisted, required this.onTap, required this.onWishlist,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accentFor(product.category);
    final name = ContentTranslationService.translateCropName(
        product.productName, langCode);
    final loc = ContentTranslationService.translateLocation(
        product.location, langCode);
    final cat = ContentTranslationService.translateExportCategory(
        product.category, langCode);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? KMColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: KMShadow.card,
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(14)),
              child: SizedBox(
                width: 90,
                height: 90,
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? Image.network(product.imageUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(accent))
                    : _placeholder(accent),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(cat,
                            style: TextStyle(
                                fontSize: 9,
                                color: accent,
                                fontWeight: FontWeight.w700)),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text(name,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text('₹${product.pricePerUnit}  •  ${product.quantity}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: KMColors.primary)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.person_outline,
                          size: 11, color: KMColors.textSecondary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text('${product.farmerName}  •  $loc',
                            style: const TextStyle(
                                fontSize: 11, color: KMColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            // Heart button
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: onWishlist,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    isWishlisted ? Icons.favorite : Icons.favorite_border,
                    size: 22,
                    color: isWishlisted ? Colors.red : KMColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(Color accent) => Container(
    color: accent.withValues(alpha: 0.12),
    child: Center(child: Icon(Icons.agriculture_rounded,
        size: 36, color: accent.withValues(alpha: 0.5))),
  );
}
