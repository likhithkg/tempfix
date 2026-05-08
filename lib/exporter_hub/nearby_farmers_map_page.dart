// lib/exporter_hub/nearby_farmers_map_page.dart
// OpenStreetMap map view for Nearby Farmers using flutter_map (v8.x).
// FIXED: null-safe lat/lon handling to prevent "Null is not a subtype of double"

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

  // ---------------- INIT ----------------
  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Location services disabled';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw 'Location permission denied';
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.best),
      );
      _myPos = pos;

      if (widget.initialFarmers != null &&
          widget.initialFarmers!.isNotEmpty) {
        _farmers = widget.initialFarmers!;
      } else {
        await _refreshFarmers();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _myPos == null) return;

        if (_isValidCoord(widget.focusLat) &&
            _isValidCoord(widget.focusLon)) {
          _mapController.move(
            ll.LatLng(widget.focusLat!, widget.focusLon!),
            14,
          );

          final farmer = widget.focusFarmer ??
              _findFarmerByCoords(
                widget.focusLat!,
                widget.focusLon!,
              );

          if (farmer != null) {
            Future.delayed(const Duration(milliseconds: 400), () {
              if (mounted) _showFarmerSheet(farmer);
            });
          }
        } else {
          _mapController.move(
            ll.LatLng(_myPos!.latitude, _myPos!.longitude),
            12,
          );
        }
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------------- HELPERS ----------------
  bool _isValidCoord(double? v) {
    return v != null && v.isFinite;
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  Map<String, dynamic>? _findFarmerByCoords(double lat, double lon) {
    try {
      return _farmers.firstWhere((f) {
        final fLat = _toDouble(f['lat']);
        final fLon = _toDouble(f['lon']);
        if (fLat == null || fLon == null) return false;
        return (fLat - lat).abs() < 0.0005 &&
            (fLon - lon).abs() < 0.0005;
      });
    } catch (_) {
      return null;
    }
  }

  // ---------------- LOAD FARMERS ----------------
  Future<void> _refreshFarmers() async {
    if (_myPos == null) return;

    setState(() => _loading = true);

    try {
      List<Map<String, dynamic>> list = [];

      try {
        list = await _service.queryNearbyFarmers(
          centerLat: _myPos!.latitude,
          centerLon: _myPos!.longitude,
          radiusKm: 300,
          limit: 2000,
        );
      } catch (_) {}

      if (list.isEmpty) {
        final snap = await FirebaseFirestore.instance
            .collection('export_products')
            .get();

        for (final d in snap.docs) {
          final m = d.data();
          final lat = _toDouble(m['lat'] ?? m['latitude']);
          final lon = _toDouble(m['lon'] ?? m['longitude']);
          if (lat == null || lon == null) continue;

          final distKm = Geolocator.distanceBetween(
                _myPos!.latitude,
                _myPos!.longitude,
                lat,
                lon,
              ) /
              1000;

          list.add({
            'id': d.id,
            'name': m['farmerName'] ?? m['name'] ?? 'Farmer',
            'phone': m['farmerMobile'] ?? '',
            'lat': lat,
            'lon': lon,
            'distKm': distKm,
            'location': m['location'] ?? '',
            'raw': m,
          });
        }
      }

      setState(() => _farmers = list);
    } catch (e) {
      debugPrint('Map refresh error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------------- UI HELPERS ----------------
  void _showFarmerSheet(Map<String, dynamic> farmer) {
    final lat = _toDouble(farmer['lat']);
    final lon = _toDouble(farmer['lon']);

    if (lat == null || lon == null) return;

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                farmer['name'] ?? 'Farmer',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(farmer['location'] ?? ''),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.call),
                    label: const Text('Call'),
                    onPressed: () => _call(farmer['phone']),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text('Open Maps'),
                    onPressed: () => _openMap(lat, lon),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openMap(double lat, double lon) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _call(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ---------------- BUILD ----------------
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nearby Farmers (Map)')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nearby Farmers (Map)')),
        body: Center(child: Text('Error: $_error')),
      );
    }

    final center = ll.LatLng(
      _myPos!.latitude,
      _myPos!.longitude,
    );

    final markers = <fm.Marker>[
      fm.Marker(
        point: center,
        width: 40,
        height: 40,
        child: const Icon(Icons.my_location, color: Colors.blue),
      ),
      ..._farmers.where((f) {
        return _toDouble(f['lat']) != null &&
            _toDouble(f['lon']) != null;
      }).map((f) {
        final lat = _toDouble(f['lat'])!;
        final lon = _toDouble(f['lon'])!;
        return fm.Marker(
          point: ll.LatLng(lat, lon),
          width: 48,
          height: 48,
          child: GestureDetector(
            onTap: () => _showFarmerSheet(f),
            child: const Text('👨‍🌾', style: TextStyle(fontSize: 30)),
          ),
        );
      }),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Farmers (Map)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshFarmers,
          ),
        ],
      ),
      body: fm.FlutterMap(
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
    );
  }
}
