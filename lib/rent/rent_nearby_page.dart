// lib/rent/rent_nearby_page.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'rent_model.dart';
import 'rent_machine_service.dart';

class RentNearbyPage extends StatefulWidget {
  final Position? userLocation; // ✅ coords from Dashboard
  final String? referenceName;  // ✅ saved location name

  const RentNearbyPage({
    super.key,
    this.userLocation,
    this.referenceName,
  });

  @override
  State<RentNearbyPage> createState() => _RentNearbyPageState();
}

class _RentNearbyPageState extends State<RentNearbyPage> {
  Position? _pos;
  List<RentMachine> _machines = [];
  bool _loading = true;

  // Filters
  final List<int> _radiusOptions = [5, 10, 25, 50, -1];
  int _selectedRadius = 10;
  bool _mapView = false;
  String _sortBy = "distance";
  final TextEditingController _locFilterCtrl = TextEditingController();
  String _locFilter = "";

  @override
  void initState() {
    super.initState();
    _pos = widget.userLocation; // ✅ start with Dashboard location
    _load();
  }

  @override
  void dispose() {
    _locFilterCtrl.dispose();
    super.dispose();
  }

  double _distKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double d) => d * math.pi / 180;

  Future<void> _load() async {
    try {
      if (_pos != null) {
        await _loadMachines();
        return;
      }

      // ✅ Try Firestore default location
      final user = fb.FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('userProfile')
            .doc(user.uid)
            .get();

        if (doc.exists &&
            doc.data()?['defaultLat'] != null &&
            doc.data()?['defaultLon'] != null) {
          final lat = doc.data()?['defaultLat'];
          final lon = doc.data()?['defaultLon'];
          _pos = Position(
            latitude: lat,
            longitude: lon,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
          await _loadMachines();
          return;
        }
      }

      // ✅ fallback: GPS
      final gps = await Geolocator.getCurrentPosition();
      _pos = gps;
      await _loadMachines();
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMachines() async {
    if (_pos == null) {
      setState(() => _loading = false);
      return;
    }

    final list = await RentMachineService.instance.fetchOnce();

    // Sort by distance
    list.sort((a, b) {
      final da = _distKm(_pos!.latitude, _pos!.longitude, a.latitude, a.longitude);
      final db = _distKm(_pos!.latitude, _pos!.longitude, b.latitude, b.longitude);
      return da.compareTo(db);
    });

    setState(() {
      _machines = list;
      _loading = false;
    });
  }

  List<RentMachine> _applyFiltersAndSort() {
    if (_pos == null) return [];

    List<RentMachine> filtered = _machines;

    // Radius filter
    if (_selectedRadius != -1) {
      filtered = filtered.where((m) {
        final d = _distKm(_pos!.latitude, _pos!.longitude, m.latitude, m.longitude);
        return d <= _selectedRadius;
      }).toList();
    }

    // Location filter
    if (_locFilter.isNotEmpty) {
      filtered = filtered.where((m) {
        final loc = m.location?.toLowerCase() ?? "";
        return loc.contains(_locFilter.toLowerCase());
      }).toList();
    }

    // Sorting
    if (_sortBy == "price") {
      filtered.sort((a, b) => a.pricePerDay.compareTo(b.pricePerDay));
    } else {
      filtered.sort((a, b) {
        final da = _distKm(_pos!.latitude, _pos!.longitude, a.latitude, a.longitude);
        final db = _distKm(_pos!.latitude, _pos!.longitude, b.latitude, b.longitude);
        return da.compareTo(db);
      });
    }

    return filtered;
  }

  Future<void> _openMaps(RentMachine m) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${m.latitude},${m.longitude}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _applyFiltersAndSort();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.referenceName ?? 'Nearby Machines'),
        actions: [
          DropdownButton<int>(
            value: _selectedRadius,
            underline: const SizedBox(),
            items: _radiusOptions.map((r) {
              final label = r == -1 ? 'All' : '${r} km';
              return DropdownMenuItem(value: r, child: Text(label));
            }).toList(),
            onChanged: (v) => setState(() => _selectedRadius = v!),
          ),
          PopupMenuButton<String>(
            tooltip: "Sort Options",
            icon: const Icon(Icons.sort),
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: "distance", child: Text("Nearest first")),
              const PopupMenuItem(value: "price", child: Text("Lowest price first")),
            ],
          ),
          IconButton(
            tooltip: _mapView ? 'List View' : 'Map View',
            onPressed: () => setState(() => _mapView = !_mapView),
            icon: Icon(_mapView ? Icons.list_rounded : Icons.map_rounded),
          ),
          const SizedBox(width: 12),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _locFilterCtrl,
              onChanged: (v) => setState(() => _locFilter = v),
              decoration: InputDecoration(
                hintText: 'Filter by location (e.g., Bangalore, Delhi)',
                prefixIcon: const Icon(Icons.location_city),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_pos == null)
              ? const Center(child: Text('Reference location not available'))
              : filtered.isEmpty
                  ? const Center(child: Text('No machines found nearby'))
                  : _mapView
                      ? GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(_pos!.latitude, _pos!.longitude),
                            zoom: 12,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('me'),
                              position: LatLng(_pos!.latitude, _pos!.longitude),
                              infoWindow: InfoWindow(
                                title: widget.referenceName ?? 'Reference Location',
                              ),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueAzure,
                              ),
                            ),
                            ...filtered.map(
                              (m) => Marker(
                                markerId: MarkerId(m.id),
                                position: LatLng(m.latitude, m.longitude),
                                infoWindow: InfoWindow(
                                  title: m.name,
                                  snippet:
                                      '${m.location ?? ''} • ₹${m.pricePerDay}/day',
                                  onTap: () => _openMaps(m),
                                ),
                              ),
                            ),
                          },
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final m = filtered[i];
                            final dist = _distKm(
                              _pos!.latitude,
                              _pos!.longitude,
                              m.latitude,
                              m.longitude,
                            );
                            final img = m.imageUrl.isNotEmpty
                                ? NetworkImage(m.imageUrl)
                                : const AssetImage('assets/farmer_logo.png')
                                    as ImageProvider;

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: CircleAvatar(radius: 28, backgroundImage: img),
                                title: Text(m.name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        Chip(label: Text(m.type)),
                                        Chip(
                                          label: Text('${dist.toStringAsFixed(1)} km'),
                                          backgroundColor: theme
                                              .colorScheme.secondaryContainer,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '📍 ${m.location ?? "Unknown location"}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text('Owner: ${m.ownerName}'),
                                  ],
                                ),
                                trailing: Wrap(
                                  spacing: 4,
                                  children: [
                                    IconButton(
                                      tooltip: 'Call',
                                      onPressed: () => _call(m.phone),
                                      icon: const Icon(Icons.call_rounded),
                                    ),
                                    IconButton(
                                      tooltip: 'Open in Maps',
                                      onPressed: () => _openMaps(m),
                                      icon: const Icon(Icons.navigation_rounded),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
    );
  }
}