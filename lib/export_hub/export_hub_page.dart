import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_export_stock_page.dart';
import 'export_listing_detail_page.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../widgets/km_widgets.dart';
import '../widgets/km_listing_card.dart';
import '../widgets/km_status_chip.dart';
import '../widgets/km_action_button.dart';

class ExportHubPage extends StatefulWidget {
  const ExportHubPage({super.key});

  @override
  State<ExportHubPage> createState() => _ExportHubPageState();
}

class _ExportHubPageState extends State<ExportHubPage> {
  String? role;
  bool isLoading = true;
  String searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        role = doc.data()?['role'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  // Returns a KMStatusChip color for a given export status string.
  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return KMColors.available;
      case 'rejected':
        return KMColors.unavailable;
      default:
        return KMColors.warning;
    }
  }

  String _statusLabel(String status, AppLocalizations l) {
    switch (status) {
      case 'approved':
        return l.statusApproved;
      case 'rejected':
        return l.statusRejected;
      default:
        return l.statusPending;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (role == 'admin') return _adminView(context);
    if (role == 'exporter') return _exporterView(context);
    return _farmerView(context);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Admin view — browse all listings with search
  // ─────────────────────────────────────────────────────────────────────────

  Widget _adminView(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.exportHub)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KMSpacing.lg,
              KMSpacing.md,
              KMSpacing.lg,
              KMSpacing.sm,
            ),
            child: KMSearchBar(
              controller: _searchCtrl,
              hintText: l.searchByCropFarmer,
              onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
              onClear: () => setState(() {
                searchQuery = '';
                _searchCtrl.clear();
              }),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('export_listings')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final product =
                      (data['productName'] ?? '').toString().toLowerCase();
                  final farmer =
                      (data['farmerName'] ?? '').toString().toLowerCase();
                  final location =
                      (data['location'] ?? '').toString().toLowerCase();
                  return product.contains(searchQuery) ||
                      farmer.contains(searchQuery) ||
                      location.contains(searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return KMEmptyState(
                    message: l.noListingsFound,
                    icon: Icons.inventory_2_outlined,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: KMSpacing.md),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: KMSpacing.md),
                      child: _exportCard(
                        context,
                        data: data,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExportListingDetailPage(
                              docId: doc.id,
                              data: data,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Farmer view — own listings + post new
  // ─────────────────────────────────────────────────────────────────────────

  Widget _farmerView(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(l.exportHub)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PostExportStockPage()),
        ),
        icon: const Icon(Icons.add),
        label: Text(l.postExportStock),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                KMSpacing.lg, KMSpacing.lg, KMSpacing.lg, KMSpacing.sm),
            child: KMSectionHeader(title: l.myListings),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('export_listings')
                  .where('farmerId', isEqualTo: user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return KMEmptyState(
                    message: l.noListingsYet,
                    icon: Icons.inventory_2_outlined,
                    onAction: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PostExportStockPage()),
                    ),
                    actionLabel: l.postExportStock,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      KMSpacing.md, 0, KMSpacing.md, KMSpacing.xl + 64),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: KMSpacing.md),
                      child: _exportCard(
                        context,
                        data: data,
                        actionRow: Row(
                          children: [
                            KMActionButton(
                              icon: Icons.edit,
                              label: l.edit,
                              outlined: true,
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PostExportStockPage(
                                    isEdit: true,
                                    docId: doc.id,
                                    existingData: data,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: KMSpacing.sm),
                            KMActionButton(
                              icon: Icons.delete_outline,
                              label: l.delete,
                              color: KMColors.error,
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('export_listings')
                                    .doc(doc.id)
                                    .delete();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Exporter view — listings visible to this exporter
  // ─────────────────────────────────────────────────────────────────────────

  Widget _exporterView(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(l.exportHub)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('export_listings')
            .where('visibleToExporters', arrayContains: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return KMEmptyState(
              message: l.noListingsFound,
              icon: Icons.inventory_2_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(KMSpacing.md),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: KMSpacing.md),
                child: _exportCard(context, data: data),
              );
            },
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Shared card builder — used by all three views
  // ─────────────────────────────────────────────────────────────────────────

  Widget _exportCard(
    BuildContext context, {
    required Map<String, dynamic> data,
    VoidCallback? onTap,
    Widget? actionRow,
  }) {
    final l = AppLocalizations.of(context)!;

    final product = (data['productName'] ?? '').toString();
    final farmer = (data['farmerName'] ?? '').toString();
    final quantity = (data['quantity'] ?? '').toString();
    final price = (data['pricePerKg'] ?? '').toString();
    final location = (data['location'] ?? '').toString();
    final status = (data['status'] ?? 'open').toString();
    final imageUrl =
        (data['imageUrl'] ?? '').toString().isNotEmpty ? data['imageUrl'].toString() : null;

    final statusColor = _statusColor(status);
    final statusLbl = _statusLabel(status, l);

    // Info lines
    final infoItems = <String>[];
    if (farmer.isNotEmpty) infoItems.add('${l.farmerLabel} $farmer');
    if (quantity.isNotEmpty) infoItems.add('${l.qtyLabel} $quantity');
    if (price.isNotEmpty) infoItems.add('${l.priceLabel} $price/kg');
    if (location.isNotEmpty) infoItems.add('${l.locationLabel} $location');

    return KMListingCard(
      imageUrl: imageUrl,
      fallbackIcon: Icons.inventory_2_outlined,
      imageHeight: 160,
      title: product,
      subtitle: infoItems.take(2).join(' • '),
      caption: infoItems.length > 2 ? infoItems.skip(2).join(' • ') : null,
      statusBadge: KMStatusChip(label: statusLbl, color: statusColor),
      infoRow: actionRow,
      onTap: onTap,
    );
  }
}
