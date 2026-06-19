// lib/exporter_hub/shipment_dashboard.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'shipment_model.dart';
import 'shipment_detail_page.dart';
import 'role_service.dart';
import '../l10n/app_localizations.dart';

class ShipmentDashboard extends StatefulWidget {
  const ShipmentDashboard({super.key});

  @override
  State<ShipmentDashboard> createState() => _ShipmentDashboardState();
}

class _ShipmentDashboardState extends State<ShipmentDashboard> {
  final _db = FirebaseFirestore.instance;
  String _userRole = 'farmer';

  @override
  void initState() {
    super.initState();
    RoleService.streamCurrentRole().listen((r) {
      if (mounted) setState(() => _userRole = r);
    });
  }

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

  String _statusLabel(String s, AppLocalizations l) {
    switch (s) {
      case 'ready_for_export': return l.statusReadyForExport;
      case 'packed': return l.shipStatusPacked;
      case 'container_loaded': return l.shipStatusContainerLoaded;
      case 'customs_cleared': return l.shipStatusCustomsCleared;
      case 'shipped': return l.shipStatusShipped;
      case 'delivered': return l.shipStatusDelivered;
      default: return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isAdmin = RoleService.isAdmin(_userRole);

    return Scaffold(
      appBar: AppBar(title: Text(l.shipmentDashboard)),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('shipments').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.directions_boat_outlined, size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text(l.noShipmentsYet,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ]),
            );
          }

          // Summary bar
          final byStatus = <String, int>{};
          for (final doc in docs) {
            final s = (doc.data() as Map<String, dynamic>)['status']?.toString() ?? '';
            byStatus[s] = (byStatus[s] ?? 0) + 1;
          }

          return Column(children: [
            // Status summary chips
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: Shipment.statusFlow.map((s) {
                  final count = byStatus[s] ?? 0;
                  if (count == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text('$count ${_statusLabel(s, l)}',
                          style: const TextStyle(fontSize: 12)),
                      backgroundColor: _statusColor(s).withValues(alpha: 0.12),
                      side: BorderSide(color: _statusColor(s)),
                    ),
                  );
                }).toList(),
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final ship = Shipment.fromMap(docs[i].id, data);
                  final color = _statusColor(ship.status);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ShipmentDetailPage(shipment: ship, isAdmin: isAdmin))),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            const Icon(Icons.directions_boat_outlined, size: 18),
                            const SizedBox(width: 6),
                            Expanded(child: Text(ship.shipmentId,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: color)),
                              child: Text(_statusLabel(ship.status, l),
                                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          Wrap(spacing: 16, runSpacing: 4, children: [
                            _Chip(Icons.flag_outlined, ship.destinationCountry),
                            _Chip(Icons.person_outline, ship.buyerName),
                            if (ship.containerNumber.isNotEmpty)
                              _Chip(Icons.view_in_ar_outlined, ship.containerNumber),
                            _Chip(Icons.scale_outlined, '${ship.totalWeight.toStringAsFixed(0)} kg'),
                            _Chip(Icons.currency_rupee, '₹${(ship.totalValue / 1000).toStringAsFixed(1)}K'),
                          ]),
                          if (ship.etd != null || ship.eta != null) ...[
                            const SizedBox(height: 6),
                            Wrap(spacing: 16, children: [
                              if (ship.etd != null)
                                _Chip(Icons.flight_takeoff, 'ETD: ${ship.etd!.day}/${ship.etd!.month}/${ship.etd!.year}'),
                              if (ship.eta != null)
                                _Chip(Icons.flight_land, 'ETA: ${ship.eta!.day}/${ship.eta!.month}/${ship.eta!.year}'),
                            ]),
                          ],
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ]);
        },
      ),
      floatingActionButton: RoleService.isAdmin(_userRole)
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const _CreateShipmentPage())),
              icon: const Icon(Icons.add),
              label: Text(l.createShipment),
            )
          : null,
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ]);
  }
}

// ── Create Shipment Page ──────────────────────────────────────────────────────

class _CreateShipmentPage extends StatefulWidget {
  const _CreateShipmentPage();

  @override
  State<_CreateShipmentPage> createState() => _CreateShipmentPageState();
}

