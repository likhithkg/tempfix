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
import '../l10n/app_localizations.dart';
import '../services/content_translation_service.dart';

class ExporterHomePage extends StatefulWidget {
  const ExporterHomePage({super.key});

  @override
  State<ExporterHomePage> createState() => _ExporterHomePageState();
}

String _localizedStatus(AppLocalizations l, String status) {
  switch (status.toLowerCase()) {
    case 'pending':   return l.statusPending;
    case 'approved':  return l.statusApproved;
    case 'rejected':  return l.statusRejected;
    case 'accepted':  return l.statusAccepted;
    case 'confirmed': return l.statusConfirmed;
    case 'completed': return l.statusCompleted;
    case 'cancelled': return l.statusCancelled;
    case 'issued':    return l.statusIssued;
    case 'open':      return l.statusOpen;
    case 'closed':    return l.statusClosed;
    default:          return status;
  }
}

class _ExporterHomePageState extends State<ExporterHomePage> {
  final _service = ExporterService();
  final TextEditingController _searchController = TextEditingController();

  // Category filter — keep lowercase English keys for Firestore comparison.
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

  List<ExportProduct> _applyFiltersToProducts(List<ExportProduct> products) {
    final q = _searchController.text.trim().toLowerCase();
    final cat = _selectedCategory.toLowerCase();

    return products.where((p) {
      String pname = '';
      String farmer = '';
      String loc = '';
      String pcat = '';

      try { pname = p.productName.toString().toLowerCase(); } catch (_) {}
      try { farmer = p.farmerName.toString().toLowerCase(); } catch (_) {}
      try { loc = p.location.toString().toLowerCase(); } catch (_) {}
      try {
        dynamic maybe = (p as dynamic).category ?? (p as dynamic).productCategory ?? '';
        pcat = (maybe ?? '').toString().toLowerCase();
      } catch (_) {}

      if (cat != 'all') {
        if (pcat.isEmpty) return false;
        if (pcat != cat) return false;
      }

      if (q.isEmpty) return true;
      if (pname.contains(q) || farmer.contains(q) || loc.contains(q)) return true;
      return false;
    }).toList();
  }

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
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchHeader(AppLocalizations l) {
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
                    prefixIcon: const Icon(Icons.search),
                    hintText: l.searchByCropFarmer,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: l.openMap,
                icon: const Icon(Icons.map_outlined),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyFarmersMapPage()));
                },
              ),
              IconButton(
                tooltip: l.nearbyFarmersList,
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
    final l = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(l.exporterHub),
          actions: [
            IconButton(
              icon: const Icon(Icons.shopping_bag_outlined),
              tooltip: l.sellingOrders,
              onPressed: () {
                final u = FirebaseAuth.instance.currentUser;
                if (u == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.pleaseSignInToViewSeller)));
                  return;
                }
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerPurchaseOrderListPage()));
              },
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(icon: const Icon(Icons.local_florist), text: l.cropsTab),
              Tab(icon: const Icon(Icons.store_mall_directory), text: l.myListingsTab),
              Tab(icon: const Icon(Icons.list_alt), text: l.verifiedBuyersTab),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (user == null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.pleaseSignInToAdd)));
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
                    _buildSearchHeader(l),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Tab 1: Public Products
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
                                return Center(child: Text(l.noExportProductsFound));
                              }
                              return _buildProductList(context, filtered, user, padding: _listPadding(context));
                            },
                          ),

                          // Tab 2: My Listings
                          user == null
                              ? Center(child: Text(l.pleaseSignInToViewListings))
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
                                      return Center(child: Text(l.noListingsMatchFilter));
                                    }
                                    return _buildProductList(context, filtered, user, isOwnerTab: true, padding: _listPadding(context));
                                  },
                                ),

                          // Tab 3: Buying Orders
                          user == null
                              ? Center(child: Text(l.pleaseSignInToViewOrders))
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
                                      return Center(child: Text(l.noPurchaseOrders));
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
                                        final loc = AppLocalizations.of(context)!;
                                        final poLang = Localizations.localeOf(context).languageCode;
                                        final rawPoName = po['productName'] ?? po['product_name'] ?? '';
                                        final poProductName = rawPoName.toString().isNotEmpty
                                            ? ContentTranslationService.translateCropName(rawPoName.toString(), poLang)
                                            : 'Order ${id.toString().substring(0, id.toString().length >= 6 ? 6 : id.toString().length)}';
                                        return Column(
                                          children: [
                                            ListTile(
                                              leading: CircleAvatar(backgroundColor: statusColor.withValues(alpha: 0.12), child: Icon(Icons.shopping_bag, color: statusColor)),
                                              title: Text(poProductName),
                                              subtitle: Text('${loc.totalLabel} ₹$total • ${loc.statusLabel} ${_localizedStatus(loc, status)}\n$timeLabel'),
                                              isThreeLine: true,
                                              trailing: TextButton(
                                                onPressed: () {
                                                  Navigator.push(context, MaterialPageRoute(builder: (_) => PODetailPage(poId: id)));
                                                },
                                                child: Text(loc.viewDetails),
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
    final l = AppLocalizations.of(context)!;
    final langCode = Localizations.localeOf(context).languageCode;
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
        final translatedProductName = ContentTranslationService.translateCropName(product.productName, langCode);
        final translatedLocation = ContentTranslationService.translateLocation(product.location, langCode);
        final sellerIdDisplay = (product.farmerMobile != null && product.farmerMobile!.isNotEmpty)
            ? '${l.mobileLabel} ${product.farmerMobile}'
            : (product.farmerId.isNotEmpty ? 'ID: ${product.farmerId}' : '${l.sellerLabel} ${product.farmerName}');

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                backgroundImage: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? NetworkImage(product.imageUrl!) as ImageProvider
                    : const AssetImage('assets/farmer_logo.png'),
                onBackgroundImageError: (_, __) {},
                child: null,
              ),
              title: Text(translatedProductName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${l.quantityLabel}: ${product.quantity} • ${l.locationLabel}: $translatedLocation\n$sellerIdDisplay'),
              trailing: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '₹${product.pricePerUnit}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(height: 8),
                      if (isOwner)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 22), tooltip: l.edit, onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ExporterFormPage(existingProduct: product)));
                            }),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 22), tooltip: l.delete, onPressed: () async {
                              final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                                title: Text(l.deleteListingTitle),
                                content: Text(l.areYouSureDeleteProduct),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
                                  TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l.delete, style: const TextStyle(color: Colors.redAccent))),
                                ],
                              ));
                              if (confirm == true) {
                                await _service.deleteExportProduct(product.id);
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.productDeletedSuccessfully)));
                              }
                            }),
                          ],
                        )
                      else
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => CreatePurchaseOrderPage(listingData: product)));
                          },
                          child: Text(l.buy),
                        ),
                    ],
                  ),
                ),
              ),
              onTap: () {
                showDialog(context: context, builder: (_) => AlertDialog(
                  title: Text(translatedProductName),
                  content: Builder(builder: (ctx) {
                    final l = AppLocalizations.of(ctx)!;
                    final lc = Localizations.localeOf(ctx).languageCode;
                    final loc = ContentTranslationService.translateLocation(product.location, lc);
                    return Text(
                      '${l.farmerLabel} ${product.farmerName}\n'
                      '${l.mobileLabel} ${product.farmerMobile ?? product.farmerId}\n'
                      '${l.qtyLabel} ${product.quantity}\n'
                      '${l.priceLabel}: ₹${product.pricePerUnit}\n'
                      '${l.locationLabel}: $loc\n\n'
                      '${product.description}',
                    );
                  }),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: Text(l.close)),
                    if (!isOwner)
                      TextButton(onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => CreatePurchaseOrderPage(listingData: product)));
                      }, child: Text(l.buyNow)),
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
