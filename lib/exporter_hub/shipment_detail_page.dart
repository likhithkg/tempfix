// lib/exporter_hub/shipment_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'shipment_model.dart';
import '../l10n/app_localizations.dart';

class ShipmentDetailPage extends StatelessWidget {
  final Shipment shipment;
  final bool isAdmin;
  const ShipmentDetailPage({super.key, required this.shipment, required this.isAdmin});

  static const _statusLabels = {
    'ready_for_export': 'Ready for Export',
    'packed': 'Packed',
    'container_loaded': 'Container Loaded',
    'customs_cleared': 'Customs Cleared',
    'shipped': 'Shipped',
    'delivered': 'Delivered',
  };

  Color _statusColor(String s) {
    switch (s) {
      case 'ready_for_export': return Colors.amber;
      case 'packed': return Colors.blue;
      case 'container_loaded': return Colors.indigo;
      case 'customs_cleared': return Colors.teal;
      case 'shipped': return Colors.green;
      case 'delivered': return Colors.green.shade800;
      default: return Colors.grey;
    }
  }

  String _fmtDate(DateTime? d) => d != null ? '${d.day}/${d.month}/${d.year}' : '—';

  Future<void> _advanceStatus(BuildContext context, Shipment ship) async {
    final idx = Shipment.statusFlow.indexOf(ship.status);
    if (idx < 0 || idx >= Shipment.statusFlow.length - 1) return;
    final nextStatus = Shipment.statusFlow[idx + 1];
    await FirebaseFirestore.instance
        .collection('shipments')
        .doc(ship.id)
        .update({'status': nextStatus});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status → ${_statusLabels[nextStatus] ?? nextStatus}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final statusColor = _statusColor(shipment.status);
    final currentIdx = Shipment.statusFlow.indexOf(shipment.status);
    final isLast = currentIdx >= Shipment.statusFlow.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(shipment.shipmentId),
        actions: [
          if (isAdmin && !isLast)
            TextButton.icon(
              onPressed: () => _advanceStatus(context, shipment),
              icon: const Icon(Icons.arrow_forward),
              label: Text(l.advance),
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('shipments')
            .doc(shipment.id)
            .snapshots(),
        builder: (context, snap) {
          final data = snap.hasData && snap.data!.exists
              ? snap.data!.data() as Map<String, dynamic>
              : shipment.toMap();
          final live = Shipment.fromMap(shipment.id, data);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Status chip ──
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor, width: 1.5)),
                  child: Text(_statusLabels[live.status] ?? live.status,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),

              // ── Timeline ──
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: Shipment.statusFlow.length,
                  itemBuilder: (_, i) {
                    final s = Shipment.statusFlow[i];
                    final liveIdx = Shipment.statusFlow.indexOf(live.status);
                    final isDone = i < liveIdx;
                    final isCurrent = i == liveIdx;
                    final color = isCurrent ? _statusColor(s) : (isDone ? Colors.green : Colors.grey.shade300);
                    return Row(mainAxisSize: MainAxisSize.min, children: [
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone ? Colors.green : (isCurrent ? color : Colors.transparent),
                            border: Border.all(color: color, width: 2),
                          ),
                          child: isDone
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : (isCurrent ? const Icon(Icons.circle, size: 10, color: Colors.white) : null),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 68,
                          child: Text((_statusLabels[s] ?? s),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 9,
                                  color: isCurrent ? color : Colors.grey,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                        ),
                      ]),
                      if (i < Shipment.statusFlow.length - 1)
                        Container(width: 20, height: 2,
                            color: isDone ? Colors.green : Colors.grey.shade300),
                    ]);
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),

              // ── Details ──
              Text(l.shipmentDetails, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _Row(l.buyerNameLabel, live.buyerName),
              _Row(l.destinationCountry, live.destinationCountry),
              if (live.containerNumber.isNotEmpty) _Row(l.containerNumber, live.containerNumber),
              _Row(l.shippingLine, live.shippingLine),
              _Row(l.portOfLoading, live.portOfLoading),
              _Row(l.portOfDischarge, live.portOfDischarge),
              _Row(l.etdLabel, _fmtDate(live.etd)),
              _Row(l.etaLabel, _fmtDate(live.eta)),
              _Row(l.totalWeight, '${live.totalWeight.toStringAsFixed(0)} kg'),
              _Row(l.totalValue, '₹${live.totalValue.toStringAsFixed(2)}'),
              if (live.notes?.isNotEmpty ?? false) _Row(l.additionalNotes, live.notes!),
              const SizedBox(height: 20),

              // ── Packing List ──
              Text(l.packingList, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...live.products.map((p) => Card(
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.eco_outlined),
                      title: Text(p['productName']?.toString() ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text('${p['quantity']} ${p['unit']} • Grade ${p['grade'] ?? 'N/A'}'),
                    ),
                  )),
              if (live.products.isEmpty)
                Text(l.noProductsInShipment,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),

              const SizedBox(height: 20),

              // ── Export Value Calculator ──
              Card(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.exportValueSummary,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    _Row(l.totalWeight, '${live.totalWeight.toStringAsFixed(0)} kg'),
                    _Row(l.totalValue, '₹${live.totalValue.toStringAsFixed(0)}'),
                    if (live.totalWeight > 0)
                      _Row(l.valuePerKg,
                          '₹${(live.totalValue / live.totalWeight).toStringAsFixed(2)}/kg'),
                  ]),
                ),
              ),
              const SizedBox(height: 40),
            ]),
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 140, child: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ]),
    );
  }
}
