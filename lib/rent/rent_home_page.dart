// lib/rent/rent_home_page.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'rent_model.dart';
import 'rent_machine_service.dart';
import 'rent_list_form_page.dart';
import 'rent_nearby_page.dart';
import 'rent_machine_details_page.dart';
import '../l10n/app_localizations.dart';
import '../services/content_translation_service.dart';

// ─── Category data ─────────────────────────────────────────────────────────

class _TypeData {
  final String key, label, emoji;
  final Color color;
  const _TypeData(this.key, this.label, this.emoji, this.color);
}

const _kTypes = [
  _TypeData('All',          'All',          '🔑', Color(0xFF37474F)),
  _TypeData('Tractor',      'Tractor',      '🚜', Color(0xFFBF360C)),
  _TypeData('Harvester',    'Harvester',    '⚙️', Color(0xFF4A148C)),
  _TypeData('Sprayer',      'Sprayer',      '💧', Color(0xFF1565C0)),
  _TypeData('Rotavator',    'Rotavator',    '🔄', Color(0xFF1B5E20)),
  _TypeData('Transplanter', 'Transplanter', '🌱', Color(0xFF006064)),
  _TypeData('Thresher',     'Thresher',     '🌾', Color(0xFFE65100)),
  _TypeData('Pump Set',     'Pump Set',     '💦', Color(0xFF0277BD)),
  _TypeData('Other',        'Other',        '📦', Color(0xFF455A64)),
];

// ─── Page ──────────────────────────────────────────────────────────────────

class RentHomePage extends StatefulWidget {
  const RentHomePage({super.key});
  @override
  State<RentHomePage> createState() => _RentHomePageState();
}

