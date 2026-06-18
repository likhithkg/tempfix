// lib/labour_hub/labour_hub_listing_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

import 'labour_model.dart';
import 'labour_hub_service.dart';
import 'labour_hub_form_page.dart';
import 'labour_hub_detail_page.dart';
import 'labour_nearby_page.dart';
import '../theme.dart';
import '../widgets/km_widgets.dart';
import '../widgets/km_listing_card.dart';
import '../widgets/km_status_chip.dart';
import '../widgets/km_action_button.dart';
import '../l10n/app_localizations.dart';

class LabourHubListingPage extends StatefulWidget {
  const LabourHubListingPage({super.key});

  @override
  State<LabourHubListingPage> createState() => _LabourHubListingPageState();
}

class _LabourHubListingPageState extends State<LabourHubListingPage> {
  final LabourHubService _service = LabourHubService();
  late Future<List<Labour>> _labourListFuture;

  String _searchQuery = '';
  bool _sortByName = true;
  String _selectedCategoryKey = 'All';
  bool _sortByDistance = false;
  Position? _currentPosition;

  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchLabours();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return;
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) setState(() {});
    } catch (_) {}
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  void _fetchLabours() {
    setState(() {
      _labourListFuture = _service.getAllLabours();
    });
  }

  Future<void> _openForm({Labour? labour}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => LabourHubFormPage(labour: labour)),
    );
    if (result == true) _fetchLabours();
  }

  void _confirmDelete(String id) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(KMRadius.md)),
        title: Text(l.deleteLabour),
        content: Text(l.deleteLabourConfirm),
        actions: [
          TextButton(
            child: Text(l.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: KMColors.error),
            icon: const Icon(Icons.delete),
            label: Text(l.delete),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _service.deleteLabour(id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.deleted)),
                  );
                }
                _fetchLabours();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l.deleteFailed}: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _callLabour(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.cannotOpenDialer)),
      );
    }
  }

  Map<String, String> _categoryMap(AppLocalizations l) => {
        'All': l.all,
        'Farm Labour': l.farmLabour,
        'Tractor Driver': l.tractorDriver,
        'Plantation Worker': l.plantationWorker,
        'Sprayer Operator': l.sprayerOperator,
        'Harvester Operator': l.harvesterOperator,
        'Machine Technician': l.machineTechnician,
        'Dairy Worker': l.dairyWorker,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final catMap = _categoryMap(l);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.labourHub),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            tooltip: l.nearby,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LabourNearbyPage()),
            ),
          ),
          IconButton(
            icon: Icon(_sortByName ? Icons.sort_by_alpha : Icons.sort),
            onPressed: () => setState(() {
              _sortByName = !_sortByName;
              _sortByDistance = false;
            }),
          ),
          IconButton(
            icon: const Icon(Icons.near_me),
            tooltip: l.sortByDistanceLabel,
            onPressed: () =>
                setState(() => _sortByDistance = !_sortByDistance),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                KMSpacing.md, KMSpacing.sm, KMSpacing.md, KMSpacing.md),
            child: Column(
              children: [
                KMSearchBar(
                  controller: _searchCtrl,
                  hintText: l.searchLabour,
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.toLowerCase()),
                  onClear: () => setState(() {
                    _searchQuery = '';
                    _searchCtrl.clear();
                  }),
                ),
                const SizedBox(height: KMSpacing.sm),
                // ── Category filter chips ──────────────────────────────────
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: catMap.entries.map((entry) {
                      final isSelected = _selectedCategoryKey == entry.key;
                      return Padding(
                        padding: const EdgeInsets.only(right: KMSpacing.sm),
                        child: KMCategoryChip(
                          label: entry.value,
                          selected: isSelected,
                          onSelected: (_) => setState(
                              () => _selectedCategoryKey = entry.key),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      body: FutureBuilder<List<Labour>>(
        future: _labourListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('${l.errorLoadingLabour}: ${snapshot.error}'));
          }

          var labours = snapshot.data ?? [];

          // Filter
          labours = labours.where((labour) {
            final categoryMatch = _selectedCategoryKey == 'All' ||
                labour.category == _selectedCategoryKey;
            final searchMatch = _searchQuery.isEmpty ||
                labour.name.toLowerCase().contains(_searchQuery) ||
                labour.location.toLowerCase().contains(_searchQuery) ||
                labour.skill.toLowerCase().contains(_searchQuery);
            return categoryMatch && searchMatch;
          }).toList();

          // Sort
          if (_sortByDistance && _currentPosition != null) {
            labours = labours
                .where((l) => l.latitude != null && l.longitude != null)
                .toList()
              ..sort((a, b) {
                final dA = _calculateDistance(_currentPosition!.latitude,
                    _currentPosition!.longitude, a.latitude!, a.longitude!);
                final dB = _calculateDistance(_currentPosition!.latitude,
                    _currentPosition!.longitude, b.latitude!, b.longitude!);
                return dA.compareTo(dB);
              });
          } else if (_sortByName) {
            labours.sort((a, b) => a.name.compareTo(b.name));
          } else {
            labours.sort(
                (a, b) => (a.experience ?? 0).compareTo(b.experience ?? 0));
          }

          if (labours.isEmpty) {
            return KMEmptyState(
              message: l.noLabourFound,
              icon: Icons.people_outline,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(KMSpacing.md),
            itemCount: labours.length,
            itemBuilder: (context, index) {
              final labour = labours[index];
              final isOwner = currentUserId != null &&
                  labour.createdBy == currentUserId;

              double? distance;
              if (_currentPosition != null &&
                  labour.latitude != null &&
                  labour.longitude != null) {
                distance = _calculateDistance(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                  labour.latitude!,
                  labour.longitude!,
                );
              }

              // ── Chips row ──────────────────────────────────────────────
              final chips = Wrap(
                spacing: KMSpacing.sm,
                runSpacing: KMSpacing.xs,
                children: [
                  if (labour.category != null)
                    KMStatusChip(
                      label: labour.category!,
                      color: KMColors.primary,
                    ),
                  if (labour.experience != null)
                    KMStatusChip(
                      label: '${labour.experience} yrs',
                      color: KMColors.secondary,
                    ),
                  if (labour.wage != null && labour.wageType != null)
                    KMStatusChip(
                      label: '₹${labour.wage} ${labour.wageType}',
                      color: KMColors.accent,
                    ),
                  if (distance != null)
                    KMStatusChip(
                      label: l.kmAway(distance.toStringAsFixed(1)),
                      color: Colors.blueGrey,
                    ),
                ],
              );

              // ── Action row ─────────────────────────────────────────────
              final actionRow = Row(
                children: [
                  KMStatusChip(
                    label: labour.available ? l.available : l.busy,
                    color: labour.available
                        ? KMColors.available
                        : KMColors.unavailable,
                  ),
                  const Spacer(),
                  KMCallIconButton(
                      onPressed: () => _callLabour(labour.contact)),
                  if (isOwner) ...[
                    const SizedBox(width: KMSpacing.xs),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _openForm(labour: labour);
                        if (value == 'delete') _confirmDelete(labour.id);
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                            value: 'edit',
                            child: Text(l.edit)),
                        PopupMenuItem(
                            value: 'delete',
                            child: Text(l.delete)),
                      ],
                    ),
                  ],
                ],
              );

              return Padding(
                padding:
                    const EdgeInsets.only(bottom: KMSpacing.md),
                child: KMListingCard(
                  imageUrl: labour.imageUrl,
                  fallbackIcon: Icons.person_outline,
                  imageHeight: 140,
                  title: labour.name,
                  subtitle: labour.skill,
                  caption: labour.location,
                  infoRow: chips,
                  actionRow: actionRow,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LabourHubDetailPage(labour: labour),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton.small(
        onPressed: () => _openForm(),
        tooltip: l.addLabour,
        child: const Icon(Icons.add),
      ),
    );
  }
}
