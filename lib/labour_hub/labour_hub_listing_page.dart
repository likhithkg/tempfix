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

  // 🔥 NEW: Category Filter
  String _selectedCategory = 'All';

  // 🔥 NEW: Distance Sorting
  bool _sortByDistance = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _fetchLabours();
    _getCurrentLocation(); // 🔥 added
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Labour'),
        content: const Text('Are you sure you want to remove this labour?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _service.deleteLabour(id);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
                _fetchLabours();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open dialer')),
      );
    }
  }

  Widget _buildCategoryChips() {
    final categories = [
      'All',
      'Farm Labour',
      'Tractor Driver',
      'Plantation Worker',
      'Sprayer Operator',
      'Harvester Operator',
      'Machine Technician',
      'Dairy Worker',
    ];

    return SizedBox(
      height: 45,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              selectedColor: Colors.green.shade200,
              onSelected: (_) {
                setState(() {
                  _selectedCategory = cat;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _labourCard(Labour labour, String? currentUserId) {
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: labour.available ? Colors.green.shade100 : Colors.red.shade100,
                backgroundImage: labour.imageUrl != null ? NetworkImage(labour.imageUrl!) : null,
                child: labour.imageUrl == null
                    ? Icon(
                        labour.available ? Icons.check_circle : Icons.cancel,
                        color: labour.available ? Colors.green : Colors.red,
                        size: 26,
                      )
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
                        "${distance.toStringAsFixed(1)} km away",
                        style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                      ),
                  ],
                ),
              ),

              IconButton(
                icon: const Icon(Icons.phone, color: Colors.green),
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
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
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
                  labour.available ? "Available" : "Busy",
                  style: TextStyle(
                    color: labour.available ? Colors.green : Colors.red,
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
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Labour Hub', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 4,
        backgroundColor: Colors.green.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on, color: Colors.white),
            tooltip: 'Nearby',
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
            tooltip: 'Sort by Distance',
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
                Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(14),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search labour...',
                      prefixIcon: const Icon(Icons.search, color: Colors.green),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
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
            return Center(child: Text('Error loading labour data: ${snapshot.error}'));
          }

          var labours = snapshot.data ?? [];

          // 🔎 SEARCH + CATEGORY FILTER
          labours = labours.where((labour) {
            final q = _searchQuery;

            final categoryMatch =
                _selectedCategory == 'All' ||
                labour.category == _selectedCategory;

            final searchMatch =
                q.isEmpty ||
                labour.name.toLowerCase().contains(q) ||
                labour.location.toLowerCase().contains(q) ||
                labour.skill.toLowerCase().contains(q);

            return categoryMatch && searchMatch;
          }).toList();

          // 📍 DISTANCE SORTING (NEW – DOES NOT REMOVE EXISTING SORT)
          if (_sortByDistance && _currentPosition != null) {
            labours = labours
                .where((l) => l.latitude != null && l.longitude != null)
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
            // 🔤 ORIGINAL SORTING PRESERVED
            if (_sortByName) {
              labours.sort((a, b) => a.name.compareTo(b.name));
            } else {
              labours.sort((a, b) =>
                  (a.experience ?? 0).compareTo(b.experience ?? 0));
            }
          }

          if (labours.isEmpty) {
            return const Center(
              child: Text(
                'No labour entries found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
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
        child: const Icon(Icons.add),
        backgroundColor: Colors.green.shade700,
        tooltip: 'Add Labour',
      ),
    );
  }
}