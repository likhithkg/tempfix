// lib/rent/rent_home_page.dart — RentHub 3.0 (Rapido + Uber for Farm Equipment)
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'rent_model.dart';
import 'rent_machine_service.dart';
import 'rent_machine_details_page.dart';
import 'rent_booking_flow_page.dart';
import 'rent_map_page.dart';
import 'rent_list_form_page.dart';
import 'rent_owner_dashboard_page.dart';
import 'rent_booking_model.dart';
import 'rent_farmer_bookings_page.dart';
// ─── Palette ────────────────────────────────────────────────────────────────

const _kPrimary = Color(0xFFE65100);
const _kDark = Color(0xFF4E1F00);
const _kGrad = LinearGradient(
  colors: [_kDark, _kPrimary],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

Color _typeColor(String type) {
  switch (type.toLowerCase()) {
    case 'tractor':    return const Color(0xFFE65100);
    case 'harvester':  return const Color(0xFF1B5E20);
    case 'rotavator':  return const Color(0xFF4CAF50);
    case 'cultivator': return const Color(0xFF2E7D32);
    case 'seeder':     return const Color(0xFF00695C);
    case 'hitachi':    return const Color(0xFFFF8F00);
    case 'jcb':        return const Color(0xFFF9A825);
    case 'lorry':      return const Color(0xFF1565C0);
    default:           return const Color(0xFF455A64);
  }
}

String _typeEmoji(String type) {
  switch (type.toLowerCase()) {
    case 'tractor':    return '🚜';
    case 'harvester':  return '🌾';
    case 'rotavator':  return '⚙️';
    case 'cultivator': return '🌿';
    case 'seeder':     return '🌱';
    case 'hitachi':    return '⛏️';
    case 'jcb':        return '🏗️';
    case 'lorry':      return '🚚';
    default:           return '🔧';
  }
}

String _availLabel(MachineAvailability a) => a.label;

Color _availColor(MachineAvailability a) {
  switch (a) {
    case MachineAvailability.available:       return const Color(0xFF4CAF50);
    case MachineAvailability.busy:            return const Color(0xFFFF9800);
    case MachineAvailability.underMaintenance: return const Color(0xFFFF5722);
    case MachineAvailability.offline:         return const Color(0xFF9E9E9E);
  }
}

// ─── Category data ──────────────────────────────────────────────────────────

class _Cat {
  final String key, label, emoji;
  const _Cat(this.key, this.label, this.emoji);
}

const _kCats = [
  _Cat('All',        'All',        '🔑'),
  _Cat('Tractor',    'Tractor',    '🚜'),
  _Cat('Harvester',  'Harvester',  '🌾'),
  _Cat('Rotavator',  'Rotavator',  '⚙️'),
  _Cat('Cultivator', 'Cultivator', '🌿'),
  _Cat('Seeder',     'Seeder',     '🌱'),
  _Cat('Hitachi',    'Hitachi',    '⛏️'),
  _Cat('JCB',        'JCB',        '🏗️'),
  _Cat('Lorry',      'Lorry',      '🚚'),
];

// ─── Helpers ────────────────────────────────────────────────────────────────

double _haversine(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLon = (lon2 - lon1) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

int _etaMinutes(double distKm) => (distKm / 30.0 * 60).round().clamp(1, 999);

List<String> _seasonalTypes() {
  final m = DateTime.now().month;
  if (m >= 6 && m <= 9) return ['Rotavator', 'Cultivator'];
  if (m >= 10 && m <= 2) return ['Seeder', 'Tractor'];
  return ['Harvester', 'Lorry'];
}

String _seasonName() {
  final m = DateTime.now().month;
  if (m >= 6 && m <= 9) return 'Monsoon';
  if (m >= 10 && m <= 2) return 'Rabi (Winter)';
  return 'Summer';
}

// ─── Page ───────────────────────────────────────────────────────────────────

class RentHomePage extends StatefulWidget {
  const RentHomePage({super.key});
  @override
  State<RentHomePage> createState() => _RentHomePageState();
}

class _RentHomePageState extends State<RentHomePage>
    with TickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _category = 'All';
  String _sortBy = 'distance';
  Position? _position;
  String _locationLabel = 'Getting location...';
  final _mapCtrl = MapController();
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _fetchLocation();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _pulseCtrl.dispose();
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
      String label = 'Your Location';
      try {
        final places =
            await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (places.isNotEmpty) {
          final p = places.first;
          label = p.subLocality?.isNotEmpty == true
              ? p.subLocality!
              : (p.locality?.isNotEmpty == true ? p.locality! : label);
        }
      } catch (_) {}
      if (mounted) {
        setState(() {
          _position = pos;
          _locationLabel = label;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _locationLabel = 'Location unavailable');
    }
  }

  double _distanceTo(RentMachine m) {
    if (_position == null || m.latitude == 0) return double.infinity;
    return _haversine(
        _position!.latitude, _position!.longitude, m.latitude, m.longitude);
  }

  List<RentMachine> _applyFilters(List<RentMachine> all) {
    var r = all.where((m) {
      if (m.availability == MachineAvailability.offline) return false;
      if (_category != 'All' &&
          m.type.toLowerCase() != _category.toLowerCase()) return false;
      if (_query.isNotEmpty) {
        final q = _query;
        return m.name.toLowerCase().contains(q) ||
            m.ownerName.toLowerCase().contains(q) ||
            (m.location?.toLowerCase().contains(q) ?? false) ||
            m.type.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    switch (_sortBy) {
      case 'distance':
        r.sort((a, b) => _distanceTo(a).compareTo(_distanceTo(b)));
      case 'price_asc':
        r.sort((a, b) => a.pricePerDay.compareTo(b.pricePerDay));
      case 'price_desc':
        r.sort((a, b) => b.pricePerDay.compareTo(a.pricePerDay));
      case 'rating':
        r.sort((a, b) => b.rating.compareTo(a.rating));
      case 'availability':
        r.sort((a, b) {
          final ao = a.availability == MachineAvailability.available ? 0 : 1;
          final bo = b.availability == MachineAvailability.available ? 0 : 1;
          return ao.compareTo(bo);
        });
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

  void _showEmergencySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmergencyBookingSheet(
        position: _position,
        onSubmit: (type, hours, location) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '🚨 Emergency request for $type sent! Nearby owners notified.'),
            backgroundColor: const Color(0xFFD32F2F),
            duration: const Duration(seconds: 3),
          ));
        },
      ),
    );
  }

  void _showAcreageCalculator() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AcreageCalculatorSheet(),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _SortSheet(
        current: _sortBy,
        onSelect: (v) {
          setState(() => _sortBy = v);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF2F2F2);

    return Scaffold(
      backgroundColor: bg,
      body: StreamBuilder<List<RentMachine>>(
        stream: RentMachineService.instance.streamRentMachines(),
        builder: (ctx, snap) {
          final all = snap.data ?? [];
          final filtered = _applyFilters(all);
          final available =
              all.where((m) => m.availability == MachineAvailability.available).toList();

          return CustomScrollView(
            slivers: [
              // ── App bar / header ─────────────────────────────────
              SliverToBoxAdapter(child: _buildHeader(available.length)),

              // ── Map preview ──────────────────────────────────────
              SliverToBoxAdapter(
                  child: _buildMapPreview(available, isDark)),

              // ── Category chips ───────────────────────────────────
              SliverToBoxAdapter(child: _buildCategoryChips()),

              // ── Sort bar ─────────────────────────────────────────
              SliverToBoxAdapter(child: _buildSortBar(filtered.length)),

              // ── Seasonal banner ──────────────────────────────────
              SliverToBoxAdapter(child: _buildSeasonalBanner()),

              // ── Content ──────────────────────────────────────────
              if (!snap.hasData)
                SliverToBoxAdapter(child: _RentShimmer(isDark: isDark))
              else if (filtered.isEmpty)
                SliverToBoxAdapter(child: _buildEmpty())
              else ...[
                // Nearby available (horizontal)
                SliverToBoxAdapter(
                    child: _buildHorizontalSection(
                        'Nearby Available', '📍',
                        filtered
                            .where((m) =>
                                m.availability == MachineAvailability.available)
                            .take(10)
                            .toList())),

                // Main list
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final m = filtered[i];
                        final dist = _distanceTo(m);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _MachineCard(
                            machine: m,
                            distance: dist,
                            isOwner: _isOwner(m),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        RentMachineDetailsPage(machine: m))),
                            onBook: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => RentBookingFlowPage(
                                          machine: m,
                                          distanceKm: dist,
                                        ))),
                            onCall: () => _call(m.phone),
                            onEdit: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => RentListFormPage(
                                            existingMachine: m)))
                                .then((_) => setState(() {})),
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
      floatingActionButton: _OwnerFabGroup(
        onEmergency: _showEmergencySheet,
        onCalc: _showAcreageCalculator,
        onList: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RentListFormPage()))
            .then((_) => setState(() {})),
        onOwnerDash: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const RentOwnerDashboardPage())),
      ),
    );
  }

  Widget _buildHeader(int nearbyCount) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 16),
      decoration: const BoxDecoration(gradient: _kGrad),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Top row
        Row(children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.maybePop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('🚜', style: TextStyle(fontSize: 20)),
                SizedBox(width: 6),
                Text('RentHub',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5)),
              ]),
              Text('Rapido for Farm Equipment',
                  style: TextStyle(
                      fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500)),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.list_alt_rounded, color: Colors.white),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const RentFarmerBookingsPage())),
            tooltip: 'My Bookings',
          ),
          IconButton(
            icon: const Icon(Icons.sort_rounded, color: Colors.white),
            onPressed: _showSortSheet,
            tooltip: 'Sort',
          ),
        ]),
        const SizedBox(height: 12),
        // Location row
        GestureDetector(
          onTap: _fetchLocation,
          child: Row(children: [
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, child) => Transform.scale(
                  scale: _pulseAnim.value, child: child),
              child: Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                    color: Color(0xFF69F0AE), shape: BoxShape.circle),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.location_on_rounded,
                color: Colors.white70, size: 16),
            const SizedBox(width: 4),
            Expanded(
              child: Text(_locationLabel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$nearbyCount machines',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        // Search
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            const Icon(Icons.search_rounded, color: _kPrimary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Where do you need the machine?',
                  hintStyle: TextStyle(fontSize: 13.5, color: Color(0xFF9E9E9E)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (_searchCtrl.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() => _query = '');
                },
                child: const Icon(Icons.close_rounded,
                    size: 18, color: Color(0xFF9E9E9E)),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildMapPreview(List<RentMachine> machines, bool isDark) {
    final markers = machines.where((m) => m.latitude != 0).map((m) {
      return Marker(
        point: LatLng(m.latitude, m.longitude),
        width: 36,
        height: 36,
        child: Container(
          decoration: BoxDecoration(
            color: _typeColor(m.type).withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                  color: _typeColor(m.type).withValues(alpha: 0.5),
                  blurRadius: 6)
            ],
          ),
          child: Center(
              child: Text(_typeEmoji(m.type),
                  style: const TextStyle(fontSize: 15))),
        ),
      );
    }).toList();

    if (_position != null) {
      markers.add(Marker(
        point: LatLng(_position!.latitude, _position!.longitude),
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
            ),
          ),
        ),
      ));
    }

    final center = _position != null
        ? LatLng(_position!.latitude, _position!.longitude)
        : const LatLng(13.3379, 76.5616); // Karnataka, India

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => RentMapPage(
                    machines: machines,
                    userLat: _position?.latitude,
                    userLon: _position?.longitude,
                  ))),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        height: 190,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(children: [
            FlutterMap(
              mapController: _mapCtrl,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 12.0,
                interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.krishimithra.app',
                ),
                if (markers.isNotEmpty) MarkerLayer(markers: markers),
              ],
            ),
            // Overlay: tap to open full map
            Positioned.fill(
              child: Container(color: Colors.transparent),
            ),
            // Badge
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.location_on_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text('${machines.length} Machines Nearby',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
            // Open map button
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.map_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('Full Map',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        itemCount: _kCats.length,
        itemBuilder: (_, i) {
          final c = _kCats[i];
          final sel = _category == c.key;
          final color = sel ? _typeColor(c.key == 'All' ? 'Other' : c.key) : null;
          return GestureDetector(
            onTap: () => setState(() => _category = c.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? (color ?? _kPrimary) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: sel
                        ? (color ?? _kPrimary)
                        : const Color(0xFFE0E0E0)),
                boxShadow: sel
                    ? [
                        BoxShadow(
                            color: (color ?? _kPrimary).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ]
                    : [],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(c.emoji, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 5),
                Text(c.label,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : const Color(0xFF616161))),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortBar(int count) {
    final labels = {
      'distance': 'Nearest First',
      'price_asc': 'Cheapest',
      'price_desc': 'Premium First',
      'rating': 'Top Rated',
      'availability': 'Available First',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _kPrimary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('$count machines',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary)),
        ),
        const Spacer(),
        GestureDetector(
          onTap: _showSortSheet,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.sort_rounded, size: 14, color: Color(0xFF616161)),
              const SizedBox(width: 4),
              Text(labels[_sortBy] ?? 'Sort',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242))),
              const SizedBox(width: 2),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 16, color: Color(0xFF9E9E9E)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildSeasonalBanner() {
    final types = _seasonalTypes();
    final season = _seasonName();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        const Text('🌤️', style: TextStyle(fontSize: 26)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$season Season Recommendations',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text('Book ${types.join(' or ')} for best results this season',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11)),
              ]),
        ),
        TextButton(
          onPressed: () =>
              setState(() => _category = types.first),
          style: TextButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(types.first,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  Widget _buildHorizontalSection(
      String title, String icon, List<RentMachine> machines) {
    if (machines.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800)),
        ]),
      ),
      SizedBox(
        height: 170,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          itemCount: machines.length,
          itemBuilder: (_, i) {
            final m = machines[i];
            final dist = _distanceTo(m);
            return _MiniCard(
              machine: m,
              distance: dist,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => RentMachineDetailsPage(machine: m))),
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildEmpty() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🚜', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          const Text('No machines found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Try clearing filters or search differently',
              style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
          const SizedBox(height: 16),
          if (_query.isNotEmpty || _category != 'All')
            ElevatedButton(
              onPressed: () => setState(() {
                _query = '';
                _searchCtrl.clear();
                _category = 'All';
              }),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary, foregroundColor: Colors.white),
              child: const Text('Clear Filters'),
            ),
        ]),
      ),
    );
  }
}

