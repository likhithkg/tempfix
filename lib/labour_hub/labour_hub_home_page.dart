import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'labour_hub_service.dart';
import 'labour_profile_model.dart';
import 'labour_detail_page.dart';
import 'labour_profile_form_page.dart';
import 'saved_workers_page.dart';
import '../theme.dart';
import '../widgets/km_widgets.dart';

// ── Filter state ───────────────────────────────────────────────────────────────

class _LabourFilter {
  final String skill;
  final bool verifiedOnly;
  final bool availableToday;
  final double minRating;
  final String gender;
  final int maxDistanceKm;
  final int minExperience;
  final String language;

  const _LabourFilter({
    this.skill = 'All',
    this.verifiedOnly = false,
    this.availableToday = false,
    this.minRating = 0,
    this.gender = 'All',
    this.maxDistanceKm = 100,
    this.minExperience = 0,
    this.language = 'All',
  });

  int get activeCount {
    int c = 0;
    if (skill != 'All') c++;
    if (verifiedOnly) c++;
    if (availableToday) c++;
    if (minRating > 0) c++;
    if (gender != 'All') c++;
    if (maxDistanceKm < 100) c++;
    if (minExperience > 0) c++;
    if (language != 'All') c++;
    return c;
  }

  _LabourFilter copyWith({
    String? skill,
    bool? verifiedOnly,
    bool? availableToday,
    double? minRating,
    String? gender,
    int? maxDistanceKm,
    int? minExperience,
    String? language,
  }) =>
      _LabourFilter(
        skill: skill ?? this.skill,
        verifiedOnly: verifiedOnly ?? this.verifiedOnly,
        availableToday: availableToday ?? this.availableToday,
        minRating: minRating ?? this.minRating,
        gender: gender ?? this.gender,
        maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
        minExperience: minExperience ?? this.minExperience,
        language: language ?? this.language,
      );

  _LabourFilter reset() => const _LabourFilter();
}

// ── Home Page ──────────────────────────────────────────────────────────────────

class LabourHubHomePage extends StatefulWidget {
  const LabourHubHomePage({super.key});

  @override
  State<LabourHubHomePage> createState() => _LabourHubHomePageState();
}

class _LabourHubHomePageState extends State<LabourHubHomePage> {
  final _service = LabourHubService();
  final _searchCtrl = TextEditingController();
  double? _userLat, _userLng;
  _LabourFilter _filter = const _LabourFilter();

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    try {
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
      if (mounted) {
        setState(() {
          _userLat = pos.latitude;
          _userLng = pos.longitude;
        });
      }
    } catch (_) {}
  }

  Future<void> _openMyCard(BuildContext ctx) async {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
        content: Text('Please sign in to manage your worker card'),
        backgroundColor: KMColors.rentPrimary,
      ));
      return;
    }
    final nav = Navigator.of(ctx);
    final existing = await _service.getMyProfile();
    if (!mounted) return;
    await nav.push(
      MaterialPageRoute(
          builder: (_) => LabourProfileFormPage(existing: existing)),
    );
    if (mounted) setState(() {});
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FilterSheet(
        filter: _filter,
        hasLocation: _userLat != null,
        onApply: (f) {
          setState(() => _filter = f);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KMColors.backgroundLight,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openMyCard(context),
        backgroundColor: KMColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('My Worker Card',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            floating: false,
            backgroundColor: KMColors.primaryDark,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_filter.activeCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Stack(children: [
                    IconButton(
                      icon: const Icon(Icons.filter_list_rounded,
                          color: Colors.white),
                      onPressed: _showFilterSheet,
                    ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                            color: KMColors.rentPrimary, shape: BoxShape.circle),
                        child: Text('${_filter.activeCount}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ]),
                )
              else
                IconButton(
                  icon: const Icon(Icons.filter_list_rounded,
                      color: Colors.white),
                  onPressed: _showFilterSheet,
                ),
              IconButton(
                icon: const Icon(Icons.favorite_rounded,
                    color: Colors.white),
                tooltip: 'Saved Workers',
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SavedWorkersPage())),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: KMGradients.primaryHeader),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 44),
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10)),
                            child: const Text('👷',
                                style: TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('WorkForce Hub',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3)),
                              Text(
                                  _userLat != null
                                      ? 'Showing workers near you'
                                      : 'Find skilled agricultural workers',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ]),
                        const SizedBox(height: 14),
                        _SearchBar(
                            controller: _searchCtrl,
                            onChanged: (_) => setState(() {})),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        body: _WorkersTab(
          service: _service,
          searchQuery: _searchCtrl.text,
          userLat: _userLat,
          userLng: _userLng,
          filter: _filter,
          onSkillChange: (s) =>
              setState(() => _filter = _filter.copyWith(skill: s)),
        ),
      ),
    );
  }
}

