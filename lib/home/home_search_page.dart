import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../labour_hub/labour_model.dart';
import '../labour_hub/labour_hub_detail_page.dart';
import '../plant_vendor/plant_vendor_model.dart';
import '../plant_vendor/plant_detail_page.dart';
import '../rent/rent_model.dart';
import '../rent/rent_home_page.dart';
import '../theme.dart';

// ── Result wrapper ────────────────────────────────────────────────────────────

enum _ResultType { plant, labour, machine }

class _SearchResult {
  final _ResultType type;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String id;
  final dynamic raw;

  const _SearchResult({
    required this.type,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.id,
    required this.raw,
  });
}

// ── Page ─────────────────────────────────────────────────────────────────────

class HomeSearchPage extends StatefulWidget {
  const HomeSearchPage({super.key});

  @override
  State<HomeSearchPage> createState() => _HomeSearchPageState();
}

class _HomeSearchPageState extends State<HomeSearchPage> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  String _query = '';
  bool _loading = false;
  List<_SearchResult> _results = [];

  // ── quick‑search categories shown before typing ───────────────────────────
  static const _categories = [
    ('🌾', 'Rice'),
    ('🌽', 'Maize'),
    ('🍅', 'Tomato'),
    ('🧅', 'Onion'),
    ('🚜', 'Tractor'),
    ('🌿', 'Plants'),
    ('👷', 'Labour'),
    ('🌱', 'Seeds'),
    ('🍌', 'Banana'),
    ('🌶', 'Chilli'),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onChanged);
    // Auto-focus after frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.removeListener(_onChanged);
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    final q = _ctrl.text.trim();
    if (q == _query) return;
    setState(() => _query = q);
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(q));
  }

  Future<void> _search(String q) async {
    if (!mounted) return;
    setState(() => _loading = true);

    final lower = q.toLowerCase();
    final results = <_SearchResult>[];

    await Future.wait([
      _searchPlants(lower, results),
      _searchLabour(lower, results),
      _searchMachines(lower, results),
    ]);

    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  // ── Firestore queries ─────────────────────────────────────────────────────

  Future<void> _searchPlants(String q, List<_SearchResult> out) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('plant_vendors')
          .limit(200)
          .get();
      for (final doc in snap.docs) {
        final v = PlantVendor.fromMap(doc.data(), doc.id);
        if (_matches(q, [v.plantName, v.type, v.location, v.vendorName])) {
          out.add(_SearchResult(
            type: _ResultType.plant,
            title: v.plantName.isNotEmpty ? v.plantName : 'Plant',
            subtitle: '${v.type} • ₹${v.price.toStringAsFixed(0)} • ${v.location}',
            imageUrl: v.imageUrl,
            id: v.id,
            raw: v,
          ));
        }
      }
    } catch (_) {}
  }

  Future<void> _searchLabour(String q, List<_SearchResult> out) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('labours')
          .limit(200)
          .get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final name = (data['name'] as String?) ?? '';
        final skill = (data['skill'] as String?) ?? '';
        final location = (data['location'] as String?) ?? '';
        final category = (data['category'] as String?) ?? '';
        if (_matches(q, [name, skill, location, category])) {
          final l = Labour.fromMap(data, doc.id);
          out.add(_SearchResult(
            type: _ResultType.labour,
            title: name.isNotEmpty ? name : 'Labour',
            subtitle: '${skill.isNotEmpty ? skill : category} • $location',
            imageUrl: data['imageUrl'] as String?,
            id: doc.id,
            raw: l,
          ));
        }
      }
    } catch (_) {}
  }

  Future<void> _searchMachines(String q, List<_SearchResult> out) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('rent_machines')
          .limit(200)
          .get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final name = (data['name'] as String?) ?? '';
        final type = (data['type'] as String?) ?? '';
        final location = (data['location'] as String?) ?? '';
        final owner = (data['ownerName'] as String?) ?? '';
        if (_matches(q, [name, type, location, owner])) {
          final m = RentMachine.fromDoc(doc);
          out.add(_SearchResult(
            type: _ResultType.machine,
            title: name.isNotEmpty ? name : type,
            subtitle: '${type.isNotEmpty ? type : 'Machine'} • ₹${m.pricePerDay.toStringAsFixed(0)}/day • ${location.isNotEmpty ? location : "—"}',
            imageUrl: m.imageUrl.isNotEmpty ? m.imageUrl : null,
            id: doc.id,
            raw: m,
          ));
        }
      }
    } catch (_) {}
  }

  bool _matches(String q, List<String> fields) =>
      fields.any((f) => f.toLowerCase().contains(q));

  // ── Navigation ────────────────────────────────────────────────────────────

  void _openResult(_SearchResult r) {
    switch (r.type) {
      case _ResultType.plant:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => PlantDetailPage(vendor: r.raw as PlantVendor)));
      case _ResultType.labour:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => LabourHubDetailPage(labour: r.raw as Labour)));
      case _ResultType.machine:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const RentHomePage()));
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? KMColors.backgroundDark : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: cs.primary,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 42,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _ctrl,
            focusNode: _focus,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(_query),
            decoration: InputDecoration(
              hintText: 'Search crops, machines, labour, products...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              prefixIcon: Icon(Icons.search_rounded, color: cs.primary, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: Colors.grey,
                      onPressed: () {
                        _ctrl.clear();
                        setState(() {
                          _query = '';
                          _results = [];
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
              isDense: true,
            ),
          ),
        ),
      ),
      body: _query.isEmpty
          ? _buildQuickCategories(cs)
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _results.isEmpty
                  ? _buildEmpty()
                  : _buildResults(isDark),
    );
  }

  Widget _buildQuickCategories(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Popular Searches',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cs.onSurface.withValues(alpha: 0.6))),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _categories.map((c) {
            return GestureDetector(
              onTap: () {
                _ctrl.text = c.$2;
                _ctrl.selection = TextSelection.fromPosition(
                    TextPosition(offset: c.$2.length));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(c.$1, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(c.$2,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface)),
                ]),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        _buildSection('🌿 Plants & Seeds', cs),
        _buildSection('🚜 Machinery for Rent', cs),
        _buildSection('👷 Labour', cs),
      ]),
    );
  }

  Widget _buildSection(String title, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4)
          ],
        ),
        child: Row(children: [
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14))),
          Icon(Icons.chevron_right_rounded, color: cs.primary),
        ]),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🔍', style: TextStyle(fontSize: 52)),
        const SizedBox(height: 12),
        Text('No results for "$_query"',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: KMColors.textSecondary)),
        const SizedBox(height: 6),
        const Text('Try different keywords',
            style: TextStyle(fontSize: 13, color: KMColors.textSecondary)),
      ]),
    );
  }

  Widget _buildResults(bool isDark) {
    // Group by type
    final plants = _results.where((r) => r.type == _ResultType.plant).toList();
    final labour = _results.where((r) => r.type == _ResultType.labour).toList();
    final machines = _results.where((r) => r.type == _ResultType.machine).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Text('  ${_results.length} result${_results.length == 1 ? '' : 's'} for "$_query"',
            style: const TextStyle(
                fontSize: 12,
                color: KMColors.textSecondary,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        if (plants.isNotEmpty) ...[
          _sectionHeader('🌿 Plants & Products', plants.length),
          ...plants.map((r) => _ResultTile(result: r, onTap: () => _openResult(r), isDark: isDark)),
        ],
        if (machines.isNotEmpty) ...[
          _sectionHeader('🚜 Machinery', machines.length),
          ...machines.map((r) => _ResultTile(result: r, onTap: () => _openResult(r), isDark: isDark)),
        ],
        if (labour.isNotEmpty) ...[
          _sectionHeader('👷 Labour', labour.length),
          ...labour.map((r) => _ResultTile(result: r, onTap: () => _openResult(r), isDark: isDark)),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _sectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(children: [
        Text(title,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
              color: KMColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Text('$count',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: KMColors.primary)),
        ),
      ]),
    );
  }
}

