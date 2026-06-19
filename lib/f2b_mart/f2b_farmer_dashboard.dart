// lib/f2b_mart/f2b_farmer_dashboard.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../exporter_hub/exporter_model.dart';
import '../exporter_hub/exporter_service.dart';
import '../exporter_hub/exporter_form_page.dart';
import '../exporter_hub/po_detail_page.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../services/content_translation_service.dart';
import 'f2b_product_detail_page.dart';

class F2BFarmerDashboard extends StatefulWidget {
  const F2BFarmerDashboard({super.key});

  @override
  State<F2BFarmerDashboard> createState() => _F2BFarmerDashboardState();
}

class _F2BFarmerDashboardState extends State<F2BFarmerDashboard>
    with SingleTickerProviderStateMixin {
  final _svc = ExporterService();
  late final TabController _tab;

  // Streams for stats derivation
  List<ExportProduct> _myListings = [];
  List<Map<String, dynamic>> _myOrders = [];
  StreamSubscription? _listingsSub;
  StreamSubscription? _ordersSub;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    final uid = _uid;
    if (uid != null) {
      _listingsSub = _svc.getMyExportProducts(uid).listen((list) {
        if (mounted) setState(() => _myListings = list);
      });
      _ordersSub = _svc.streamPOsForFarmer(uid).listen((orders) {
        if (mounted) setState(() => _myOrders = orders);
      });
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    _listingsSub?.cancel();
    _ordersSub?.cancel();
    super.dispose();
  }

  // ── Derived stats ──────────────────────────────────────────────────────────

  int get _activeListings => _myListings.length;

  int get _pendingOrders => _myOrders
      .where((o) => ['issued', 'pending'].contains(
          (o['status'] as String? ?? '').toLowerCase()))
      .length;

  double get _totalEarned => _myOrders
      .where((o) =>
          (o['status'] as String? ?? '').toLowerCase() == 'completed')
      .fold(0.0, (sum, o) {
        final v = o['totalAmount'];
        return sum + (v is num ? v.toDouble() : double.tryParse('$v') ?? 0);
      });

  // ── Delete listing ─────────────────────────────────────────────────────────

  Future<void> _deleteListing(
      BuildContext ctx, AppLocalizations l, ExportProduct p) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l.deleteListing),
        content: Text(l.deleteListingConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text(l.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style:
                  TextButton.styleFrom(foregroundColor: KMColors.error),
              child: Text(l.delete)),
        ],
      ),
    );
    if (confirmed != true) return;
    await _svc.deleteExportProduct(p.id);
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx)
          .showSnackBar(SnackBar(content: Text(l.listingDeleted)));
    }
  }

  // ── Counter Offer ──────────────────────────────────────────────────────────

  void _showCounterOffer(
      BuildContext ctx, AppLocalizations l, String poId) {
    final priceCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool submitting = false;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (_, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(l.makeCounterOffer,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: priceCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l.counterOfferPrice,
                    prefixText: '₹ ',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final n = double.tryParse(
                        v?.replaceAll(RegExp(r'[^\d.]'), '') ?? '');
                    if (n == null || n <= 0) return l.enterValidOfferPrice;
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: submitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setSheet(() => submitting = true);
                            final price = double.parse(priceCtrl.text
                                .replaceAll(RegExp(r'[^\d.]'), ''));
                            await _svc.addCounterOffer(poId, {
                              'price': price,
                              'byFarmerId': _uid,
                              'note': 'Counter offer from farmer',
                            });
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text(l.counterOfferSent)));
                            }
                          },
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: submitting
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(l.submitOffer,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Quick status update ────────────────────────────────────────────────────

  Future<void> _updateStatus(
      BuildContext ctx, AppLocalizations l, String poId, String status) async {
    final uid = _uid;
    if (uid == null) return;
    await _svc.updatePOStatus(poId, status, uid);
    if (ctx.mounted) {
      final msg = status == 'accepted' ? l.orderAccepted : l.orderRejected;
      ScaffoldMessenger.of(ctx)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_uid == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.farmerDashboard)),
        body: Center(child: Text(l.pleaseSignInToPerformAction)),
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? KMColors.backgroundDark : const Color(0xFFF0F7F0),
      appBar: AppBar(
        title: Text(l.farmerDashboard),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(icon: const Icon(Icons.inventory_2_outlined, size: 18),
                text: l.myListingsTab),
            Tab(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 18),
                  if (_pendingOrders > 0)
                    Positioned(
                      right: -6, top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle),
                        child: Text('$_pendingOrders',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                ],
              ),
              text: l.incomingOrders,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const ExporterFormPage()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(l.addListing),
      ),
      body: Column(
        children: [
          // ── Stats row ───────────────────────────────────────────────
          _StatsRow(
            activeListings: _activeListings,
            pendingOrders: _pendingOrders,
            totalEarned: _totalEarned,
            l: l,
          ),
          // ── Tab views ───────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _ListingsTab(
                  listings: _myListings,
                  l: l,
                  onEdit: (p) => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ExporterFormPage(existingProduct: p)),
                  ),
                  onDelete: (p) => _deleteListing(context, l, p),
                  onTap: (p) => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => F2BProductDetailPage(product: p)),
                  ),
                ),
                _OrdersTab(
                  orders: _myOrders,
                  l: l,
                  onView: (poId) => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PODetailPage(poId: poId)),
                  ),
                  onAccept: (poId) =>
                      _updateStatus(context, l, poId, 'accepted'),
                  onReject: (poId) =>
                      _updateStatus(context, l, poId, 'rejected'),
                  onCounterOffer: (poId) =>
                      _showCounterOffer(context, l, poId),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats row ─────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int activeListings;
  final int pendingOrders;
  final double totalEarned;
  final AppLocalizations l;
  const _StatsRow({
    required this.activeListings,
    required this.pendingOrders,
    required this.totalEarned,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? KMColors.surfaceDark : Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(children: [
        Expanded(
          child: _StatChip(
            icon: Icons.inventory_2_outlined,
            iconColor: KMColors.primary,
            label: l.activeListings,
            value: '$activeListings',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            icon: Icons.pending_outlined,
            iconColor: const Color(0xFFF57F17),
            label: l.pendingOrders,
            value: '$pendingOrders',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            icon: Icons.currency_rupee_rounded,
            iconColor: const Color(0xFF1565C0),
            label: l.totalEarned,
            value: totalEarned >= 1000
                ? '₹${(totalEarned / 1000).toStringAsFixed(1)}k'
                : '₹${totalEarned.toStringAsFixed(0)}',
          ),
        ),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _StatChip({
    required this.icon, required this.iconColor,
    required this.label, required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? KMColors.cardDark
            : const Color(0xFFF0F7F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 10, color: KMColors.textSecondary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ]),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: iconColor)),
      ]),
    );
  }
}