// ── Search Bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24)),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'Search workers, skills, location…',
          hintStyle: TextStyle(color: Colors.white60, fontSize: 13),
          prefixIcon:
              Icon(Icons.search_rounded, color: Colors.white70, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

// ── Workers Tab ───────────────────────────────────────────────────────────────

class _WorkersTab extends StatefulWidget {
  final LabourHubService service;
  final String searchQuery;
  final double? userLat;
  final double? userLng;
  final _LabourFilter filter;
  final ValueChanged<String> onSkillChange;

  const _WorkersTab({
    required this.service,
    required this.searchQuery,
    required this.userLat,
    required this.userLng,
    required this.filter,
    required this.onSkillChange,
  });

  @override
  State<_WorkersTab> createState() => _WorkersTabState();
}

class _WorkersTabState extends State<_WorkersTab>
    with AutomaticKeepAliveClientMixin {
  late final Stream<List<LabourProfile>> _stream;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _stream = widget.service.streamAllProfiles();
  }

  List<LabourProfile> _applyFilter(List<LabourProfile> all) {
    var list = all;

    if (widget.filter.skill != 'All') {
      list = list
          .where((p) => p.skills.contains(widget.filter.skill))
          .toList();
    }
    if (widget.filter.verifiedOnly) {
      list = list.where((p) => p.isVerified).toList();
    }
    if (widget.filter.availableToday) {
      list = list.where((p) => p.isAvailableToday).toList();
    }
    if (widget.filter.minRating > 0) {
      list = list
          .where((p) => p.rating >= widget.filter.minRating)
          .toList();
    }
    if (widget.filter.gender != 'All') {
      list =
          list.where((p) => p.gender == widget.filter.gender).toList();
    }
    if (widget.filter.minExperience > 0) {
      list = list
          .where((p) => p.experienceYears >= widget.filter.minExperience)
          .toList();
    }
    if (widget.filter.language != 'All') {
      list = list
          .where((p) => p.languages.contains(widget.filter.language))
          .toList();
    }
    if (widget.userLat != null &&
        widget.userLng != null &&
        widget.filter.maxDistanceKm < 100) {
      list = list.where((p) {
        if (!p.hasLocation) return true;
        final d = _dist(
            widget.userLat!, widget.userLng!, p.latitude, p.longitude);
        return d <= widget.filter.maxDistanceKm;
      }).toList();
    }

    final q = widget.searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.skills.any((s) => s.toLowerCase().contains(q)) ||
              p.village.toLowerCase().contains(q) ||
              p.district.toLowerCase().contains(q))
          .toList();
    }

    return list;
  }

  double _dist(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<List<LabourProfile>>(
      stream: _stream,
      builder: (ctx, snap) {
        if (snap.hasError) {
          return Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('Could not load data'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: KMColors.primary),
                  ),
                ]),
          );
        }

        final loading = !snap.hasData;
        final all = snap.data ?? [];
        final filtered = _applyFilter(all);

        final availableToday =
            filtered.where((p) => p.isAvailableToday).toList();
        final featured = filtered
            .where((p) => p.isVerified || p.rating >= 4.5)
            .toList();
        final topRated = ([...filtered]
              ..sort((a, b) => b.rating.compareTo(a.rating)))
            .take(10)
            .toList();
        final highlyExp =
            filtered.where((p) => p.experienceYears >= 5).toList();
        final women =
            filtered.where((p) => p.gender == 'Female').toList();
        final machineOps = filtered
            .where((p) => p.skills.any((s) => [
                  'Tractor Driver',
                  'Harvester Operator',
                  'JCB Operator',
                  'Machine Operator'
                ].contains(s)))
            .toList();
        final organic = filtered
            .where((p) => p.skills.contains('Organic Farming'))
            .toList();
        final recent = ([...filtered]
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
            .take(10)
            .toList();

        List<LabourProfile> nearby = [];
        if (widget.userLat != null && widget.userLng != null) {
          nearby = filtered.where((p) => p.hasLocation).toList();
          nearby.sort((a, b) => _dist(widget.userLat!, widget.userLng!,
                  a.latitude, a.longitude)
              .compareTo(_dist(widget.userLat!, widget.userLng!,
                  b.latitude, b.longitude)));
          nearby = nearby.take(15).toList();
        }

        return CustomScrollView(
          slivers: [
            // Active filter indicator
            if (widget.filter.activeCount > 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: Row(children: [
                    const Icon(Icons.filter_list_rounded,
                        size: 16, color: KMColors.primary),
                    const SizedBox(width: 6),
                    Text(
                        '${widget.filter.activeCount} filter(s) active',
                        style: const TextStyle(
                            fontSize: 12,
                            color: KMColors.primary,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),

            // Stats
            if (!loading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: Row(children: [
                    _StatChip(
                        label: '${all.length} Workers', color: KMColors.primary),
                    const SizedBox(width: 8),
                    _StatChip(
                        label:
                            '${all.where((p) => p.availabilityStatus == 'available').length} Available',
                        color: KMColors.available),
                    if (filtered.length != all.length) ...[
                      const SizedBox(width: 8),
                      _StatChip(
                          label: '${filtered.length} Shown',
                          color: Colors.blue),
                    ],
                  ]),
                ),
              ),

            // Quick Categories
            _SectionHeader(
              title: 'Browse by Skill',
              icon: Icons.category_rounded,
              iconColor: KMColors.primary,
            ),
            SliverToBoxAdapter(
              child: _QuickCategories(
                  onTap: (s) => widget.onSkillChange(s)),
            ),

            // Nearby Workers
            if (widget.userLat != null) ...[
              _SectionHeader(
                title: 'Nearby Workers',
                icon: Icons.near_me_rounded,
                iconColor: Colors.blue.shade600,
              ),
              SliverToBoxAdapter(
                child: loading
                    ? _HorizontalShimmer()
                    : nearby.isEmpty
                        ? const _EmptyHorizontal(
                            message: 'No workers found nearby')
                        : _HorizontalWorkerList(
                            workers: nearby,
                            service: widget.service,
                            userLat: widget.userLat,
                            userLng: widget.userLng),
              ),
            ],
            if (widget.userLat == null)
              SliverToBoxAdapter(
                child: _LocationBanner(),
              ),

            // Available Today
            if (availableToday.isNotEmpty || loading) ...[
              _SectionHeader(
                title: 'Available Today',
                icon: Icons.today_rounded,
                iconColor: KMColors.available,
              ),
              SliverToBoxAdapter(
                child: loading
                    ? _HorizontalShimmer()
                    : availableToday.isEmpty
                        ? const SizedBox()
                        : _HorizontalWorkerList(
                            workers: availableToday,
                            service: widget.service,
                            userLat: widget.userLat,
                            userLng: widget.userLng),
              ),
            ],

            // Featured / Verified
            _SectionHeader(
              title: 'Verified & Top Workers',
              icon: Icons.verified_rounded,
              iconColor: Colors.blue,
            ),
            SliverToBoxAdapter(
              child: loading
                  ? _HorizontalShimmer()
                  : featured.isEmpty
                      ? const _EmptyHorizontal(
                          message: 'No featured workers yet')
                      : _HorizontalWorkerList(
                          workers: featured,
                          service: widget.service,
                          userLat: widget.userLat,
                          userLng: widget.userLng),
            ),

            // Top Rated
            _SectionHeader(
              title: 'Top Rated Workers',
              icon: Icons.star_rounded,
              iconColor: KMColors.accent,
            ),
            SliverToBoxAdapter(
              child: loading
                  ? _HorizontalShimmer()
                  : topRated.isEmpty
                      ? const _EmptyHorizontal(
                          message: 'No rated workers yet')
                      : _HorizontalWorkerList(
                          workers: topRated,
                          service: widget.service,
                          userLat: widget.userLat,
                          userLng: widget.userLng),
            ),

            // Highly Experienced
            if (highlyExp.isNotEmpty || loading) ...[
              _SectionHeader(
                title: 'Highly Experienced (5+ yrs)',
                icon: Icons.workspace_premium_rounded,
                iconColor: Colors.purple,
              ),
              SliverToBoxAdapter(
                child: loading
                    ? _HorizontalShimmer()
                    : highlyExp.isEmpty
                        ? const SizedBox()
                        : _HorizontalWorkerList(
                            workers: highlyExp,
                            service: widget.service,
                            userLat: widget.userLat,
                            userLng: widget.userLng),
              ),
            ],

            // Women Workers
            if (women.isNotEmpty || loading) ...[
              _SectionHeader(
                title: 'Women Workers',
                icon: Icons.female_rounded,
                iconColor: Colors.pink.shade400,
              ),
              SliverToBoxAdapter(
                child: loading
                    ? _HorizontalShimmer()
                    : women.isEmpty
                        ? const SizedBox()
                        : _HorizontalWorkerList(
                            workers: women,
                            service: widget.service,
                            userLat: widget.userLat,
                            userLng: widget.userLng),
              ),
            ],

            // Machine Operators
            if (machineOps.isNotEmpty || loading) ...[
              _SectionHeader(
                title: 'Machine Operators',
                icon: Icons.agriculture_rounded,
                iconColor: KMColors.rentPrimary,
              ),
              SliverToBoxAdapter(
                child: loading
                    ? _HorizontalShimmer()
                    : machineOps.isEmpty
                        ? const SizedBox()
                        : _HorizontalWorkerList(
                            workers: machineOps,
                            service: widget.service,
                            userLat: widget.userLat,
                            userLng: widget.userLng),
              ),
            ],

            // Organic Farming
            if (organic.isNotEmpty || loading) ...[
              _SectionHeader(
                title: 'Organic Farming Specialists',
                icon: Icons.eco_rounded,
                iconColor: KMColors.available,
              ),
              SliverToBoxAdapter(
                child: loading
                    ? _HorizontalShimmer()
                    : organic.isEmpty
                        ? const SizedBox()
                        : _HorizontalWorkerList(
                            workers: organic,
                            service: widget.service,
                            userLat: widget.userLat,
                            userLng: widget.userLng),
              ),
            ],

            // Recently Joined
            _SectionHeader(
              title: 'Recently Joined',
              icon: Icons.fiber_new_rounded,
              iconColor: KMColors.rentPrimary,
            ),
            SliverToBoxAdapter(
              child: loading
                  ? _HorizontalShimmer()
                  : recent.isEmpty
                      ? const _EmptyHorizontal(
                          message: 'No recent workers')
                      : _HorizontalWorkerList(
                          workers: recent,
                          service: widget.service,
                          userLat: widget.userLat,
                          userLng: widget.userLng),
            ),

            // All Workers list
            _SectionHeader(
              title: 'All Workers (${filtered.length})',
              icon: Icons.people_rounded,
              iconColor: KMColors.primary,
            ),
            if (loading)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const _WorkerCardShimmer(),
                  childCount: 6,
                ),
              )
            else if (filtered.isEmpty)
              const SliverToBoxAdapter(
                child: _FullEmptyState(
                  icon: Icons.person_search_rounded,
                  title: 'No workers found',
                  subtitle: 'Try changing filters or search terms',
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _WorkerCard(
                      worker: filtered[i],
                      service: widget.service,
                      userLat: widget.userLat,
                      userLng: widget.userLng),
                  childCount: filtered.length,
                ),
              ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
          ],
        );
      },
    );
  }
}

