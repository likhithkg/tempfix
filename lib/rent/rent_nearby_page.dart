// lib/rent/rent_nearby_page.dart
//
// Nearby Machines page with inline Google Map and exporter-hub style fullscreen map (flutter_map).
// Google Maps symbols imported with prefix `gm` to avoid symbol collisions with flutter_map.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

// Use a prefix for google_maps_flutter to avoid name collisions
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;

// Local models & service
import 'rent_model.dart';
import 'rent_machine_service.dart';

// Import the fullscreen map page (single, aliased import)
import 'rent_nearby_map_page.dart' as rent_map_page;
import '../l10n/app_localizations.dart';


class RentNearbyPage extends StatefulWidget {
  final Position? userLocation; // coords from Dashboard (optional)
  final String? referenceName; // saved location name (optional)

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
  final bool _mapView = false;
  String _sortBy = "distance";
  final TextEditingController _locFilterCtrl = TextEditingController();
  String _locFilter = "";

  // Debug toggle — shows raw coords and fix option
  bool _showDebug = false;

  @override
  void initState() {
    super.initState();
    _pos = widget.userLocation;
    _load();
  }

  @override
  void dispose() {
    _locFilterCtrl.dispose();
    super.dispose();
  }

  // -------------------------
  // Haversine distance helpers
  // -------------------------
  double _deg2rad(double d) => d * math.pi / 180.0;

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    if (lat1.isNaN || lon1.isNaN || lat2.isNaN || lon2.isNaN) {
      return double.infinity;
    }
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

  double _distKmSafe(double lat1, double lon1, double lat2, double lon2) {
    if (_pos == null) return double.infinity;
    if ((lat2 == 0 && lon2 == 0) || lat2.isNaN || lon2.isNaN) {
      return double.infinity;
    }

    final dNormal = _haversineKm(lat1, lon1, lat2, lon2);
    final dSwapped = _haversineKm(lat1, lon1, lon2, lat2);
    if (dSwapped + 0.001 < dNormal) {
      debugPrint('[RentNearby] swapped lat/lon detected, using swapped distance');
      return dSwapped;
    }
    return dNormal;
  }

  String _formatDistance(double km) {
    if (km.isInfinite || km.isNaN) return 'Unknown';
    if (km < 1.0) return '${(km * 1000).toStringAsFixed(0)} m';
    return '${km.toStringAsFixed(1)} km';
  }

  // -------------------------
  // Load machines & location
  // -------------------------
  Future<void> _load({bool forceGps = false}) async {
    setState(() => _loading = true);

    if (forceGps) _pos = null;

    try {
      // Try GPS first
      Position? gpsPosition;
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          gpsPosition = await Geolocator.getCurrentPosition(
            locationSettings:
                const LocationSettings(accuracy: LocationAccuracy.high),
          );
        }
      } catch (e, st) {
        debugPrint('[RentNearby] GPS attempt failed: $e\n$st');
      }

      if (gpsPosition != null) {
        _pos = gpsPosition;
        await _loadMachines();
        return;
      }

