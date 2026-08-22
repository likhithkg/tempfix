// lib/exporter_hub/demand_board_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations.dart';
import '../services/content_translation_service.dart';

// ── Demand Board Page ──────────────────────────────────────────────────────────
// Admin posts export demand; farmers can indicate they can supply.

class DemandBoardPage extends StatefulWidget {
  final bool isAdmin;
  const DemandBoardPage({super.key, this.isAdmin = false});

  @override
  State<DemandBoardPage> createState() => _DemandBoardPageState();
}

class _DemandBoardPageState extends State<DemandBoardPage> {
  final _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.demandBoard),
        actions: [
          if (widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: l.postDemand,
              onPressed: () => _showCreateDemandSheet(context),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('export_demand')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(l.noDemandPostsYet,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return _DemandCard(
                demandId: docs[i].id,
                data: data,
                user: user,
                isAdmin: widget.isAdmin,
                db: _db,
              );
            },
          );
        },
      ),
      floatingActionButton: !widget.isAdmin && user != null
          ? null // Farmers use 'Respond' buttons on each card
          : null,
    );
  }

  void _showCreateDemandSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _CreateDemandSheet(),
    );
  }
}

// ── Create Demand Sheet ────────────────────────────────────────────────────────

class _CreateDemandSheet extends StatefulWidget {
  const _CreateDemandSheet();

  @override
  State<_CreateDemandSheet> createState() => _CreateDemandSheetState();
}

class _CreateDemandSheetState extends State<_CreateDemandSheet> {
  final _formKey = GlobalKey<FormState>();
  final _db = FirebaseFirestore.instance;

  final _cropCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _gradeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _unit = 'MT';
  DateTime? _deliveryDeadline;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _cropCtrl.dispose();
    _quantityCtrl.dispose();
    _gradeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    try {
      await _db.collection('export_demand').add({
        'crop': _cropCtrl.text.trim(),
        'quantity': '${_quantityCtrl.text.trim()} $_unit',
        'grade': _gradeCtrl.text.trim(),
        'deliveryDeadline': _deliveryDeadline?.toIso8601String(),
        'notes': _notesCtrl.text.trim(),
        'postedBy': user.uid,
        'postedByName': user.displayName ?? user.email ?? user.uid,
        'status': 'open',        // open | fulfilled | closed
        'responses': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.demandPosted)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text(l.postDemand, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              TextFormField(
                controller: _cropCtrl,
                decoration: InputDecoration(labelText: l.cropLabel, border: const OutlineInputBorder()),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(child: TextFormField(
                  controller: _quantityCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l.quantityLabel, border: const OutlineInputBorder()),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
                )),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _unit,
                  items: ['MT', 'ton', 'kg', 'quintal']
                      .map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (v) { if (v != null) setState(() => _unit = v); },
                ),
              ]),
              const SizedBox(height: 12),

