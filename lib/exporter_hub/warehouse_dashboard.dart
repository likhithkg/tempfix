// lib/exporter_hub/warehouse_dashboard.dart
import 'package:flutter/material.dart';
import 'warehouse_service.dart';
import 'warehouse_model.dart';
import 'warehouse_stock_page.dart';
import 'warehouse_transaction_page.dart';
import '../l10n/app_localizations.dart';

class WarehouseDashboard extends StatelessWidget {
  const WarehouseDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final svc = WarehouseService();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.warehouseDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: l.stockMovementHistory,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const WarehouseTransactionPage())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Summary Cards ──
              StreamBuilder<Map<String, double>>(
                stream: svc.streamStockSummary(),
                builder: (context, snap) {
                  final data = snap.data ?? {};
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.0,
                    children: [
                      _SummaryCard(
                        label: l.incomingStock,
                        value: '${(data['incoming'] ?? 0).toStringAsFixed(0)} kg',
                        color: Colors.blue,
                        icon: Icons.download_outlined,
                      ),
                      _SummaryCard(
                        label: l.availableStock,
                        value: '${(data['available'] ?? 0).toStringAsFixed(0)} kg',
                        color: Colors.green,
                        icon: Icons.inventory_2_outlined,
                      ),
                      _SummaryCard(
                        label: l.reservedStock,
                        value: '${(data['reserved'] ?? 0).toStringAsFixed(0)} kg',
                        color: Colors.orange,
                        icon: Icons.lock_outline,
                      ),
                      _SummaryCard(
                        label: l.exportedStock,
                        value: '${(data['exported'] ?? 0).toStringAsFixed(0)} kg',
                        color: Colors.teal,
                        icon: Icons.flight_takeoff,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // ── Sections ──
              _SectionButton(
                icon: Icons.download_outlined,
                label: l.incomingStock,
                color: Colors.blue,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => WarehouseStockPage(filterStatus: 'incoming'))),
              ),
              const SizedBox(height: 8),
              _SectionButton(
                icon: Icons.inventory_2_outlined,
                label: l.availableStock,
                color: Colors.green,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => WarehouseStockPage(filterStatus: 'available'))),
              ),
              const SizedBox(height: 8),
              _SectionButton(
                icon: Icons.lock_outline,
                label: l.reservedStock,
                color: Colors.orange,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => WarehouseStockPage(filterStatus: 'reserved'))),
              ),
              const SizedBox(height: 8),
              _SectionButton(
                icon: Icons.flight_takeoff,
                label: l.exportedStock,
                color: Colors.teal,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => WarehouseStockPage(filterStatus: 'exported'))),
              ),
              const SizedBox(height: 8),
              _SectionButton(
                icon: Icons.list_alt_outlined,
                label: l.allStock,
                color: Colors.indigo,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const WarehouseStockPage())),
              ),

              const SizedBox(height: 24),

              // ── Recent Transactions ──
              Text(l.recentTransactions,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              StreamBuilder<List<WarehouseTransaction>>(
                stream: svc.streamTransactions(limit: 5),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final txs = snap.data ?? [];
                  if (txs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(l.noTransactionsYet,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    );
                  }
                  return Column(
                    children: txs.map((tx) => _TransactionTile(tx: tx)).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStockSheet(context, svc),
        icon: const Icon(Icons.add),
        label: Text(l.addStock),
      ),
    );
  }

  void _showAddStockSheet(BuildContext context, WarehouseService svc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddStockSheet(svc: svc),
    );
  }
}

// ── Summary Card ───────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _SummaryCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          )),
        ]),
      ),
    );
  }
}

// ── Section Button ─────────────────────────────────────────────────────────────

class _SectionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SectionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

