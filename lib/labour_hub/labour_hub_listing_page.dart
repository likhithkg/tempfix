// lib/labour_hub/labour_hub_listing_page.dart
// Only owner can see Edit/Delete (three-dot menu).

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'labour_model.dart';
import 'labour_hub_service.dart';
import 'labour_hub_form_page.dart';
import 'labour_hub_detail_page.dart';
import 'labour_nearby_page.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import '../theme.dart';
import '../widgets/km_widgets.dart';
import '../l10n/app_localizations.dart';

const String headerImagePath = '/mnt/data/e197c40d-db36-4f5f-ad56-9d5c5aec7599.png';

class LabourHubListingPage extends StatefulWidget {
  const LabourHubListingPage({Key? key}) : super(key: key);

  @override
  State<LabourHubListingPage> createState() => _LabourHubListingPageState();
}

class _LabourHubListingPageState extends State<LabourHubListingPage> {
  final LabourHubService _service = LabourHubService();
  late Future<List<Labour>> _labourListFuture;

  String _searchQuery = '';
  bool _sortByName = true;

  // Category filter uses English key to match Firestore values
  String _selectedCategoryKey = 'All';

  // Distance Sorting
  bool _sortByDistance = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _fetchLabours();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) return;

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {});
    } catch (_) {}
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _deg2rad(double deg) {
    return deg * (pi / 180);
  }

  void _fetchLabours() {
    setState(() {
      _labourListFuture = _service.getAllLabours();
    });
  }

  Future<void> _openForm({Labour? labour}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LabourHubFormPage(labour: labour),
      ),
    );

    if (result == true) {
      _fetchLabours();
    }
  }

  void _confirmDelete(String id) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(l.deleteLabour),
        content: Text(l.deleteLabourConfirm),
        actions: [
          TextButton(
            child: Text(l.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            icon: const Icon(Icons.delete),
            label: Text(l.delete),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _service.deleteLabour(id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.deleted)),
                  );
                }
                _fetchLabours();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${AppLocalizations.of(context)!.deleteFailed}: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _callLabour(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.cannotOpenDialer)),
        );
      }
    }
  }

  // Maps English Firestore keys to localized display labels.
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

  Widget _buildCategoryChips() {
    final l = AppLocalizations.of(context)!;
    final catMap = _categoryMap(l);

    return SizedBox(
      height: 45,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: catMap.entries.map((entry) {
          final isSelected = _selectedCategoryKey == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedCategoryKey = entry.key;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _labourCard(Labour labour, String? currentUserId) {
    final l = AppLocalizations.of(context)!;
    final bool isOwner = currentUserId != null && labour.createdBy == currentUserId;

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

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: KMShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
             CircleAvatar(
  radius: 28,
  backgroundColor: labour.available
      ? KMColors.available.withValues(alpha: 0.18)
      : KMColors.unavailable.withValues(alpha: 0.18),

  backgroundImage:
      labour.imageUrl != null &&
              labour.imageUrl!.isNotEmpty
          ? NetworkImage(labour.imageUrl!)
          : const AssetImage(
                  'assets/farmer_logo.png')
              as ImageProvider,

  onBackgroundImageError: (_, __) {},

  child: (labour.imageUrl == null ||
          labour.imageUrl!.isEmpty)
      ? null
      : null,
),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      labour.name,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labour.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    if (distance != null)
                      Text(
                        l.kmAway(distance.toStringAsFixed(1)),
                        style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                      ),
                  ],
                ),
              ),

              IconButton(
                icon: Icon(Icons.phone, color: Theme.of(context).colorScheme.primary),
                onPressed: () => _callLabour(labour.contact),
              ),

              if (isOwner)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openForm(labour: labour);
                    } else if (value == 'delete') {
                      _confirmDelete(labour.id);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'edit', child: Text(l.edit)),
                    PopupMenuItem(value: 'delete', child: Text(l.delete)),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (labour.category != null)
                Chip(label: Text(labour.category!)),

              if (labour.experience != null)
                Chip(label: Text("${labour.experience} yrs")),

              if (labour.wage != null && labour.wageType != null)
                Chip(label: Text("₹${labour.wage} ${labour.wageType}")),

              Chip(
                label: Text(
                  labour.available ? l.available : l.busy,
                  style: TextStyle(
                    color: labour.available ? KMColors.available : KMColors.unavailable,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.labourHub, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on, color: Colors.white),
            tooltip: l.nearby,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LabourNearbyPage()));
            },
          ),
          IconButton(
            icon: Icon(_sortByName ? Icons.sort_by_alpha : Icons.sort, color: Colors.white),
            onPressed: () {
              setState(() {
                _sortByName = !_sortByName;
                _sortByDistance = false;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.near_me, color: Colors.white),
            tooltip: l.sortByDistanceLabel,
            onPressed: () {
              setState(() {
                _sortByDistance = !_sortByDistance;
              });
            },
          ),
        ],

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              children: [
                KMSearchBar(
                  hintText: l.searchLabour,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 8),
                _buildCategoryChips(),
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
            return Center(child: Text('${l.errorLoadingLabour}: ${snapshot.error}'));
          }

          var labours = snapshot.data ?? [];

          // SEARCH + CATEGORY FILTER — compare against English Firestore keys
          labours = labours.where((labour) {
            final q = _searchQuery;

            final categoryMatch =
                _selectedCategoryKey == 'All' ||
                labour.category == _selectedCategoryKey;

            final searchMatch =
                q.isEmpty ||
                labour.name.toLowerCase().contains(q) ||
                labour.location.toLowerCase().contains(q) ||
                labour.skill.toLowerCase().contains(q);

            return categoryMatch && searchMatch;
          }).toList();

          // DISTANCE SORTING
          if (_sortByDistance && _currentPosition != null) {
            labours = labours
                .where((lab) => lab.latitude != null && lab.longitude != null)
                .toList();

            labours.sort((a, b) {
              final distA = _calculateDistance(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                a.latitude!,
                a.longitude!,
              );

              final distB = _calculateDistance(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                b.latitude!,
                b.longitude!,
              );

              return distA.compareTo(distB);
            });
          } else {
            if (_sortByName) {
              labours.sort((a, b) => a.name.compareTo(b.name));
            } else {
              labours.sort((a, b) =>
                  (a.experience ?? 0).compareTo(b.experience ?? 0));
            }
          }

          if (labours.isEmpty) {
            return Center(
              child: Text(
                l.noLabourFound,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: labours.length,
            itemBuilder: (context, index) {
              final labour = labours[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          LabourHubDetailPage(labour: labour),
                    ),
                  );
                },
                child: _labourCard(labour, currentUserId),
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
