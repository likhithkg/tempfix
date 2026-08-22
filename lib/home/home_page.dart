// lib/home/home_page.dart
// KrishiMithra — Complete Home Redesign
// Modern Material 3, Swiggy/BigBasket-inspired agricultural UX.

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../chatbot/chatbot_page.dart';
import 'home_search_page.dart';
import '../crop_disease/crop_disease_page.dart';
import '../exporter_hub/exporter_home_page.dart';
import '../exporter_hub/notifications_page.dart';
import '../f2b_mart/f2b_home_page.dart';
import '../l10n/app_localizations.dart';
import '../labour_hub/labour_hub_home_page.dart';
import '../plant_vendor/plant_vendor_home.dart';
import '../profile/profile_page.dart';
import '../rent/rent_home_page.dart';
import '../service/user_service.dart';
import '../services/locale_service.dart';
import '../weather/weather_page.dart';
import 'widgets/home_weather_widget.dart';

// ─── Bottom-nav host ──────────────────────────────────────────────────────────

class KrishiMithraHome extends StatefulWidget {
  const KrishiMithraHome({super.key});

  @override
  State<KrishiMithraHome> createState() => _KrishiMithraHomeState();
}

class _KrishiMithraHomeState extends State<KrishiMithraHome> {
  int _sel = 0;

  final List<Widget> _pages = [
    const HomeTab(),
    const F2BHomePage(),
    const ExporterHomePage(),
    const NotificationsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: IndexedStack(index: _sel, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _sel,
        onDestinationSelected: (i) => setState(() => _sel = i),
        height: 66,
        backgroundColor: cs.surface,
        indicatorColor: cs.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: cs.primary),
            label: l.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded, color: cs.primary),
            label: l.greenBazaar,
          ),
          NavigationDestination(
            icon: Stack(clipBehavior: Clip.none, children: [
              const Icon(Icons.local_shipping_outlined),
              const Positioned(right: -4, bottom: -4,
                  child: Icon(Icons.lock, size: 12, color: Colors.grey)),
            ]),
            selectedIcon: Stack(clipBehavior: Clip.none, children: [
              Icon(Icons.local_shipping_rounded, color: cs.primary),
              const Positioned(right: -4, bottom: -4,
                  child: Icon(Icons.lock, size: 12, color: Colors.grey)),
            ]),
            label: l.exportHub,
          ),
          NavigationDestination(
            icon: const Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications_rounded, color: cs.primary),
            label: l.notificationCenter,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: cs.primary),
            label: l.profile,
          ),
        ],
      ),
    );
  }
}

