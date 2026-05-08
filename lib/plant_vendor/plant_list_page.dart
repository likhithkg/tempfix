// lib/plant_vendor/plant_vendor_list_page.dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:krishimithra/plant_vendor/plant_vendor_model.dart';
import 'package:krishimithra/plant_vendor/plant_vendor_service.dart';
import 'package:krishimithra/plant_vendor/plant_list_form_page.dart';
import 'package:krishimithra/plant_vendor/plant_detail_page.dart';
import 'package:krishimithra/plant_vendor/plant_vendor_nearby_page.dart';

/// Shows plant vendor listings filtered by category.
/// category: "Seeds" or "Plant". If null -> defaults to "Plant".
class PlantVendorListPage extends StatefulWidget {
  final String category; // "Seeds" or "Plant"
  const PlantVendorListPage({super.key, this.category = 'Plant'});

  @override
  State<PlantVendorListPage> createState() => _PlantVendorListPageState();
}

class _PlantVendorListPageState extends State<PlantVendorListPage> {
  final PlantVendorService _service = PlantVendorService();
  List<PlantVendor> _vendors = [];
  List<PlantVendor> _filtered = [];
  bool _loading = true;
  String _search = '';
  String _sort = 'Newest';
  String _filterCategory = '';

  StreamSubscription<List<PlantVendor>>? _streamSub;

