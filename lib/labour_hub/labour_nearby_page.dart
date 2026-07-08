import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'labour_hub_service.dart';
import 'labour_profile_model.dart';
import 'labour_detail_page.dart';

const _kP1 = Color(0xFF1B5E20);
const _kP2 = Color(0xFF2E7D32);
const _kGreen = Color(0xFF4CAF50);
const _kLightGreen = Color(0xFFE8F5E9);
const _kOrange = Color(0xFFE65100);
const _kAmber = Color(0xFFFFA000);
const _kDark = Color(0xFF1A2D1A);

class LabourNearbyPage extends StatefulWidget {
  const LabourNearbyPage({super.key});

  @override
  State<LabourNearbyPage> createState() => _LabourNearbyPageState();
}

class _LabourNearbyPageState extends State<LabourNearbyPage> {
  final _service = LabourHubService();
  final _searchCtrl = TextEditingController();

  bool _loading = true;
  bool _permissionDenied = false;
  String? _error;
  double? _userLat, _userLng;
  String _query = '';
  int _radiusKm = 20;

  late final Stream<List<LabourProfile>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = _service.streamAllProfiles();
    _fetchLocation();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _loading = true;
      _error = null;
      _permissionDenied = false;
    });
    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
            'Location services are disabled. Please enable them.');
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.deniedForever) {
        setState(() {
          _permissionDenied = true;
          _loading = false;
        });
        return;
      }
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied ||
            perm == LocationPermission.deniedForever) {
          setState(() {
            _permissionDenied = true;
            _loading = false;
          });
          return;
        }
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
      if (mounted) {
        setState(() {
          _userLat = pos.latitude;
          _userLng = pos.longitude;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double _distanceTo(LabourProfile p) {
    if (_userLat == null || _userLng == null || !p.hasLocation) {
      return double.infinity;
    }
    const R = 6371.0;
    final dLat = (p.latitude - _userLat!) * pi / 180;
    final dLon = (p.longitude - _userLng!) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_userLat! * pi / 180) *
            cos(p.latitude * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  List<LabourProfile> _filter(List<LabourProfile> all) {
    var list = all.where((p) => p.hasLocation).toList();
    list = list
        .where((p) => _distanceTo(p) <= _radiusKm)
        .toList();
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.skills.any((s) => s.toLowerCase().contains(q)) ||
              p.village.toLowerCase().contains(q) ||
              p.district.toLowerCase().contains(q))
          .toList();
    }
    list.sort((a, b) => _distanceTo(a).compareTo(_distanceTo(b)));
    return list;
  }

  void _showRadiusPicker() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const Text('Select Search Radius',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [5, 10, 20, 50, 100].map((r) {
                final sel = _radiusKm == r;
                return GestureDetector(
                  onTap: () => Navigator.pop(ctx, r),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? _kP2 : _kLightGreen,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: sel ? _kP2 : Colors.grey.shade300),
                    ),
                    child: Text('$r km',
                        style: TextStyle(
                            color: sel ? Colors.white : _kDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _radiusKm = selected);
    }
  }

  void _call(LabourProfile p) async {
    if (p.phone.isEmpty) return;
    final uri = Uri.parse('tel:${p.phone}');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  void _whatsapp(LabourProfile p) async {
    final raw =
        (p.whatsappNumber.isNotEmpty ? p.whatsappNumber : p.phone)
            .replaceAll(RegExp(r'\D'), '');
    if (raw.isEmpty) return;
    final number = raw.startsWith('91') ? raw : '91$raw';
    final uri = Uri.parse('https://wa.me/$number');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  void _openMap(LabourProfile p) async {
    if (!p.hasLocation) return;
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${p.latitude},${p.longitude}');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F2),
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 130,
            backgroundColor: _kP1,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded,
                    color: Colors.white),
                onPressed: _fetchLocation,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [_kP1, _kP2, Color(0xFF388E3C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        const Row(children: [
                          Icon(Icons.near_me_rounded,
                              color: Colors.white, size: 22),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text('Nearby Workers',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              Text('Sorted by distance from you',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12)),
                            ],
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Search + Radius ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(children: [
                Expanded(
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2))
                        ]),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v.trim()),
                      decoration: const InputDecoration(
                        hintText: 'Search name, skill, village…',
                        prefixIcon: Icon(Icons.search_rounded,
                            size: 20, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 13),
                        hintStyle: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _showRadiusPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                        color: _kP2,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: _kP2.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2))
                        ]),
                    child: Row(children: [
                      const Icon(Icons.my_location_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text('$_radiusKm km',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────────
          if (_loading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: _kP2),
                      const SizedBox(height: 12),
                      Text('Getting your location…',
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14)),
                    ]),
              ),
            )
          else if (_permissionDenied)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_off_rounded,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('Location Permission Denied',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                            'Please allow location access to find workers near you.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.grey.shade600)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: Geolocator.openAppSettings,
                          icon: const Icon(Icons.settings_rounded),
                          label: const Text('Open Settings'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _kP2,
                              foregroundColor: Colors.white),
                        ),
                      ]),
                ),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('Error: $_error',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchLocation,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _kP2,
                              foregroundColor: Colors.white),
                        ),
                      ]),
                ),
              ),
            )
          else if (_userLat == null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.gps_not_fixed_rounded,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('Could not get location'),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _fetchLocation,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _kP2,
                            foregroundColor: Colors.white),
                      ),
                    ]),
              ),
            )
          else
            StreamBuilder<List<LabourProfile>>(
              stream: _stream,
              builder: (ctx, snap) {
                if (snap.hasError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text('Error loading data',
                          style:
                              TextStyle(color: Colors.grey.shade600)),
                    ),
                  );
                }
                if (!snap.hasData) {
                  return const SliverFillRemaining(
                    child: Center(
                        child: CircularProgressIndicator(color: _kP2)),
                  );
                }

                final workers = _filter(snap.data!);

                if (workers.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              const Icon(
                                  Icons.person_search_rounded,
                                  size: 64,
                                  color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text('No workers found nearby',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 8),
                              Text(
                                  'Try increasing the radius or changing your search',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.grey.shade500)),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: _showRadiusPicker,
                                icon: const Icon(
                                    Icons.add_circle_outline_rounded,
                                    color: _kP2),
                                label: const Text('Increase Radius',
                                    style: TextStyle(color: _kP2)),
                                style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: _kP2)),
                              ),
                            ]),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(
                              16, 12, 16, 8),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                  color: _kLightGreen,
                                  borderRadius:
                                      BorderRadius.circular(20)),
                              child: Text(
                                  '${workers.length} workers within $_radiusKm km',
                                  style: const TextStyle(
                                      color: _kP2,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12)),
                            ),
                          ]),
                        );
                      }
                      return _NearbyWorkerCard(
                        worker: workers[i - 1],
                        distance: _distanceTo(workers[i - 1]),
                        onTap: () => Navigator.push(
                            ctx,
                            MaterialPageRoute(
                                builder: (_) => LabourDetailPage(
                                    profile: workers[i - 1]))),
                        onCall: () => _call(workers[i - 1]),
                        onWhatsApp: () => _whatsapp(workers[i - 1]),
                        onMap: () => _openMap(workers[i - 1]),
                      );
                    },
                    childCount: workers.length + 1,
                  ),
                );
              },
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }
}

