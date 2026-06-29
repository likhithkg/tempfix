// lib/labour_hub/labour_hub_listing_page.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'labour_model.dart';
import 'labour_hub_service.dart';
import 'labour_hub_form_page.dart';
import 'labour_hub_detail_page.dart';
import 'labour_nearby_page.dart';
import 'hire_request_form_page.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';

// ─── Category data ─────────────────────────────────────────────────────────

class _CatData {
  final String key, label, emoji;
  final Color color;
  const _CatData(this.key, this.label, this.emoji, this.color);
}

const _kCats = [
  _CatData('All',                 'All Workers',       '👷', Color(0xFF388E3C)),
  _CatData('Farm Labour',         'Farm Labour',        '🌾', Color(0xFF2E7D32)),
  _CatData('Tractor Driver',      'Tractor Driver',     '🚜', Color(0xFFE65100)),
  _CatData('Plantation Worker',   'Plantation',         '🌱', Color(0xFF00695C)),
  _CatData('Sprayer Operator',    'Sprayer',            '💧', Color(0xFF1565C0)),
  _CatData('Harvester Operator',  'Harvester',          '⚙️', Color(0xFF4A148C)),
  _CatData('Machine Technician',  'Technician',         '🔧', Color(0xFF37474F)),
  _CatData('Dairy Worker',        'Dairy',              '🐄', Color(0xFF880E4F)),
];

// ─── Page ──────────────────────────────────────────────────────────────────

class LabourHubListingPage extends StatefulWidget {
  const LabourHubListingPage({super.key});
  @override
  State<LabourHubListingPage> createState() => _LabourHubListingPageState();
}

class _LabourHubListingPageState extends State<LabourHubListingPage> {
  final _service = LabourHubService();
  late final Stream<List<dynamic>> _stream;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  String _searchQuery = '';
  String _selectedCat = 'All';
  String _sortBy = 'name'; // 'name' | 'experience' | 'distance'
  Position? _position;
  bool _searchActive = false;