// ─── Machine card (Rapido-style, horizontal) ────────────────────────────────

class _MachineCard extends StatelessWidget {
  final RentMachine machine;
  final double distance;
  final bool isOwner;
  final VoidCallback onTap, onBook, onCall, onEdit;

  const _MachineCard({
    required this.machine,
    required this.distance,
    required this.isOwner,
    required this.onTap,
    required this.onBook,
    required this.onCall,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _typeColor(machine.type);
    final emoji = _typeEmoji(machine.type);
    final hasImage = machine.imageUrl.isNotEmpty;
    final hasDist = distance.isFinite && distance < 500;
    final eta = hasDist ? _etaMinutes(distance) : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 12,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(children: [
          // ── Left: image ─────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(20)),
            child: SizedBox(
              width: 110,
              height: 140,
              child: hasImage
                  ? Image.network(machine.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _Placeholder(color: color, emoji: emoji))
                  : _Placeholder(color: color, emoji: emoji),
            ),
          ),
          // ── Right: info ──────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + availability
                  Row(children: [
                    Expanded(
                      child: Text(machine.name,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (isOwner)
                      GestureDetector(
                        onTap: onEdit,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6)),
                          child: Icon(Icons.edit_rounded,
                              size: 13, color: color),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 4),
                  // Type + status
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('$emoji ${machine.type}',
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: color)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: _availColor(machine.availability),
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 3),
                    Text(_availLabel(machine.availability),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _availColor(machine.availability))),
                  ]),
                  const SizedBox(height: 6),
                  // Rating + jobs
                  Row(children: [
                    const Icon(Icons.star_rounded,
                        size: 13, color: Color(0xFFFFC107)),
                    const SizedBox(width: 2),
                    Text(machine.rating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    Text('• ${machine.completedJobs} jobs',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9E9E9E))),
                  ]),
                  const SizedBox(height: 4),
                  // Distance + ETA
                  if (hasDist)
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: Color(0xFF9E9E9E)),
                      const SizedBox(width: 2),
                      Text('${distance.toStringAsFixed(1)} km',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      const Icon(Icons.access_time_rounded,
                          size: 12, color: Color(0xFF9E9E9E)),
                      const SizedBox(width: 2),
                      Text('$eta min ETA',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: Color(0xFF1565C0))),
                    ]),
                  const SizedBox(height: 5),
                  // Price
                  Text(
                    '₹${machine.effectiveHourlyRate.toStringAsFixed(0)}/hr  '
                    '₹${machine.pricePerDay.toStringAsFixed(0)}/day',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: color),
                  ),
                  const SizedBox(height: 8),
                  // Action buttons
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onCall,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: color, width: 1.2),
                          foregroundColor: color,
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.phone_rounded, size: 13),
                              SizedBox(width: 3),
                              Text('Call',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: machine.availability ==
                                MachineAvailability.available
                            ? onBook
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              const Color(0xFFE0E0E0),
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Book Now',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800)),
                              SizedBox(width: 3),
                              Icon(Icons.arrow_forward_rounded, size: 13),
                            ]),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Mini horizontal card ────────────────────────────────────────────────────

