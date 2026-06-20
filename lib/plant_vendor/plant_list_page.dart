// lib/plant_vendor/plant_list_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'plant_vendor_model.dart';
import 'plant_vendor_service.dart';
import 'plant_list_form_page.dart';
import 'plant_vendor_nearby_page.dart';
import 'plant_detail_page.dart';
import '../services/content_translation_service.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';

// ─── Category / type data ──────────────────────────────────────────────────

class _TabData {
  final String key, label, emoji;
  const _TabData(this.key, this.label, this.emoji);
}

const _kTabs = [
  _TabData('all',   'All',   '🌿'),
  _TabData('plant', 'Plants','🪴'),
  _TabData('seeds', 'Seeds', '🌾'),
];

class _ChipData {
  final String key, label, emoji;
  final Color color;
  const _ChipData(this.key, this.label, this.emoji, this.color);
}

const _kPlantChips = [
  _ChipData('all',        'All Types',  '🌿', Color(0xFF2E7D32)),
  _ChipData('fruit',      'Fruit',      '🍎', Color(0xFFE67E22)),
  _ChipData('flowering',  'Flowering',  '🌸', Color(0xFFE91E8C)),
  _ChipData('vegetable',  'Vegetable',  '🥦', Color(0xFF27AE60)),
  _ChipData('medicinal',  'Medicinal',  '💊', Color(0xFF16A085)),
  _ChipData('ornamental', 'Ornamental', '🪴', Color(0xFF8E44AD)),
  _ChipData('timber',     'Timber',     '🌳', Color(0xFF795548)),
  _ChipData('aromatic',   'Aromatic',   '🌿', Color(0xFF00897B)),
];

const _kSeedChips = [
  _ChipData('all',       'All Seeds',      '🌾', Color(0xFFF39C12)),
  _ChipData('vegetable', 'Vegetable',       '🥦', Color(0xFF27AE60)),
  _ChipData('flower',    'Flower',          '🌸', Color(0xFFE91E8C)),
  _ChipData('herb',      'Herb',            '🌿', Color(0xFF00897B)),
  _ChipData('fruit',     'Fruit',           '🍎', Color(0xFFE67E22)),
  _ChipData('grain',     'Grain',           '🌾', Color(0xFFBF360C)),
];

Color _accentForType(String rawType) {
  final lower = rawType.toLowerCase();
  if (lower.contains('fruit'))      return const Color(0xFFE67E22);
  if (lower.contains('flower'))     return const Color(0xFFE91E8C);
  if (lower.contains('vegetable'))  return const Color(0xFF27AE60);
  if (lower.contains('medicinal'))  return const Color(0xFF16A085);
  if (lower.contains('ornamental')) return const Color(0xFF8E44AD);
  if (lower.contains('timber'))     return const Color(0xFF795548);
  if (lower.contains('aromatic'))   return const Color(0xFF00897B);
  if (lower.contains('seeds') || lower.contains('seed')) return const Color(0xFFF39C12);
  return const Color(0xFF2E7D32);
}

IconData _iconForType(String rawType) {
  final lower = rawType.toLowerCase();
  if (lower.contains('fruit'))      return Icons.apple_rounded;
  if (lower.contains('flower'))     return Icons.local_florist_rounded;
  if (lower.contains('vegetable'))  return Icons.eco_rounded;
  if (lower.contains('medicinal'))  return Icons.healing_rounded;
  if (lower.contains('ornamental')) return Icons.yard_rounded;
  if (lower.contains('timber'))     return Icons.forest_rounded;
  if (lower.contains('aromatic'))   return Icons.spa_rounded;
  if (lower.contains('seeds') || lower.contains('seed')) return Icons.grass_rounded;
  return Icons.local_florist_rounded;
}

// ─── Helpers ───────────────────────────────────────────────────────────────

String _mainCategory(PlantVendor v) {
  final raw = v.type.toString();
  return raw.contains(' - ')
      ? raw.split(' - ').first.trim().toLowerCase()
      : 'plant';
}