// ── Skill Chips ───────────────────────────────────────────────────────────────

class _SkillChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _SkillChips({required this.selected, required this.onSelect});

  static const _skills = [
    'All', 'Harvesting', 'Planting', 'Weeding', 'Spraying',
    'Drip Irrigation', 'Organic Farming', 'Tractor Driver',
    'Harvester Operator', 'JCB Operator', 'Coconut Tree Climber',
    'Dairy Farm Worker', 'Greenhouse Work', 'Machine Operator',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _skills.length,
        itemBuilder: (_, i) {
          final s = _skills[i];
          final sel = s == selected;
          return GestureDetector(
            onTap: () => onSelect(s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? KMColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: sel ? KMColors.primary : Colors.grey.shade300),
                boxShadow: sel
                    ? [
                        BoxShadow(
                            color: KMColors.primary.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2))
                      ]
                    : [],
              ),
              child: Text(s,
                  style: TextStyle(
                      color: sel ? Colors.white : Colors.grey.shade700,
                      fontWeight:
                          sel ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13)),
            ),
          );
        },
      ),
    );
  }
}

// ── Quick Categories ──────────────────────────────────────────────────────────

class _QuickCategories extends StatelessWidget {
  final ValueChanged<String> onTap;

  const _QuickCategories({required this.onTap});