  @override
  void initState() {
    super.initState();
    _filterCategory = widget.category;
    _load();
    _streamSub = _service.streamVendors().listen((list) {
      // update local list from realtime stream and reapply filters
      _vendors = list;
      _applyFilters();
    }, onError: (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Realtime load error: $e'), backgroundColor: Colors.red),
        );
      }
    });
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final vendors = await _service.getPlantVendors();
      _vendors = vendors;
      _applyFilters();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading vendors: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    final cat = _filterCategory.trim().toLowerCase();
    final search = _search.trim().toLowerCase();

    _filtered = _vendors.where((v) {
      final rawType = (v.type).toString();
      String derivedCategory = 'plant';
      if (rawType.contains(' - ')) {
        derivedCategory = rawType.split(' - ').first.toLowerCase();
      } else {
        derivedCategory = 'plant';
      }

      final catMatches = (cat == 'all') ? true : (derivedCategory == cat);

      final typeText = rawType.contains(' - ') ? rawType.split(' - ').sublist(1).join(' - ') : rawType;
      final haystack = '${v.plantName} $typeText ${v.vendorName} ${v.location}'.toLowerCase();

      final searchMatches = search.isEmpty ? true : haystack.contains(search);

      return catMatches && searchMatches;
    }).toList();

    // sort
    if (_sort == 'Newest') {
      _filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } else if (_sort == 'Oldest') {
      _filtered.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } else if (_sort == 'Price: Low') {
      _filtered.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sort == 'Price: High') {
      _filtered.sort((a, b) => b.price.compareTo(a.price));
    }

    if (mounted) setState(() {});
  }

  String _displayCategoryLabel(PlantVendor v) {
    final rawType = (v.type).toString();
    if (rawType.contains(' - ')) {
      return rawType.split(' - ').first;
    }
    return 'Plant';
  }

  String _displayTypeLabel(PlantVendor v) {
    final rawType = (v.type).toString();
    if (rawType.contains(' - ')) {
      return rawType.split(' - ').sublist(1).join(' - ');
    }
    return rawType;
  }

  Widget _buildTile(PlantVendor v) {
    // defensive local copies (avoid passing nulls into Text widgets)
    final safePlantName = (v.plantName).isNotEmpty ? v.plantName : 'Unknown plant';
    final safeType = (v.type).isNotEmpty ? v.type : 'Plant';
    final safeLocation = (v.location).isNotEmpty ? v.location : '';
    final safeVendorName = (v.vendorName).isNotEmpty ? v.vendorName : '';
    final safePrice = v.price;
    final safeQty = v.quantity;
    final safeTimestamp = v.timestamp;

    final category = _displayCategoryLabel(v);
    final typeLabel = _displayTypeLabel(v);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.local_florist, size: 30),
        ),
        title: Row(
          children: [
            Expanded(child: Text(safePlantName, style: const TextStyle(fontWeight: FontWeight.bold))),
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: category.toLowerCase() == 'seeds' ? Colors.orange.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(category, style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text('$typeLabel • ₹${safePrice.toStringAsFixed(2)}${safeLocation.isNotEmpty ? ' • $safeLocation' : ''}'),
            const SizedBox(height: 6),
            Text('Qty: $safeQty • ${formatDate(safeTimestamp)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ],
        ),
        isThreeLine: true,
        onTap: () async {
          try {
            // owner detection uses createdBy first, then ownerId; both may be empty
            final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
            final owner = (v.createdBy.isNotEmpty ? v.createdBy : (v.ownerId.isNotEmpty ? v.ownerId : ''));

            if (owner.isNotEmpty && owner == uid) {
              // owner -> edit page (existing behavior)
              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => PlantListFormPage(existingVendor: v)),
              );
              if (changed == true) _load();
            } else {
              // not owner -> open read-only details page
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PlantVendorDetailsPage(vendor: v)),
              );
              // no refresh needed for view-only
            }
          } catch (err, st) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Unable to open listing: $err'), backgroundColor: Colors.red),
              );
            }
            // ignore: avoid_print
            print('Navigation error: $err\n$st');
          }
        },

        // show 3-dots only for owner
        trailing: (() {
          final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
          final owner = (v.createdBy.isNotEmpty ? v.createdBy : (v.ownerId.isNotEmpty ? v.ownerId : ''));

          if (owner.isNotEmpty && owner == uid) {
            // Show 3 dots only if current user is owner
            return IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                _showActions(v);
              },
            );
          } else {
            return const SizedBox(); // hide for non-owner
          }
        }()),
      ),
    );
  }

  void _showActions(PlantVendor v) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => PlantListFormPage(existingVendor: v)),
                ).then((changed) {
                  if (changed == true) _load();
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete listing?'),
                    content: const Text('This will permanently delete the listing.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await _service.deletePlantVendor(v.id);
                  _load();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search plant, type, vendor, location...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
                onChanged: (s) {
                  _search = s;
                  _applyFilters();
                },
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: _sort,
              underline: Container(height: 0),
              items: const [
                DropdownMenuItem(value: 'Newest', child: Text('Newest')),
                DropdownMenuItem(value: 'Oldest', child: Text('Oldest')),
                DropdownMenuItem(value: 'Price: Low', child: Text('Price: Low')),
                DropdownMenuItem(value: 'Price: High', child: Text('Price: High')),
              ],
              onChanged: (v) {
                if (v == null) return;
                _sort = v;
                _applyFilters();
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            DropdownButton<String>(
              value: _filterCategory.toLowerCase(),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All')),
                DropdownMenuItem(value: 'plant', child: Text('Plant')),
                DropdownMenuItem(value: 'seeds', child: Text('Seeds')),
              ],
              onChanged: (v) {
                if (v == null) return;
                _filterCategory = v[0].toUpperCase() + v.substring(1); // store with capital first letter
                _applyFilters();
              },
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              onPressed: _load,
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.location_on),
              label: const Text('Nearby'),
              onPressed: () async {
                // open Nearby page; no explicit return value expected but reload on return just in case
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const PlantVendorNearbyPage()));
                _load();
              },
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add'),
              onPressed: () async {
                final added = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const PlantListFormPage()),
                );
                if (added == true) _load();
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.category.toLowerCase() == 'seeds' ? 'Seeds' : 'Plant Vendors';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _filtered.isEmpty
                        ? Center(child: Text('No ${widget.category} listings found.'))
                        : ListView.builder(
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => _buildTile(_filtered[i]),
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Simple read-only details page for non-owners
class PlantVendorDetailsPage extends StatelessWidget {
  final PlantVendor vendor;
  const PlantVendorDetailsPage({super.key, required this.vendor});

  @override
  Widget build(BuildContext context) {
    final safeType = (vendor.type).isNotEmpty ? vendor.type : 'Plant';
    final category = safeType.contains(' - ') ? safeType.split(' - ').first : 'Plant';
    final typeLabel = safeType.contains(' - ') ? safeType.split(' - ').sublist(1).join(' - ') : safeType;

    final safePlantName = (vendor.plantName).isNotEmpty ? vendor.plantName : 'Unknown plant';
    final safePrice = vendor.price;
    final safeQty = vendor.quantity;
    final safeVendorName = (vendor.vendorName).isNotEmpty ? vendor.vendorName : 'Unknown vendor';
    final safeLocation = (vendor.location).isNotEmpty ? vendor.location : 'Not provided';
    final safeTimestamp = vendor.timestamp;
    final safeDescription = (vendor.description).isNotEmpty ? vendor.description : 'No description provided.';

    return Scaffold(
      appBar: AppBar(
        title: Text(safePlantName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.local_florist, size: 40),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(safePlantName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: category.toLowerCase() == 'seeds' ? Colors.orange.shade100 : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(category),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _infoRow('Type', typeLabel),
            const SizedBox(height: 8),
            _infoRow('Price', '₹${safePrice.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _infoRow('Quantity', safeQty.toString()),
            const SizedBox(height: 8),
            _infoRow('Vendor', safeVendorName),
            const SizedBox(height: 8),
            _infoRow('Location', safeLocation),
            const SizedBox(height: 8),
            _infoRow('Listed on', formatDate(safeTimestamp)),
            const SizedBox(height: 20),
            const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(safeDescription),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: Text(value)),
      ],
    );
  }
}

/// Top-level date formatter used by both list and details page
String formatDate(DateTime dt) {
  final month = _monthName(dt.month);
  final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  return '$month ${dt.day} $hour:${dt.minute.toString().padLeft(2, '0')} $ampm';
}

String _monthName(int m) {
  const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return names[(m - 1).clamp(0, 11)];
}