// ─── Listings tab ──────────────────────────────────────────────────────────

class _ListingsTab extends StatelessWidget {
  final List<ExportProduct> listings;
  final AppLocalizations l;
  final void Function(ExportProduct) onEdit;
  final void Function(ExportProduct) onDelete;
  final void Function(ExportProduct) onTap;
  const _ListingsTab({
    required this.listings, required this.l,
    required this.onEdit, required this.onDelete, required this.onTap,
  });

  Color _accent(String cat) {
    switch (cat.toLowerCase()) {
      case 'fruits':     return const Color(0xFFD84315);
      case 'vegetables': return const Color(0xFF2E7D32);
      case 'grains':     return const Color(0xFFF57F17);
      case 'spices':     return const Color(0xFFAD1457);
      case 'pulses':     return const Color(0xFF6D4C41);
      case 'crops':      return const Color(0xFF1565C0);
      default:           return KMColors.primaryDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;
    if (listings.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.inventory_2_outlined,
              size: 64, color: KMColors.textSecondary),
          const SizedBox(height: 12),
          Text(l.noListingsYet,
              style: const TextStyle(
                  fontSize: 15, color: KMColors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded),
            label: Text(l.addListing),
          ),
        ]),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      itemCount: listings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final p = listings[i];
        final accent = _accent(p.category);
        final name = ContentTranslationService.translateCropName(
            p.productName, langCode);
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return GestureDetector(
          onTap: () => onTap(p),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? KMColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: KMShadow.card,
            ),
            child: Row(children: [
              // Thumbnail
              ClipRRect(
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(14)),
                child: SizedBox(
                  width: 90, height: 90,
                  child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                      ? Image.network(p.imageUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _placeholder(accent))
                      : _placeholder(accent),
                ),
              ),
              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            ContentTranslationService
                                .translateExportCategory(
                                    p.category, langCode),
                            style: TextStyle(
                                fontSize: 9,
                                color: accent,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text(name,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(
                          '₹${p.pricePerUnit}  ·  ${p.quantity}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: KMColors.primary)),
                    ],
                  ),
                ),
              ),
              // Actions column
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: l.editListing,
                    icon: const Icon(Icons.edit_outlined,
                        color: KMColors.primary, size: 20),
                    onPressed: () => onEdit(p),
                  ),
                  IconButton(
                    tooltip: l.deleteListing,
                    icon: const Icon(Icons.delete_outline,
                        color: KMColors.error, size: 20),
                    onPressed: () => onDelete(p),
                  ),
                ],
              ),
              const SizedBox(width: 4),
            ]),
          ),
        );
      },
    );
  }

  Widget _placeholder(Color accent) => Container(
    color: accent.withValues(alpha: 0.12),
    child: Center(child: Icon(Icons.agriculture_rounded, size: 36,
        color: accent.withValues(alpha: 0.5))),
  );
}

// ─── Orders tab ────────────────────────────────────────────────────────────

