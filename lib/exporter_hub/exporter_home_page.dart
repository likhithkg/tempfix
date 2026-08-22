// lib/exporter_hub/exporter_home_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'export_constants.dart';
import 'exporter_service.dart';
import 'exporter_model.dart';
import 'exporter_form_page.dart';
import 'nearby_farmers_page.dart';
import 'nearby_farmers_map_page.dart';
import 'seller_purchase_order_list_page.dart';
import 'purchase_order_list_page.dart';
import 'demand_board_page.dart';
import 'export_operations_dashboard.dart';
import 'warehouse_dashboard.dart';
import 'shipment_dashboard.dart';
import 'export_documents_page.dart';
import 'buyers_page.dart';
import 'finance_dashboard.dart';
import 'notifications_page.dart';
import 'create_purchase_order_page.dart';
import 'ai_insights_page.dart';
import 'role_service.dart';
import '../l10n/app_localizations.dart';
import '../services/content_translation_service.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kGreen1 = Color(0xFF1B5E20);
const _kGreen2 = Color(0xFF2E7D32);
const _kTeal   = Color(0xFF00897B);
const _kGold   = Color(0xFFFFB300);

class ExporterHomePage extends StatefulWidget {
  const ExporterHomePage({super.key});

  @override
  State<ExporterHomePage> createState() => _ExporterHomePageState();
}

class _ExporterHomePageState extends State<ExporterHomePage> {
  final _service = ExporterService();

  StreamSubscription<Map<String, int>>? _statsSub;
  StreamSubscription<String>? _roleSub;

  Map<String, int> _stats = {
    'totalFarmers': 0,
    'activeListings': 0,
    'pendingPOs': 0,
    'exportReady': 0,
  };
  bool _statsLoading = true;
  String _userRole = 'farmer'; // default until resolved

  @override
  void initState() {
    super.initState();
    _statsSub = _service.streamDashboardStats().listen(
      (stats) {
        if (mounted) setState(() { _stats = stats; _statsLoading = false; });
      },
      onError: (_) { if (mounted) setState(() => _statsLoading = false); },
    );
    _roleSub = RoleService.streamCurrentRole().listen((role) {
      if (mounted) setState(() => _userRole = role);
    });
  }

  @override
  void dispose() {
    _statsSub?.cancel();
    _roleSub?.cancel();
    super.dispose();
  }