// ─── Home Tab ─────────────────────────────────────────────────────────────────

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _db = FirebaseFirestore.instance;
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  // Location state (mirrors DashboardPage logic)
  String _location = 'Select Location';
  LatLng? _coords;
  List<String> _recentLocations = [];

  // User
  Map<String, dynamic>? _userProfile;
  String get _userName {
    final name = _userProfile?['name'] ?? _userProfile?['displayName'] ??
        _auth.currentUser?.displayName ?? '';
    return name.toString().split(' ').first;
  }

  // Banner auto-scroll
  late final PageController _bannerCtrl = PageController();
  int _bannerIndex = 0;
  Timer? _bannerTimer;

  // Search
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLocation();
    _loadUserProfile();
    _startBannerTimer();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_bannerIndex + 1) % _kBanners.length;
      _bannerCtrl.animateToPage(next,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    });
  }

  Future<void> _loadLocation() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;

    // ── Step 1: SharedPreferences (instant, offline, zero permission issues) ──
    // This is the primary source — always written on every save.
    try {
      final prefs = await SharedPreferences.getInstance();
      final loc = prefs.getString('loc_name_$uid') ?? '';
      final lat = prefs.getDouble('loc_lat_$uid');
      final lon = prefs.getDouble('loc_lon_$uid');
      if (loc.isNotEmpty && mounted) {
        setState(() {
          _location = loc;
          if (lat != null && lon != null) _coords = LatLng(lat, lon);
        });
      }
      _recentLocations = prefs.getStringList('recent_locations_$uid') ?? [];
    } catch (_) {}

    // ── Step 2: Firestore (cross-device sync, async backup) ──
    // Only updates state if SharedPreferences had nothing.
    if (_location == 'Select Location') {
      for (final col in ['users', 'userProfile']) {
        try {
          final doc = await _db.collection(col).doc(uid).get();
          if (!doc.exists) continue;
          final d = doc.data()!;
          final loc = d['defaultLocation']?.toString() ?? '';
          if (loc.isNotEmpty && mounted) {
            final lat = (d['defaultLat'] as num?)?.toDouble();
            final lon = (d['defaultLon'] as num?)?.toDouble();
            setState(() {
              _location = loc;
              if (lat != null && lon != null) _coords = LatLng(lat, lon);
            });
            // Mirror Firestore data to SharedPreferences for next cold start
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('loc_name_$uid', loc);
              if (lat != null) await prefs.setDouble('loc_lat_$uid', lat);
              if (lon != null) await prefs.setDouble('loc_lon_$uid', lon);
            } catch (_) {}
            break;
          }
        } catch (_) {
          continue;
        }
      }
    }
  }

  Future<void> _loadUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    for (final col in ['users', 'userProfile']) {
      try {
        final doc = await _db.collection(col).doc(user.uid).get();
        if (doc.exists && mounted) {
          setState(() => _userProfile = doc.data());
          return;
        }
      } catch (_) {
        continue;
      }
    }
  }

  Future<void> _saveLocation(String loc) async {
    double lat = 0, lon = 0;
    try {
      final c = await LocationService.getCoordinatesFromName(loc);
      lat = (c['lat'] as num?)?.toDouble() ?? 0;
      lon = (c['lon'] as num?)?.toDouble() ?? 0;
    } catch (_) {}

    final user = _auth.currentUser;
    if (user != null) {
      final uid = user.uid;

      // ── Primary: SharedPreferences (keyed by UID, survives re-login) ──
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('loc_name_$uid', loc);
        if (lat != 0) await prefs.setDouble('loc_lat_$uid', lat);
        if (lon != 0) await prefs.setDouble('loc_lon_$uid', lon);

        // Per-user recent searches
        _recentLocations.remove(loc);
        _recentLocations.insert(0, loc);
        if (_recentLocations.length > 8) {
          _recentLocations = _recentLocations.sublist(0, 8);
        }
        await prefs.setStringList('recent_locations_$uid', _recentLocations);
      } catch (_) {}

      // ── Backup: Firestore (cross-device sync) ──
      try {
        await _db.collection('users').doc(uid).set({
          'defaultLocation': loc,
          'defaultLat': lat,
          'defaultLon': lon,
        }, SetOptions(merge: true));
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _location = loc;
        if (lat != 0) { _coords = LatLng(lat, lon); }
      });
    }
  }

  String _greeting(AppLocalizations l) {
    final h = DateTime.now().hour;
    if (h < 12) return l.goodMorning;
    if (h < 17) return l.goodAfternoon;
    return l.goodEvening;
  }

  void _openLocationSearch(BuildContext ctx) {
    final l = AppLocalizations.of(ctx)!;
    List<dynamic> results = [];
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (bc) => StatefulBuilder(
        builder: (bc2, ss) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(bc2).viewInsets.bottom),
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              builder: (_, sc) => Column(children: [
                const SizedBox(height: 8),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: ctrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: l.searchLocation,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                    onChanged: (t) async {
                      if (t.length < 2) { ss(() => results = []); return; }
                      try {
                        final r = await LocationService.getSuggestions(t);
                        ss(() => results = r);
                      } catch (_) {}
                    },
                  ),
                ),
                const SizedBox(height: 8),
                if (_recentLocations.isNotEmpty && results.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(children: [
                      const Icon(Icons.history, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(l.recentLocations, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ]),
                  ),
                  ..._recentLocations.map((r) => ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(r, style: const TextStyle(fontSize: 14)),
                    onTap: () { Navigator.pop(bc2); _saveLocation(r); },
                  )),
                ],
                Expanded(
                  child: ListView(controller: sc, children: results.map<Widget>((s) {
                    final name = s['display_name']?.toString() ?? '';
                    return ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                      onTap: () { Navigator.pop(bc2); _saveLocation(name); },
                    );
                  }).toList()),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadLocation();
          await _loadUserProfile();
        },
        child: CustomScrollView(
          slivers: [
            // ── 1. HEADER ──────────────────────────────────────────────────
            SliverToBoxAdapter(child: _buildHeader(context, l, cs, user)),

            // ── 2. SEARCH BAR ──────────────────────────────────────────────
            SliverToBoxAdapter(child: _buildSearchBar(context, l, cs)),

            // ── 3. HERO BANNER CAROUSEL ─────────────────────────────────────
            SliverToBoxAdapter(child: _buildBannerCarousel(context, l)),

            // ── 3.5 WEATHER CARD ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: HomeWeatherWidget(location: _location),
            ),

            // ── 4. QUICK ACTIONS ────────────────────────────────────────────
            SliverToBoxAdapter(child: _buildSectionHeader(context, l.quickActions, null, cs)),
            SliverToBoxAdapter(child: _buildQuickActions(context, l)),

            // ── 5. SMART SERVICES ───────────────────────────────────────────
            SliverToBoxAdapter(child: _buildSectionHeader(context, l.smartServices, null, cs)),
            SliverToBoxAdapter(child: _buildSmartServices(context, l)),

            // ── 6. PLANT VENDORS ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _buildSectionHeader(context, l.plantVendors, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PlantVendorHome()));
              }, cs),
            ),
            SliverToBoxAdapter(child: _buildPlantVendorsSection(context, l, cs)),

            // ── 7. GREENBAZAAR HIGHLIGHTS ───────────────────────────────────
            SliverToBoxAdapter(
              child: _buildSectionHeader(context, l.greenBazaarHighlights, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PlantVendorHome()));
              }, cs),
            ),
            SliverToBoxAdapter(child: _buildGreenBazaar(context, l, cs)),

            // ── 8. NEARBY FARMERS ───────────────────────────────────────────
            SliverToBoxAdapter(child: _buildSectionHeader(context, l.nearbyFarmersSection, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ExporterHomePage()));
            }, cs)),
            SliverToBoxAdapter(child: _buildNearbyFarmers(context, l, cs)),

            // ── 9. PERSONALIZED INSIGHTS ─────────────────────────────────────
            SliverToBoxAdapter(child: _buildSectionHeader(context, l.personalizedInsights, null, cs)),
            SliverToBoxAdapter(child: _buildInsights(context, l, user)),

            // ── 10. RECENT ACTIVITY ─────────────────────────────────────────
            SliverToBoxAdapter(child: _buildSectionHeader(context, l.recentActivity, null, cs)),
            SliverToBoxAdapter(child: _buildRecentActivity(context, l, cs, user)),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, AppLocalizations l, ColorScheme cs, fb.User? user) {
    final avatarText = _userName.isNotEmpty ? _userName[0].toUpperCase() : '?';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF1B5E20), cs.primary],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              // Logo
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Image.asset('assets/leaves.png', width: 24, height: 24,
                  errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: Colors.white, size: 22))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${_greeting(l)},',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                Text(_userName.isNotEmpty ? _userName : l.appName,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ])),
              // Language
              IconButton(
                icon: const Icon(Icons.language, color: Colors.white),
                onPressed: () {
                  final langs = LocaleService.instance.supportedLanguages;
                  final cur = LocaleService.instance.currentLanguageCode;
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l.selectLanguage),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      content: SizedBox(width: 260, child: ListView(shrinkWrap: true, children: langs.entries.map((e) {
                        final sel = e.value.languageCode == cur;
                        return ListTile(
                          title: Text(e.key, style: TextStyle(fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                          trailing: sel ? Icon(Icons.check, color: cs.primary) : null,
                          onTap: () { LocaleService.instance.setLocale(e.value); Navigator.pop(ctx); },
                        );
                      }).toList())),
                    ),
                  );
                },
              ),
              // Notification
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const NotificationsPage())),
              ),
              // Avatar
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                  child: user?.photoURL == null
                      ? Text(avatarText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                      : null,
                ),
              ),
            ]),
            const SizedBox(height: 14),
            // Location pill
            GestureDetector(
              onTap: () => _openLocationSearch(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Flexible(child: Text(_location,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Search Bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar(BuildContext context, AppLocalizations l, ColorScheme cs) {
    return Container(
      color: cs.primary,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(22), topRight: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
        child: Material(
          elevation: 3,
          shadowColor: Colors.black.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HomeSearchPage()),
            ),
            child: AbsorbPointer(
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: l.searchHint,
                  hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: cs.primary),
                  suffixIcon: Icon(Icons.mic_outlined, color: cs.primary),
                  filled: true,
                  fillColor: cs.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Banner Carousel ───────────────────────────────────────────────────────
  Widget _buildBannerCarousel(BuildContext context, AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
      child: Column(children: [
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: _bannerCtrl,
            onPageChanged: (i) => setState(() => _bannerIndex = i),
            itemCount: _kBanners.length,
            itemBuilder: (_, i) {
              final b = _kBanners[i];
              return GestureDetector(
                onTap: () => b.onTap(context, _location, _coords),
                child: _BannerSlide(data: b, l: l),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_kBanners.length, (i) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: _bannerIndex == i ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: _bannerIndex == i
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300,
            ),
          );
        })),
      ]),
    );
  }

  // ── Quick Actions ─────────────────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context, AppLocalizations l) {
    final actions = _quickActions(context, l, _location, _coords);
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _QuickActionTile(data: actions[i]),
      ),
    );
  }

  // ── Smart Services ────────────────────────────────────────────────────────
  Widget _buildSmartServices(BuildContext context, AppLocalizations l) {
    final services = [
      _SmartServiceData(
        icon: Icons.agriculture_outlined,
        color: Colors.brown,
        title: l.rentMachine,
        subtitle: l.machinesAvailableNearby,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RentHomePage())),
      ),
      _SmartServiceData(
        icon: Icons.groups_outlined,
        color: Colors.purple,
        title: l.labourHub,
        subtitle: l.hireFarmWorkers,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LabourHubHomePage())),
      ),
      _SmartServiceData(
        icon: Icons.bug_report_outlined,
        color: Colors.red,
        title: l.cropDisease,
        subtitle: l.detectTreatDiseases,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CropDiseasePage())),
      ),
    ];
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: services.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _SmartServiceCard(data: services[i]),
      ),
    );
  }

  // ── Plant Vendors ─────────────────────────────────────────────────────────
  Widget _buildPlantVendorsSection(BuildContext context, AppLocalizations l, ColorScheme cs) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('plant_vendors').limit(8).snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) return _shimmerRow();
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return _emptyHorizontalSection(l.plantVendors, Icons.local_florist_outlined);
        }
        return SizedBox(
          height: 188,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              return _ProductCard(
                imageUrl: d['imageUrl']?.toString() ?? d['primaryImage']?.toString() ?? '',
                name: d['plantName']?.toString() ?? d['name']?.toString() ?? '',
                detail: '₹${d['price']?.toString() ?? d['pricePerUnit']?.toString() ?? ''}',
                badge: d['type']?.toString() ?? d['category']?.toString(),
                badgeColor: Colors.green,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PlantVendorHome())),
              );
            },
          ),
        );
      },
    );
  }

  // ── GreenBazaar Highlights ────────────────────────────────────────────────
  Widget _buildGreenBazaar(BuildContext context, AppLocalizations l, ColorScheme cs) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('plant_vendors').limit(8).snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) return _shimmerRow();
        if (snap.hasError) {
          return _emptyHorizontalSection(l.greenBazaar, Icons.storefront_outlined);
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return _emptyHorizontalSection(l.greenBazaar, Icons.storefront_outlined);
        }
        return SizedBox(
          height: 188,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              return _ProductCard(
                imageUrl: d['imageUrl']?.toString() ?? d['primaryImage']?.toString() ?? '',
                name: d['plantName']?.toString() ?? d['name']?.toString() ?? '',
                detail: '₹${d['price']?.toString() ?? d['pricePerUnit']?.toString() ?? ''}',
                badge: d['type']?.toString() ?? d['category']?.toString(),
                badgeColor: Colors.green,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PlantVendorHome())),
              );
            },
          ),
        );
      },
    );
  }

  // ── Nearby Farmers ────────────────────────────────────────────────────────
  Widget _buildNearbyFarmers(BuildContext context, AppLocalizations l, ColorScheme cs) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('export_products').limit(5).snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            height: 80,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snap.hasError) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: Text(l.noProcurementItems,
                style: TextStyle(color: cs.onSurfaceVariant))),
          );
        }
        final docs = snap.data?.docs ?? [];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(children: [
            if (docs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  Icon(Icons.people_outline, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                  const SizedBox(height: 8),
                  Text('No farmers listed yet',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
                ]),
              ),
            ...docs.asMap().entries.map((e) {
              final i = e.key;
              final d = e.value.data() as Map<String, dynamic>;
              final name = d['farmerName']?.toString() ??
                  d['sellerName']?.toString() ?? 'Farmer';
              final loc = d['location']?.toString() ?? '';
              final crop = d['productName']?.toString() ??
                  d['name']?.toString() ?? '';
              final img = d['primaryImage']?.toString() ??
                  d['imageUrl']?.toString() ?? '';
              return Column(children: [
                if (i > 0) Divider(height: 1, indent: 60,
                    color: cs.outlineVariant.withValues(alpha: 0.3)),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    backgroundImage: img.isNotEmpty ? NetworkImage(img) : null,
                    child: img.isEmpty
                        ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'F',
                            style: TextStyle(color: cs.primary,
                                fontWeight: FontWeight.bold))
                        : null,
                  ),
                  title: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(
                    [if (crop.isNotEmpty) crop, if (loc.isNotEmpty) loc].join(' · '),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                  trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ExporterHomePage())),
                ),
              ]);
            }),
            if (docs.isNotEmpty)
              TextButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ExporterHomePage())),
                icon: const Icon(Icons.storefront_outlined, size: 16),
                label: Text(l.viewAll),
              ),
          ]),
        );
      },
    );
  }

  // ── Personalized Insights / For You ──────────────────────────────────────
  Widget _buildInsights(BuildContext context, AppLocalizations l, fb.User? user) {
    final insights = [
      _InsightData(
        icon: Icons.wb_sunny_outlined,
        color: Colors.orange,
        title: l.insightMonitorSoilTitle,
        subtitle: l.insightMonitorSoilSubtitle,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => WeatherPage(location: _location))),
      ),
      _InsightData(
        icon: Icons.trending_up_outlined,
        color: Colors.green,
        title: l.insightExportPricesTitle,
        subtitle: l.insightExportPricesSubtitle,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ExporterHomePage())),
      ),
      _InsightData(
        icon: Icons.agriculture_outlined,
        color: const Color(0xFF795548),
        title: l.insightRentMachineTitle,
        subtitle: l.insightRentMachineSubtitle,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const RentHomePage())),
      ),
      _InsightData(
        icon: Icons.chat_bubble_outline_rounded,
        color: Colors.indigo,
        title: l.insightAskAiTitle,
        subtitle: l.insightAskAiSubtitle,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ChatbotPage())),
      ),
    ];
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: insights.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _InsightCard(data: insights[i]),
      ),
    );
  }

  // ── Recent Activity ───────────────────────────────────────────────────────
  Widget _buildRecentActivity(BuildContext context, AppLocalizations l, ColorScheme cs, fb.User? user) {
    if (user == null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(l.pleaseSignInToViewOrders,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant)),
      );
    }
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('purchase_orders')
          .where('farmerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (_, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
              ),
              child: Center(child: Text(l.noRecentActivity,
                  style: TextStyle(color: cs.onSurfaceVariant))),
            ),
          );
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
          ),
          child: Column(children: docs.asMap().entries.map((e) {
            final i = e.key;
            final d = e.value.data() as Map<String, dynamic>;
            final status = d['status']?.toString() ?? '';
            final crop = d['productName']?.toString() ?? 'Product';
            final ts = (d['createdAt'] as Timestamp?)?.toDate();
            final timeStr = ts != null ? _timeAgo(ts) : '';
            return Column(children: [
              if (i > 0) Divider(height: 1, indent: 56, color: cs.outlineVariant.withValues(alpha: 0.3)),
              ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: _poStatusColor(status).withValues(alpha: 0.12),
                  child: Icon(_poStatusIcon(status), color: _poStatusColor(status), size: 18),
                ),
                title: Text(crop, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(_formatStatus(status), style: TextStyle(fontSize: 12, color: _poStatusColor(status))),
                trailing: Text(timeStr, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              ),
            ]);
          }).toList()),
        );
      },
    );
  }

  // ── Section header ────────────────────────────────────────────────────────
  Widget _buildSectionHeader(BuildContext ctx, String title, VoidCallback? onSeeAll, ColorScheme cs) {
    final l = AppLocalizations.of(ctx)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 12, 6),
      child: Row(children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
            child: Text(l.viewAll, style: TextStyle(fontSize: 13, color: cs.primary)),
          ),
      ]),
    );
  }

  // ── Shimmer placeholder row ────────────────────────────────────────────────
  Widget _shimmerRow() {
    return SizedBox(
      height: 188,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, __) => _ShimmerCard(),
      ),
    );
  }

  Widget _emptyHorizontalSection(String label, IconData icon) {
    final l = AppLocalizations.of(context)!;
    return SizedBox(
      height: 100,
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 32, color: Colors.grey.shade300),
        const SizedBox(height: 6),
        Text(l.noItemsAvailable(label), style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
      ])),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Color _poStatusColor(String s) {
    switch (s) {
      case 'farmer_accepted': return Colors.green;
      case 'farmer_rejected': return Colors.red;
      case 'collected': return Colors.teal;
      case 'qc_approved': return Colors.indigo;
      case 'exported': return Colors.blue;
      case 'delivered': return Colors.purple;
      default: return Colors.orange;
    }
  }

  IconData _poStatusIcon(String s) {
    switch (s) {
      case 'farmer_accepted': return Icons.check_circle_outline;
      case 'farmer_rejected': return Icons.cancel_outlined;
      case 'collected': return Icons.inventory_2_outlined;
      case 'qc_approved': return Icons.verified_outlined;
      case 'exported': return Icons.local_shipping_outlined;
      case 'delivered': return Icons.done_all_outlined;
      default: return Icons.pending_outlined;
    }
  }

  String _formatStatus(String s) => s.replaceAll('_', ' ').split(' ')
      .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