      // Try Firestore default location
      final user = fb.FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('userProfile')
            .doc(user.uid)
            .get();
        if (doc.exists &&
            doc.data()?['defaultLat'] != null &&
            doc.data()?['defaultLon'] != null) {
          final lat = (doc.data()?['defaultLat'] as num?)?.toDouble() ?? 0.0;
          final lon = (doc.data()?['defaultLon'] as num?)?.toDouble() ?? 0.0;
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

      // Fallback: widget userLocation
      if (widget.userLocation != null) {
        _pos = widget.userLocation;
        await _loadMachines();
        return;
      }

      setState(() => _loading = false);
    } catch (e, st) {
      debugPrint('[RentNearby] load error: $e\n$st');
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMachines() async {
    if (_pos == null) {
      setState(() => _loading = false);
      return;
    }

    final list = await RentMachineService.instance.fetchOnce();
    list.sort((a, b) {
      final da = _distKmSafe(_pos!.latitude, _pos!.longitude, a.latitude, a.longitude);
      final db = _distKmSafe(_pos!.latitude, _pos!.longitude, b.latitude, b.longitude);
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

    if (_selectedRadius != -1) {
      filtered = filtered.where((m) {
        final d = _distKmSafe(
            _pos!.latitude, _pos!.longitude, m.latitude, m.longitude);
        return d <= _selectedRadius;
      }).toList();
    }

    if (_locFilter.isNotEmpty) {
      filtered = filtered.where((m) {
        final text =
            '${m.name} ${m.ownerName} ${m.location}'.toLowerCase(); // 🔥 includes name, owner & location
        return text.contains(_locFilter.toLowerCase());
      }).toList();
    }

    if (_sortBy == 'price') {
      filtered.sort((a, b) => a.pricePerDay.compareTo(b.pricePerDay));
    } else {
      filtered.sort((a, b) {
        final da = _distKmSafe(
            _pos!.latitude, _pos!.longitude, a.latitude, a.longitude);
        final db = _distKmSafe(
            _pos!.latitude, _pos!.longitude, b.latitude, b.longitude);
        return da.compareTo(db);
      });
    }

    return filtered;
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openMaps(RentMachine m) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${m.latitude},${m.longitude}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openFullMap(List<RentMachine> machines) {
    if (_pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.referenceLocationNotAvailable)),
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => rent_map_page.RentNearbyMapPage(
        initialMachines: machines,
        focusLat: _pos!.latitude,
        focusLon: _pos!.longitude,
        onRefreshRequest: () async => await _load(forceGps: true),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _applyFiltersAndSort();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.referenceName ?? AppLocalizations.of(context)!.nearbyMachines),
        actions: [
          DropdownButton<int>(
            value: _selectedRadius,
            underline: const SizedBox(),
            items: _radiusOptions
                .map((r) =>
                    DropdownMenuItem(value: r, child: Text(r == -1 ? 'All' : '$r km')))
                .toList(),
            onChanged: (v) => setState(() => _selectedRadius = v!),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (ctx) {
              final l2 = AppLocalizations.of(ctx)!;
              return [
                PopupMenuItem(value: "distance", child: Text(l2.nearestFirst)),
                PopupMenuItem(value: "price", child: Text(l2.lowestPriceFirst)),
              ];
            },
          ),
          
          IconButton(
            tooltip: 'Open full map',
            icon: const Icon(Icons.map_outlined),
            onPressed: () => _openFullMap(filtered),
          ),
          IconButton(
            tooltip: _showDebug ? 'Hide debug' : 'Show debug',
            icon: Icon(_showDebug
                ? Icons.bug_report
                : Icons.bug_report_outlined),
            onPressed: () => setState(() => _showDebug = !_showDebug),
          ),
          const SizedBox(width: 12),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _locFilterCtrl,
              onChanged: (v) => setState(() => _locFilter = v),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchByNameOwnerLocation,
                prefixIcon: const Icon(Icons.search),
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
              ? Center(child: Text(AppLocalizations.of(context)!.referenceLocationNotAvailable))
              : filtered.isEmpty
                  ? Center(child: Text(AppLocalizations.of(context)!.noMachinesFoundNearby))
                  : _mapView
                      ? SizedBox(
                          height: 300,
                          child: _InlineSmallMap(
                            machines: filtered,
                            reference:
                                gm.LatLng(_pos!.latitude, _pos!.longitude),
                            onMarkerTap: (m) => _showMachineBottomSheet(m),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final m = filtered[i];
                            final dist = _distKmSafe(
                                _pos!.latitude, _pos!.longitude, m.latitude, m.longitude);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Card(
                                clipBehavior: Clip.antiAlias,
                                child: ListTile(
                                  onTap: () => _showMachineBottomSheet(m),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: m.imageUrl.isNotEmpty
                                        ? Image.network(
                                            m.imageUrl,
                                            width: 56,
                                            height: 56,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.agriculture, size: 32),
                                          )
                                        : const SizedBox(
                                            width: 56,
                                            height: 56,
                                            child: Center(
                                              child: Icon(Icons.agriculture, size: 32),
                                            ),
                                          ),
                                  ),
                                  title: Text(m.name,
                                      style: const TextStyle(fontWeight: FontWeight.w700)),
                                  subtitle: Text(
                                    '${m.type} • ${_formatDistance(dist)}'
                                    '\n📍 ${m.location ?? "Unknown"}'
                                    '\n👤 ${m.ownerName}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.call_rounded),
                                    onPressed: () => _call(m.phone),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
    );
  }

  void _showMachineBottomSheet(RentMachine m) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final isOwner =
            (fb.FirebaseAuth.instance.currentUser?.uid ?? '') == m.ownerId;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(children: [
            ListTile(
              leading: CircleAvatar(
                radius: 28,
                backgroundImage: m.imageUrl.isNotEmpty
                    ? NetworkImage(m.imageUrl)
                    : const AssetImage('assets/farmer_logo.png')
                        as ImageProvider,
              ),
              title:
                  Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle:
                  Text('📍 ${m.location ?? "Unknown"}\nOwner: ${m.ownerName}'),
            ),
            Row(children: [
              ElevatedButton.icon(
                onPressed: () => _call(m.phone),
                icon: const Icon(Icons.call),
                label: Text(AppLocalizations.of(context)!.call),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _openMaps(m),
                icon: const Icon(Icons.map),
                label: Text(AppLocalizations.of(ctx)!.openInMaps),
              ),
              const SizedBox(width: 8),
              if (isOwner)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.edit),
                  label: Text(AppLocalizations.of(ctx)!.edit),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                ),
            ]),
          ]),
        );
      },
    );
  }
}