// ── Transaction Tile ───────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final dynamic tx;
  const _TransactionTile({required this.tx});

  Color _txColor(String type) {
    switch (type) {
      case 'received': return Colors.green;
      case 'dispatched': return Colors.red;
      case 'reserved': return Colors.orange;
      case 'adjusted': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _txIcon(String type) {
    switch (type) {
      case 'received': return Icons.add_circle_outline;
      case 'dispatched': return Icons.remove_circle_outline;
      case 'reserved': return Icons.lock_outline;
      case 'adjusted': return Icons.edit_outlined;
      default: return Icons.swap_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = tx.transactionType as String;
    final color = _txColor(type);
    final qty = tx.quantity as double;
    final sign = (type == 'received') ? '+' : (type == 'dispatched' ? '-' : '');
    final dt = tx.createdAt as DateTime;

    return ListTile(
      leading: Icon(_txIcon(type), color: color),
      title: Text(tx.cropName, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text('${tx.batchId} • $type'),
      trailing: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('$sign${qty.toStringAsFixed(0)} ${tx.unit}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        Text('${dt.day}/${dt.month}', style: const TextStyle(fontSize: 11)),
      ]),
    );
  }
}

// ── Add Stock Sheet ────────────────────────────────────────────────────────────

class _AddStockSheet extends StatefulWidget {
  final WarehouseService svc;
  const _AddStockSheet({required this.svc});

  @override
  State<_AddStockSheet> createState() => _AddStockSheetState();
}

class _AddStockSheetState extends State<_AddStockSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cropCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _moistureCtrl = TextEditingController();

  String _unit = 'kg';
  String _status = 'incoming';
  String? _grade;
  bool _isOrganic = false;
  DateTime _receivedDate = DateTime.now();
  DateTime? _expiryDate;
  bool _submitting = false;

  @override
  void dispose() {
    _cropCtrl.dispose(); _qtyCtrl.dispose(); _locationCtrl.dispose();
    _notesCtrl.dispose(); _moistureCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final cropName = _cropCtrl.text.trim();
      final batchId = 'B${DateTime.now().millisecondsSinceEpoch}';
      final lotNumber = WarehouseService.generateLotNumber(cropName);
      final stock = WarehouseStock(
        id: '',
        batchId: batchId,
        cropName: cropName,
        category: 'Other',
        quantity: double.tryParse(_qtyCtrl.text.trim()) ?? 0,
        unit: _unit,
        warehouseLocation: _locationCtrl.text.trim(),
        lotNumber: lotNumber,
        receivedDate: _receivedDate,
        expiryDate: _expiryDate,
        status: _status,
        grade: _grade,
        isOrganic: _isOrganic,
        moistureLevel: double.tryParse(_moistureCtrl.text.trim()),
        notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      );
      await widget.svc.addStock(stock);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.stockAdded)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(l.addStock, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            TextFormField(controller: _cropCtrl,
                decoration: InputDecoration(labelText: l.cropLabel, border: const OutlineInputBorder()),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null),
            const SizedBox(height: 12),

            Row(children: [
              Expanded(child: TextFormField(controller: _qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l.quantityLabel, border: const OutlineInputBorder()),
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null)),
              const SizedBox(width: 8),
              DropdownButton<String>(value: _unit,
                  items: ['kg', 'MT', 'ton', 'quintal'].map((u) =>
                      DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (v) { if (v != null) setState(() => _unit = v); }),
            ]),
            const SizedBox(height: 12),

            TextFormField(controller: _locationCtrl,
                decoration: InputDecoration(labelText: l.warehouseLocation, border: const OutlineInputBorder()),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _status,
              decoration: InputDecoration(labelText: l.statusLabel, border: const OutlineInputBorder()),
              items: ['incoming', 'available', 'reserved']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) { if (v != null) setState(() => _status = v); },
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String?>(
              value: _grade,
              decoration: InputDecoration(labelText: l.grade, border: const OutlineInputBorder()),
              items: [null, 'A', 'B', 'C'].map((g) =>
                  DropdownMenuItem(value: g, child: Text(g ?? 'None'))).toList(),
              onChanged: (v) => setState(() => _grade = v),
            ),
            const SizedBox(height: 8),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.organic),
              value: _isOrganic,
              onChanged: (v) => setState(() => _isOrganic = v),
            ),

            TextFormField(controller: _moistureCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l.moistureLevelLabel, border: const OutlineInputBorder())),
            const SizedBox(height: 12),

            TextFormField(controller: _notesCtrl, maxLines: 2,
                decoration: InputDecoration(labelText: l.additionalNotes, border: const OutlineInputBorder())),
            const SizedBox(height: 20),

            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _submitting
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l.addStock, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }
}