String _subType(PlantVendor v) {
  final raw = v.type.toString();
  return raw.contains(' - ')
      ? raw.split(' - ').sublist(1).join(' - ').trim().toLowerCase()
      : raw.toLowerCase();
}

String _displayType(PlantVendor v) {
  final raw = v.type.toString();
  return raw.contains(' - ')
      ? raw.split(' - ').sublist(1).join(' - ').trim()
      : raw;
}

// ─── Page ──────────────────────────────────────────────────────────────────

class PlantVendorListPage extends StatefulWidget {
  final String category;
  const PlantVendorListPage({super.key, this.category = 'Plant'});

  @override
  State<PlantVendorListPage> createState() => _PlantVendorListPageState();
}

class _PlantVendorListPageState extends State<PlantVendorListPage> {
  final _service = PlantVendorService();
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  String _tabKey = 'all';     // 'all' | 'plant' | 'seeds'
  String _typeKey = 'all';    // sub-type chip key
  String _sortBy = 'newest';  // 'newest' | 'oldest' | 'price_asc' | 'price_desc'
  String _search = '';

  @override
  void initState() {
    super.initState();
    final cat = widget.category.toLowerCase();
    if (cat == 'seeds') _tabKey = 'seeds';
    else if (cat == 'plant') _tabKey = 'plant';
    else _tabKey = 'all';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<PlantVendor> _applyFilters(List<PlantVendor> all) {
    var r = all;

    // Tab filter
    if (_tabKey != 'all') {
      r = r.where((v) => _mainCategory(v) == _tabKey).toList();
    }

    // Sub-type chip filter
    if (_typeKey != 'all') {
      r = r.where((v) => _subType(v).contains(_typeKey)).toList();
    }

    // Search
    if (_search.isNotEmpty) {
      final q = _search;
      r = r.where((v) =>
          v.plantName.toLowerCase().contains(q) ||
          v.type.toLowerCase().contains(q) ||
          v.vendorName.toLowerCase().contains(q) ||
          v.location.toLowerCase().contains(q)).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'oldest':
        r.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      case 'price_asc':
        r.sort((a, b) => a.price.compareTo(b.price));
      case 'price_desc':
        r.sort((a, b) => b.price.compareTo(a.price));
      default:
        r.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }

    return r;
  }

  List<_ChipData> get _activeChips {
    if (_tabKey == 'seeds') return _kSeedChips;
    if (_tabKey == 'plant') return _kPlantChips;
    return const [_ChipData('all', 'All', '🌿', Color(0xFF2E7D32))];
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Sort Listings',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          ...[
            ('newest',     Icons.new_releases_rounded,   'Newest First'),
            ('oldest',     Icons.history_rounded,         'Oldest First'),
            ('price_asc',  Icons.arrow_upward_rounded,    'Price: Low to High'),
            ('price_desc', Icons.arrow_downward_rounded,  'Price: High to Low'),
          ].map((opt) {
            final sel = _sortBy == opt.$1;
            return ListTile(
              leading: Icon(opt.$2,
                  color: sel ? const Color(0xFF2E7D32) : Colors.grey),
              title: Text(opt.$3,
                  style: TextStyle(
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
              trailing: sel
                  ? const Icon(Icons.check_rounded, color: Color(0xFF2E7D32))
                  : null,
              onTap: () {
                setState(() => _sortBy = opt.$1);
                Navigator.pop(context);
              },
            );
          }),
        ]),
      ),
    );
  }

  Future<void> _showActions(PlantVendor v) async {
    final l = AppLocalizations.of(context)!;
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 8),
          ListTile(
            leading: Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.edit_rounded,
                    color: Color(0xFF2E7D32), size: 18)),
            title: Text(l.edit,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push<bool>(context,
                  MaterialPageRoute(
                      builder: (_) => PlantListFormPage(existingVendor: v)))
                  .then((changed) {
                if (changed == true && mounted) setState(() {});
              });
            },
          ),
          ListTile(
            leading: Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: KMColors.error.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.delete_rounded,
                    color: KMColors.error, size: 18)),
            title: Text(l.delete,
                style: const TextStyle(color: KMColors.error,
                    fontWeight: FontWeight.w600)),
            onTap: () async {
              Navigator.pop(context);
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: Text(l.deleteListingQ),
                  content: Text(l.permanentlyDeleteListing),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false),
                        child: Text(l.cancel)),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: KMColors.error),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(l.delete),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await _service.deletePlantVendor(v.id);
                if (mounted) setState(() {});
              }
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPad = MediaQuery.of(context).padding.top;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF1F8F1),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                  builder: (_) => const PlantListFormPage()));
          if (added == true && mounted) setState(() {});
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(l.add),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: Column(children: [
        // ── Header ─────────────────────────────────────────────
        _PlantHeader(
          topPad: topPad,
          onNearby: () => Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => const PlantVendorNearbyPage())),
          onSort: _showSortSheet,
        ),
        // ── Search bar ─────────────────────────────────────────
        _PlantSearchBar(
          controller: _searchCtrl,
          focusNode: _searchFocus,
          onChanged: (v) => setState(() => _search = v.toLowerCase()),
          onClear: () {
            _searchCtrl.clear();
            setState(() => _search = '');
            _searchFocus.unfocus();
          },
        ),
        // ── Main category tabs ─────────────────────────────────
        _MainTabs(
          selected: _tabKey,
          onSelect: (k) => setState(() {
            _tabKey = k;
            _typeKey = 'all';
          }),
        ),
        // ── Sub-type chips (only when Plant or Seeds tab active) ─
        if (_tabKey != 'all')
          _SubTypeChips(
            chips: _activeChips,
            selected: _typeKey,
            onSelect: (k) => setState(() => _typeKey = k),
          ),
        // ── Grid ───────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<List<PlantVendor>>(
            stream: _service.streamVendors(),
            builder: (ctx, snap) {
              if (snap.hasError) {
                return Center(child: Column(mainAxisSize: MainAxisSize.min,
                    children: [
                  const Icon(Icons.error_outline, size: 48,
                      color: KMColors.error),
                  const SizedBox(height: 8),
                  Text('Error: ${snap.error}'),
                ]));
              }
              if (!snap.hasData) {
                return _PlantShimmer(isDark: isDark);
              }

              final filtered = _applyFilters(snap.data!);

              if (filtered.isEmpty) {
                return Center(child: Column(mainAxisSize: MainAxisSize.min,
                    children: [
                  const Text('🌿', style: TextStyle(fontSize: 52)),
                  const SizedBox(height: 12),
                  Text(l.noListingsFound,
                      style: const TextStyle(fontSize: 15,
                          color: Color(0xFF9E9E9E))),
                  if (_search.isNotEmpty || _tabKey != 'all' || _typeKey != 'all')
                    TextButton(
                      onPressed: () => setState(() {
                        _search = '';
                        _searchCtrl.clear();
                        _tabKey = 'all';
                        _typeKey = 'all';
                      }),
                      child: const Text('Clear Filters'),
                    ),
                ]));
              }

              return RefreshIndicator(
                color: const Color(0xFF2E7D32),
                onRefresh: () async => setState(() {}),
                child: CustomScrollView(slivers: [
                  // Stats bar
                  SliverToBoxAdapter(
                    child: _StatsBar(
                        total: snap.data!.length,
                        filtered: filtered.length),
                  ),
                  // Grid
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          final v = filtered[i];
                          final isOwner = (v.createdBy.isNotEmpty
                                  ? v.createdBy
                                  : v.ownerId) ==
                              uid;
                          return _PlantCard(
                            vendor: v,
                            isOwner: isOwner,
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) =>
                                    PlantDetailPage(vendor: v))),
                            onActions: () => _showActions(v),
                          );
                        },
                        childCount: filtered.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.62,
                      ),
                    ),
                  ),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────────

