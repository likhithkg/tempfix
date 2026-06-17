// lib/labour_hub/labour_nearby_page.dart
// Polished Nearby Labour page — header image removed and Add FAB removed.
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import 'labour_hub_detail_page.dart';
import 'labour_hub_form_page.dart';
import 'labour_model.dart';

class LabourNearbyPage extends StatefulWidget {
  const LabourNearbyPage({Key? key}) : super(key: key);

  @override
  State<LabourNearbyPage> createState() => _LabourNearbyPageState();
}

class _LabourNearbyPageState extends State<LabourNearbyPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _loading = true;
  String? _error;
  Position? _currentPosition;
  List<_NearbyLabour> _nearby = [];

  double _radiusKm = 150.0;
  bool _permissionDenied = false;

  String _query = '';
  String _skillFilter = 'All';

  // header image path (not used anymore but kept for reference)
  final String headerImageUrl = '/mnt/data/e197c40d-db36-4f5f-ad56-9d5c5aec7599.png';

  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _initAndLoad();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initAndLoad() async {
    setState(() {
      _loading = true;
      _error = null;
      _permissionDenied = false;
    });

    try {
      final pos = await _determinePosition();
      setState(() => _currentPosition = pos);
      await _loadNearbyLabours(pos.latitude, pos.longitude, _radiusKm);
      _animController.forward(from: 0);
    } catch (e) {
      setState(() {
        _error = e.toString();
        if (e is PermissionDeniedException || e.toString().toLowerCase().contains('permission')) {
          _permissionDenied = true;
        }
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable them.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      throw PermissionDeniedException('Location permission is permanently denied.');
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw PermissionDeniedException('Location permission denied.');
      }
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
  }

  Future<void> _loadNearbyLabours(double myLat, double myLng, double radiusKm) async {
    try {
      final snapshot = await _firestore.collection('labours').get();
      final List<_NearbyLabour> results = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        Labour labour;
        try {
          labour = Labour.fromMap(Map<String, dynamic>.from(data), doc.id);
        } catch (_) {
          continue;
        }

        final lat = labour.latitude;
        final lng = labour.longitude;
        if (lat == null || lng == null) continue;

        final distanceKm = _haversineDistance(myLat, myLng, lat, lng);

        if (distanceKm <= radiusKm) {
          if (_skillFilter != 'All' && labour.skill.trim().isNotEmpty) {
            if (labour.skill.toLowerCase() != _skillFilter.toLowerCase()) continue;
          }
          if (_query.isNotEmpty) {
            final q = _query.toLowerCase();
            if (!labour.name.toLowerCase().contains(q) && !labour.location.toLowerCase().contains(q)) continue;
          }

          results.add(_NearbyLabour(
            labour: labour,
            docId: doc.id,
            lat: lat,
            lng: lng,
            distanceKm: distanceKm,
          ));
        }
      }

      results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      setState(() => _nearby = results);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180.0);

  void _openOnMap(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open maps')));
    }
  }

  void _callNumber(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open dialer')));
    }
  }

  Future<void> _refresh() async {
    if (_currentPosition != null) {
      setState(() => _loading = true);
      await _loadNearbyLabours(_currentPosition!.latitude, _currentPosition!.longitude, _radiusKm);
      setState(() => _loading = false);
    } else {
      await _initAndLoad();
    }
  }

  Future<void> _showRadiusPicker() async {
    final selected = await showDialog<double>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Select radius'),
          children: [
            ...[5, 10, 20, 50, 100, 150, 200, 500].map((v) {
              return SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, v.toDouble()),
                child: Text('$v km'),
              );
            }).toList(),
          ],
        );
      },
    );

    if (selected != null) {
      setState(() => _radiusKm = selected);
      if (_currentPosition != null) {
        _loadNearbyLabours(_currentPosition!.latitude, _currentPosition!.longitude, _radiusKm);
      }
    }
  }

  Widget _buildHeaderRow() {
    return Container(
      color: Colors.green.shade700,
      padding: const EdgeInsets.only(top: 12, bottom: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.maybePop(context),
          ),
          const Expanded(
            child: Text(
              'Nearby Labour',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refresh,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      // FAB removed as requested
      body: SafeArea(
        child: Column(
          children: [
            _buildHeaderRow(),
            const SizedBox(height: 6),
            // removed header image block (no blank space above search)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(12),
                      child: TextField(
                        onChanged: (v) {
                          setState(() => _query = v.trim());
                          if (_currentPosition != null) {
                            _loadNearbyLabours(_currentPosition!.latitude, _currentPosition!.longitude, _radiusKm);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Search by name or address',
                          prefixIcon: const Icon(Icons.search, color: Colors.green),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: _showRadiusPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade100),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.place, color: Colors.green, size: 18),
                          const SizedBox(width: 6),
                          Text('${_radiusKm.toStringAsFixed(0)} km'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _permissionDenied
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Location permission denied.'),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () => Geolocator.openAppSettings(),
                                  child: const Text('Open App Settings'),
                                ),
                              ],
                            ),
                          )
                        : _error != null
                            ? Center(child: Text('Error: $_error'))
                            : _nearby.isEmpty
                                ? const Center(child: Text('No nearby labour found.'))
                                : RefreshIndicator(
                                    onRefresh: _refresh,
                                    child: ListView.separated(
                                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                                      itemCount: _nearby.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                                      itemBuilder: (context, i) {
                                        final n = _nearby[i];
                                        final labour = n.labour;

                                        final anim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
                                        return SizeTransition(
                                          sizeFactor: anim,
                                          axis: Axis.vertical,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(14),
                                            onTap: () {
                                              Navigator.push(context, MaterialPageRoute(builder: (_) => LabourHubDetailPage(labour: labour)));
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(14),
                                                boxShadow: [
                                                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 3)),
                                                ],
                                              ),
                                              child: Row(
                                                children: [
                                                  CircleAvatar(
  radius: 28,

  backgroundColor: labour.available
      ? Colors.green.shade50
      : Colors.red.shade50,

  backgroundImage:
      labour.imageUrl != null &&
              labour.imageUrl!.isNotEmpty
          ? NetworkImage(labour.imageUrl!)
          : const AssetImage(
                  'assets/farmer_logo.png')
              as ImageProvider,

  onBackgroundImageError: (_, __) {},

  child: null,
),
                                                  const SizedBox(width: 12),

                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(labour.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                                        const SizedBox(height: 6),
                                                        if (labour.skill.trim().isNotEmpty)
                                                          Text(labour.skill.toLowerCase(), style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                                                        const SizedBox(height: 8),
                                                        Text(labour.location, style: TextStyle(fontSize: 13, color: Colors.grey.shade800), maxLines: 2, overflow: TextOverflow.ellipsis),
                                                        const SizedBox(height: 8),
                                                        Row(
                                                          children: [
                                                            const Icon(Icons.location_pin, size: 14, color: Colors.grey),
                                                            const SizedBox(width: 6),
                                                            Text('${n.distanceKm.toStringAsFixed(1)} km away', style: const TextStyle(fontSize: 13)),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),

                                                  const SizedBox(width: 8),

                                                  Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(Icons.call, color: Colors.green),
                                                        onPressed: () => _callNumber(labour.contact),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.map, color: Colors.blue),
                                                        onPressed: () => _openOnMap(n.lat, n.lng),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyLabour {
  final Labour labour;
  final String docId;
  final double lat;
  final double lng;
  final double distanceKm;

  _NearbyLabour({
    required this.labour,
    required this.docId,
    required this.lat,
    required this.lng,
    required this.distanceKm,
  });
}

class PermissionDeniedException implements Exception {
  final String message;
  PermissionDeniedException([this.message = 'Permission denied']);
  @override
  String toString() => message;
}