class _OrdersTab extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final AppLocalizations l;
  final void Function(String poId) onView;
  final void Function(String poId) onAccept;
  final void Function(String poId) onReject;
  final void Function(String poId) onCounterOffer;
  const _OrdersTab({
    required this.orders, required this.l,
    required this.onView, required this.onAccept,
    required this.onReject, required this.onCounterOffer,
  });

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'completed': return const Color(0xFF2E7D32);
      case 'accepted':  return const Color(0xFF1565C0);
      case 'rejected':  return KMColors.error;
      case 'cancelled': return Colors.grey;
      default:          return const Color(0xFFF57F17);
    }
  }

  String _statusLabel(AppLocalizations l, String s) {
    switch (s.toLowerCase()) {
      case 'pending':   return l.statusPending;
      case 'approved':  return l.statusApproved;
      case 'rejected':  return l.statusRejected;
      case 'accepted':  return l.statusAccepted;
      case 'confirmed': return l.statusConfirmed;
      case 'completed': return l.statusCompleted;
      case 'cancelled': return l.statusCancelled;
      case 'issued':    return l.statusIssued;
      default:          return s;
    }
  }

  String _formatTs(dynamic ts) {
    try {
      if (ts == null) return '—';
      DateTime dt;
      if (ts is DateTime) {
        dt = ts;
      } else {
        final t = ts as dynamic;
        dt = t.toDate();
      }
      const m = ['Jan','Feb','Mar','Apr','May','Jun',
                  'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${m[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (orders.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.receipt_long_outlined,
              size: 64, color: KMColors.textSecondary),
          const SizedBox(height: 12),
          Text(l.noIncomingOrders,
              style: const TextStyle(
                  fontSize: 15, color: KMColors.textSecondary)),
        ]),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final o = orders[i];
        final poId = o['id'] as String? ?? '';
        final status = (o['status'] as String? ?? 'issued').toLowerCase();
        final statusColor = _statusColor(status);
        final total = o['totalAmount'];
        final totalStr = total != null ? '₹$total' : '—';
        final buyerName = o['buyerName'] as String? ?? '—';
        final createdAt = _formatTs(o['createdAt']);

        final isNegotiation = () {
          final pt = o['paymentTerms'];
          if (pt is Map) return pt['isNegotiation'] == true;
          return false;
        }();
        final offeredPrice = () {
          final pt = o['paymentTerms'];
          if (pt is Map) {
            final v = pt['offeredPricePerUnit'];
            return v != null ? '₹$v' : null;
          }
          return null;
        }();

        final isActionable =
            ['issued', 'pending'].contains(status);

        return Container(
          decoration: BoxDecoration(
            color: isDark ? KMColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: KMShadow.card,
            border: isNegotiation && isActionable
                ? Border.all(
                    color: const Color(0xFFF57F17).withValues(alpha: 0.5),
                    width: 1.5)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 0),
                child: Row(children: [
                  // PO ID + buyer
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${poId.length > 8 ? poId.substring(0, 8).toUpperCase() : poId.toUpperCase()}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: KMColors.textSecondary,
                              letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 2),
                        Text(buyerName,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(_statusLabel(l, status),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor)),
                  ),
                ]),
              ),

              // Amount + date row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(children: [
                  Text(totalStr,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: KMColors.primary)),
                  const SizedBox(width: 10),
                  const Icon(Icons.calendar_today_outlined,
                      size: 12, color: KMColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(createdAt,
                      style: const TextStyle(
                          fontSize: 12, color: KMColors.textSecondary)),
                  const Spacer(),
                  // Negotiation badge
                  if (isNegotiation) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF57F17)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(l.negotiationOffer,
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF57F17))),
                    ),
                  ],
                ]),
              ),

              // Buyer offered price (negotiation only)
              if (isNegotiation && offeredPrice != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  child: Row(children: [
                    const Icon(Icons.price_change_outlined,
                        size: 14, color: Color(0xFFF57F17)),
                    const SizedBox(width: 6),
                    Text('${l.buyerOfferedPrice}: $offeredPrice',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF57F17))),
                  ]),
                ),

              const Divider(height: 1),

              // Action buttons
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(children: [
                  // View details
                  TextButton.icon(
                    onPressed: () => onView(poId),
                    icon: const Icon(Icons.open_in_new_rounded, size: 14),
                    label: Text(l.viewOrderDetails,
                        style: const TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4)),
                  ),
                  const Spacer(),
                  if (isActionable) ...[
                    // Accept
                    _ActionBtn(
                      label: l.accept,
                      color: KMColors.primary,
                      onPressed: () => onAccept(poId),
                    ),
                    const SizedBox(width: 6),
                    // Counter offer (negotiation only)
                    if (isNegotiation) ...[
                      _ActionBtn(
                        label: l.makeCounterOffer,
                        color: const Color(0xFFF57F17),
                        onPressed: () => onCounterOffer(poId),
                      ),
                      const SizedBox(width: 6),
                    ],
                    // Reject
                    _ActionBtn(
                      label: l.reject,
                      color: KMColors.error,
                      onPressed: () => onReject(poId),
                    ),
                  ],
                ]),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;
  const _ActionBtn({
    required this.label, required this.color, required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
