// lib/exporter_hub/nearby_farmers_page.dart
// FINAL VERSION – Correct KM + Auto Geocoding + Attractive UI + Detail Page Navigation

import 'dart:math';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import 'nearby_farmers_map_page.dart';
import 'nearby_farmers_service.dart';
import '../l10n/app_localizations.dart';

const String _locationIqKey = 'pk.56ccd9d8fb2cd5f3e9d7a656e3b52566';

class NearbyFarmersPage extends StatefulWidget {
  const NearbyFarmersPage({Key? key}) : super(key: key);

  @override
  State<NearbyFarmersPage> createState() => _NearbyFarmersPageState();
}

class _NearbyFarmersPageState extends State<NearbyFarmersPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loading = true;
  String? _error;
  Position? _currentPosition;
  List<_NearbyFarmer> _nearby = [];

  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _initAndLoad();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initAndLoad() async {
    try {
      final pos = await _determinePosition();
      _currentPosition = pos;
      await _loadNearbyFarmers(pos.latitude, pos.longitude);
      _animController.forward(from: 0);
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<Position> _determinePosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Location services disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied');
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
  }

  // ---------------- LOAD FARMERS ----------------
  Future<void> _loadNearbyFarmers(double myLat, double myLng) async {
    final List<Map<String, dynamic>> collected = [];

    try {
      final svc = NearbyFarmersService();
      final svcRes = await svc.queryNearbyFarmers(
        centerLat: myLat,
        centerLon: myLng,
        radiusKm: 1000,
        limit: 2000,
      );
      for (final e in svcRes) {
        if (e is Map) collected.add(Map<String, dynamic>.from(e));
      }
    } catch (_) {}

    try {
      final snap = await _firestore.collection('export_products').get();
      for (final d in snap.docs) {
        collected.add({...d.data(), '_docId': d.id, '_col': 'export_products'});
      }
    } catch (_) {}

    try {
      final snap = await _firestore.collection('farmers').get();
      for (final d in snap.docs) {
        collected.add({...d.data(), '_docId': d.id, '_col': 'farmers'});
      }
    } catch (_) {}

    final List<_NearbyFarmer> results = [];

    for (final raw in collected) {
      Map<String, double>? coords = _extractCoords(raw);

      if (coords == null) {
        final address = raw['location'] ?? raw['address'] ?? '';
        if (address.toString().trim().isNotEmpty) {
          coords = await _geocodeAddress(address.toString());

          if (coords != null && raw['_docId'] != null && raw['_col'] != null) {
            try {
              await _firestore
                  .collection(raw['_col'])
                  .doc(raw['_docId'])
                  .update({
                'lat': coords['lat'],
                'lon': coords['lon'],
              });
            } catch (_) {}
          }
        }
      }

      if (coords == null) continue;

      final dist = _distance(
        myLat,
        myLng,
        coords['lat']!,
        coords['lon']!,
      );

      results.add(
        _NearbyFarmer(
          docId: raw['_docId']?.toString() ?? '',
          name: (raw['farmerName'] ?? raw['name'] ?? 'Unknown').toString(),
          phone: (raw['phone'] ?? raw['contact'] ?? '').toString(),
          location:
              (raw['location'] ?? raw['address'] ?? 'Unknown').toString(),
          lat: coords['lat']!,
          lon: coords['lon']!,
          distanceKm: dist,
        ),
      );
    }

    results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    setState(() => _nearby = results);
  }

  // ---------------- HELPERS ----------------
  Future<Map<String, double>?> _geocodeAddress(String address) async {
    try {
      final uri = Uri.parse(
        'https://us1.locationiq.com/v1/search.php'
        '?key=$_locationIqKey'
        '&q=${Uri.encodeComponent(address)}'
        '&format=json'
        '&limit=1',
      );

      final res = await http.get(uri);
      if (res.statusCode != 200) return null;

      final List data = jsonDecode(res.body);
      if (data.isEmpty) return null;

      return {
        'lat': double.parse(data[0]['lat']),
        'lon': double.parse(data[0]['lon']),
      };
    } catch (_) {
      return null;
    }
  }

  Map<String, double>? _extractCoords(dynamic raw) {
    if (raw is Map) {
      final lat = raw['lat'] ?? raw['latitude'];
      final lon = raw['lon'] ?? raw['longitude'];
      if (lat is num && lon is num) {
        return {'lat': lat.toDouble(), 'lon': lon.toDouble()};
      }
    }
    return null;
  }

  double _distance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _deg(lat2 - lat1);
    final dLon = _deg(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg(lat1)) *
            cos(_deg(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _deg(double d) => d * (pi / 180);

  void _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openMap(double lat, double lon) async {
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(AppLocalizations.of(context)!.nearbyFarmersTitle),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  itemCount: _nearby.length,
                  itemBuilder: (_, i) {
                    final f = _nearby[i];

                    return FadeTransition(
                      opacity: _animController,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NearbyFarmersMapPage(
                                initialFarmers: [
                                  {
                                    'id': f.docId,
                                    'name': f.name,
                                    'phone': f.phone,
                                    'location': f.location,
                                    'lat': f.lat,
                                    'lon': f.lon,
                                  }
                                ],
                                focusLat: f.lat,
                                focusLon: f.lon,
                                focusFarmer: {
                                  'name': f.name,
                                  'phone': f.phone,
                                  'location': f.location,
                                  'lat': f.lat,
                                  'lon': f.lon,
                                },
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.agriculture,
                                    color: Colors.green,
                                    size: 26,
                                  ),
                                ),CircleAvatar(
  radius: 28,

  backgroundColor: Colors.green.shade50,

  backgroundImage:
      (f as dynamic).imageUrl != null &&
              ((f as dynamic)
                      .imageUrl)
                  .toString()
                  .isNotEmpty
          ? NetworkImage(
              ((f as dynamic)
                      .imageUrl)
                  .toString(),
            )
          : const AssetImage(
                  'assets/farmer_logo.png')
              as ImageProvider,

  onBackgroundImageError:
      (_, __) {},

  child: null,
),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              f.name,
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '${f.distanceKm.toStringAsFixed(1)} km',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.green),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on,
                                              size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              f.location,
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade700),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.call,
                                          color: Colors.green),
                                      onPressed: f.phone.isNotEmpty
                                          ? () => _call(f.phone)
                                          : null,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.map,
                                          color: Colors.blue),
                                      onPressed: () =>
                                          _openMap(f.lat, f.lon),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _NearbyFarmer {
  final String docId;
  final String name;
  final String phone;
  final String location;
  final double lat;
  final double lon;
  final double distanceKm;

  _NearbyFarmer({
    required this.docId,
    required this.name,
    required this.phone,
    required this.location,
    required this.lat,
    required this.lon,
    required this.distanceKm,
  });
}