  bool get _isAdmin => RoleService.isAdmin(_userRole);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _statsLoading = true);
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: CustomScrollView(
          slivers: [
            // ── SliverAppBar ──────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              stretch: true,
              backgroundColor: _kGreen1,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gradient background
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1B5E20),
                            Color(0xFF00796B),
                            Color(0xFF004D40),
                          ],
                          stops: [0.0, 0.6, 1.0],
                        ),
                      ),
                    ),
                    // Top-right decorative circle
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    // Bottom-left decorative circle
                    Positioned(
                      bottom: -20,
                      left: -20,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    // Header content
                    Positioned(
                      bottom: 60,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.moving_outlined,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _kGold,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _isAdmin ? 'ADMIN' : 'FARMER',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Export Hub',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            l.procurementDashboard,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  tooltip: l.notificationCenter,
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const NotificationsPage())),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  tooltip: 'More',
                  onSelected: (v) {
                    switch (v) {
                      case 'map':
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const NearbyFarmersMapPage()));
                      case 'nearby':
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const NearbyFarmersPage()));
                      case 'seller':
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l.pleaseSignInToViewSeller)));
                        } else {
                          Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => const SellerPurchaseOrderListPage()));
                        }
                      case 'buyer':
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l.pleaseSignInToViewOrders)));
                        } else if (_isAdmin) {
                          Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => const PurchaseOrderListPage(isAdmin: true)));
                        } else {
                          Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => const SellerPurchaseOrderListPage()));
                        }
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                        value: 'map',
                        child: Row(children: [
                          const Icon(Icons.map_outlined, size: 18),
                          const SizedBox(width: 10),
                          Text(l.openMap)
                        ])),
                    PopupMenuItem(
                        value: 'nearby',
                        child: Row(children: [
                          const Icon(Icons.people_outline, size: 18),
                          const SizedBox(width: 10),
                          Text(l.nearbyFarmersList)
                        ])),
                    if (!_isAdmin)
                      PopupMenuItem(
                          value: 'seller',
                          child: Row(children: [
                            const Icon(Icons.receipt_long_outlined, size: 18),
                            const SizedBox(width: 10),
                            Text(l.sellingOrders)
                          ])),
                    PopupMenuItem(
                        value: 'buyer',
                        child: Row(children: [
                          const Icon(Icons.shopping_bag_outlined, size: 18),
                          const SizedBox(width: 10),
                          Text(l.verifiedBuyersTab)
                        ])),
                  ],
                ),
              ],
            ),

            // ── Analytics Cards ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
                child: _AnalyticsRow(stats: _stats, loading: _statsLoading),
              ),
            ),

            // ── Role Banner ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: _RoleBanner(isAdmin: _isAdmin),
              ),
            ),

            // ── Operations Hub Grid ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: _OperationsHub(isAdmin: _isAdmin, user: user),
            ),

            // ── Section 0: My Listings (admin quick preview) ──────────────────
            if (_isAdmin && user != null) ...[
              const _SectionHeader(
                title: 'My Listings',
                icon: Icons.person_outline,
                onViewAll: null,
              ),
              SliverToBoxAdapter(
                child: _HorizontalProductScroll(
                  stream: _service.getMyExportProducts(user.uid),
                  emptyLabel: 'You have no listings yet. Tap + Add Listing to get started.',
                  onTap: (p) => _showDetail(context, p, user),
                ),
              ),
            ],

            // ── Admin-only sections: global marketplace view ───────────────────
            if (_isAdmin) ...[
              _SectionHeader(
                title: l.recentlyListedProduce,
                icon: Icons.new_releases_outlined,
                onViewAll: () => _showAllProducts(context, user),
              ),
              SliverToBoxAdapter(
                child: _HorizontalProductScroll(
                  stream: _service.streamRecentListings(limit: 10),
                  emptyLabel: l.noProcurementItems,
                  onTap: (p) => _showDetail(context, p, user),
                ),
              ),
              _SectionHeader(
                title: l.highQuantityListings,
                icon: Icons.inventory_2_outlined,
                onViewAll: () => _showAllProducts(context, user),
              ),
              SliverToBoxAdapter(
                child: _HorizontalProductScroll(
                  stream: _service.streamHighQuantityListings(limit: 10),
                  emptyLabel: l.noProcurementItems,
                  onTap: (p) => _showDetail(context, p, user),
                ),
              ),
              _SectionHeader(
                title: l.exportReadyProduce,
                icon: Icons.verified_outlined,
                onViewAll: () => _showAllProducts(context, user),
              ),
              SliverToBoxAdapter(
                child: _HorizontalProductScroll(
                  stream: _service.streamExportReadyListings(limit: 10),
                  emptyLabel: l.noProcurementItems,
                  onTap: (p) => _showDetail(context, p, user),
                ),
              ),
            ],

            // ── All Listings (admin: all products; farmer: own products only) ──
            _SectionHeader(
              title: _isAdmin ? l.cropsTab : 'My Listed Products',
              icon: Icons.local_florist_outlined,
              onViewAll: _isAdmin ? () => _showAllProducts(context, user) : null,
            ),
            SliverToBoxAdapter(
              child: _AllListingsView(
                service: _service,
                user: user,
                isAdmin: _isAdmin,
                onTap: (p) => _showDetail(context, p, user),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: _isAdmin
          ? null
          : FloatingActionButton(
              backgroundColor: _kGreen2,
              onPressed: () {
                if (user == null) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(l.pleaseSignInToAdd)));
                  return;
                }
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ExporterFormPage()));
              },
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
    );
  }

  void _showAllProducts(BuildContext context, User? user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _AllProductsSheet(service: _service, user: user),
    );
  }

  void _showDetail(BuildContext context, ExportProduct p, User? user) {
    final langCode = Localizations.localeOf(context).languageCode;
    final name = ContentTranslationService.translateCropName(p.productName, langCode);
    final loc = ContentTranslationService.translateLocation(p.location, langCode);
    final isOwner = user != null && p.sellerUid == user.uid;

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ProductDetailPage(
        product: p,
        translatedName: name,
        translatedLocation: loc,
        isOwner: isOwner,
        service: _service,
      ),
    ));
  }
}