// ── Nearby Worker Card ────────────────────────────────────────────────────────

class _NearbyWorkerCard extends StatelessWidget {
  final LabourProfile worker;
  final double distance;
  final VoidCallback onTap;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onMap;

  const _NearbyWorkerCard({
    required this.worker,
    required this.distance,
    required this.onTap,
    required this.onCall,
    required this.onWhatsApp,
    required this.onMap,
  });

  String get _distText {
    if (distance == double.infinity) return '';
    if (distance < 1) return '${(distance * 1000).round()}m away';
    return '${distance.toStringAsFixed(1)} km away';
  }

  @override
  Widget build(BuildContext context) {
    final p = worker;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Stack(children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: _kLightGreen,
                backgroundImage: p.photoUrl.isNotEmpty
                    ? NetworkImage(p.photoUrl)
                    : null,
                child: p.photoUrl.isEmpty
                    ? Text(
                        p.name.isNotEmpty
                            ? p.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 24,
                            color: _kP2,
                            fontWeight: FontWeight.bold))
                    : null,
              ),
              if (p.onlineStatus)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                        color: _kGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white, width: 2)),
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
                        child: Text(p.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                      ),
                      if (p.isVerified)
                        const Icon(Icons.verified_rounded,
                            color: _kP2, size: 16),
                    ]),
                    const SizedBox(height: 3),
                    // Distance badge
                    if (_distText.isNotEmpty)
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.blue.shade200)),
                          child: Row(children: [
                            Icon(Icons.near_me_rounded,
                                size: 11,
                                color: Colors.blue.shade600),
                            const SizedBox(width: 3),
                            Text(_distText,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.location_on_rounded,
                            size: 12, color: Colors.grey),
                        Expanded(
                          child: Text(
                              ' ${p.locationDisplay}',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                    const SizedBox(height: 6),
                    if (p.skills.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: p.skills
                            .take(3)
                            .map((s) => _SmallChip(s))
                            .toList(),
                      ),
                    const SizedBox(height: 8),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color:
                                p.availabilityStatus == 'available'
                                    ? _kLightGreen
                                    : Colors.orange.shade50,
                            borderRadius:
                                BorderRadius.circular(20)),
                        child: Text(
                          p.availabilityStatus == 'available'
                              ? '● Available'
                              : '○ Busy',
                          style: TextStyle(
                              fontSize: 10,
                              color: p.availabilityStatus ==
                                      'available'
                                  ? _kGreen
                                  : Colors.orange,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (p.rating > 0) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.star_rounded,
                            color: _kAmber, size: 13),
                        Text(' ${p.rating.toStringAsFixed(1)}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                      const Spacer(),
                      Text(p.wageDisplay,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _kOrange)),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onCall,
                          icon: const Icon(Icons.phone_rounded,
                              size: 14),
                          label: const Text('Call',
                              style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _kP2,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10))),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onWhatsApp,
                          icon: const Icon(Icons.chat_rounded,
                              size: 14),
                          label: const Text('WhatsApp',
                              style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10))),
                        ),
                      ),
                      if (p.hasLocation) ...[
                        const SizedBox(width: 6),
                        ElevatedButton(
                          onPressed: onMap,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10))),
                          child: const Icon(Icons.map_rounded,
                              size: 16),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.person_rounded,
                            size: 14),
                        label: const Text('View Full Profile',
                            style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: _kP2,
                            side: const BorderSide(color: _kP2),
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10))),
                      ),
                    ),
                  ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label;

  const _SmallChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: _kLightGreen,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kGreen.withOpacity(0.3))),
      child: Text(label,
          style: const TextStyle(
              fontSize: 10, color: _kP2, fontWeight: FontWeight.w500)),
    );
  }
}