  static const _cats = [
    ('Tractor Driver', Icons.agriculture_rounded, Color(0xFFE65100)),
    ('Harvesting', Icons.grass_rounded, Color(0xFF2E7D32)),
    ('Organic Farming', Icons.eco_rounded, Color(0xFF388E3C)),
    ('Dairy Farm Worker', Icons.water_drop_rounded, Color(0xFF1565C0)),
    ('Machine Operator', Icons.settings_rounded, Color(0xFF4A148C)),
    ('Coconut Tree Climber', Icons.park_rounded, Color(0xFF1B5E20)),
    ('Drip Irrigation', Icons.shower_rounded, Color(0xFF006064)),
    ('Greenhouse Work', Icons.home_work_rounded, Color(0xFF880E4F)),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: _cats.length,
        itemBuilder: (_, i) {
          final (label, icon, color) = _cats[i];
          return GestureDetector(
            onTap: () => onTap(label),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 68,
                  child: Text(label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Location Banner ───────────────────────────────────────────────────────────

class _LocationBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade500],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        const Icon(Icons.near_me_rounded, color: Colors.white, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Find Workers Near You',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text('Enable location to see nearby workers',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12)),
              ]),
        ),
      ]),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Row(children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: KMColors.textPrimary)),
        ]),
      ),
    );
  }
}

