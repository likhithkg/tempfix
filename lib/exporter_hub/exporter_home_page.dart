// lib/exporter_hub/exporter_home_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'exporter_service.dart';
import 'exporter_model.dart';
import 'exporter_form_page.dart';
import 'create_purchase_order_page.dart';
import 'po_detail_page.dart';
import 'nearby_farmers_page.dart';
import 'nearby_farmers_map_page.dart';
import 'seller_purchase_order_list_page.dart';

class ExporterHomePage extends StatefulWidget {
  ExporterHomePage({Key? key}) : super(key: key);

  @override
  State<ExporterHomePage> createState() => _ExporterHomePageState();
}

class _ExporterHomePageState extends State<ExporterHomePage> {
  final _service = ExporterService();
  final TextEditingController _searchController = TextEditingController();

  // Category filter. Keep values lowercase for comparison.
  final List<String> _categories = ['all', 'fruits', 'vegetables', 'grains', 'other'];
  String _selectedCategory = 'all';

  Stream<List<Map<String, dynamic>>> _ordersForBuyer(String uid) => _service.streamPOsForBuyer(uid);
  Stream<List<ExportProduct>> _myProducts(String uid) => _service.getMyExportProducts(uid);

  EdgeInsets _listPadding(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    const fabExtra = 140.0;
    return EdgeInsets.fromLTRB(12, 8, 12, bottomSafe + fabExtra + viewInsetsBottom);
  }

  double _fabExtra() => 140.0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Apply search and category filter to a list of products
  List<ExportProduct> _applyFiltersToProducts(List<ExportProduct> products) {
    final q = _searchController.text.trim().toLowerCase();
    final cat = _selectedCategory.toLowerCase();

    return products.where((p) {
      // Safely read fields; ExportProduct implementation may differ so we use try/catch to avoid crashes
      String pname = '';
      String farmer = '';
      String loc = '';
      String pcat = '';

      try {
        pname = (p.productName ?? '').toString().toLowerCase();
      } catch (_) {}
      try {
        farmer = (p.farmerName ?? '').toString().toLowerCase();
      } catch (_) {}
      try {
        loc = (p.location ?? '').toString().toLowerCase();
      } catch (_) {}
      try {
        // common names for category fields: category, productCategory
        dynamic maybe = (p as dynamic).category ?? (p as dynamic).productCategory ?? '';
        pcat = (maybe ?? '').toString().toLowerCase();
      } catch (_) {}
      // Category filter
      if (cat != 'all') {
        if (pcat.isEmpty) return false;
        if (pcat != cat) return false;
      }

      // Search query filter: match any of name / farmer / location
      if (q.isEmpty) return true;
      if (pname.contains(q) || farmer.contains(q) || loc.contains(q)) return true;
      return false;
    }).toList();
  }