  @override
  void initState() {
    super.initState();
    _stream = _service.streamLabours();
    _fetchLocation();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _service.dispose();
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

  double _distanceTo(Labour l) {
    if (_position == null || l.latitude == null || l.longitude == null) {
      return double.infinity;
    }
    const r = 6371.0;
    final dLat = (l.latitude! - _position!.latitude) * pi / 180;
    final dLon = (l.longitude! - _position!.longitude) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_position!.latitude * pi / 180) *
            cos(l.latitude! * pi / 180) *
            sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  List<Labour> _applyFilters(List<Labour> all) {
    var r = all;
    if (_selectedCat != 'All') {
      r = r.where((l) => l.category == _selectedCat).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      r = r.where((l) =>
          l.name.toLowerCase().contains(q) ||
          l.skill.toLowerCase().contains(q) ||
          l.location.toLowerCase().contains(q) ||
          (l.category?.toLowerCase().contains(q) ?? false)).toList();
    }
    switch (_sortBy) {
      case 'experience':
        r.sort((a, b) =>
            (b.experience ?? 0).compareTo(a.experience ?? 0));
      case 'distance':
        r.sort((a, b) => _distanceTo(a).compareTo(_distanceTo(b)));
      default:
        r.sort((a, b) => a.name.compareTo(b.name));
    }
    return r;
  }

  Future<void> _delete(String id) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(l.deleteLabour),
        content: Text(l.deleteLabourConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
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
    if (confirmed != true) return;
    try {
      await _service.deleteLabour(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.deleted)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e')));
      }
    }
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
          const Text('Sort Workers',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          ...[
            ('name', Icons.sort_by_alpha_rounded, 'By Name'),
            ('experience', Icons.workspace_premium_rounded, 'By Experience'),
            ('distance', Icons.near_me_rounded, 'By Distance'),
          ].map((opt) {
            final sel = _sortBy == opt.$1;
            return ListTile(
              leading: Icon(opt.$2,
                  color: sel ? KMColors.primary : KMColors.textSecondary),
              title: Text(opt.$3,
                  style: TextStyle(
                      fontWeight:
                          sel ? FontWeight.w700 : FontWeight.w400)),
              trailing: sel
                  ? const Icon(Icons.check_rounded,
                      color: KMColors.primary)
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor:
          isDark ? KMColors.backgroundDark : const Color(0xFFF3F5F3),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => const LabourHubFormPage())).then((_) => setState(() {})),
        icon: const Icon(Icons.person_add_rounded),
        label: Text(l.addLabour),
        backgroundColor: KMColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(children: [
        // ── Fixed header ────────────────────────────────────────
        _LHHeader(
          topPad: topPad,
          sortBy: _sortBy,
          onNearby: () => Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => const LabourNearbyPage())),
          onSort: _showSortSheet,
        ),
        // ── Search bar ──────────────────────────────────────────
        _SearchBarRow(
          controller: _searchCtrl,
          focusNode: _searchFocus,
          active: _searchActive,
          onFocus: (v) => setState(() => _searchActive = v),
          onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          onClear: () {
            _searchCtrl.clear();
            setState(() {
              _searchQuery = '';
              _searchActive = false;
            });
            _searchFocus.unfocus();
          },
        ),
        // ── Category row ────────────────────────────────────────
        _CategoryRow(
          selected: _selectedCat,
          onSelect: (k) => setState(() => _selectedCat = k),
        ),
        // ── Worker list ─────────────────────────────────────────
        Expanded(
          child: StreamBuilder<List<dynamic>>(
            stream: _stream,
            builder: (ctx, snap) {
              if (snap.hasError) {
                return Center(child: Column(mainAxisSize: MainAxisSize.min,
                    children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: KMColors.error),
                  const SizedBox(height: 8),
                  Text('${l.errorLoadingLabour}: ${snap.error}'),
                  TextButton(onPressed: () => setState(() {}),
                      child: const Text('Retry')),
                ]));
              }
              if (!snap.hasData) {
                return _LHShimmer(isDark: isDark);
              }

              final typedData = snap.data!.whereType<Labour>().toList();
              final filtered = _applyFilters(typedData);
              final total = typedData.length;
              final available = typedData.where((x) => x.available).length;

              if (filtered.isEmpty) {
                return Center(child: Column(mainAxisSize: MainAxisSize.min,
                    children: [
                  const Text('👷', style: TextStyle(fontSize: 52)),
                  const SizedBox(height: 12),
                  Text(l.noLabourFound,
                      style: const TextStyle(fontSize: 15,
                          color: KMColors.textSecondary)),
                  if (_searchQuery.isNotEmpty || _selectedCat != 'All')
                    TextButton(
                      onPressed: () => setState(() {
                        _searchQuery = '';
                        _searchCtrl.clear();
                        _selectedCat = 'All';
                      }),
                      child: const Text('Clear Filters'),
                    ),
                ]));
              }

              return RefreshIndicator(
                color: KMColors.primary,
                onRefresh: () async => setState(() {}),
                child: CustomScrollView(slivers: [
                  // Stats bar
                  SliverToBoxAdapter(
                    child: _StatsBar(
                        total: total, available: available,
                        filtered: filtered.length),
                  ),
                  // Cards
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _WorkerCard(
                          labour: filtered[i],
                          isOwner: uid != null &&
                              filtered[i].createdBy == uid,
                          distance: _distanceTo(filtered[i]),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) =>
                                  LabourHubDetailPage(
                                      labour: filtered[i]))),
                          onCall: () => _call(filtered[i].contact),
                          onHire: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) =>
                                  HireRequestFormPage(
                                    labourId: filtered[i].id,
                                    labourName: filtered[i].name,
                                  ))),
                          onEdit: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) =>
                                  LabourHubFormPage(
                                      labour: filtered[i])))
                              .then((_) => setState(() {})),
                          onDelete: () => _delete(filtered[i].id),
                        ),
                        childCount: filtered.length,
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