// ----------------------
// Inline Google Map widget
// ----------------------
class _InlineSmallMap extends StatefulWidget {
  final List<RentMachine> machines;
  final gm.LatLng reference;
  final void Function(RentMachine m) onMarkerTap;

  const _InlineSmallMap({
    required this.machines,
    required this.reference,
    required this.onMarkerTap,
  });

  @override
  State<_InlineSmallMap> createState() => _InlineSmallMapState();
}

class _InlineSmallMapState extends State<_InlineSmallMap> {
  gm.GoogleMapController? _ctrl;
  Set<gm.Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _buildMarkers();
  }

  void _buildMarkers() {
    final m = <gm.Marker>{};
    m.add(gm.Marker(
      markerId: const gm.MarkerId('ref'),
      position: widget.reference,
      infoWindow: const gm.InfoWindow(title: 'Reference'),
      icon:
          gm.BitmapDescriptor.defaultMarkerWithHue(gm.BitmapDescriptor.hueAzure),
    ));
    for (var rm in widget.machines) {
      if (rm.latitude.isNaN || rm.longitude.isNaN) continue;
      m.add(gm.Marker(
        markerId: gm.MarkerId(rm.id),
        position: gm.LatLng(rm.latitude, rm.longitude),
        infoWindow: gm.InfoWindow(title: rm.name, snippet: rm.location),
        onTap: () {
          // animate the inline Google map so the controller is used (removes unused_field)
          _ctrl?.animateCamera(
            gm.CameraUpdate.newLatLng(gm.LatLng(rm.latitude, rm.longitude)),
          );
          widget.onMarkerTap(rm);
        },
      ));
    }
    setState(() => _markers = m);
  }

  @override
  Widget build(BuildContext context) {
    return gm.GoogleMap(
      initialCameraPosition:
          gm.CameraPosition(target: widget.reference, zoom: 11),
      onMapCreated: (c) => _ctrl = c,
      markers: _markers,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
    );
  }
}
