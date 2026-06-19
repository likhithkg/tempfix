// lib/exporter_hub/warehouse_stock_page.dart
import 'package:flutter/material.dart';
import 'warehouse_service.dart';
import 'warehouse_model.dart';
import '../l10n/app_localizations.dart';

class WarehouseStockPage extends StatefulWidget {
  final String? filterStatus;
  const WarehouseStockPage({super.key, this.filterStatus});

  @override
  State<WarehouseStockPage> createState() => _WarehouseStockPageState();
}

class _WarehouseStockPageState extends State<WarehouseStockPage> {
  final _svc = WarehouseService();
  String _search = '';

  Color _statusColor(String s) {
    switch (s) {
      case 'incoming': return Colors.blue;
      case 'available': return Colors.green;
      case 'reserved': return Colors.orange;
      case 'exported': return Colors.teal;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final title = widget.filterStatus != null
        ? '${widget.filterStatus![0].toUpperCase()}${widget.filterStatus!.substring(1)} ${l.stock}'
        : l.allStock;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l.searchByCropFarmer,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<WarehouseStock>>(
              stream: _svc.streamStock(status: widget.filterStatus),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                var items = snap.data ?? [];
                if (_search.isNotEmpty) {
                  items = items.where((s) =>
                      s.cropName.toLowerCase().contains(_search) ||
                      s.lotNumber.toLowerCase().contains(_search) ||
                      s.batchId.toLowerCase().contains(_search) ||
                      s.warehouseLocation.toLowerCase().contains(_search)).toList();
                }
                if (items.isEmpty) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.inventory_2_outlined, size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(l.noStockFound,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ]),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final s = items[i];
                    final color = _statusColor(s.status);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(s.cropName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: color),
                              ),
                              child: Text(s.status.toUpperCase(),
                                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ]),
                          const SizedBox(height: 6),
                          Wrap(spacing: 16, children: [
                            _InfoItem(Icons.numbers, 'Lot: ${s.lotNumber}'),
                            _InfoItem(Icons.inventory_2_outlined,
                                '${s.quantity.toStringAsFixed(1)} ${s.unit}'),
                            _InfoItem(Icons.location_on_outlined, s.warehouseLocation),
                          ]),
                          const SizedBox(height: 4),
                          Wrap(spacing: 16, children: [
                            _InfoItem(Icons.calendar_today_outlined,
                                'Rcv: ${s.receivedDate.day}/${s.receivedDate.month}/${s.receivedDate.year}'),
                            if (s.expiryDate != null)
                              _InfoItem(Icons.event_busy_outlined,
                                  'Exp: ${s.expiryDate!.day}/${s.expiryDate!.month}/${s.expiryDate!.year}'),
                            if (s.grade != null) _InfoItem(Icons.verified_outlined, 'Grade ${s.grade}'),
                            if (s.isOrganic) _InfoItem(Icons.eco_outlined, 'Organic'),
                          ]),
                          if (s.notes?.isNotEmpty ?? false) ...[
                            const SizedBox(height: 4),
                            Text(s.notes!, style: TextStyle(
                                fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ],
                          const SizedBox(height: 8),
                          // Status action buttons
                          if (s.status == 'incoming')
                            TextButton.icon(
                              onPressed: () async {
                                await _svc.updateStockStatus(s.id, 'available');
                              },
                              icon: const Icon(Icons.check_circle_outline, size: 16),
                              label: Text(l.markAvailable),
                            ),
                        ]),
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
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoItem(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ]);
  }
}