class _CreateShipmentPageState extends State<_CreateShipmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _db = FirebaseFirestore.instance;

  final _buyerCtrl = TextEditingController();
  final _buyerEmailCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _containerCtrl = TextEditingController();
  final _shippingLineCtrl = TextEditingController();
  final _polCtrl = TextEditingController();
  final _podCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime? _etd;
  DateTime? _eta;
  bool _submitting = false;

  // Products list
  final List<Map<String, dynamic>> _products = [];

  @override
  void dispose() {
    _buyerCtrl.dispose(); _buyerEmailCtrl.dispose(); _countryCtrl.dispose();
    _containerCtrl.dispose(); _shippingLineCtrl.dispose(); _polCtrl.dispose();
    _podCtrl.dispose(); _weightCtrl.dispose(); _valueCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final shipment = Shipment(
        id: '',
        shipmentId: Shipment.generateShipmentId(),
        containerNumber: _containerCtrl.text.trim(),
        destinationCountry: _countryCtrl.text.trim(),
        buyerName: _buyerCtrl.text.trim(),
        buyerEmail: _buyerEmailCtrl.text.trim(),
        shippingLine: _shippingLineCtrl.text.trim(),
        portOfLoading: _polCtrl.text.trim(),
        portOfDischarge: _podCtrl.text.trim(),
        etd: _etd,
        eta: _eta,
        status: 'ready_for_export',
        products: _products,
        totalWeight: double.tryParse(_weightCtrl.text.trim()) ?? 0,
        totalValue: double.tryParse(_valueCtrl.text.trim()) ?? 0,
        createdBy: user?.uid,
        notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      );
      await _db.collection('shipments').add(shipment.toMap());
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.shipmentCreated)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickDate(BuildContext context, bool isEtd) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => isEtd ? _etd = picked : _eta = picked);
  }

  String _fmtDate(DateTime? d) => d != null ? '${d.day}/${d.month}/${d.year}' : '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.createShipment)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_buyerCtrl, l.buyerNameLabel),
            _field(_buyerEmailCtrl, l.emailLabel, keyboardType: TextInputType.emailAddress),
            _field(_countryCtrl, l.destinationCountry),
            _field(_containerCtrl, l.containerNumber, required: false),
            _field(_shippingLineCtrl, l.shippingLine),
            _field(_polCtrl, l.portOfLoading),
            _field(_podCtrl, l.portOfDischarge),
            const SizedBox(height: 12),

            Row(children: [
              Expanded(child: InkWell(
                onTap: () => _pickDate(context, true),
                child: InputDecorator(
                  decoration: InputDecoration(labelText: l.etdLabel, border: const OutlineInputBorder()),
                  child: Text(_etd != null ? _fmtDate(_etd) : l.tapToSelect,
                      style: TextStyle(color: _etd != null ? null : Colors.grey)),
                ),
              )),
              const SizedBox(width: 12),
              Expanded(child: InkWell(
                onTap: () => _pickDate(context, false),
                child: InputDecorator(
                  decoration: InputDecoration(labelText: l.etaLabel, border: const OutlineInputBorder()),
                  child: Text(_eta != null ? _fmtDate(_eta) : l.tapToSelect,
                      style: TextStyle(color: _eta != null ? null : Colors.grey)),
                ),
              )),
            ]),
            const SizedBox(height: 12),

            _field(_weightCtrl, l.totalWeight, keyboardType: TextInputType.number),
            _field(_valueCtrl, l.totalValue, keyboardType: TextInputType.number),
            _field(_notesCtrl, l.additionalNotes, required: false, maxLines: 2),
            const SizedBox(height: 24),

            // Products summary
            Text(l.products, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._products.map((p) => ListTile(
                  dense: true,
                  title: Text(p['productName']?.toString() ?? ''),
                  subtitle: Text('${p['quantity']} ${p['unit']} • Grade ${p['grade'] ?? 'N/A'}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _products.remove(p)),
                  ),
                )),
            TextButton.icon(
              onPressed: () => _showAddProduct(context),
              icon: const Icon(Icons.add),
              label: Text(l.addProduct),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _submitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l.createShipment, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {TextInputType? keyboardType, bool required = true, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: required ? (v) => v!.trim().isEmpty ? 'Required' : null : null,
      ),
    );
  }

  void _showAddProduct(BuildContext context) {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    String unit = 'kg';
    String? grade;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) {
        final l = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(l.addProduct),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl,
                decoration: InputDecoration(labelText: l.cropLabel, border: const OutlineInputBorder())),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l.quantityLabel, border: const OutlineInputBorder()))),
              const SizedBox(width: 8),
              DropdownButton<String>(value: unit,
                  items: ['kg', 'MT', 'ton'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (v) { if (v != null) setS(() => unit = v); }),
            ]),
            const SizedBox(height: 8),
            DropdownButton<String?>(value: grade,
                hint: Text(l.grade),
                items: [null, 'A', 'B', 'C'].map((g) =>
                    DropdownMenuItem(value: g, child: Text(g ?? 'None'))).toList(),
                onChanged: (v) => setS(() => grade = v)),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                setState(() {
                  _products.add({
                    'productName': nameCtrl.text.trim(),
                    'quantity': double.tryParse(qtyCtrl.text.trim()) ?? 0,
                    'unit': unit,
                    'grade': grade,
                  });
                });
                nameCtrl.dispose();
                qtyCtrl.dispose();
                Navigator.pop(ctx);
              },
              child: Text(l.addProduct),
            ),
          ],
        );
      }),
    );
  }
}