class _MiniCard extends StatelessWidget {
  final RentMachine machine;
  final double distance;
  final VoidCallback onTap;
  const _MiniCard(
      {required this.machine, required this.distance, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(machine.type);
    final hasDist = distance.isFinite && distance < 500;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 8)
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  height: 80,
                  width: double.infinity,
                  child: machine.imageUrl.isNotEmpty
                      ? Image.network(machine.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _Placeholder(
                                  color: color,
                                  emoji: _typeEmoji(machine.type)))
                      : _Placeholder(
                          color: color,
                          emoji: _typeEmoji(machine.type)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(machine.name,
                          style: const TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('${_typeEmoji(machine.type)} ${machine.type}',
                          style: TextStyle(fontSize: 10, color: color,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      if (hasDist)
                        Text(
                            '${distance.toStringAsFixed(1)} km • '
                            '${_etaMinutes(distance)} min',
                            style: const TextStyle(
                                fontSize: 9.5,
                                color: Color(0xFF1565C0),
                                fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                          '₹${machine.effectiveHourlyRate.toStringAsFixed(0)}/hr',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: color)),
                    ]),
              ),
            ]),
      ),
    );
  }
}

// ─── Placeholder image ───────────────────────────────────────────────────────

class _Placeholder extends StatelessWidget {
  final Color color;
  final String emoji;
  const _Placeholder({required this.color, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.12),
      child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 36))),
    );
  }
}