class _RentHomePageState extends State<RentHomePage> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _searchQuery = '';
  String _selectedType = 'All';
  String _sortBy = 'newest'; // 'newest' | 'price_asc' | 'price_desc' | 'distance'
  Position? _position;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));
      if (mounted) setState(() => _position = pos);
    } catch (_) {}
  }

  double _distanceTo(RentMachine m) {
    if (_position == null) return double.infinity;
    const r = 6371.0;
    final dLat = (m.latitude - _position!.latitude) * pi / 180;
    final dLon = (m.longitude - _position!.longitude) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_position!.latitude * pi / 180) *
            cos(m.latitude * pi / 180) *
            sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  List<RentMachine> _applyFilters(List<RentMachine> all) {
    var r = all;
    if (_selectedType != 'All') {
      r = r.where((m) =>
          m.type.toLowerCase() == _selectedType.toLowerCase()).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery;
      r = r.where((m) =>
          m.name.toLowerCase().contains(q) ||
          m.type.toLowerCase().contains(q) ||
          m.ownerName.toLowerCase().contains(q) ||
          (m.location?.toLowerCase().contains(q) ?? false)).toList();
    }
    switch (_sortBy) {
      case 'price_asc':
        r.sort((a, b) => a.pricePerDay.compareTo(b.pricePerDay));
      case 'price_desc':
        r.sort((a, b) => b.pricePerDay.compareTo(a.pricePerDay));
      case 'distance':
        r.sort((a, b) => _distanceTo(a).compareTo(_distanceTo(b)));
      default:
        r.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return r;
  }

  bool _isOwner(RentMachine m) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return uid.isNotEmpty && uid == m.ownerId;
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
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
          const Text('Sort Machines',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          ...[
            ('newest', Icons.new_releases_rounded, 'Newest First'),
            ('price_asc', Icons.arrow_upward_rounded, 'Price: Low to High'),
            ('price_desc', Icons.arrow_downward_rounded, 'Price: High to Low'),
            ('distance', Icons.near_me_rounded, 'Nearest First'),
          ].map((opt) {
            final sel = _sortBy == opt.$1;
            return ListTile(
              leading: Icon(opt.$2,
                  color: sel ? const Color(0xFFBF360C) : Colors.grey),
              title: Text(opt.$3,
                  style: TextStyle(
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
              trailing: sel
                  ? const Icon(Icons.check_rounded,
                      color: Color(0xFFBF360C))
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F3F0),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => const RentListFormPage()))
            .then((_) => setState(() {})),
        icon: const Icon(Icons.add_rounded),
        label: Text(l.listMachine),
        backgroundColor: const Color(0xFFBF360C),
        foregroundColor: Colors.white,
      ),
      body: Column(children: [
        // ── Fixed header ────────────────────────────────────────
        _RentHeader(
          topPad: topPad,
          onNearby: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RentNearbyPage())),
          onSort: _showSortSheet,
        ),
        // ── Search bar ──────────────────────────────────────────
        _RentSearchBar(
          controller: _searchCtrl,
          focusNode: _searchFocus,
          onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          onClear: () {
            _searchCtrl.clear();
            setState(() => _searchQuery = '');
            _searchFocus.unfocus();
          },
        ),
        // ── Type filter chips ───────────────────────────────────
        _TypeFilterRow(
          selected: _selectedType,
          onSelect: (k) => setState(() => _selectedType = k),
        ),
        // ── Machine grid ────────────────────────────────────────
        Expanded(
          child: StreamBuilder<List<RentMachine>>(
            stream: RentMachineService.instance.streamRentMachines(),
            builder: (ctx, snap) {
              if (snap.hasError) {
                return Center(child: Column(mainAxisSize: MainAxisSize.min,
                    children: [
                  const Icon(Icons.error_outline, size: 48,
                      color: Color(0xFFBF360C)),
                  const SizedBox(height: 8),
                  Text('Error: ${snap.error}'),
                ]));
              }
              if (!snap.hasData) {
                return _RentShimmer(isDark: isDark);
              }

              final filtered = _applyFilters(snap.data!);

              if (filtered.isEmpty) {
                return Center(child: Column(mainAxisSize: MainAxisSize.min,
                    children: [
                  const Text('🚜', style: TextStyle(fontSize: 52)),
                  const SizedBox(height: 12),
                  Text(l.noMachinesFoundNearby,
                      style: const TextStyle(fontSize: 15,
                          color: Color(0xFF9E9E9E))),
                  if (_searchQuery.isNotEmpty || _selectedType != 'All')
                    TextButton(
                      onPressed: () => setState(() {
                        _searchQuery = '';
                        _searchCtrl.clear();
                        _selectedType = 'All';
                      }),
                      child: const Text('Clear Filters'),
                    ),
                ]));
              }

              return RefreshIndicator(
                color: const Color(0xFFBF360C),
                onRefresh: () async => setState(() {}),
                child: CustomScrollView(slivers: [
                  // Stats
                  SliverToBoxAdapter(
                    child: _RentStatsBar(
                        total: snap.data!.length,
                        filtered: filtered.length),
                  ),
                  // Grid
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _MachineCard(
                          machine: filtered[i],
                          isOwner: _isOwner(filtered[i]),
                          distance: _distanceTo(filtered[i]),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) =>
                                  RentMachineDetailsPage(
                                      machine: filtered[i]))),
                          onCall: () => _call(filtered[i].phone),
                          onEdit: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) =>
                                  RentListFormPage(
                                      existingMachine: filtered[i])))
                              .then((_) => setState(() {})),
                        ),
                        childCount: filtered.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.66,
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

class _RentHeader extends StatelessWidget {
  final double topPad;
  final VoidCallback onNearby, onSort;
  const _RentHeader(
      {required this.topPad, required this.onNearby, required this.onSort});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(4, topPad + 8, 8, 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4E1F00), Color(0xFFBF360C)],
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
              Text('🚜', style: TextStyle(fontSize: 18)),
              SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('RentHub',
                      style: TextStyle(fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3)),
                  Text('Farm Equipment Rental',
                      style: TextStyle(fontSize: 9.5,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ]),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.near_me_rounded,
              color: Colors.white, size: 22),
          tooltip: 'Nearby Machines',
          onPressed: onNearby,
        ),
        IconButton(
          icon: const Icon(Icons.sort_rounded, color: Colors.white, size: 22),
          tooltip: 'Sort',
          onPressed: onSort,
        ),
      ]),
    );
  }
}

// ─── Search bar ────────────────────────────────────────────────────────────