class _LHHeader extends StatelessWidget {
  final double topPad;
  final String sortBy;
  final VoidCallback onNearby, onSort;
  const _LHHeader({required this.topPad, required this.sortBy,
      required this.onNearby, required this.onSort});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, topPad + 8, 8, 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
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
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text('👷', style: TextStyle(fontSize: 18)),
                SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('LabourHub',
                        style: TextStyle(fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.3)),
                    Text('Find & Hire Workers',
                        style: TextStyle(fontSize: 9.5,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ]),
            ),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.location_on_rounded, color: Colors.white,
              size: 22),
          tooltip: 'Nearby Workers',
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

class _SearchBarRow extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool active;
  final ValueChanged<bool> onFocus;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const _SearchBarRow({required this.controller, required this.focusNode,
      required this.active, required this.onFocus,
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
            onTap: () => onFocus(true),
            decoration: const InputDecoration(
              hintText: 'Search name, skill, location...',
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

// ─── Category row ──────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _CategoryRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        itemCount: _kCats.length,
        itemBuilder: (_, i) {
          final c = _kCats[i];
          final sel = selected == c.key;
          return GestureDetector(
            onTap: () => onSelect(c.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
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
                Text(c.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 5),
                Text(c.label,
                    style: TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : KMColors.textSecondary)),
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
  final int total, available, filtered;
  const _StatsBar(
      {required this.total, required this.available, required this.filtered});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(children: [
        _StatPill(
          label: '$total Total', icon: Icons.people_rounded,
          color: KMColors.primary),
        const SizedBox(width: 8),
        _StatPill(
          label: '$available Available',
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF2E7D32)),
        const Spacer(),
        Text('$filtered shown',
            style: const TextStyle(fontSize: 11,
                color: KMColors.textSecondary,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _StatPill(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: color)),
      ]),
    );
  }
}

// ─── Worker card ───────────────────────────────────────────────────────────

Color _avatarColor(String name) {
  const colors = [
    Color(0xFF1B5E20), Color(0xFFBF360C), Color(0xFF0D47A1),
    Color(0xFF4A148C), Color(0xFF006064), Color(0xFF880E4F),
    Color(0xFF4E342E), Color(0xFF37474F), Color(0xFF1565C0),
    Color(0xFFE65100),
  ];
  final code = name.isNotEmpty ? name.codeUnitAt(0) : 0;
  return colors[code % colors.length];
}

class _WorkerCard extends StatelessWidget {
  final Labour labour;
  final bool isOwner;
  final double distance;
  final VoidCallback onTap, onCall, onHire, onEdit, onDelete;
  const _WorkerCard({
    required this.labour, required this.isOwner, required this.distance,
    required this.onTap, required this.onCall, required this.onHire,
    required this.onEdit, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarColor = _avatarColor(labour.name);
    final initial = labour.name.isNotEmpty
        ? labour.name[0].toUpperCase()
        : '?';
    final hasDistance =
        distance.isFinite && distance < 999;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? KMColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // ── Top: avatar + info + owner actions ──────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Avatar
              Stack(children: [
                Container(
                  width: 58, height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [avatarColor,
                          avatarColor.withValues(alpha: 0.65)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: labour.imageUrl != null &&
                          labour.imageUrl!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            labour.imageUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(initial,
                                  style: const TextStyle(fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                            ),
                          ),
                        )
                      : Center(child: Text(initial,
                          style: const TextStyle(fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white))),
                ),
                // Online/available dot
                Positioned(
                  bottom: 1, right: 1,
                  child: Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                      color: labour.available
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFE53935),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ]),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(labour.name,
                        style: const TextStyle(fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: KMColors.textPrimary),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                    // Availability badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (labour.available
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFB71C1C))
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        labour.available ? '● Available' : '● Busy',
                        style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: labour.available
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFB71C1C),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 3),
                  // Skill
                  Text(labour.skill,
                      style: const TextStyle(fontSize: 13,
                          color: KMColors.textSecondary,
                          fontWeight: FontWeight.w600),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  // Location + distance
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 12, color: KMColors.textSecondary),
                    const SizedBox(width: 3),
                    Expanded(child: Text(labour.location,
                        style: const TextStyle(fontSize: 11,
                            color: KMColors.textSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                    if (hasDistance) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withValues(
                              alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${distance.toStringAsFixed(1)} km',
                          style: const TextStyle(fontSize: 9.5,
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ]),
                ],
              )),
              if (isOwner)
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  icon: const Icon(Icons.more_vert_rounded,
                      color: KMColors.textSecondary, size: 20),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit',
                        child: Row(children: [
                          Icon(Icons.edit_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ])),
                    PopupMenuItem(value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_rounded,
                              size: 16, color: KMColors.error),
                          SizedBox(width: 8),
                          Text('Delete',
                              style: TextStyle(color: KMColors.error)),
                        ])),
                  ],
                ),
            ]),
          ),
          // ── Info pills row ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Wrap(spacing: 6, runSpacing: 4, children: [
              if (labour.category != null)
                _InfoPill(label: labour.category!,
                    color: const Color(0xFF1B5E20)),
              if (labour.experience != null)
                _InfoPill(
                    label: '${labour.experience} yrs exp',
                    color: const Color(0xFF1565C0)),
              if (labour.wage != null && labour.wageType != null)
                _InfoPill(
                    label: '₹${labour.wage!.toStringAsFixed(0)} / ${labour.wageType}',
                    color: const Color(0xFFE65100)),
              if (labour.rating != null && (labour.rating ?? 0) > 0)
                _InfoPill(
                    label: '⭐ ${labour.rating!.toStringAsFixed(1)}',
                    color: const Color(0xFFFF8F00)),
            ]),
          ),
          // ── Divider ────────────────────────────────────────────
          Divider(height: 1,
              color: isDark ? Colors.white10 : const Color(0xFFF0F0F0)),
          // ── Action row ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(children: [
              // Call button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.phone_rounded, size: 16),
                  label: const Text('Call',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1B5E20),
                    side: const BorderSide(color: Color(0xFF1B5E20)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Hire button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: labour.available ? onHire : null,
                  icon: const Icon(Icons.work_rounded, size: 16),
                  label: Text(
                    labour.available ? 'Hire Now' : 'Not Available',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
              color: color)),
    );
  }
}

