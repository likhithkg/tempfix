// lib/exporter_hub/nearby_farmers_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'nearby_farmers_map_page.dart';
import 'nearby_farmers_service.dart';

class NearbyFarmersPage extends StatefulWidget {
  const NearbyFarmersPage({Key? key}) : super(key: key);

  @override
  State<NearbyFarmersPage> createState() => _NearbyFarmersPageState();
}

class _NearbyFarmersPageState extends State<NearbyFarmersPage> {
  bool _loading = true;
  String? _error;
  Position? _currentPos;
  StreamSubscription<Position>? _posSub;
  List<Map<String, dynamic>> _items = [];
  double _radiusKm = 40; // default radius
  bool _showOutside = false; // toggle to also display items outside radius

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() {
          _error = 'Location services disabled. Please enable.';
          _loading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        setState(() {
          _error = 'Location permission denied.';
          _loading = false;
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Location permission permanently denied. Grant from settings.';
          _loading = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.best));
      setState(() {
        _currentPos = pos;
        _loading = false;
      });

      await _loadAllItems();
    } catch (e) {
      setState(() {
        _error = 'Failed to determine location: $e';
        _loading = false;
      });
    }
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    final m = Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
    return m / 1000.0;
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot open dialer')));
    }
  }

  // Robust recursive coordinate extractor:
  Map<String, double>? _extractCoords(dynamic raw) {
    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    Map<String, double>? search(dynamic node) {
      if (node == null) return null;

      // Firestore GeoPoint
      if (node is GeoPoint) return {'lat': node.latitude, 'lon': node.longitude};

      // Map-like
      if (node is Map) {
        // direct lat/lon style
        final la = toDouble(node['lat'] ?? node['latitude'] ?? node['y']);
        final lo = toDouble(node['lng'] ?? node['lon'] ?? node['longitude'] ?? node['x']);
        if (la != null && lo != null) return {'lat': la, 'lon': lo};

        // GeoJSON coordinate field
        if (node.containsKey('coordinates')) {
          final coords = node['coordinates'];
          if (coords is List && coords.length >= 2) {
            final a = toDouble(coords[0]);
            final b = toDouble(coords[1]);
            if (a != null && b != null) {
              return {'lat': b, 'lon': a}; // assume [lon, lat]
            }
          }
        }

        // nested search
        for (final e in node.entries) {
          try {
            final res = search(e.value);
            if (res != null) return res;
          } catch (_) {}
        }
      }

      // List-like [lat, lon] or [lon, lat]
      if (node is List && node.length >= 2) {
        final a = toDouble(node[0]);
        final b = toDouble(node[1]);
        if (a != null && b != null) {
          if (a.abs() <= 90) return {'lat': a, 'lon': b}; // [lat, lon]
          return {'lat': b, 'lon': a}; // [lon, lat]
        }
      }

      // String "lat,lon"
      if (node is String && node.contains(',')) {
        final parts = node.split(RegExp(r'\s*,\s*'));
        if (parts.length >= 2) {
          final a = toDouble(parts[0]);
          final b = toDouble(parts[1]);
          if (a != null && b != null) {
            if (a.abs() <= 90) return {'lat': a, 'lon': b};
            return {'lat': b, 'lon': a};
          }
        }
      }

      return null;
    }

    try {
      if (raw is DocumentSnapshot) {
        final d = raw.data();
        if (d != null) return search(d);
      }
      return search(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadAllItems() async {
    if (_currentPos == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final List<Map<String, dynamic>> collected = [];

      // 1) try using NearbyFarmersService (it may already have filtering), but we will re-evaluate distances
      try {
        final svc = NearbyFarmersService();
        final svcRes = await svc.queryNearbyFarmers(
          centerLat: _currentPos!.latitude,
          centerLon: _currentPos!.longitude,
          radiusKm: _radiusKm * 5, // get broader set from service then filter ourselves
          limit: 2000,
        );
        for (final item in svcRes) {
          // item might already be normalized; ensure it's a Map<String, dynamic>
          final Map<String, dynamic> m = Map<String, dynamic>.from(item);
          // Add a marker showing it came from service
          m['_source'] = 'service';
          collected.add(m);
        }
      } catch (e) {
        debugPrint('NearbyFarmersPage: service failed: $e');
      }

      // 2) fetch export_products
      try {
        final snap = await FirebaseFirestore.instance.collection('export_products').get();
        for (final d in snap.docs) {
          final m = d.data();
          final wrapped = Map<String, dynamic>.from(m);
          wrapped['_docId'] = d.id;
          wrapped['_sourceCollection'] = 'export_products';
          collected.add(wrapped);
        }
      } catch (e) {
        debugPrint('NearbyFarmersPage: export_products fetch failed: $e');
      }

      // 3) fetch farmers collection if present
      try {
        final snap2 = await FirebaseFirestore.instance.collection('farmers').get();
        for (final d in snap2.docs) {
          final m = d.data();
          final wrapped = Map<String, dynamic>.from(m);
          wrapped['_docId'] = d.id;
          wrapped['_sourceCollection'] = 'farmers';
          collected.add(wrapped);
        }
      } catch (_) {
        // ignore if collection not present
      }

      // Normalize: for each collected item, find coords, compute distance
      final List<Map<String, dynamic>> finalList = [];
      for (final raw in collected) {
        final coords = _extractCoords(raw);
        if (coords == null) continue;
        final lat = coords['lat']!;
        final lon = coords['lon']!;
        final dist = _distanceKm(_currentPos!.latitude, _currentPos!.longitude, lat, lon);

        final name = (raw['farmerName'] ?? raw['name'] ?? raw['productName'] ?? raw['title'] ?? 'Unknown').toString();
        final phone = (raw['farmerMobile'] ?? raw['phone'] ?? raw['farmerMobileNo'] ?? raw['farmer_phone'] ?? '').toString();
        final loc = (raw['location'] ?? raw['address'] ?? raw['place'] ?? '').toString();

        finalList.add({
          'name': name,
          'phone': phone,
          'lat': lat,
          'lon': lon,
          'distKm': dist,
          'location': loc,
          'raw': raw,
        });
      }

      // Sort by distance
      finalList.sort((a, b) => (a['distKm'] as double).compareTo(b['distKm'] as double));

      // Filter to those within radius unless _showOutside is true
      final itemsToShow = _showOutside ? finalList : finalList.where((e) => (e['distKm'] as double) <= _radiusKm).toList();

      setState(() {
        _items = itemsToShow;
      });
    } catch (e, st) {
      debugPrint('NearbyFarmersPage: load error $e\n$st');
      setState(() {
        _error = 'Failed to load items: $e';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error ?? 'Unknown error', style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: _initLocation,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radiusCard = Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.tune, color: Colors.black54, size: 20),
            const SizedBox(width: 8),
            const Text('Radius:', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Expanded(
              child: Slider(
                min: 5,
                max: 500,
                divisions: 99,
                value: _radiusKm,
                label: '${_radiusKm.round()} km',
                onChanged: (v) => setState(() => _radiusKm = v),
                onChangeEnd: (v) async {
                  await _loadAllItems();
                },
              ),
            ),
            Text('${_radiusKm.toStringAsFixed(0)} km', style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Farmers'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Text('👨‍🌾', style: TextStyle(fontSize: 20)),
            tooltip: 'Show all items on map',
            onPressed: () {
              final mapItems = _items
                  .map((e) => {'id': e['raw']?['_docId'] ?? '', 'name': e['name'], 'lat': e['lat'], 'lon': e['lon'], 'raw': e['raw']})
                  .toList();
              Navigator.push(context, MaterialPageRoute(builder: (_) => NearbyFarmersMapPage(initialFarmers: mapItems)));
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllItems,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
              ? _buildError()
              : _currentPos == null
                  ? const Center(child: Text('Could not determine your location.'))
                  : Column(
                      children: [
                        radiusCard,
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _showOutside,
                                onChanged: (v) {
                                  setState(() {
                                    _showOutside = v ?? false;
                                  });
                                  _loadAllItems();
                                },
                              ),
                              const Text('Show items outside radius (grayed)'),
                              const Spacer(),
                              Text('Total found: ${_items.length}'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _items.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('No items found (within radius).', style: TextStyle(fontSize: 16)),
                                      const SizedBox(height: 12),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Retry & Expand Radius'),
                                        onPressed: () {
                                          setState(() {
                                            _radiusKm = (_radiusKm * 2).clamp(5, 500);
                                          });
                                          _loadAllItems();
                                        },
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemCount: _items.length,
                                  itemBuilder: (context, index) {
                                    final it = _items[index];
                                    final name = (it['name'] ?? 'Unknown') as String;
                                    final phone = (it['phone'] ?? '') as String;
                                    final lat = (it['lat'] as double);
                                    final lon = (it['lon'] as double);
                                    final dist = (it['distKm'] as double);
                                    final loc = (it['location'] ?? '') as String;
                                    final within = dist <= _radiusKm;
                                    final displayLoc = loc.isNotEmpty ? (loc.split(',').take(2).join(', ')) : 'Unknown location';

                                    return Opacity(
                                      opacity: within ? 1.0 : 0.5,
                                      child: Card(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        elevation: 1,
                                        child: SizedBox(
                                          height: 110,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                CircleAvatar(
                                                  radius: 20,
                                                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'F'),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                                      const SizedBox(height: 6),
                                                      Text(displayLoc, style: const TextStyle(color: Colors.black87, fontSize: 13)),
                                                      const Spacer(),
                                                      Text('${dist.toStringAsFixed(2)} km away', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      tooltip: 'View on map',
                                                      icon: const Text('👨‍🌾', style: TextStyle(fontSize: 22, color: Colors.green)),
                                                      onPressed: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (_) => NearbyFarmersMapPage(
                                                              focusLat: lat,
                                                              focusLon: lon,
                                                              focusFarmer: it,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                    if (phone.isNotEmpty)
                                                      IconButton(
                                                        tooltip: 'Call',
                                                        icon: const Icon(Icons.call, color: Colors.blue),
                                                        onPressed: () => _callPhone(phone),
                                                      ),
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
    );
  }
}