// ── Role Banner ────────────────────────────────────────────────────────────────

class _RoleBanner extends StatelessWidget {
  final bool isAdmin;
  const _RoleBanner({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final color = isAdmin ? _kGreen2 : Colors.blue.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isAdmin ? Icons.admin_panel_settings_outlined : Icons.info_outline,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            isAdmin ? l.adminRoleBanner : l.procurementAdminNote,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Operations Hub ─────────────────────────────────────────────────────────────

class _OperationsHub extends StatelessWidget {
  final bool isAdmin;
  final User? user;
  const _OperationsHub({required this.isAdmin, required this.user});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    final tiles = <_OpTileData>[
      _OpTileData(
        icon: Icons.pending_actions_outlined,
        label: isAdmin ? 'All Orders' : 'Purchase Orders',
        color: Colors.orange,
        onTap: () {
          if (user == null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l.pleaseSignInToViewOrders)));
            return;
          }
          if (isAdmin) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PurchaseOrderListPage(isAdmin: true)));
          } else {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SellerPurchaseOrderListPage()));
          }
        },
      ),
      _OpTileData(
        icon: Icons.assignment_outlined,
        label: l.demandBoard,
        color: Colors.deepPurple,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => DemandBoardPage(isAdmin: isAdmin))),
      ),
      _OpTileData(
        icon: Icons.analytics_outlined,
        label: l.exportOperationsDashboard,
        color: Colors.indigo,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ExportOperationsDashboard())),
      ),
      if (isAdmin) ...[
        _OpTileData(
          icon: Icons.warehouse_outlined,
          label: l.warehouseDashboard,
          color: Colors.brown,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const WarehouseDashboard())),
        ),
        _OpTileData(
          icon: Icons.directions_boat_outlined,
          label: l.shipmentDashboard,
          color: Colors.blue,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ShipmentDashboard())),
        ),
        _OpTileData(
          icon: Icons.folder_outlined,
          label: l.exportDocuments,
          color: Colors.cyan,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ExportDocumentsPage())),
        ),
        _OpTileData(
          icon: Icons.people_alt_outlined,
          label: l.internationalBuyers,
          color: Colors.green,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const BuyersPage())),
        ),
        _OpTileData(
          icon: Icons.account_balance_outlined,
          label: l.financeDashboard,
          color: Colors.red,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const FinanceDashboard())),
        ),
        _OpTileData(
          icon: Icons.insights_outlined,
          label: l.aiInsights,
          color: Colors.amber.shade800,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AiInsightsPage())),
        ),
      ],
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            isAdmin ? 'Operations Hub' : 'Quick Access',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.0,
          children: tiles.map((t) => _OpTile(data: t)).toList(),
        ),
      ]),
    );
  }
}

class _OpTileData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _OpTileData(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
}

class _OpTile extends StatelessWidget {
  final _OpTileData data;
  const _OpTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shadowColor: data.color.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: data.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                data.color.withValues(alpha: 0.15),
                data.color.withValues(alpha: 0.05),
              ],
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: data.color.withValues(alpha: 0.2),
                child: Icon(data.icon, color: data.color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                data.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: data.color,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Analytics Row ──────────────────────────────────────────────────────────────

class _AnalyticsRow extends StatelessWidget {
  final Map<String, int> stats;
  final bool loading;
  const _AnalyticsRow({required this.stats, required this.loading});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cards = [
      (l.totalFarmers, stats['totalFarmers'] ?? 0, Icons.people_alt_outlined, Colors.teal),
      (l.activeListings, stats['activeListings'] ?? 0, Icons.inventory_outlined, Colors.indigo),
      (l.pendingPOs, stats['pendingPOs'] ?? 0, Icons.pending_actions_outlined, Colors.orange),
      (l.exportReadyCount, stats['exportReady'] ?? 0, Icons.verified_outlined, Colors.green),
    ];

    return Row(
      children: cards.map((c) {
        final (label, value, icon, color) = c;
        return Expanded(
          child: _StatCard(
            label: label,
            value: loading ? '—' : value.toString(),
            icon: icon,
            color: color,
          ),
        );
      }).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.04),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onViewAll;
  const _SectionHeader({required this.title, required this.icon, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    const primaryColor = _kGreen2;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 22, 12, 6),
        child: Row(children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 18, color: primaryColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (onViewAll != null)
            OutlinedButton(
              onPressed: onViewAll,
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: const BorderSide(color: primaryColor),
              ),
              child: Text(l.viewAll,
                  style: const TextStyle(fontSize: 12, color: primaryColor)),
            ),
        ]),
      ),
    );
  }
}