// ── Result tile ───────────────────────────────────────────────────────────────

class _ResultTile extends StatelessWidget {
  final _SearchResult result;
  final VoidCallback onTap;
  final bool isDark;

  const _ResultTile({required this.result, required this.onTap, required this.isDark});

  IconData get _icon {
    switch (result.type) {
      case _ResultType.plant: return Icons.local_florist_rounded;
      case _ResultType.labour: return Icons.person_rounded;
      case _ResultType.machine: return Icons.agriculture_rounded;
    }
  }

  Color get _color {
    switch (result.type) {
      case _ResultType.plant: return const Color(0xFF2E7D32);
      case _ResultType.labour: return const Color(0xFF1565C0);
      case _ResultType.machine: return const Color(0xFFE65100);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      decoration: BoxDecoration(
        color: isDark ? KMColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: result.imageUrl != null && result.imageUrl!.isNotEmpty
              ? Image.network(
                  result.imageUrl!,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
              : _placeholder(),
        ),
        title: Text(
          result.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          result.subtitle,
          style: const TextStyle(fontSize: 12, color: KMColors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(Icons.chevron_right_rounded,
            color: Colors.grey.shade400, size: 20),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 52,
        height: 52,
        color: _color.withValues(alpha: 0.12),
        child: Icon(_icon, color: _color, size: 26),
      );
}
