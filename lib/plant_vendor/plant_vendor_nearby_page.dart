// lib/plant_vendor/plant_vendor_nearby_page.dart
// FINAL VERSION – AUTO GEOCODE + ROAD DISTANCE (LocationIQ)

import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'plant_vendor_model.dart';
import 'plant_detail_page.dart';

/// ⚠️ Do NOT commit this key to public GitHub
const String _locationIqKey = 'pk.56ccd9d8fb2cd5f3e9d7a656e3b52566';

class PlantVendorNearbyPage extends StatefulWidget {
  const PlantVendorNearbyPage({Key? key}) : super(key: key);

  @override
  State<PlantVendorNearbyPage> createState() => _PlantVendorNearbyPageState();
}

class _PlantVendorNearbyPageState extends State<PlantVendorNearbyPage> {
  bool _loading = true;
  Position? _currentPosition;
  List<_VendorWithDistance> _vendors = [];

  final Map<String, double> _distanceCache = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _determinePosition();
      await _loadVendors();
    } catch (e) {
      debugPrint('Init error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ---------------- LOCATION ----------------
  Future<void> _determinePosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) throw Exception('Location disabled');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permission denied forever');
    }

    _currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
  }

  // ---------------- LOAD VENDORS ----------------
  Future<void> _loadVendors() async {
    final myLat = _currentPosition!.latitude;
    final myLon = _currentPosition!.longitude;

    final snap =
        await FirebaseFirestore.instance.collection('plant_vendors').get();

    final List<_VendorWithDistance> list = [];

    for (final doc in snap.docs) {
      final data = Map<String, dynamic>.from(doc.data());

      double? lat;
      double? lon;

      // 1️⃣ Existing coordinates
      if (data['location'] is GeoPoint) {
        final gp = data['location'] as GeoPoint;
        lat = gp.latitude;
        lon = gp.longitude;
      } else if (data['latitude'] != null && data['longitude'] != null) {
        lat = (data['latitude'] as num).toDouble();
        lon = (data['longitude'] as num).toDouble();
      }

      // 2️⃣ AUTO-GEOCODE if missing
      if (lat == null || lon == null) {
        final addr = (data['address'] ??
                data['locationString'] ??
                data['location'] ??
                '')
            .toString();

        if (addr.isNotEmpty) {
          final geo = await _geocodeAddress(addr);
          if (geo != null) {
            lat = geo['lat'];
            lon = geo['lon'];

            // 🔥 SAVE BACK TO FIRESTORE (ONE-TIME FIX)
            await FirebaseFirestore.instance
                .collection('plant_vendors')
                .doc(doc.id)
                .update({
              'latitude': lat,
              'longitude': lon,
            });
          }
        }
      }

      double? distanceKm;
      bool hasLocation = false;

      if (lat != null && lon != null) {
        distanceKm = await _roadDistanceKm(
          fromLat: myLat,
          fromLon: myLon,
          toLat: lat,
          toLon: lon,
        );
        hasLocation = distanceKm != null;
      }

      list.add(
        _VendorWithDistance(
          id: doc.id,
          name:
              (data['vendorName'] ?? data['name'] ?? 'Plant Vendor').toString(),
          plantName: data['plantName']?.toString(),
          address: (data['address'] ?? '').toString(),
          distanceKm: distanceKm,
          hasLocation: hasLocation,
          doc: doc,
        ),
      );
    }

    list.sort((a, b) {
      if (!a.hasLocation && !b.hasLocation) return 0;
      if (!a.hasLocation) return 1;
      if (!b.hasLocation) return -1;
      return a.distanceKm!.compareTo(b.distanceKm!);
    });

    setState(() => _vendors = list);
  }

  // ---------------- GEOCODE ----------------
  Future<Map<String, double>?> _geocodeAddress(String address) async {
    try {
      final url =
          'https://us1.locationiq.com/v1/search.php?key=$_locationIqKey'
          '&q=${Uri.encodeComponent(address)}&format=json&limit=1';

      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body);
      if (data is List && data.isNotEmpty) {
        return {
          'lat': double.parse(data[0]['lat']),
          'lon': double.parse(data[0]['lon']),
        };
      }
    } catch (_) {}
    return null;
  }

  // ---------------- ROAD DISTANCE ----------------
  Future<double?> _roadDistanceKm({
    required double fromLat,
    required double fromLon,
    required double toLat,
    required double toLon,
  }) async {
    final key = '$fromLat,$fromLon->$toLat,$toLon';
    if (_distanceCache.containsKey(key)) return _distanceCache[key];

    try {
      final url =
          'https://us1.locationiq.com/v1/directions/driving/'
          '$fromLon,$fromLat;$toLon,$toLat'
          '?key=$_locationIqKey&overview=false';

      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body);
      final meters = json['routes']?[0]?['distance'];
      if (meters == null) return null;

      final km = (meters as num).toDouble() / 1000.0;
      _distanceCache[key] = km;
      return km;
    } catch (_) {
      return null;
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Plant Vendors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _vendors.clear();
                _distanceCache.clear();
                _loading = true;
              });
              _init();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _vendors.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final v = _vendors[i];

                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: const Icon(Icons.local_florist,
                        color: Colors.green),
                    title: Text(v.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (v.plantName != null) Text(v.plantName!),
                        if (v.address.isNotEmpty) Text(v.address),
                        const SizedBox(height: 4),
                        Text(
                          v.hasLocation
                              ? '${v.distanceKm!.toStringAsFixed(1)} km (road)'
                              : 'Location not verified',
                          style: TextStyle(
                            color:
                                v.hasLocation ? Colors.grey : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    trailing:
                        const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      final vendor = PlantVendor.fromMap(
                        Map<String, dynamic>.from(v.doc.data() as Map),
                        v.id,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PlantDetailPage(vendor: vendor),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

// ---------------- MODEL ----------------
class _VendorWithDistance {
  final String id;
  final String name;
  final String? plantName;
  final String address;
  final double? distanceKm;
  final bool hasLocation;
  final QueryDocumentSnapshot doc;

  _VendorWithDistance({
    required this.id,
    required this.name,
    required this.plantName,
    required this.address,
    required this.distanceKm,
    required this.hasLocation,
    required this.doc,
  });
}