// ── Horizontal Worker List ────────────────────────────────────────────────────

class _HorizontalWorkerList extends StatelessWidget {
  final List<LabourProfile> workers;
  final LabourHubService service;
  final double? userLat;
  final double? userLng;

  const _HorizontalWorkerList({
    required this.workers,
    required this.service,
    this.userLat,
    this.userLng,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: workers.length,
        itemBuilder: (_, i) => _WorkerCardHorizontal(
            worker: workers[i],
            service: service,
            userLat: userLat,
            userLng: userLng),
      ),
    );
  }
}

class _WorkerCardHorizontal extends StatelessWidget {
  final LabourProfile worker;
  final LabourHubService service;
  final double? userLat;
  final double? userLng;

  const _WorkerCardHorizontal({
    required this.worker,
    required this.service,
    this.userLat,
    this.userLng,
  });

  String? _distanceText() {
    if (userLat == null || userLng == null || !worker.hasLocation) {
      return null;
    }
    const R = 6371.0;
    final dLat = (worker.latitude - userLat!) * pi / 180;
    final dLon = (worker.longitude - userLng!) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(userLat! * pi / 180) *
            cos(worker.latitude * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final d = R * 2 * atan2(sqrt(a), sqrt(1 - a));
    return d < 1 ? '${(d * 1000).round()}m' : '${d.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final dist = _distanceText();
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => LabourDetailPage(profile: worker))),
      child: Container(
        width: 155,
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 14),
            Stack(alignment: Alignment.bottomRight, children: [
              _Avatar(
                  photoUrl: worker.photoUrl,
                  name: worker.name,
                  size: 58),
              if (worker.isVerified)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.verified_rounded,
                        color: KMColors.primary, size: 12),
                  ),
                ),
            ]),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(worker.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            const SizedBox(height: 3),
            if (worker.rating > 0)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.star_rounded, color: KMColors.accent, size: 13),
                Text(' ${worker.rating.toStringAsFixed(1)}',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ]),
            if (dist != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.near_me_rounded,
                          size: 11, color: Colors.blue),
                      Text(' $dist',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.blue)),
                    ]),
              ),
            const SizedBox(height: 4),
            if (worker.skills.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(worker.skills.first,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10,
                        color: KMColors.primary,
                        fontWeight: FontWeight.w500)),
              ),
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: worker.availabilityStatus == 'available'
                      ? KMColors.cardTint
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20)),
              child: Text(
                worker.availabilityStatus == 'available'
                    ? '● Available'
                    : '○ Busy',
                style: TextStyle(
                    fontSize: 10,
                    color: worker.availabilityStatus == 'available'
                        ? KMColors.available
                        : Colors.orange,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 6),
            Text(worker.wageDisplay,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: KMColors.rentPrimary)),
          ],
        ),
      ),
    );
  }
}