// ─── Sort bottom sheet ───────────────────────────────────────────────────────

class _SortSheet extends StatelessWidget {
  final String current;
  final ValueChanged<String> onSelect;
  const _SortSheet({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final options = [
      ('distance', Icons.near_me_rounded, 'Nearest First'),
      ('price_asc', Icons.arrow_upward_rounded, 'Cheapest First'),
      ('price_desc', Icons.arrow_downward_rounded, 'Premium First'),
      ('rating', Icons.star_rounded, 'Top Rated'),
      ('availability', Icons.check_circle_rounded, 'Available First'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        const Text('Sort Machines',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        ...options.map((o) {
          final sel = current == o.$1;
          return ListTile(
            leading: Icon(o.$2, color: sel ? _kPrimary : Colors.grey),
            title: Text(o.$3,
                style: TextStyle(
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
            trailing: sel
                ? const Icon(Icons.check_rounded, color: _kPrimary)
                : null,
            onTap: () => onSelect(o.$1),
          );
        }),
      ]),
    );
  }
}

// ─── Emergency booking sheet ─────────────────────────────────────────────────

class _EmergencyBookingSheet extends StatefulWidget {
  final Position? position;
  final void Function(String type, int hours, String location) onSubmit;
  const _EmergencyBookingSheet({this.position, required this.onSubmit});

  @override
  State<_EmergencyBookingSheet> createState() =>
      _EmergencyBookingSheetState();
}

class _EmergencyBookingSheetState extends State<_EmergencyBookingSheet> {
  String _type = 'Tractor';
  int _hours = 4;
  final _locCtrl = TextEditingController();

  @override
  void dispose() {
    _locCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20,
          MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        const Row(children: [
          Text('🚨', style: TextStyle(fontSize: 24)),
          SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Emergency Booking',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text('Nearest owners will be notified instantly',
                style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
          ]),
        ]),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _type,
          decoration: const InputDecoration(labelText: 'Machine Needed'),
          items: ['Tractor', 'Harvester', 'Rotavator', 'Cultivator',
                  'Seeder', 'Hitachi', 'JCB', 'Lorry']
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (v) => setState(() => _type = v!),
        ),
        const SizedBox(height: 12),
        Row(children: [
          const Text('Hours needed:', style: TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          IconButton(
            onPressed: _hours > 1 ? () => setState(() => _hours--) : null,
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          Text('$_hours',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          IconButton(
            onPressed: _hours < 24 ? () => setState(() => _hours++) : null,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: _locCtrl,
          decoration: const InputDecoration(
            labelText: 'Field Location',
            prefixIcon: Icon(Icons.location_on_rounded),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => widget.onSubmit(_type, _hours, _locCtrl.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('🚨  Send Emergency Request',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }
}

// ─── Acreage calculator sheet ────────────────────────────────────────────────

class _AcreageCalculatorSheet extends StatefulWidget {
  const _AcreageCalculatorSheet();

  @override
  State<_AcreageCalculatorSheet> createState() =>
      _AcreageCalculatorSheetState();
}

class _AcreageCalculatorSheetState extends State<_AcreageCalculatorSheet> {
  double _acres = 5;
  String _type = 'Tractor';

  // Hours per acre per machine type
  double _hoursPerAcre(String type) {
    switch (type.toLowerCase()) {
      case 'rotavator':  return 1.5;
      case 'cultivator': return 1.0;
      case 'seeder':     return 0.8;
      case 'harvester':  return 0.5;
      case 'tractor':    return 1.2;
      default:           return 2.0;
    }
  }

  // Approx rates
  double _ratePerHour(String type) {
    switch (type.toLowerCase()) {
      case 'jcb':       return 1500;
      case 'hitachi':   return 1800;
      case 'harvester': return 1200;
      case 'lorry':     return 800;
      default:          return 600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hours = (_acres * _hoursPerAcre(_type)).ceil();
    final cost = hours * _ratePerHour(_type);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20,
          MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        const Row(children: [
          Icon(Icons.calculate_rounded, color: Color(0xFF2E7D32)),
          SizedBox(width: 8),
          Text('Acreage Calculator',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          const Text('Acres:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const Spacer(),
          Slider(
            value: _acres,
            min: 0.5,
            max: 50,
            divisions: 99,
            activeColor: const Color(0xFF2E7D32),
            onChanged: (v) => setState(() => _acres = v),
          ),
          Text('${_acres.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _type,
          decoration: const InputDecoration(labelText: 'Machine Type'),
          items: ['Tractor', 'Harvester', 'Rotavator', 'Cultivator',
                  'Seeder', 'JCB', 'Hitachi', 'Lorry']
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (v) => setState(() => _type = v!),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F8E9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF81C784)),
          ),
          child: Column(children: [
            _CalcRow('Field Size', '${_acres.toStringAsFixed(1)} acres'),
            _CalcRow('Recommended Machine', _type),
            _CalcRow('Estimated Hours', '$hours hours'),
            const Divider(height: 16),
            _CalcRow('Estimated Cost',
                '₹${cost.toStringAsFixed(0)}',
                valueStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2E7D32))),
          ]),
        ),
      ]),
    );
  }
}

class _CalcRow extends StatelessWidget {
  final String label, value;
  final TextStyle? valueStyle;
  const _CalcRow(this.label, this.value, {this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF616161))),
          Text(value,
              style: valueStyle ??
                  const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─── Shimmer ─────────────────────────────────────────────────────────────────

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
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, __) => AnimatedBuilder(
          animation: _anim,
          builder: (_, __) {
            final t = _anim.value;
            final shine = LinearGradient(
              begin: Alignment(-1.0 + t * 2, 0),
              end: Alignment(t * 2, 0),
              colors: widget.isDark
                  ? [const Color(0xFF2A2A2A), const Color(0xFF3A3A3A),
                     const Color(0xFF2A2A2A)]
                  : [const Color(0xFFE8E8E8), const Color(0xFFF5F5F5),
                     const Color(0xFFE8E8E8)],
              stops: const [0, 0.5, 1],
            );
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              height: 130,
              decoration: BoxDecoration(
                  color: widget.isDark
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  gradient: shine),
            );
          },
        ),
        childCount: 5,
      ),
    );
  }
}

// ─── Owner FAB group with live pending-requests badge ────────────────────────

class _OwnerFabGroup extends StatelessWidget {
  final VoidCallback onEmergency, onCalc, onList, onOwnerDash;
  const _OwnerFabGroup({
    required this.onEmergency,
    required this.onCalc,
    required this.onList,
    required this.onOwnerDash,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<List<RentBooking>>(
      stream: uid.isEmpty
          ? Stream.value([])
          : RentMachineService.instance.streamBookingsByOwner(uid),
      builder: (ctx, snap) {
        final pending = (snap.data ?? [])
            .where((b) => b.status == BookingStatus.requested)
            .length;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'emergency',
              onPressed: onEmergency,
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              mini: true,
              tooltip: 'Emergency Booking',
              child: const Text('🚨', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 10),
            FloatingActionButton(
              heroTag: 'calc',
              onPressed: onCalc,
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              mini: true,
              tooltip: 'Acreage Calculator',
              child: const Icon(Icons.calculate_rounded, size: 20),
            ),
            const SizedBox(height: 10),
            // Owner dashboard with live badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                FloatingActionButton(
                  heroTag: 'owner',
                  onPressed: onOwnerDash,
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  mini: true,
                  tooltip: 'Owner Dashboard',
                  child: const Icon(Icons.dashboard_rounded, size: 20),
                ),
                if (pending > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD32F2F),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('$pending',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              heroTag: 'list',
              onPressed: onList,
              icon: const Icon(Icons.add_rounded),
              label: const Text('List Machine',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
            ),
          ],
        );
      },
    );
  }
}