class _RentSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const _RentSearchBar({required this.controller, required this.focusNode,
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
            color: Color(0xFFBF360C), size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            decoration: const InputDecoration(
              hintText: 'Search machines, owner, location...',
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

// ─── Type filter ───────────────────────────────────────────────────────────

class _TypeFilterRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _TypeFilterRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        itemCount: _kTypes.length,
        itemBuilder: (_, i) {
          final t = _kTypes[i];
          final sel = selected == t.key;
          return GestureDetector(
            onTap: () => onSelect(t.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? t.color : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: sel ? t.color : const Color(0xFFE0E0E0)),
                boxShadow: sel
                    ? [BoxShadow(color: t.color.withValues(alpha: 0.28),
                        blurRadius: 6, offset: const Offset(0, 2))]
                    : null,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(t.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 5),
                Text(t.label,
                    style: TextStyle(fontSize: 12,
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

class _RentStatsBar extends StatelessWidget {
  final int total, filtered;
  const _RentStatsBar({required this.total, required this.filtered});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFBF360C).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.agriculture_rounded,
                size: 13, color: Color(0xFFBF360C)),
            const SizedBox(width: 4),
            Text('$total machines',
                style: const TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFBF360C))),
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

// ─── Machine card ──────────────────────────────────────────────────────────

Color _typeColor(String type) {
  switch (type.toLowerCase()) {
    case 'tractor': return const Color(0xFFBF360C);
    case 'harvester': return const Color(0xFF4A148C);
    case 'sprayer': return const Color(0xFF1565C0);
    case 'rotavator': return const Color(0xFF1B5E20);
    case 'transplanter': return const Color(0xFF006064);
    case 'thresher': return const Color(0xFFE65100);
    case 'pump set': return const Color(0xFF0277BD);
    default: return const Color(0xFF455A64);
  }
}

class _MachineCard extends StatelessWidget {
  final RentMachine machine;
  final bool isOwner;
  final double distance;
  final VoidCallback onTap, onCall, onEdit;
  const _MachineCard({required this.machine, required this.isOwner,
      required this.distance, required this.onTap,
      required this.onCall, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langCode = Localizations.localeOf(context).languageCode;
    final typeColor = _typeColor(machine.type);
    final hasImage = machine.imageUrl.isNotEmpty;
    final hasDistance = distance.isFinite && distance < 999;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image / gradient header ────────────────────────
            Stack(children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18)),
                child: hasImage
                    ? Image.network(
                        machine.imageUrl,
                        height: 130, width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _GradientPlaceholder(
                                color: typeColor,
                                type: machine.type),
                      )
                    : _GradientPlaceholder(
                        color: typeColor, type: machine.type),
              ),
              // Price badge
              Positioned(
                bottom: 8, left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '₹${machine.pricePerDay.toStringAsFixed(0)}/day',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              // Owner edit menu
              if (isOwner)
                Positioned(
                  top: 6, right: 6,
                  child: GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.edit_rounded,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ),
              // Distance badge
              if (hasDistance)
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(
                          alpha: 0.88),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${distance.toStringAsFixed(1)} km',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 9.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ]),
            // ── Body ──────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Machine name
                    Text(machine.name,
                        style: const TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    // Type chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ContentTranslationService.translateMachineType(
                            machine.type, langCode),
                        style: TextStyle(fontSize: 10,
                            fontWeight: FontWeight.w700, color: typeColor),
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Location
                    if (machine.location != null) ...[
                      Row(children: [
                        const Icon(Icons.location_on_outlined,
                            size: 11, color: Color(0xFF9E9E9E)),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            ContentTranslationService.translateLocation(
                                machine.location!, langCode),
                            style: const TextStyle(fontSize: 10.5,
                                color: Color(0xFF9E9E9E)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 3),
                    ],
                    // Owner
                    Row(children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 11, color: Color(0xFF9E9E9E)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(machine.ownerName,
                            style: const TextStyle(fontSize: 10.5,
                                color: Color(0xFF9E9E9E)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                    const Spacer(),
                    // Call button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onCall,
                        icon: const Icon(Icons.phone_rounded, size: 14),
                        label: const Text('Call Owner',
                            style: TextStyle(fontSize: 11,
                                fontWeight: FontWeight.w800)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBF360C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
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

class _GradientPlaceholder extends StatelessWidget {
  final Color color;
  final String type;
  const _GradientPlaceholder(
      {required this.color, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130, width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.agriculture_rounded,
            size: 48, color: Colors.white.withValues(alpha: 0.35)),
      ),
    );
  }
}

// ─── Shimmer ───────────────────────────────────────────────────────────────

class _RentShimmer extends StatefulWidget {
  final bool isDark;
  const _RentShimmer({required this.isDark});
  @override
  State<_RentShimmer> createState() => _RentShimmerState();
}

class _RentShimmerState extends State<_RentShimmer>
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
        mainAxisSpacing: 12, childAspectRatio: 0.66,
      ),
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
              color: widget.isDark
                  ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 130,
                    decoration: BoxDecoration(
                      gradient: shine,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18)),
                    )),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 13,
                          decoration: BoxDecoration(gradient: shine,
                              borderRadius: BorderRadius.circular(6))),
                      const SizedBox(height: 7),
                      Container(height: 18, width: 70,
                          decoration: BoxDecoration(gradient: shine,
                              borderRadius: BorderRadius.circular(6))),
                      const SizedBox(height: 7),
                      Container(height: 10,
                          decoration: BoxDecoration(gradient: shine,
                              borderRadius: BorderRadius.circular(6))),
                      const SizedBox(height: 5),
                      Container(height: 10,
                          decoration: BoxDecoration(gradient: shine,
                              borderRadius: BorderRadius.circular(6))),
                      const SizedBox(height: 10),
                      Container(height: 32,
                          decoration: BoxDecoration(gradient: shine,
                              borderRadius: BorderRadius.circular(10))),
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
