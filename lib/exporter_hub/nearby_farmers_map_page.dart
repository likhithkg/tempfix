// lib/exporter_hub/nearby_farmers_map_page.dart
// OpenStreetMap map view for Nearby Farmers using flutter_map (v8.x).
// Displays farmers with 👨‍🌾 emoji markers and no radius control slider.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'nearby_farmers_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NearbyFarmersMapPage extends StatefulWidget {
  final double? focusLat;
  final double? focusLon;
  final Map<String, dynamic>? focusFarmer;
  final List<Map<String, dynamic>>? initialFarmers;

  const NearbyFarmersMapPage({
    super.key,
    this.focusLat,
    this.focusLon,
    this.focusFarmer,
    this.initialFarmers,
  });

  @override
  State<NearbyFarmersMapPage> createState() => _NearbyFarmersMapPageState();
}

class _NearbyFarmersMapPageState extends State<NearbyFarmersMapPage> {
  final NearbyFarmersService _service = NearbyFarmersService();
  Position? _myPos;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _farmers = [];
  final fm.MapController _mapController = fm.MapController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) throw 'Location services disabled';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) throw 'Location permission denied';

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
      );
      _myPos = pos;

      if (widget.initialFarmers != null) {
        setState(() => _farmers = widget.initialFarmers!);
      } else {
        await _refreshFarmers();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || _myPos == null) return;
        try {
          if (widget.focusLat != null && widget.focusLon != null) {
            _mapController.move(ll.LatLng(widget.focusLat!, widget.focusLon!), 14);
            await Future.delayed(const Duration(milliseconds: 350));
            if (!mounted) return;
            final farmer = widget.focusFarmer ?? _findFarmerByCoords(widget.focusLat!, widget.focusLon!);
            if (farmer != null) _showFarmerSheet(farmer);
          } else {
            _mapController.move(ll.LatLng(_myPos!.latitude, _myPos!.longitude), 12);
          }
        } catch (_) {}
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic>? _findFarmerByCoords(double lat, double lon) {
    try {
      return _farmers.firstWhere((f) {
        final fLat = (f['lat'] is num) ? (f['lat'] as num).toDouble() : double.tryParse(f['lat'].toString()) ?? double.nan;
        final fLon = (f['lon'] is num) ? (f['lon'] as num).toDouble() : double.tryParse(f['lon'].toString()) ?? double.nan;
        const tol = 0.0005;
        return (fLat - lat).abs() < tol && (fLon - lon).abs() < tol;
      }, orElse: () => {});
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshFarmers() async {
    if (_myPos == null) return;
    setState(() => _loading = true);
    try {
      List<Map<String, dynamic>> list = [];
      try {
        list = await _service.queryNearbyFarmers(
          centerLat: _myPos!.latitude,
          centerLon: _myPos!.longitude,
          radiusKm: 200,
          limit: 1500,
        );
      } catch (e) {
        debugPrint('NearbyFarmers: service call failed: $e');
      }

      if (list.isEmpty) {
        final snap = await FirebaseFirestore.instance.collection('export_products').get();
        final docs = snap.docs;
        final Map<String, Map<String, dynamic>> farmersMap = {};
        for (final d in docs) {
          final m = d.data();
          final coords = _extractCoords(m);
          if (coords == null) continue;
          final lat = coords['lat']!;
          final lon = coords['lon']!;
          final farmerPhone = (m['farmerMobile'] ?? m['farmerMobileNo'] ?? m['farmer_phone'] ?? '') as String;
          final farmerIdKey = farmerPhone.trim().isNotEmpty ? farmerPhone.trim() : (m['farmerId'] ?? d.id).toString();
          final distKm = Geolocator.distanceBetween(_myPos!.latitude, _myPos!.longitude, lat, lon) / 1000.0;

          if (farmersMap.containsKey(farmerIdKey)) {
            final existing = farmersMap[farmerIdKey]!;
            if (distKm < (existing['distKm'] as double)) {
              existing['lat'] = lat;
              existing['lon'] = lon;
              existing['distKm'] = distKm;
              existing['sourceDoc'] = d.id;
              existing['raw'] = m;
            }
          } else {
            farmersMap[farmerIdKey] = {
              'id': farmerIdKey,
              'name': (m['farmerName'] ?? m['name'] ?? 'Unknown') as String,
              'phone': farmerPhone,
              'lat': lat,
              'lon': lon,
              'distKm': distKm,
              'location': (m['location'] ?? '') as String,
              'sourceDoc': d.id,
              'raw': m,
            };
          }
        }
        setState(() => _farmers = farmersMap.values.toList());
      } else {
        setState(() => _farmers = list);
      }
    } catch (e) {
      debugPrint('NearbyFarmers: _refreshFarmers error $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, double>? _extractCoords(Map<String, dynamic> doc) {
    final possible = doc['location'];
    if (possible is Map) {
      final la = _toDouble(possible['lat'] ?? possible['latitude']);
      final lo = _toDouble(possible['lon'] ?? possible['longitude']);
      if (la != null && lo != null) return {'lat': la, 'lon': lo};
    }
    final a = _toDouble(doc['lat'] ?? doc['latitude']);
    final b = _toDouble(doc['lon'] ?? doc['longitude']);
    if (a != null && b != null) return {'lat': a, 'lon': b};
    return null;
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  void _showFarmerSheet(Map<String, dynamic> farmer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(farmer['name'] ?? 'Unknown', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${(farmer['distKm'] as double).toStringAsFixed(2)} km',
                        style: const TextStyle(color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 8),
                Text((farmer['location'] ?? '') as String),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _call(farmer['phone']?.toString());
                      },
                      icon: const Icon(Icons.call),
                      label: const Text('Call'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _openMap(farmer);
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('Open in Maps'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openMap(Map<String, dynamic> f) async {
    final lat = f['lat'] as double;
    final lon = f['lon'] as double;
    final google = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    if (await canLaunchUrl(google)) {
      await launchUrl(google, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _call(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nearby Farmers (Map)'), backgroundColor: Colors.green),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nearby Farmers (Map)'), backgroundColor: Colors.green),
        body: Center(child: Text('Error: $_error')),
      );
    }

    final center = ll.LatLng(_myPos!.latitude, _myPos!.longitude);

    final markers = <fm.Marker>[
      fm.Marker(
        point: center,
        width: 40,
        height: 40,
        child: const Icon(Icons.my_location, color: Colors.blue),
      ),
      ..._farmers.map((f) {
        final lat = (f['lat'] as double);
        final lon = (f['lon'] as double);
        return fm.Marker(
          point: ll.LatLng(lat, lon),
          width: 48,
          height: 48,
          child: GestureDetector(
            onTap: () => _showFarmerSheet(f),
            // 👨‍🌾 Replaced red pin with farmer emoji
            child: const Text('👨‍🌾', style: TextStyle(fontSize: 30)),
          ),
        );
      })
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Farmers (Map)'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshFarmers),
        ],
      ),
      body: Stack(
        children: [
          fm.FlutterMap(
            mapController: _mapController,
            options: fm.MapOptions(
              initialCenter: center,
              initialZoom: 12,
              maxZoom: 18,
              minZoom: 3,
            ),
            children: [
              fm.TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.krishimithra',
              ),
              fm.MarkerLayer(markers: markers),
            ],
          ),
          // Farmer count label (kept for debugging/info)
          Positioned(
            left: 12,
            top: 12,
            child: Card(
              color: Colors.white70,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Farmers shown: ${_farmers.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
