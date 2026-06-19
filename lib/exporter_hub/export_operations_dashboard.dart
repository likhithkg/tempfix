// lib/exporter_hub/export_operations_dashboard.dart
// Export Operations Dashboard — procurement metrics and charts using only
// Flutter's CustomPainter (no external charting package needed).

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'role_service.dart';
import '../l10n/app_localizations.dart';
import '../services/content_translation_service.dart';

class ExportOperationsDashboard extends StatelessWidget {
  const ExportOperationsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DashboardBody();
  }
}

class _DashboardBody extends StatefulWidget {
  const _DashboardBody();

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  final _db = FirebaseFirestore.instance;
  String _userRole = 'farmer';

  @override
  void initState() {
    super.initState();
    RoleService.streamCurrentRole().listen((r) {
      if (mounted) setState(() => _userRole = r);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.exportOperationsDashboard),
        actions: [
          if (RoleService.isAdmin(_userRole))
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.primary)),
                  child: Text(l.adminRole,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Metrics Row 1: overall stats ──
              StreamBuilder<QuerySnapshot>(
                stream: _db.collection('export_products').snapshots(),
                builder: (context, prodSnap) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: _db.collection('purchase_orders').snapshots(),
                    builder: (context, poSnap) {
                      final products = prodSnap.data?.docs ?? [];
                      final pos = poSnap.data?.docs ?? [];

                      final farmerIds = products
                          .map((d) => (d.data() as Map<String, dynamic>)['farmerId']?.toString() ?? '')
                          .where((id) => id.isNotEmpty)
                          .toSet();

                      final exportedPOs = pos.where((d) {
                        final s = ((d.data() as Map<String, dynamic>)['status'] ?? '').toString();
                        return ['exported', 'completed'].contains(s);
                      }).length;

                      final pendingQC = pos.where((d) {
                        final s = ((d.data() as Map<String, dynamic>)['status'] ?? '').toString();
                        return s == 'qc_pending';
                      }).length;

                      double totalValue = 0;
                      for (final po in pos) {
                        final data = po.data() as Map<String, dynamic>;
                        final v = data['totalAmount'];
                        if (v is num) totalValue += v.toDouble();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.procurementOverview,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 2.2,
                            children: [
                              _MetricTile(
                                icon: Icons.people_alt_outlined, color: Colors.teal,
                                label: l.totalFarmers, value: farmerIds.length.toString()),
                              _MetricTile(
                                icon: Icons.inventory_outlined, color: Colors.indigo,
                                label: l.activeListings, value: products.length.toString()),
                              _MetricTile(
                                icon: Icons.science_outlined, color: Colors.purple,
                                label: l.pendingQC, value: pendingQC.toString()),
                              _MetricTile(
                                icon: Icons.flight_takeoff, color: Colors.green,
                                label: l.totalExported, value: exportedPOs.toString()),
                              _MetricTile(
                                icon: Icons.receipt_long_outlined, color: Colors.orange,
                                label: l.totalPOs, value: pos.length.toString()),
                              _MetricTile(
                                icon: Icons.currency_rupee, color: Colors.blue,
                                label: l.totalProcurementValue,
                                value: '₹${(totalValue / 1000).toStringAsFixed(1)}K'),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 24),

              // ── Crop-wise Procurement Chart ──
              StreamBuilder<QuerySnapshot>(
                stream: _db.collection('export_products').snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snap.data!.docs;

                  // Count by category
                  final Map<String, int> catCounts = {};
                  for (final doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final cat = (data['category'] ?? 'Other').toString();
                    catCounts[cat] = (catCounts[cat] ?? 0) + 1;
                  }

                  return _CategoryBarChart(
                    title: l.cropWiseProcurement,
                    data: catCounts,
                  );
                },
              ),

              const SizedBox(height: 24),

              // ── PO Status Breakdown ──
              StreamBuilder<QuerySnapshot>(
                stream: _db.collection('purchase_orders').snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox.shrink();
                  final docs = snap.data!.docs;

                  final Map<String, int> statusCounts = {};
                  for (final doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = (data['status'] ?? 'listed').toString();
                    statusCounts[status] = (statusCounts[status] ?? 0) + 1;
                  }

                  return _StatusPieDonut(
                    title: l.poStatusBreakdown,
                    data: statusCounts,
                  );
                },
              ),

              const SizedBox(height: 24),

              // ── Top Districts ──
              StreamBuilder<QuerySnapshot>(
                stream: _db.collection('export_products').snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox.shrink();
                  final docs = snap.data!.docs;
                  final langCode = Localizations.localeOf(context).languageCode;

                  final Map<String, int> districtCounts = {};
                  for (final doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final loc = (data['location'] ?? '').toString().trim();
                    if (loc.isEmpty) continue;
                    // use first component as district
                    final district = loc.split(',').first.trim();
                    final translated = ContentTranslationService.translateLocation(district, langCode);
                    districtCounts[translated] = (districtCounts[translated] ?? 0) + 1;
                  }

                  // Top 5 districts
                  final top = districtCounts.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));
                  final topFive = top.take(5).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.topDistricts,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...topFive.map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: _DistrictRow(district: e.key, count: e.value,
                                max: topFive.isNotEmpty ? topFive.first.value : 1),
                          )),
                      if (topFive.isEmpty)
                        Text(l.noDataYet,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  );
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Metric Tile ────────────────────────────────────────────────────────────────

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _MetricTile({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              Text(label,
                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          )),
        ]),
      ),
    );
  }
}