  // Small helper to render category chips
  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((c) {
          final label = c[0].toUpperCase() + c.substring(1);
          final selected = c == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(label),
              selected: selected,
              onSelected: (_) {
                setState(() => _selectedCategory = c);
              },
              selectedColor: Colors.green.shade300,
              backgroundColor: Colors.grey.shade200,
              labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search by crop, farmer name or location',
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              // Map icon (opens map page showing all farmers)
              IconButton(
                tooltip: 'Open map',
                icon: const Icon(Icons.map_outlined),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyFarmersMapPage()));
                },
              ),
              // Nearby list icon (kept in header — top-right AppBar icon was removed)
              IconButton(
                tooltip: 'Nearby farmers (list)',
                icon: const Icon(Icons.people_outline),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyFarmersPage()));
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(height: 36, child: _buildCategoryChips()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text('Exporter Hub'),
          backgroundColor: Colors.green,
          actions: [
            // removed the top-right nearby farmer icon as requested
            IconButton(
              icon: const Icon(Icons.shopping_bag_outlined),
              tooltip: 'Selling Orders',
              onPressed: () {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to view seller orders.')));
                  return;
                }
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerPurchaseOrderListPage()));
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.local_florist), text: 'Crops'),
              Tab(icon: Icon(Icons.store_mall_directory), text: 'My Listings'),
              Tab(icon: Icon(Icons.list_alt), text: 'Verified Buyers'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.green,
          onPressed: () {
            if (user == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to add products.')));
              return;
            }
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ExporterFormPage()));
          },
          child: const Icon(Icons.add),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final viewInsets = MediaQuery.of(context).viewInsets.bottom;
              return AnimatedPadding(
                padding: EdgeInsets.only(bottom: viewInsets),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: Column(
                  children: [
                    // search + category header (always visible above tabs content)
                    _buildSearchHeader(),
                    // Expanded tab content
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Tab 1: Public Products (filtered client-side)
                          StreamBuilder<List<ExportProduct>>(
                            stream: _service.getExportProducts(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError) {
                                return Center(child: Text('Error: ${snapshot.error}'));
                              }
                              final products = snapshot.data ?? [];
                              final filtered = _applyFiltersToProducts(products);
                              if (filtered.isEmpty) {
                                return const Center(child: Text('No export products match your search / filter.'));
                              }
                              return _buildProductList(context, filtered, user, padding: _listPadding(context));
                            },
                          ),

                          // Tab 2: My Listings (also filtered)
                          user == null
                              ? const Center(child: Text('Please sign in to view your listings'))
                              : StreamBuilder<List<ExportProduct>>(
                                  stream: _myProducts(user.uid),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
                                    }
                                    if (snapshot.hasError) {
                                      return Center(child: Text('Error: ${snapshot.error}'));
                                    }
                                    final myProducts = snapshot.data ?? [];
                                    final filtered = _applyFiltersToProducts(myProducts);
                                    if (filtered.isEmpty) {
                                      return const Center(child: Text('No listings match your search / filter.'));
                                    }
                                    return _buildProductList(context, filtered, user, isOwnerTab: true, padding: _listPadding(context));
                                  },
                                ),

                          // Tab 3: Buying Orders (unchanged)
                          user == null
                              ? const Center(child: Text('Please sign in to view your orders'))
                              : StreamBuilder<List<Map<String, dynamic>>>(
                                  stream: _ordersForBuyer(user.uid),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
                                    }
                                    if (snapshot.hasError) {
                                      return Center(child: Text('Error: ${snapshot.error}'));
                                    }
                                    final orders = snapshot.data ?? [];
                                    if (orders.isEmpty) {
                                      return const Center(child: Text('No purchase orders yet.'));
                                    }

                                    final fabExtra = _fabExtra();
                                    return ListView.builder(
                                      padding: _listPadding(context),
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      itemCount: orders.length + 1,
                                      itemBuilder: (context, index) {
                                        if (index == orders.length) return SizedBox(height: fabExtra);
                                        final po = orders[index];
                                        final id = po['id'] ?? '—';
                                        final total = po['totalAmount'] ?? 0;
                                        final status = po['status'] ?? 'issued';
                                        final createdAt = po['createdAt'];
                                        String timeLabel = '';
                                        try {
                                          if (createdAt is Timestamp) {
                                            final dt = createdAt.toDate();
                                            timeLabel = '${dt.day}/${dt.month}/${dt.year}';
                                          } else if (createdAt is Map && createdAt.containsKey('_seconds')) {
                                            final ts = DateTime.fromMillisecondsSinceEpoch(createdAt['_seconds'] * 1000);
                                            timeLabel = '${ts.day}/${ts.month}/${ts.year}';
                                          }
                                        } catch (_) {}
                                        Color statusColor;
                                        switch (status.toString().toLowerCase()) {
                                          case 'completed':
                                            statusColor = Colors.green;
                                            break;
                                          case 'confirmed':
                                            statusColor = Colors.blue;
                                            break;
                                          default:
                                            statusColor = Colors.orange;
                                        }
                                        return Column(
                                          children: [
                                            ListTile(
                                              leading: CircleAvatar(backgroundColor: statusColor.withOpacity(0.12), child: Icon(Icons.shopping_bag, color: statusColor)),
                                              // show crop / product name when available (if stored in order) else short id
                                              title: Text(po['productName'] ?? po['product_name'] ?? 'Order ${id.toString().substring(0, id.toString().length >= 6 ? 6 : id.toString().length)}'),
                                              subtitle: Text('Total: ₹$total • Status: $status\n$timeLabel'),
                                              isThreeLine: true,
                                              trailing: TextButton(
                                                onPressed: () {
                                                  Navigator.push(context, MaterialPageRoute(builder: (_) => PODetailPage(poId: id)));
                                                },
                                                child: const Text('View Details'),
                                              ),
                                            ),
                                            const Divider(height: 1, color: Colors.grey),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProductList(BuildContext context, List<ExportProduct> products, User? user, {bool isOwnerTab = false, EdgeInsets? padding}) {
    final pad = padding ?? const EdgeInsets.all(8);
    final fabExtra = _fabExtra();

    return ListView.builder(
      padding: pad,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: products.length + 1,
      itemBuilder: (context, index) {
        if (index == products.length) return SizedBox(height: fabExtra);

        final product = products[index];
        final isOwner = user != null && product.ownerId == user.uid;
        final sellerIdDisplay = (product.farmerMobile != null && product.farmerMobile!.isNotEmpty)
            ? 'Mobile: ${product.farmerMobile}'
            : (product.farmerId.isNotEmpty ? 'ID: ${product.farmerId}' : 'Seller: ${product.farmerName}');

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              leading: CircleAvatar(backgroundColor: Colors.green.shade100, child: const Icon(Icons.local_florist, color: Colors.green)),
              title: Text(product.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${product.quantity} • ${product.location}\n$sellerIdDisplay'),
              trailing: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // <- Price made larger, bolder and colored
                      Text(
                        '₹${product.pricePerUnit}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green.shade800),
                      ),
                      const SizedBox(height: 8),
                      if (isOwner)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 22), tooltip: 'Edit', onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ExporterFormPage(existingProduct: product)));
                            }),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 22), tooltip: 'Delete', onPressed: () async {
                              final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                                title: const Text('Delete Listing'),
                                content: const Text('Are you sure you want to delete this product?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
                                ],
                              ));
                              if (confirm == true) {
                                await _service.deleteExportProduct(product.id);
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted successfully')));
                              }
                            }),
                          ],
                        )
                      else
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => CreatePurchaseOrderPage(listingData: product)));
                          },
                          child: const Text('Buy'),
                        ),
                    ],
                  ),
                ),
              ),
              onTap: () {
                showDialog(context: context, builder: (_) => AlertDialog(
                  title: Text(product.productName),
                  content: Text(
                    'Farmer: ${product.farmerName}\n'
                    'Mobile: ${product.farmerMobile ?? product.farmerId}\n'
                    'Qty: ${product.quantity}\n'
                    'Price: ₹${product.pricePerUnit}\n'
                    'Location: ${product.location}\n\n'
                    '${product.description}',
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                    if (!isOwner)
                      TextButton(onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => CreatePurchaseOrderPage(listingData: product)));
                      }, child: const Text('Buy now')),
                  ],
                ));
              },
            ),
          ),
        );
      },
    );
  }
}