// ─── Shimmer loading ────────────────────────────────────────────────────────

class _LHShimmer extends StatefulWidget {
  final bool isDark;
  const _LHShimmer({required this.isDark});
  @override
  State<_LHShimmer> createState() => _LHShimmerState();
}

class _LHShimmerState extends State<_LHShimmer>
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
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: 5,
      itemBuilder: (_, __) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          final t = _anim.value;
          final base = widget.isDark
              ? const Color(0xFF1E1E1E)
              : Colors.white;
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
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: base,
                borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Container(width: 58, height: 58,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                          gradient: shine)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 16, width: 140,
                          decoration: BoxDecoration(gradient: shine,
                              borderRadius: BorderRadius.circular(8))),
                      const SizedBox(height: 8),
                      Container(height: 12, width: 100,
                          decoration: BoxDecoration(gradient: shine,
                              borderRadius: BorderRadius.circular(6))),
                      const SizedBox(height: 6),
                      Container(height: 10, width: 160,
                          decoration: BoxDecoration(gradient: shine,
                              borderRadius: BorderRadius.circular(6))),
                    ],
                  )),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  for (final w in [70.0, 90.0, 80.0]) ...[
                    Container(height: 22, width: w,
                        decoration: BoxDecoration(gradient: shine,
                            borderRadius: BorderRadius.circular(8))),
                    const SizedBox(width: 6),
                  ],
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: Container(height: 36,
                      decoration: BoxDecoration(gradient: shine,
                          borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(width: 10),
                  Expanded(flex: 2, child: Container(height: 36,
                      decoration: BoxDecoration(gradient: shine,
                          borderRadius: BorderRadius.circular(10)))),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }
}
