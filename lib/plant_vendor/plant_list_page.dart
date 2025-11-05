import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:krishimithra/plant_vendor/plant_list_form_page.dart';
import 'package:krishimithra/plant_vendor/plant_vendor_model.dart';
import 'package:krishimithra/plant_vendor/plant_vendor_service.dart';
import 'package:krishimithra/plant_vendor/plant_detail_page.dart';

class PlantListingPage extends StatefulWidget {
  const PlantListingPage({super.key});

  @override
  State<PlantListingPage> createState() => _PlantListingPageState();
}

class _PlantListingPageState extends State<PlantListingPage> {
  late Future<List<PlantVendor>> _vendorsFuture;
  List<PlantVendor> _all = [];
  List<PlantVendor> _filtered = [];

  String _query = '';
  String _typeFilter = 'All';
  String _sort = 'Newest';

  @override
  void initState() {
    super.initState();
    _vendorsFuture = _load();
  }

  Future<List<PlantVendor>> _load() async {
    final list = await PlantVendorService().getAllVendors();
    _all = list;
    _applyFilters();
    return list;
  }

  Future<void> _refresh() async {
    setState(() {
      _vendorsFuture = _load();
    });
  }

  void _applyFilters() {
    List<PlantVendor> res = List.of(_all);

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      res = res.where((v) {
        return v.plantName.toLowerCase().contains(q) ||
            v.type.toLowerCase().contains(q) ||
            v.location.toLowerCase().contains(q) ||
            v.vendorName.toLowerCase().contains(q);
      }).toList();
    }

    if (_typeFilter != 'All') {
      res = res.where((v) => v.type == _typeFilter).toList();
    }

    if (_sort == 'Price ↑') {
      res.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sort == 'Price ↓') {
      res.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sort == 'Newest') {
      res.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } else if (_sort == 'Oldest') {
      res.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    setState(() {
      _filtered = res;
    });
  }

  List<String> _typesFromData() {
    final set = <String>{};
    for (final v in _all) {
      if (v.type.trim().isNotEmpty) set.add(v.type.trim());
    }
    final list = set.toList()..sort();
    return ['All', ...list];
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Vendors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<PlantVendor>>(
        future: _vendorsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _all.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final types = _typesFromData();

          return Column(
            children: [
              // Search + Filters
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) {
                          _query = v;
                          _applyFilters();
                        },
                        decoration: InputDecoration(
                          hintText: 'Search plant, type, vendor, location…',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _sort,
                      items: const [
                        DropdownMenuItem(value: 'Newest', child: Text('Newest')),
                        DropdownMenuItem(value: 'Oldest', child: Text('Oldest')),
                        DropdownMenuItem(value: 'Price ↑', child: Text('Price ↑')),
                        DropdownMenuItem(value: 'Price ↓', child: Text('Price ↓')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        _sort = v;
                        _applyFilters();
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: DropdownButton<String>(
                    value: types.contains(_typeFilter) ? _typeFilter : 'All',
                    items: types
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      _typeFilter = v;
                      _applyFilters();
                    },
                  ),
                ),
              ),

              const Divider(height: 1),

              Expanded(
                child: _filtered.isEmpty
                    ? const Center(child: Text('No matching listings'))
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final v = _filtered[index];
                            final isMine = v.createdBy == currentUser?.uid;

                            return _VendorCard(
                              vendor: v,
                              isMine: isMine,
                              onOpen: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PlantDetailPage(vendor: v),
                                  ),
                                );
                              },
                              onEdit: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PlantListFormPage(existingVendor: v),
                                  ),
                                );
                                _refresh();
                              },
                              onDelete: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete listing?'),
                                    content: Text(
                                        'Remove "${v.plantName}" from listings?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (ok == true) {
                                  await PlantVendorService()
                                      .deletePlantVendor(v.id);
                                  _refresh();
                                }
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PlantListFormPage()),
          );
          _refresh();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}

class _VendorCard extends StatelessWidget {
  final PlantVendor vendor;
  final bool isMine;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;

  const _VendorCard({
    required this.vendor,
    required this.isMine,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  String _date(DateTime d) => DateFormat.MMMd().add_jm().format(d);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(
            children: [
              // Avatar / Placeholder
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.green.withOpacity(0.08),
                ),
                child: const Icon(Icons.local_florist, size: 28),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.plantName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${vendor.type} • ₹${vendor.price.toStringAsFixed(2)} • ${vendor.location}',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Qty: ${vendor.quantity} • ${_date(vendor.timestamp)}',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isMine) // 👈 show menu only if added by me
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'open') {
                      onOpen();
                    } else if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      await onDelete();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'open', child: Text('View details')),
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Remove',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}