// ── Category Bar Chart ─────────────────────────────────────────────────────────

class _CategoryBarChart extends StatelessWidget {
  final String title;
  final Map<String, int> data;
  const _CategoryBarChart({required this.title, required this.data});

  static const _catColors = {
    'Vegetables': Color(0xFF2E7D32),
    'Fruits': Color(0xFFD84315),
    'Grains': Color(0xFFF57F17),
    'Spices': Color(0xFFAD1457),
    'Crops': Color(0xFF1565C0),
    'Other': Color(0xFF6D4C41),
  };

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final max = data.values.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...data.entries.map((e) {
          final color = _catColors[e.key] ?? Colors.blueGrey;
          final fraction = max > 0 ? e.value / max : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              SizedBox(
                width: 80,
                child: Text(e.key, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 18,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )),
              const SizedBox(width: 8),
              Text(e.value.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ]),
          );
        }),
      ],
    );
  }
}

// ── PO Status Donut Chart ──────────────────────────────────────────────────────

class _StatusPieDonut extends StatelessWidget {
  final String title;
  final Map<String, int> data;
  const _StatusPieDonut({required this.title, required this.data});

  Color _colorForStatus(String s) {
    switch (s) {
      case 'exported': return Colors.green.shade700;
      case 'qc_approved': return Colors.green;
      case 'qc_rejected': return Colors.red;
      case 'farmer_accepted': return Colors.blue;
      case 'collected': return Colors.teal;
      case 'po_issued': return Colors.indigo;
      case 'listed': return Colors.teal.shade300;
      case 'under_review': return Colors.amber;
      case 'rejected': return Colors.red.shade300;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final total = data.values.fold(0, (a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: CustomPaint(painter: _DonutPainter(data: data, colorForStatus: _colorForStatus)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: data.entries.map((e) {
                  final pct = total > 0 ? (e.value / total * 100).round() : 0;
                  return Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(
                        color: _colorForStatus(e.key), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text('${e.key} ($pct%)', style: const TextStyle(fontSize: 11)),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final Map<String, int> data;
  final Color Function(String) colorForStatus;

  const _DonutPainter({required this.data, required this.colorForStatus});

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.values.fold(0, (a, b) => a + b);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeW = 28.0;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeW / 2);

    double startAngle = -3.14159 / 2;
    for (final e in data.entries) {
      final sweep = (e.value / total) * 3.14159 * 2;
      final paint = Paint()
        ..color = colorForStatus(e.key)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW;
      canvas.drawArc(rect, startAngle, sweep - 0.04, false, paint);
      startAngle += sweep;
    }

    // Center: draw total count
    final tp2 = TextPainter(
      text: TextSpan(text: total.toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp2.paint(canvas, Offset(center.dx - tp2.width / 2, center.dy - tp2.height / 2));
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.data != data;
}

// ── District Row ───────────────────────────────────────────────────────────────

class _DistrictRow extends StatelessWidget {
  final String district;
  final int count;
  final int max;
  const _DistrictRow({required this.district, required this.count, required this.max});

  @override
  Widget build(BuildContext context) {
    final fraction = max > 0 ? count / max : 0.0;
    return Row(children: [
      SizedBox(
        width: 100,
        child: Text(district, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
      ),
      const SizedBox(width: 8),
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: fraction,
          minHeight: 14,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
        ),
      )),
      const SizedBox(width: 8),
      Text(count.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
    ]);
  }
}