// ── Worker Card (vertical list) ───────────────────────────────────────────────

class _WorkerCard extends StatelessWidget {
  final LabourProfile worker;
  final LabourHubService service;
  final double? userLat;
  final double? userLng;

  const _WorkerCard({
    required this.worker,
    required this.service,
    this.userLat,
    this.userLng,
  });

  void _call(BuildContext ctx) async {
    if (worker.phone.isEmpty) return;
    final uri = Uri.parse('tel:${worker.phone}');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  String? _distanceText() {
    if (userLat == null || userLng == null || !worker.hasLocation) {
      return null;
    }
    const R = 6371.0;
    final dLat = (worker.latitude - userLat!) * pi / 180;
    final dLon = (worker.longitude - userLng!) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(userLat! * pi / 180) *
            cos(worker.latitude * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final d = R * 2 * atan2(sqrt(a), sqrt(1 - a));
    return d < 1 ? '${(d * 1000).round()}m' : '${d.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final dist = _distanceText();
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => LabourDetailPage(profile: worker))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              _Avatar(
                  photoUrl: worker.photoUrl,
                  name: worker.name,
                  size: 60),
              if (worker.isVerified)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.verified_rounded,
                        color: KMColors.primary, size: 14),
                  ),
                ),
              if (worker.onlineStatus)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: KMColors.available,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white, width: 1.5)),
                  ),
                ),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(worker.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                      ),
                      _AvailBadge(status: worker.availabilityStatus),
                    ]),
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.location_on_rounded,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(worker.locationDisplay,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (dist != null) ...[
                        const Icon(Icons.near_me_rounded,
                            size: 12, color: Colors.blue),
                        Text(' $dist',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.blue)),
                      ],
                    ]),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: worker.skills
                          .take(3)
                          .map((s) => _SkillChipSmall(s))
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      if (worker.rating > 0) ...[
                        const Icon(Icons.star_rounded,
                            color: KMColors.accent, size: 14),
                        Text(' ${worker.rating.toStringAsFixed(1)}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        Text(' (${worker.reviewCount})',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                        const SizedBox(width: 8),
                      ],
                      const Icon(Icons.timer_rounded,
                          size: 13, color: Colors.grey),
                      Text(' ${worker.experienceYears} yrs exp',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      const Spacer(),
                      Text(
                        worker.wageDisplay,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: KMColors.rentPrimary),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _call(context),
                          icon: const Icon(Icons.phone_rounded,
                              size: 15),
                          label: const Text('Call'),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: KMColors.primary,
                              side: const BorderSide(color: KMColors.primary),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10))),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => LabourDetailPage(
                                      profile: worker))),
                          icon: const Icon(Icons.person_rounded,
                              size: 15),
                          label: const Text('View Profile'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: KMColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10))),
                        ),
                      ),
                    ]),
                  ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Filter Bottom Sheet ───────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final _LabourFilter filter;
  final bool hasLocation;
  final ValueChanged<_LabourFilter> onApply;

  const _FilterSheet({
    required this.filter,
    required this.hasLocation,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late _LabourFilter _local;

  @override
  void initState() {
    super.initState();
    _local = widget.filter;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: SingleChildScrollView(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            const Expanded(
              child: Text('Filters',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () => setState(() => _local = _local.reset()),
              child: const Text('Reset All',
                  style: TextStyle(color: KMColors.rentPrimary)),
            ),
          ]),
          const SizedBox(height: 8),

          SwitchListTile(
            value: _local.verifiedOnly,
            onChanged: (v) =>
                setState(() => _local = _local.copyWith(verifiedOnly: v)),
            activeThumbColor: KMColors.primary,
            contentPadding: EdgeInsets.zero,
            title: const Row(children: [
              Icon(Icons.verified_rounded, color: KMColors.primary, size: 18),
              SizedBox(width: 8),
              Text('Verified Workers Only',
                  style: TextStyle(fontWeight: FontWeight.w500)),
            ]),
          ),

          SwitchListTile(
            value: _local.availableToday,
            onChanged: (v) =>
                setState(() => _local = _local.copyWith(availableToday: v)),
            activeThumbColor: KMColors.available,
            contentPadding: EdgeInsets.zero,
            title: const Row(children: [
              Icon(Icons.today_rounded, color: KMColors.available, size: 18),
              SizedBox(width: 8),
              Text('Available Today',
                  style: TextStyle(fontWeight: FontWeight.w500)),
            ]),
          ),

          _FTitle('Gender', Icons.wc_rounded),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['All', 'Male', 'Female', 'Other'].map((g) {
              final sel = _local.gender == g;
              return ChoiceChip(
                label: Text(g),
                selected: sel,
                selectedColor: KMColors.primary,
                labelStyle:
                    TextStyle(color: sel ? Colors.white : KMColors.textPrimary),
                onSelected: (_) =>
                    setState(() => _local = _local.copyWith(gender: g)),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          _FTitle('Minimum Rating', Icons.star_rounded),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children:
                [(0.0, 'Any'), (3.0, '3+'), (4.0, '4+'), (4.5, '4.5+')]
                    .map((e) {
              final (val, lbl) = e;
              final sel = _local.minRating == val;
              return ChoiceChip(
                label: Text(lbl),
                selected: sel,
                selectedColor: KMColors.accent,
                labelStyle:
                    TextStyle(color: sel ? Colors.white : KMColors.textPrimary),
                onSelected: (_) =>
                    setState(() => _local = _local.copyWith(minRating: val)),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          _FTitle('Minimum Experience', Icons.work_history_rounded),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              (0, 'Any'), (1, '1+ yr'), (3, '3+ yrs'),
              (5, '5+ yrs'), (10, '10+ yrs')
            ].map((e) {
              final (val, lbl) = e;
              final sel = _local.minExperience == val;
              return ChoiceChip(
                label: Text(lbl),
                selected: sel,
                selectedColor: KMColors.primary,
                labelStyle:
                    TextStyle(color: sel ? Colors.white : KMColors.textPrimary),
                onSelected: (_) => setState(
                    () => _local = _local.copyWith(minExperience: val)),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          if (widget.hasLocation) ...[
            _FTitle('Max Distance', Icons.near_me_rounded),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                (5, '5 km'), (10, '10 km'), (20, '20 km'),
                (50, '50 km'), (100, 'Any')
              ].map((e) {
                final (val, lbl) = e;
                final sel = _local.maxDistanceKm == val;
                return ChoiceChip(
                  label: Text(lbl),
                  selected: sel,
                  selectedColor: Colors.blue,
                  labelStyle:
                      TextStyle(color: sel ? Colors.white : KMColors.textPrimary),
                  onSelected: (_) => setState(
                      () => _local = _local.copyWith(maxDistanceKm: val)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          _FTitle('Language', Icons.translate_rounded),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['All', ...kLanguages].map((l) {
              final sel = _local.language == l;
              return ChoiceChip(
                label: Text(l, style: const TextStyle(fontSize: 12)),
                selected: sel,
                selectedColor: KMColors.primary,
                labelStyle:
                    TextStyle(color: sel ? Colors.white : KMColors.textPrimary),
                onSelected: (_) =>
                    setState(() => _local = _local.copyWith(language: l)),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onApply(_local),
              style: ElevatedButton.styleFrom(
                  backgroundColor: KMColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: Text(
                  _local.activeCount > 0
                      ? 'Apply ${_local.activeCount} Filter(s)'
                      : 'Apply Filters',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _FTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _FTitle(this.title, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: KMColors.primary),
      const SizedBox(width: 6),
      Text(title,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: KMColors.textPrimary)),
    ]);
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String photoUrl;
  final String name;
  final double size;

  const _Avatar(
      {required this.photoUrl, required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: KMColors.cardTint,
      backgroundImage:
          photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
      child: photoUrl.isEmpty
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                  fontSize: size * 0.38,
                  color: KMColors.primary,
                  fontWeight: FontWeight.bold),
            )
          : null,
    );
  }
}

class _AvailBadge extends StatelessWidget {
  final String status;

  const _AvailBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isAvail = status == 'available';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: isAvail ? KMColors.cardTint : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(20)),
      child: Text(
        isAvail ? '● Available' : '○ Busy',
        style: TextStyle(
            fontSize: 10,
            color: isAvail ? KMColors.available : Colors.orange.shade700,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SkillChipSmall extends StatelessWidget {
  final String label;

  const _SkillChipSmall(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: KMColors.cardTint,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: KMColors.available.withValues(alpha: 0.3))),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11, color: KMColors.primary, fontWeight: FontWeight.w500)),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12)),
    );
  }
}

// ── Shimmer Placeholders ──────────────────────────────────────────────────────

class _HorizontalShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: 4,
        itemBuilder: (_, __) => const KMShimmerBox(
            width: 155, height: 220, borderRadius: 16),
      ),
    );
  }
}

class _WorkerCardShimmer extends StatelessWidget {
  const _WorkerCardShimmer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: KMShimmerBox(height: 130, borderRadius: 16),
    );
  }
}

// ── Empty States ──────────────────────────────────────────────────────────────

class _EmptyHorizontal extends StatelessWidget {
  final String message;

  const _EmptyHorizontal({required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Center(
        child: Text(message,
            style:
                TextStyle(color: Colors.grey.shade500, fontSize: 13)),
      ),
    );
  }
}

class _FullEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FullEmptyState(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: KMColors.textPrimary)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ]),
    );
  }
}