// ─── Banner data ──────────────────────────────────────────────────────────────

class _BannerData {
  final List<Color> gradient;
  final IconData icon;
  final String Function(AppLocalizations) title;
  final String Function(AppLocalizations) subtitle;
  final void Function(BuildContext ctx, String location, LatLng? coords) onTap;
  const _BannerData({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

final _kBanners = [
  _BannerData(
    gradient: [const Color(0xFF1B5E20), const Color(0xFF43A047)],
    icon: Icons.agriculture_rounded,
    title: (l) => l.sellDirectlyBanner,
    subtitle: (l) => l.connectExportBuyers,
    onTap: (ctx, _, __) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ExporterHomePage())),
  ),
  _BannerData(
    gradient: [const Color(0xFF0277BD), const Color(0xFF29B6F6)],
    icon: Icons.cloud_outlined,
    title: (l) => l.checkWeatherBanner,
    subtitle: (l) => l.realTimeFarmForecast,
    onTap: (ctx, loc, _) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => WeatherPage(location: loc))),
  ),
  _BannerData(
    gradient: [const Color(0xFFE65100), const Color(0xFFFF9800)],
    icon: Icons.precision_manufacturing_outlined,
    title: (l) => l.rentEquipmentBanner,
    subtitle: (l) => l.tractorsHarvestersLowCost,
    onTap: (ctx, _, __) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const RentHomePage())),
  ),
  _BannerData(
    gradient: [const Color(0xFF00695C), const Color(0xFF26A69A)],
    icon: Icons.local_shipping_outlined,
    title: (l) => l.exportBanner,
    subtitle: (l) => l.reachInternationalBuyers,
    onTap: (ctx, _, __) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ExporterHomePage())),
  ),
  _BannerData(
    gradient: [const Color(0xFF4A148C), const Color(0xFF9C27B0)],
    icon: Icons.groups_outlined,
    title: (l) => l.hireLabourBanner,
    subtitle: (l) => l.findSkilledFarmWorkers,
    onTap: (ctx, _, __) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const LabourHubHomePage())),
  ),
];