class _PlantHeader extends StatelessWidget {
  final double topPad;
  final VoidCallback onNearby, onSort;
  const _PlantHeader(
      {required this.topPad, required this.onNearby, required this.onSort});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(4, topPad + 8, 8, 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A5E20), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        Expanded(
          child: Container(
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
                  Text('PlantHub',
                      style: TextStyle(fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3)),
                  Text('Plants & Seeds Market',
                      style: TextStyle(fontSize: 9.5,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ]),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.location_on_rounded,
              color: Colors.white, size: 22),
          tooltip: 'Nearby',
          onPressed: onNearby,
        ),
        IconButton(
          icon: const Icon(Icons.sort_rounded, color: Colors.white, size: 22),
          onPressed: onSort,
        ),
      ]),
    );
  }
}

// ─── Search bar ────────────────────────────────────────────────────────────

class _PlantSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const _PlantSearchBar({required this.controller, required this.focusNode,
      required this.onChanged, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        const Icon(Icons.search_rounded,
            color: Color(0xFF2E7D32), size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            decoration: const InputDecoration(
              hintText: 'Search plant, vendor, location...',
              hintStyle: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        if (controller.text.isNotEmpty)
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close_rounded,
                size: 20, color: Color(0xFF9E9E9E)),
          ),
      ]),
    );
  }
}

