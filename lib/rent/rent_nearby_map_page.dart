// lib/rent/rent_nearby_map_page.dart
// OpenStreetMap map view for Nearby Rent Machines using flutter_map (v6+/v8 style).
// Displays machines with 🚜 emoji markers and a bottom sheet for actions.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';

import 'rent_machine_service.dart';
import 'rent_model.dart';

class RentNearbyMapPage extends StatefulWidget {
  final double? focusLat;
  final double? focusLon;
  final RentMachine? focusMachine;
  final List<RentMachine>? initialMachines;
  final Future<void> Function()? onRefreshRequest;

  const RentNearbyMapPage({
    super.key,
    this.focusLat,
    this.focusLon,
    this.focusMachine,
    this.initialMachines,
    this.onRefreshRequest,
  });

  @override
  State<RentNearbyMapPage> createState() => _RentNearbyMapPageState();
}

class _RentNearbyMapPageState extends State<RentNearbyMapPage> {
  final RentMachineService _service = RentMachineService.instance;
  Position? _myPos;
  bool _loading = true;
  String? _error;
  List<RentMachine> _machines = [];
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

      if (widget.initialMachines != null) {
        setState(() => _machines = widget.initialMachines!);
      } else {
        await _refreshMachines();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || _myPos == null) return;
        try {
          if (widget.focusLat != null && widget.focusLon != null) {
            _mapController.move(ll.LatLng(widget.focusLat!, widget.focusLon!), 14);
            await Future.delayed(const Duration(milliseconds: 350));
            if (!mounted) return;
            final machine = widget.focusMachine ?? _findMachineByCoords(widget.focusLat!, widget.focusLon!);
            if (machine != null) _showMachineSheet(machine);
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

  RentMachine? _findMachineByCoords(double lat, double lon) {
    try {
      const tol = 0.0005;
      for (final m in _machines) {
        final fLat = m.latitude;
        final fLon = m.longitude;
        if ((fLat - lat).abs() < tol && (fLon - lon).abs() < tol) return m;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshMachines() async {
    if (_myPos == null) return;
    setState(() => _loading = true);
    try {
      List<RentMachine> list = [];

      // NOTE: RentMachineService may not have server-side queryNearby.
      // Use fetchOnce() and client-side filter by distance.
      try {
        final all = await _service.fetchOnce();
        final kmLimit = 200.0;
        final metersLimit = kmLimit * 1000.0;
        final filtered = <RentMachine>[];
        for (final rm in all) {
          if (rm.latitude.isNaN || rm.longitude.isNaN) continue;
          final distMeters = Geolocator.distanceBetween(_myPos!.latitude, _myPos!.longitude, rm.latitude, rm.longitude);
          if (distMeters <= metersLimit) filtered.add(rm);
        }
        list = filtered;
      } catch (e) {
        debugPrint('RentNearby: service.fetchOnce failed: $e');
      }

      if (list.isEmpty) {
        // fallback: load some machines from Firestore (collection 'rent_machines')
        final snap = await FirebaseFirestore.instance.collection('rent_machines').get();
        final docs = snap.docs;
        final Map<String, RentMachine> machinesMap = {};
        for (final d in docs) {
          final m = d.data();
          final lat = (m['latitude'] is num) ? (m['latitude'] as num).toDouble() : double.tryParse(m['latitude']?.toString() ?? '');
          final lon = (m['longitude'] is num) ? (m['longitude'] as num).toDouble() : double.tryParse(m['longitude']?.toString() ?? '');
          if (lat == null || lon == null) continue;
          final id = d.id;
          final name = (m['name'] ?? 'Unknown') as String;
          final owner = (m['ownerName'] ?? '') as String;
          final phone = (m['phone'] ?? '') as String;
          final price = (m['pricePerDay'] is num) ? (m['pricePerDay'] as num).toDouble() : double.tryParse(m['pricePerDay']?.toString() ?? '') ?? 0.0;
          machinesMap[id] = RentMachine(
            id: id,
            name: name,
            type: (m['type'] ?? 'Other') as String,
            pricePerDay: price,
            ownerName: owner,
            ownerId: (m['ownerId'] ?? '') as String,
            phone: phone,
            latitude: lat,
            longitude: lon,
            imageUrl: (m['imageUrl'] ?? '') as String,
            createdAt: DateTime.tryParse((m['createdAt'] ?? '').toString()) ?? DateTime.now(),
            location: (m['location'] ?? '') as String,
          );
        }
        setState(() => _machines = machinesMap.values.toList());
      } else {
        setState(() => _machines = list);
      }
    } catch (e) {
      debugPrint('RentNearby: _refreshMachines error $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMachineSheet(RentMachine m) {
    final isOwner = (fb.FirebaseAuth.instance.currentUser?.uid ?? '') == m.ownerId;

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
                    Flexible(child: Text(m.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    Text('${(Geolocator.distanceBetween(_myPos!.latitude, _myPos!.longitude, m.latitude, m.longitude) / 1000.0).toStringAsFixed(2)} km',
                        style: const TextStyle(color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(m.location ?? ''),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _call(m.phone);
                      },
                      icon: const Icon(Icons.call),
                      label: const Text('Call'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _openMap(m);
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('Open in Maps'),
                    ),
                    const SizedBox(width: 8),
                    if (isOwner)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // navigate to edit screen if you have one
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
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

  Future<void> _openMap(RentMachine m) async {
    final lat = m.latitude;
    final lon = m.longitude;
    final google = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    if (await canLaunchUrl(google)) {
      await launchUrl(google, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _call(String phone) async {
    if (phone.trim().isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nearby Machines (Map)'), backgroundColor: Colors.green),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nearby Machines (Map)'), backgroundColor: Colors.green),
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
      ..._machines.map((m) {
        final lat = m.latitude;
        final lon = m.longitude;
        return fm.Marker(
          point: ll.LatLng(lat, lon),
          width: 48,
          height: 48,
          child: GestureDetector(
            onTap: () {
              _mapController.move(ll.LatLng(lat, lon), 14);
              _showMachineSheet(m);
            },
            child: const Text('🚜', style: TextStyle(fontSize: 30)),
          ),
        );
      }).toList(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Machines (Map)'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshMachines),
          if (widget.onRefreshRequest != null)
            IconButton(
              icon: const Icon(Icons.location_searching),
              onPressed: () async {
                await widget.onRefreshRequest!.call();
                await _refreshMachines();
              },
            ),
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

          Positioned(
            left: 12,
            top: 12,
            child: Card(
              color: Colors.white70,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Machines shown: ${_machines.length}',
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