// ─── Quick actions data ───────────────────────────────────────────────────────

class _QuickActionData {
  final IconData icon;
  final List<Color> gradient;
  final String label;
  final VoidCallback onTap;
  const _QuickActionData({required this.icon, required this.gradient, required this.label, required this.onTap});
}

List<_QuickActionData> _quickActions(BuildContext ctx, AppLocalizations l, String location, LatLng? coords) => [
  _QuickActionData(
    icon: Icons.cloud_outlined,
    gradient: [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
    label: l.weather,
    onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => WeatherPage(location: location))),
  ),
  _QuickActionData(
    icon: Icons.bug_report_outlined,
    gradient: [const Color(0xFFB71C1C), const Color(0xFFEF5350)],
    label: l.cropDisease,
    onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const CropDiseasePage())),
  ),
  _QuickActionData(
    icon: Icons.agriculture_outlined,
    gradient: [const Color(0xFF4E342E), const Color(0xFFFF7043)],
    label: l.rentMachine,
    onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const RentHomePage())),
  ),
  _QuickActionData(
    icon: Icons.storefront_outlined,
    gradient: [const Color(0xFF1B5E20), const Color(0xFF66BB6A)],
    label: l.greenBazaar,
    onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const F2BHomePage())),
  ),
  _QuickActionData(
    icon: Icons.groups_outlined,
    gradient: [const Color(0xFF4A148C), const Color(0xFFAB47BC)],
    label: l.labourHub,
    onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const LabourHubHomePage())),
  ),
  _QuickActionData(
    icon: Icons.local_shipping_outlined,
    gradient: [const Color(0xFF004D40), const Color(0xFF26A69A)],
    label: l.exportHub,
    onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ExporterHomePage())),
  ),
  _QuickActionData(
    icon: Icons.chat_bubble_outline_rounded,
    gradient: [const Color(0xFF1A237E), const Color(0xFF5C6BC0)],
    label: l.chatbot,
    onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ChatbotPage())),
  ),
  _QuickActionData(
    icon: Icons.local_florist_outlined,
    gradient: [const Color(0xFF2E7D32), const Color(0xFF81C784)],
    label: l.plantVendors,
    onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const PlantVendorHome())),
  ),
];