// ─── Main category tabs ────────────────────────────────────────────────────

class _MainTabs extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _MainTabs({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(children: _kTabs.map((t) {
        final sel = selected == t.key;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(t.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFF2E7D32) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(t.emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(t.label,
                      style: TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : const Color(0xFF757575))),
                ]),
              ),
            ),
          ),
        );
      }).toList()),
    );
  }
}

// ─── Sub-type chips ────────────────────────────────────────────────────────

class _SubTypeChips extends StatelessWidget {
  final List<_ChipData> chips;
  final String selected;
  final ValueChanged<String> onSelect;
  const _SubTypeChips(
      {required this.chips, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        itemCount: chips.length,
        itemBuilder: (_, i) {
          final c = chips[i];
          final sel = selected == c.key;
          return GestureDetector(
            onTap: () => onSelect(c.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: sel ? c.color : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: sel ? c.color : const Color(0xFFE0E0E0)),
                boxShadow: sel
                    ? [BoxShadow(color: c.color.withValues(alpha: 0.28),
                        blurRadius: 6, offset: const Offset(0, 2))]
                    : null,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(c.emoji, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text(c.label,
                    style: TextStyle(fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : const Color(0xFF757575))),
              ]),
            ),
          );
        },
      ),
    );
  }
}

// ─── Stats bar ─────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final int total, filtered;
  const _StatsBar({required this.total, required this.filtered});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.local_florist_rounded,
                size: 13, color: Color(0xFF2E7D32)),
            const SizedBox(width: 4),
            Text('$total listings',
                style: const TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E7D32))),
          ]),
        ),
        const Spacer(),
        Text('$filtered shown',
            style: const TextStyle(fontSize: 11,
                color: Color(0xFF9E9E9E), fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ─── Plant card ────────────────────────────────────────────────────────────

class _PlantCard extends StatelessWidget {
  final PlantVendor vendor;
  final bool isOwner;
  final VoidCallback onTap, onActions;
  const _PlantCard({required this.vendor, required this.isOwner,
      required this.onTap, required this.onActions});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langCode = Localizations.localeOf(context).languageCode;
    final accent = _accentForType(vendor.type);
    final catIcon = _iconForType(vendor.type);
    final hasImage =
        vendor.imageUrl != null && vendor.imageUrl!.isNotEmpty;
    final typeLabel = _displayType(vendor);
    final translatedType =
        ContentTranslationService.translatePlantCategory(typeLabel, langCode);
    final plantName = vendor.plantName.isNotEmpty ? vendor.plantName : '—';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Image ─────────────────────────────────────────────
          Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18)),
              child: hasImage
                  ? Image.network(
                      vendor.imageUrl!, height: 130,
                      width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _PlantPlaceholder(accent: accent, icon: catIcon),
                    )
                  : _PlantPlaceholder(accent: accent, icon: catIcon),
            ),
            // Price badge
            Positioned(
              bottom: 8, right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('₹${vendor.price.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ),
            // Owner actions
            if (isOwner)
              Positioned(
                top: 6, right: 6,
                child: GestureDetector(
                  onTap: onActions,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.more_vert_rounded,
                        color: Colors.white, size: 14),
                  ),
                ),
              ),
            // Stock low badge
            if (vendor.quantity > 0 && vendor.quantity <= 5)
              Positioned(
                top: 8, left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Low Stock',
                      style: TextStyle(color: Colors.white,
                          fontSize: 9, fontWeight: FontWeight.w700)),
                ),
              ),
          ]),

          // ── Body ──────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Plant name
                Text(plantName,
                    style: const TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w800),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 5),
                // Type chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(catIcon, size: 10, color: accent),
                    const SizedBox(width: 3),
                    Flexible(child: Text(translatedType,
                        style: TextStyle(fontSize: 9.5,
                            fontWeight: FontWeight.w700, color: accent),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                ),
                const SizedBox(height: 5),
                // Vendor
                Row(children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 11, color: Color(0xFF9E9E9E)),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(vendor.vendorName,
                        style: const TextStyle(fontSize: 10.5,
                            color: Color(0xFF9E9E9E)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ]),
                if (vendor.location.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 11, color: Color(0xFF9E9E9E)),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(vendor.location,
                          style: const TextStyle(fontSize: 10.5,
                              color: Color(0xFF9E9E9E)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ],
                const Spacer(),
                // Qty + price row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withValues(
                            alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Qty: ${vendor.quantity}',
                          style: const TextStyle(fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1565C0))),
                    ),
                    Text('₹${vendor.price.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: accent)),
                  ],
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _PlantPlaceholder extends StatelessWidget {
  final Color accent;
  final IconData icon;
  const _PlantPlaceholder({required this.accent, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130, width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.35),
              accent.withValues(alpha: 0.65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(icon, size: 48,
            color: Colors.white.withValues(alpha: 0.45)),
      ),
    );
  }
}

