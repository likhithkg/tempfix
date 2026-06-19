// lib/exporter_hub/finance_dashboard.dart
// Procurement Finance Dashboard — tracks procurement value, farmer payments,
// shipment revenue, and margins. All computed from Firestore streams.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations.dart';

class FinanceDashboard extends StatefulWidget {
  const FinanceDashboard({super.key});

  @override
  State<FinanceDashboard> createState() => _FinanceDashboardState();
}

class _FinanceDashboardState extends State<FinanceDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.financeDashboard),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: [
            Tab(text: l.monthly),
            Tab(text: l.quarterly),
            Tab(text: l.yearly),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('purchase_orders').snapshots(),
        builder: (context, poSnap) {
          return StreamBuilder<QuerySnapshot>(
            stream: _db.collection('shipments').snapshots(),
            builder: (context, shipSnap) {
              final pos = poSnap.data?.docs ?? [];
              final ships = shipSnap.data?.docs ?? [];

              // ── Aggregate totals ──
              double totalProcurement = 0;
              double pendingPayments = 0;
              double paidPayments = 0;

              for (final doc in pos) {
                final data = doc.data() as Map<String, dynamic>;
                final amount = (data['totalAmount'] ?? data['amount'] as num? ?? 0).toDouble();
                final payStatus = data['paymentStatus']?.toString() ?? 'pending';
                totalProcurement += amount;
                if (payStatus == 'paid') {
                  paidPayments += amount;
                } else {
                  pendingPayments += amount;
                }
              }

              double shipmentRevenue = 0;
              for (final doc in ships) {
                final data = doc.data() as Map<String, dynamic>;
                shipmentRevenue += (data['totalValue'] as num? ?? 0).toDouble();
              }

              final grossMargin = shipmentRevenue - totalProcurement;
              final grossMarginPct = shipmentRevenue > 0
                  ? (grossMargin / shipmentRevenue * 100) : 0.0;

              return TabBarView(
                controller: _tabCtrl,
                children: [
                  _FinanceView(
                    period: l.monthly,
                    totalProcurement: totalProcurement,
                    pendingPayments: pendingPayments,
                    paidPayments: paidPayments,
                    shipmentRevenue: shipmentRevenue,
                    grossMargin: grossMargin,
                    grossMarginPct: grossMarginPct,
                    pos: pos,
                    ships: ships,
                    db: _db,
                  ),
                  _FinanceView(
                    period: l.quarterly,
                    totalProcurement: totalProcurement,
                    pendingPayments: pendingPayments,
                    paidPayments: paidPayments,
                    shipmentRevenue: shipmentRevenue,
                    grossMargin: grossMargin,
                    grossMarginPct: grossMarginPct,
                    pos: pos,
                    ships: ships,
                    db: _db,
                  ),
                  _FinanceView(
                    period: l.yearly,
                    totalProcurement: totalProcurement,
                    pendingPayments: pendingPayments,
                    paidPayments: paidPayments,
                    shipmentRevenue: shipmentRevenue,
                    grossMargin: grossMargin,
                    grossMarginPct: grossMarginPct,
                    pos: pos,
                    ships: ships,
                    db: _db,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _FinanceView extends StatelessWidget {
  final String period;
  final double totalProcurement;
  final double pendingPayments;
  final double paidPayments;
  final double shipmentRevenue;
  final double grossMargin;
  final double grossMarginPct;
  final List<QueryDocumentSnapshot> pos;
  final List<QueryDocumentSnapshot> ships;
  final FirebaseFirestore db;

  const _FinanceView({
    required this.period,
    required this.totalProcurement,
    required this.pendingPayments,
    required this.paidPayments,
    required this.shipmentRevenue,
    required this.grossMargin,
    required this.grossMarginPct,
    required this.pos,
    required this.ships,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isPositive = grossMargin >= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$period ${l.overview}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.0,
          children: [
            _FinTile(l.totalProcurementValue, '₹${_fmt(totalProcurement)}', Colors.indigo,
                Icons.shopping_cart_outlined),
            _FinTile(l.pendingPayments, '₹${_fmt(pendingPayments)}', Colors.orange,
                Icons.pending_outlined),
            _FinTile(l.paidPayments, '₹${_fmt(paidPayments)}', Colors.green,
                Icons.check_circle_outline),
            _FinTile(l.shipmentRevenue, '₹${_fmt(shipmentRevenue)}', Colors.teal,
                Icons.flight_takeoff_outlined),
            _FinTile(l.grossMargin,
                '${isPositive ? '+' : ''}₹${_fmt(grossMargin)}',
                isPositive ? Colors.green : Colors.red,
                Icons.trending_up_outlined),
            _FinTile(l.grossMarginPct,
                '${grossMarginPct.toStringAsFixed(1)}%',
                isPositive ? Colors.teal : Colors.orange,
                Icons.percent_outlined),
          ],
        ),

        const SizedBox(height: 24),

        // Payment status bar chart
        Text(l.paymentBreakdown, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        if (totalProcurement > 0) ...[
          _PaymentBar(l.paidPayments, paidPayments, totalProcurement, Colors.green),
          const SizedBox(height: 6),
          _PaymentBar(l.pendingPayments, pendingPayments, totalProcurement, Colors.orange),
        ] else
          Text(l.noDataYet, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),

        const SizedBox(height: 24),

        // Recent POs with amounts
        Text(l.recentPOs, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        ...pos.take(5).map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = (data['totalAmount'] ?? data['amount'] as num? ?? 0).toDouble();
          final status = data['status']?.toString() ?? '';
          final buyer = data['buyerName']?.toString() ?? data['ownerName']?.toString() ?? '';
          return ListTile(
            dense: true,
            leading: const Icon(Icons.receipt_outlined, size: 18),
            title: Text(buyer.isNotEmpty ? buyer : doc.id.substring(0, 8),
                style: const TextStyle(fontSize: 13)),
            subtitle: Text(status),
            trailing: Text('₹${_fmt(amount)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          );
        }),
      ]),
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _FinTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _FinTile(this.label, this.value, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          )),
        ]),
      ),
    );
  }
}

class _PaymentBar extends StatelessWidget {
  final String label;
  final double value;
  final double total;
  final Color color;
  const _PaymentBar(this.label, this.value, this.total, this.color);

  @override
  Widget build(BuildContext context) {
    final frac = total > 0 ? (value / total).clamp(0.0, 1.0) : 0.0;
    final pct = (frac * 100).round();
    return Row(children: [
      SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 12))),
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: frac,
          minHeight: 14,
          backgroundColor: color.withValues(alpha: 0.12),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      )),
      const SizedBox(width: 8),
      Text('$pct%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    ]);
  }
}