// ── Horizontal Product Scroll ──────────────────────────────────────────────────

class _HorizontalProductScroll extends StatelessWidget {
  final Stream<List<ExportProduct>> stream;
  final String emptyLabel;
  final void Function(ExportProduct) onTap;

  const _HorizontalProductScroll({
    required this.stream,
    required this.emptyLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ExportProduct>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, __) => const _ShimmerCard(),
            ),
          );
        }
        final products = snap.data ?? [];
        if (products.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Text(emptyLabel,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          );
        }
        return SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) => _ProcurementCard(
              product: products[i],
              onTap: () => onTap(products[i]),
            ),
          ),
        );
      },
    );
  }
}

class _ProcurementCard extends StatelessWidget {
  final ExportProduct product;
  final VoidCallback onTap;
  const _ProcurementCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final langCode = Localizations.localeOf(context).languageCode;
    final name = ContentTranslationService.translateCropName(product.productName, langCode);
    final loc = ContentTranslationService.translateLocation(product.location, langCode);
    final hasImage = product.primaryImage.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 175,
        child: Card(
          elevation: 4,
          shadowColor: Colors.black26,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image area with overlay
              SizedBox(
                height: 120,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'product-image-${product.id}',
                      child: hasImage
                          ? Image.network(
                              product.primaryImage,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _ImagePlaceholder(product: product),
                            )
                          : _ImagePlaceholder(product: product),
                    ),
                    // Gradient overlay
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                          ),
                        ),
                      ),
                    ),
                    // Price at bottom-left
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Text(
                        '₹${product.pricePerUnit}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    // Badges at top-right
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (product.isOrganic)
                            _Badge(label: l.organic, color: Colors.green),
                          if (product.isOrganic && (product.grade?.isNotEmpty ?? false))
                            const SizedBox(height: 3),
                          if (product.grade?.isNotEmpty ?? false)
                            _Badge(
                                label: '${l.grade} ${product.grade}',
                                color: Colors.indigo),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Info area
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(product.quantity,
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey)),
                    ]),
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          loc,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final ExportProduct product;
  const _ImagePlaceholder({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1B5E20),
            Color(0xFF00897B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.grain,
          size: 36,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surfaceContainerHighest;
    return SizedBox(
      width: 175,
      child: Card(
        elevation: 4,
        shadowColor: Colors.black26,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 120, color: bg),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                    height: 12,
                    width: 110,
                    decoration: BoxDecoration(
                        color: bg, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 6),
                Container(
                    height: 10,
                    width: 80,
                    decoration: BoxDecoration(
                        color: bg, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 4),
                Container(
                    height: 10,
                    width: 90,
                    decoration: BoxDecoration(
                        color: bg, borderRadius: BorderRadius.circular(4))),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ── All Listings View (search + filter) ────────────────────────────────────────

class _AllListingsView extends StatefulWidget {
  final ExporterService service;
  final User? user;
  final bool isAdmin;
  final void Function(ExportProduct) onTap;

  const _AllListingsView({
    required this.service,
    required this.user,
    required this.isAdmin,
    required this.onTap,
  });

  @override
  State<_AllListingsView> createState() => _AllListingsViewState();
}

class _AllListingsViewState extends State<_AllListingsView> {
  String _query = '';
  String _selectedCategory = 'all';
  final _categories = ['all', ...ExportCategories.all];

  List<ExportProduct> _filter(List<ExportProduct> all) {
    final q = _query.toLowerCase();
    return all.where((p) {
      if (_selectedCategory != 'all' &&
          p.category.toLowerCase() != _selectedCategory.toLowerCase()) {
        return false;
      }
      if (q.isEmpty) return true;
      return p.productName.toLowerCase().contains(q) ||
          p.farmerName.toLowerCase().contains(q) ||
          p.location.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: _kGreen2),
              hintText: l.searchByCropFarmer,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _kGreen2, width: 2),
              ),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        const SizedBox(height: 8),
        // Category filter chips
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final c = _categories[i];
              final label = c == 'all' ? l.cropsTab : c;
              final isSelected = c == _selectedCategory;
              return ChoiceChip(
                label: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? _kGreen2 : null,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                selectedColor: _kGreen2.withValues(alpha: 0.2),
                shape: const StadiumBorder(),
                onSelected: (_) => setState(() => _selectedCategory = c),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Products stream
        StreamBuilder<List<ExportProduct>>(
          stream: widget.isAdmin
              ? widget.service.getExportProducts()
              : (widget.user != null
                  ? widget.service.getMyExportProducts(widget.user!.uid)
                  : const Stream.empty()),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()));
            }
            final filtered = _filter(snap.data ?? []);
            if (filtered.isEmpty) {
              return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                      child: Text(widget.isAdmin
                          ? l.noExportProductsFound
                          : 'You have no listings yet. Tap + Add Listing to get started.')));
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: filtered
                  .map((p) => _ListingRow(
                        product: p,
                        user: widget.user,
                        onTap: () => widget.onTap(p),
                        onEdit: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ExporterFormPage(existingProduct: p))),
                        onDelete: () async {
                          final l2 = AppLocalizations.of(context)!;
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              title: Text(l2.deleteListingTitle),
                              content: Text(l2.areYouSureDeleteProduct),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogCtx, false),
                                    child: Text(l2.cancel)),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogCtx, true),
                                    child: Text(l2.delete,
                                        style: const TextStyle(
                                            color: Colors.redAccent))),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            await widget.service.deleteExportProduct(p.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(AppLocalizations.of(context)!
                                      .productDeletedSuccessfully)));
                            }
                          }
                        },
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ListingRow extends StatelessWidget {
  final ExportProduct product;
  final User? user;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ListingRow({
    required this.product,
    required this.user,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final langCode = Localizations.localeOf(context).languageCode;
    final name = ContentTranslationService.translateCropName(product.productName, langCode);
    final loc = ContentTranslationService.translateLocation(product.location, langCode);
    final isOwner = user != null && product.sellerUid == user!.uid;
    final hasImage = product.primaryImage.isNotEmpty;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 70,
                  height: 70,
                  child: hasImage
                      ? Image.network(product.primaryImage, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _ListingPlaceholder())
                      : _ListingPlaceholder(),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${product.pricePerUnit}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _kGreen2),
                    ),
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          loc,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      _QuantityChip(label: product.quantity),
                      if (product.grade?.isNotEmpty ?? false) ...[
                        const SizedBox(width: 4),
                        _Badge(
                            label: '${l.grade} ${product.grade}',
                            color: Colors.indigo),
                      ],
                    ]),
                  ],
                ),
              ),
              // Actions
              if (isOwner)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit,
                          size: 20, color: Colors.blue),
                      onPressed: onEdit,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(height: 4),
                    IconButton(
                      icon: const Icon(Icons.delete,
                          size: 20, color: Colors.red),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                )
              else if (product.grade?.isNotEmpty ?? false)
                _Badge(
                    label: '${AppLocalizations.of(context)!.grade} ${product.grade}',
                    color: Colors.indigo),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListingPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _kGreen1.withValues(alpha: 0.3),
            _kTeal.withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.local_florist, color: _kGreen2, size: 28),
      ),
    );
  }
}

