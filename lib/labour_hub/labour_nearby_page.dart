// lib/labour_hub/labour_nearby_page.dart
// Polished Nearby Labour page — header image removed and Add FAB removed.
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'labour_hub_detail_page.dart';
import 'labour_model.dart';
import '../l10n/app_localizations.dart';
import '../widgets/km_listing_card.dart';
import '../widgets/km_action_button.dart';
import '../widgets/km_status_chip.dart';
import '../theme.dart';
import '../services/content_translation_service.dart';

class LabourNearbyPage extends StatefulWidget {
  const LabourNearbyPage({super.key});

  @override
  State<LabourNearbyPage> createState() => _LabourNearbyPageState();
}

class _LabourNearbyPageState extends State<LabourNearbyPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loading = true;
  String? _error;
  Position? _currentPosition;
  List<_NearbyLabour> _nearby = [];

  double _radiusKm = 150.0;
  bool _permissionDenied = false;

  String _query = '';
  final String _skillFilter = 'All';

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

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
    );
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

  Future<void> _openOnMap(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.couldNotOpenMaps)));
    }
  }

  Future<void> _callNumber(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.couldNotOpenDialer)));
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
          title: Text(AppLocalizations.of(context)!.selectRadius),
          children: [
            ...[5, 10, 20, 50, 100, 150, 200, 500].map((v) {
              return SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, v.toDouble()),
                child: Text('$v km'),
              );
            }),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.nearbyLabourTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 6),
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
                          hintText: AppLocalizations.of(context)!.searchLabourHint,
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
                                Text(AppLocalizations.of(context)!.locationPermissionDenied),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () => Geolocator.openAppSettings(),
                                  child: Text(AppLocalizations.of(context)!.openSettings),
                                ),
                              ],
                            ),
                          )
                        : _error != null
                            ? Center(child: Text('Error: $_error'))
                            : _nearby.isEmpty
                                ? Center(child: Text(AppLocalizations.of(context)!.noLabourFoundNearby))
                                : RefreshIndicator(
                                    onRefresh: _refresh,
                                    child: ListView.separated(
                                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                                      itemCount: _nearby.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                                      itemBuilder: (context, i) {
                                        final n = _nearby[i];
                                        final labour = n.labour;

                                        final anim = CurvedAnimation(
                                          parent: _animController,
                                          curve: Curves.easeOut,
                                        );
                                        final l = AppLocalizations.of(context)!;
                                        final langCode = Localizations.localeOf(context).languageCode;
                                        return SizeTransition(
                                          sizeFactor: anim,
                                          axis: Axis.vertical,
                                          child: Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: KMListingCard(
                                              imageUrl: labour.imageUrl,
                                              fallbackIcon: Icons.person_outline,
                                              imageHeight: 130,
                                              title: labour.name,
                                              subtitle: labour.skill.trim().isNotEmpty
                                                  ? '${l.skillProfessionLabel}: ${ContentTranslationService.translateLabourSkill(labour.skill, langCode)}'
                                                  : null,
                                              caption: '${l.locationLabel}: ${ContentTranslationService.translateLocation(labour.location, langCode)}',
                                              statusBadge: KMStatusChip(
                                                label: labour.available ? l.available : l.busy,
                                                color: labour.available
                                                    ? KMColors.available
                                                    : KMColors.unavailable,
                                              ),
                                              infoRow: Row(
                                                children: [
                                                  const Icon(Icons.location_pin,
                                                      size: 14, color: Colors.grey),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    l.kmAway(n.distanceKm.toStringAsFixed(1)),
                                                    style: const TextStyle(fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                              actionRow: Row(
                                                children: [
                                                  KMCallIconButton(
                                                    onPressed: () =>
                                                        _callNumber(labour.contact),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  IconButton(
                                                    icon: const Icon(Icons.map,
                                                        color: Colors.blue),
                                                    onPressed: () =>
                                                        _openOnMap(n.lat, n.lng),
                                                  ),
                                                ],
                                              ),
                                              onTap: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      LabourHubDetailPage(labour: labour),
                                                ),
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