// ─── Shimmer ───────────────────────────────────────────────────────────────

class _PlantShimmer extends StatefulWidget {
  final bool isDark;
  const _PlantShimmer({required this.isDark});
  @override
  State<_PlantShimmer> createState() => _PlantShimmerState();
}

class _PlantShimmerState extends State<_PlantShimmer>
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
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12,
          mainAxisSpacing: 12, childAspectRatio: 0.62),
      itemCount: 6,
      itemBuilder: (_, __) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          final t = _anim.value;
          final shine = LinearGradient(
            begin: Alignment(-1.0 + t * 2, 0),
            end: Alignment(t * 2, 0),
            colors: widget.isDark
                ? [const Color(0xFF2A2A2A), const Color(0xFF3D3D3D),
                   const Color(0xFF2A2A2A)]
                : [const Color(0xFFE8E8E8), const Color(0xFFF5F5F5),
                   const Color(0xFFE8E8E8)],
            stops: const [0, 0.5, 1],
          );
          return Container(
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 130,
                    decoration: BoxDecoration(gradient: shine,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18)))),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 13,
                          decoration: BoxDecoration(gradient: shine,
                              borderRadius: BorderRadius.circular(6))),
                      const SizedBox(height: 7),
                      Container(height: 18, width: 60,
                          decoration: BoxDecoration(gradient: shine,
                              borderRadius: BorderRadius.circular(6))),
                      const SizedBox(height: 7),
                      Container(height: 10,
                          decoration: BoxDecoration(gradient: shine,
                              borderRadius: BorderRadius.circular(6))),
                      const SizedBox(height: 5),
                      Container(height: 10, width: 100,
                          decoration: BoxDecoration(gradient: shine,
                              borderRadius: BorderRadius.circular(6))),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PlantVendorDetailsPage — kept for backward compatibility
// ─────────────────────────────────────────────────────────────────────────────

class PlantVendorDetailsPage extends StatelessWidget {
  final PlantVendor vendor;
  const PlantVendorDetailsPage({super.key, required this.vendor});

  @override
  Widget build(BuildContext context) {
    return PlantDetailPage(vendor: vendor);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date formatter (shared utility)
// ─────────────────────────────────────────────────────────────────────────────

String formatDate(DateTime dt) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  return '${months[dt.month - 1]} ${dt.day} '
      '$hour:${dt.minute.toString().padLeft(2, '0')} $ampm';
}