class _QuantityChip extends StatelessWidget {
  final String label;
  const _QuantityChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      ),
    );
  }
}

// ── All Products Bottom Sheet ──────────────────────────────────────────────────

class _AllProductsSheet extends StatelessWidget {
  final ExporterService service;
  final User? user;
  const _AllProductsSheet({required this.service, required this.user});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 1.0,
      expand: false,
      builder: (_, controller) => Column(children: [
        const SizedBox(height: 8),
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 12),
        Text(l.cropsTab, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Divider(),
        Expanded(
          child: StreamBuilder<List<ExportProduct>>(
            stream: service.getExportProducts(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final products = snap.data ?? [];
              if (products.isEmpty) return Center(child: Text(l.noExportProductsFound));
              return ListView.builder(
                controller: controller,
                itemCount: products.length,
                itemBuilder: (_, i) => _ListingRow(
                  product: products[i],
                  user: user,
                  onTap: () {},
                  onEdit: () {},
                  onDelete: () {},
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ── Product Detail Page ────────────────────────────────────────────────────────

class ProductDetailPage extends StatelessWidget {
  final ExportProduct product;
  final String translatedName;
  final String translatedLocation;
  final bool isOwner;
  final ExporterService service;

  const ProductDetailPage({
    super.key,
    required this.product,
    required this.translatedName,
    required this.translatedLocation,
    required this.isOwner,
    required this.service,
  });

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final hasImage = product.primaryImage.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                translatedName,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)]),
              ),
              background: Hero(
                tag: 'product-image-${product.id}',
                child: hasImage
                    ? Image.network(product.primaryImage, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _PlaceholderBg())
                    : _PlaceholderBg(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price + category row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _kGreen2,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '₹${product.pricePerUnit}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            product.category,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Badges
                    if (product.isOrganic || (product.grade?.isNotEmpty ?? false)) ...[
                      Wrap(spacing: 6, children: [
                        if (product.isOrganic)
                          _Badge(label: l.organic, color: Colors.green),
                        if (product.grade?.isNotEmpty ?? false)
                          _Badge(
                              label: '${l.grade} ${product.grade}',
                              color: Colors.indigo),
                      ]),
                      const SizedBox(height: 10),
                    ],

                    const Divider(),

                    // Detail rows
                    _DetailRow(l.quantityLabel, product.quantity,
                        icon: Icons.inventory_2_outlined),
                    _DetailRow(l.locationLabel, translatedLocation,
                        icon: Icons.location_on_outlined),
                    _DetailRow(l.farmerLabel, product.farmerName,
                        icon: Icons.person_outline),
                    if (product.farmerMobile?.isNotEmpty ?? false)
                      _DetailRow(l.mobileLabel, product.farmerMobile!,
                          icon: Icons.phone_outlined),
                    if (product.variety?.isNotEmpty ?? false)
                      _DetailRow(l.varietyLabel, product.variety!,
                          icon: Icons.grass_outlined),
                    if (product.harvestDate != null)
                      _DetailRow(l.harvestDate, _fmt(product.harvestDate!),
                          icon: Icons.event_outlined),
                    if (product.moistureLevel?.isNotEmpty ?? false)
                      _DetailRow(l.moistureLevelLabel, product.moistureLevel!,
                          icon: Icons.water_drop_outlined),
                    if (product.storageLocation?.isNotEmpty ?? false)
                      _DetailRow(l.storageLocationLabel, product.storageLocation!,
                          icon: Icons.warehouse_outlined),
                    if (product.packagingType?.isNotEmpty ?? false)
                      _DetailRow(l.packagingTypeLabel, product.packagingType!,
                          icon: Icons.all_inbox_outlined),
                    if (product.minOrderQty?.isNotEmpty ?? false)
                      _DetailRow(l.minOrder, product.minOrderQty!,
                          icon: Icons.shopping_cart_outlined),
                    if (product.expectedPrice?.isNotEmpty ?? false)
                      _DetailRow(l.expectedPriceLabel, '₹${product.expectedPrice}',
                          icon: Icons.currency_rupee),

                    // Additional images gallery
                    if (product.imageUrls.length > 1) ...[
                      const SizedBox(height: 16),
                      Text(l.additionalImagesLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: product.imageUrls.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product.imageUrls[i],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                      ),
                    ],

                    if (product.description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(l.description,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(product.description),
                    ],

                    const SizedBox(height: 24),

                    // Action buttons
                    if (isOwner) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      ExporterFormPage(existingProduct: product))),
                          icon: const Icon(Icons.edit),
                          label: Text(l.edit),
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kGreen2,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Please sign in to place an order')));
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => CreatePurchaseOrderPage(
                                      listingData: product)),
                            );
                          },
                          icon: const Icon(Icons.shopping_cart_checkout),
                          label: const Text('Place Order',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1B5E20),
            Color(0xFF00897B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.grain,
          size: 64,
          color: Colors.white.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _DetailRow(this.label, this.value, {required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(right: 8),
          child: Icon(icon, size: 16, color: _kGreen2),
        ),
        SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ]),
    );
  }
}