// ─── Smart service data ───────────────────────────────────────────────────────

class _SmartServiceData {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SmartServiceData({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap});
}

class _InsightData {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _InsightData({required this.icon, required this.color, required this.title, required this.subtitle, this.onTap});
}

// ─── UI helper widgets ────────────────────────────────────────────────────────

class _BannerSlide extends StatelessWidget {
  final _BannerData data;
  final AppLocalizations l;
  const _BannerSlide({required this.data, required this.l});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: data.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: data.gradient.last.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
              child: const Text('KrishiMithra', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            Text(data.title(l),
                style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold, height: 1.2)),
            const SizedBox(height: 5),
            Text(data.subtitle(l),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
              ),
              child: const Text('Explore →', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ])),
          const SizedBox(width: 12),
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, color: Colors.white, size: 42),
          ),
        ]),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final _QuickActionData data;
  const _QuickActionTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: SizedBox(
        width: 74,
        child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: data.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: data.gradient.last.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Icon(data.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 7),
          Text(data.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.2)),
        ]),
      ),
    );
  }
}

class _SmartServiceCard extends StatelessWidget {
  final _SmartServiceData data;
  const _SmartServiceCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(data.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 2),
            Text(data.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ])),
        ]),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String detail;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;
  const _ProductCard({
    required this.imageUrl, required this.name, required this.detail,
    this.badge, this.badgeColor, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 142,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: SizedBox(
              height: 106,
              width: double.infinity,
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover,
                    loadingBuilder: (_, child, p) => p == null ? child : _shimmerBox(),
                    errorBuilder: (_, __, ___) => _placeholderImg(cs))
                  : _placeholderImg(cs),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(9),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (badge != null && badge!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? Colors.green).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(badge!, style: TextStyle(fontSize: 9, color: badgeColor ?? Colors.green, fontWeight: FontWeight.bold)),
                ),
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: cs.primary, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _placeholderImg(ColorScheme cs) => Container(
    color: cs.primaryContainer.withValues(alpha: 0.3),
    child: Center(child: Icon(Icons.local_florist_outlined, color: cs.primary.withValues(alpha: 0.4), size: 36)),
  );

  Widget _shimmerBox() => Container(color: Colors.grey.shade200);
}

class _InsightCard extends StatelessWidget {
  final _InsightData data;
  const _InsightCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: data.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: data.color.withValues(alpha: 0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: data.color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(data.icon, color: data.color, size: 18),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_rounded, color: data.color, size: 16),
          ]),
          const SizedBox(height: 8),
          Text(data.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: data.color)),
          const SizedBox(height: 3),
          Text(data.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
    _a = Tween<double>(begin: 0.3, end: 0.7).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) => Container(
        width: 142,
        decoration: BoxDecoration(
          color: base.withValues(alpha: _a.value),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: [
          Container(height: 106, color: Colors.transparent),
          Padding(padding: const EdgeInsets.all(9), child: Column(children: [
            Container(height: 12, width: 100, color: base.withValues(alpha: _a.value)),
            const SizedBox(height: 6),
            Container(height: 10, width: 80, color: base.withValues(alpha: _a.value)),
          ])),
        ]),
      ),
    );
  }
}