              TextFormField(
                controller: _gradeCtrl,
                decoration: InputDecoration(
                    labelText: l.grade, border: const OutlineInputBorder(),
                    hintText: 'e.g. A, Grade 1, Export quality'),
              ),
              const SizedBox(height: 12),

              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _deliveryDeadline ?? DateTime.now().add(const Duration(days: 14)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _deliveryDeadline = picked);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                      labelText: l.deliveryWindowLabel, border: const OutlineInputBorder()),
                  child: Text(
                    _deliveryDeadline != null
                        ? '${_deliveryDeadline!.day}/${_deliveryDeadline!.month}/${_deliveryDeadline!.year}'
                        : 'Tap to select deadline',
                    style: TextStyle(color: _deliveryDeadline != null ? null : Colors.grey.shade500),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                    labelText: l.additionalNotes, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _isSubmitting
                      ? const SizedBox(height: 18, width: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(l.postDemand,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Demand Card ────────────────────────────────────────────────────────────────

class _DemandCard extends StatefulWidget {
  final String demandId;
  final Map<String, dynamic> data;
  final User? user;
  final bool isAdmin;
  final FirebaseFirestore db;

  const _DemandCard({
    required this.demandId,
    required this.data,
    required this.user,
    required this.isAdmin,
    required this.db,
  });

  @override
  State<_DemandCard> createState() => _DemandCardState();
}

class _DemandCardState extends State<_DemandCard> {
  bool _responding = false;

  bool get _hasResponded {
    final uid = widget.user?.uid;
    if (uid == null) return false;
    final responses = widget.data['responses'] as List? ?? [];
    return responses.any((r) => r is Map && r['farmerId'] == uid);
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'open': return Colors.green;
      case 'fulfilled': return Colors.blue;
      case 'closed': return Colors.grey;
      default: return Colors.orange;
    }
  }

  Future<void> _respond(BuildContext context) async {
    final user = widget.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSignInToPerformAction)));
      return;
    }

    // Show response sheet
    final l = AppLocalizations.of(context)!;
    final farmerNameCtrl = TextEditingController(text: user.displayName ?? '');
    final phoneCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final quantityCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.respondToDemand, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: farmerNameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Your Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Phone Number', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationCtrl,
                decoration: const InputDecoration(
                    labelText: 'Location (Village / District)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: l.canSupplyQty, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                    labelText: l.additionalNotes, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    setState(() => _responding = true);
                    try {
                      await widget.db.collection('export_demand').doc(widget.demandId).update({
                        'responses': FieldValue.arrayUnion([
                          {
                            'farmerId': user.uid,
                            'farmerName': farmerNameCtrl.text.trim().isNotEmpty
                                ? farmerNameCtrl.text.trim()
                                : (user.displayName ?? user.email ?? user.uid),
                            'farmerPhone': phoneCtrl.text.trim(),
                            'farmerLocation': locationCtrl.text.trim(),
                            'canSupplyQty': quantityCtrl.text.trim(),
                            'notes': notesCtrl.text.trim(),
                            'respondedAt': DateTime.now().toIso8601String(),
                          }
                        ]),
                      });
                      if (context.mounted) Navigator.pop(context);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context)!.responseSubmitted)));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    } finally {
                      if (mounted) setState(() => _responding = false);
                      farmerNameCtrl.dispose();
                      phoneCtrl.dispose();
                      locationCtrl.dispose();
                      quantityCtrl.dispose();
                      notesCtrl.dispose();
                    }
                  },
                  child: Text(l.submitResponse),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final langCode = Localizations.localeOf(context).languageCode;
    final status = (widget.data['status'] ?? 'open').toString();
    final crop = ContentTranslationService.translateCropName(
        (widget.data['crop'] ?? '').toString(), langCode);
    final quantity = (widget.data['quantity'] ?? '').toString();
    final grade = (widget.data['grade'] ?? '').toString();
    final deadline = widget.data['deliveryDeadline']?.toString() ?? '';
    final notes = (widget.data['notes'] ?? '').toString();
    final postedBy = (widget.data['postedByName'] ?? 'Admin').toString();
    final responses = (widget.data['responses'] as List? ?? []);
    final statusColor = _statusColor(status);

    String deadlineDisplay = '';
    if (deadline.isNotEmpty) {
      final dt = DateTime.tryParse(deadline);
      if (dt != null) deadlineDisplay = '${dt.day}/${dt.month}/${dt.year}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              Expanded(
                child: Text(crop,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor),
                ),
                child: Text(status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ]),
            const SizedBox(height: 8),

            // Details chips
            Wrap(spacing: 12, runSpacing: 6, children: [
              _InfoChip(Icons.inventory_2_outlined, quantity),
              if (grade.isNotEmpty) _InfoChip(Icons.verified_outlined, 'Grade: $grade'),
              if (deadlineDisplay.isNotEmpty) _InfoChip(Icons.event_outlined, l.byDate(deadlineDisplay)),
            ]),

            if (notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(notes, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],

            const SizedBox(height: 8),
            Text('${l.postedByLabel}: $postedBy',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),

            // Responses summary
            if (responses.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(l.farmersResponded(responses.length),
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
            ],

            // Admin: expand responses
            if (widget.isAdmin && responses.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              Text(l.farmerResponses, style: const TextStyle(fontWeight: FontWeight.bold)),
              ...responses.map((r) {
                if (r is! Map) return const SizedBox.shrink();
                final rName = (r['farmerName'] ?? 'Farmer').toString();
                final rPhone = (r['farmerPhone'] ?? '').toString();
                final rLocation = (r['farmerLocation'] ?? '').toString();
                final rQty = (r['canSupplyQty'] ?? '').toString();
                final rNotes = (r['notes'] ?? '').toString();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.person, size: 15),
                          const SizedBox(width: 6),
                          Text(rName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ]),
                        if (rPhone.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(children: [
                            const Icon(Icons.phone, size: 14),
                            const SizedBox(width: 6),
                            Text(rPhone, style: const TextStyle(fontSize: 13)),
                          ]),
                        ],
                        if (rLocation.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(children: [
                            const Icon(Icons.location_on, size: 14),
                            const SizedBox(width: 6),
                            Text(rLocation, style: const TextStyle(fontSize: 13)),
                          ]),
                        ],
                        if (rQty.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(children: [
                            const Icon(Icons.inventory_2_outlined, size: 14),
                            const SizedBox(width: 6),
                            Text('Can supply: $rQty', style: const TextStyle(fontSize: 13)),
                          ]),
                        ],
                        if (rNotes.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(rNotes, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 12),

            // Action buttons
            Row(children: [
              if (!widget.isAdmin && status == 'open') ...[
                _hasResponded
                    ? Row(children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 4),
                        Text(l.alreadyResponded, style: const TextStyle(color: Colors.green, fontSize: 13)),
                      ])
                    : ElevatedButton.icon(
                        onPressed: _responding ? null : () => _respond(context),
                        icon: const Icon(Icons.send, size: 16),
                        label: Text(l.respond),
                      ),
              ],
              if (widget.isAdmin && status == 'open') ...[
                OutlinedButton.icon(
                  onPressed: () async {
                    await widget.db
                        .collection('export_demand')
                        .doc(widget.demandId)
                        .update({'status': 'fulfilled'});
                  },
                  icon: const Icon(Icons.done_all, size: 16),
                  label: Text(l.markFulfilled),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () async {
                    await widget.db
                        .collection('export_demand')
                        .doc(widget.demandId)
                        .update({'status': 'closed'});
                  },
                  icon: const Icon(Icons.close, size: 16, color: Colors.red),
                  label: Text(l.closeDemand, style: const TextStyle(color: Colors.red)),
                ),
              ],
            ]),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ]);
  }
}
