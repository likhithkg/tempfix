// lib/exporter_hub/export_documents_page.dart
// Document management for export workflow: generate/track document status.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';

// Document types in an export workflow
const List<_DocType> _kDocTypes = [
  _DocType('commercial_invoice', 'Commercial Invoice', Icons.receipt_long_outlined),
  _DocType('packing_list', 'Packing List', Icons.list_alt_outlined),
  _DocType('purchase_order', 'Purchase Order', Icons.shopping_bag_outlined),
  _DocType('qc_certificate', 'QC Certificate', Icons.verified_outlined),
  _DocType('certificate_of_origin', 'Certificate of Origin', Icons.flag_outlined),
  _DocType('phytosanitary', 'Phytosanitary Certificate', Icons.eco_outlined),
  _DocType('shipping_instructions', 'Shipping Instructions', Icons.directions_boat_outlined),
  _DocType('bill_of_lading', 'Bill of Lading Reference', Icons.description_outlined),
];

class _DocType {
  final String key;
  final String label;
  final IconData icon;
  const _DocType(this.key, this.label, this.icon);
}

class ExportDocumentsPage extends StatefulWidget {
  final String? shipmentId; // optional: scoped to a shipment
  const ExportDocumentsPage({super.key, this.shipmentId});

  @override
  State<ExportDocumentsPage> createState() => _ExportDocumentsPageState();
}

class _ExportDocumentsPageState extends State<ExportDocumentsPage> {
  final _db = FirebaseFirestore.instance;

  Query get _query {
    var q = _db.collection('export_documents').orderBy('createdAt', descending: true);
    if (widget.shipmentId != null) {
      q = _db.collection('export_documents')
          .where('shipmentId', isEqualTo: widget.shipmentId)
          .orderBy('createdAt', descending: true);
    }
    return q;
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'draft': return Colors.grey;
      case 'pending_review': return Colors.orange;
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'submitted': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _docIcon(String type) {
    for (final dt in _kDocTypes) {
      if (dt.key == type) return dt.icon;
    }
    return Icons.description_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l.exportDocuments)),
      body: StreamBuilder<QuerySnapshot>(
        stream: _query.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.folder_open_outlined, size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text(l.noDocumentsYet,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _showCreateSheet(context),
                  icon: const Icon(Icons.add),
                  label: Text(l.addDocument),
                ),
              ]),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final docId = docs[i].id;
              final type = data['documentType']?.toString() ?? '';
              final status = data['status']?.toString() ?? 'draft';
              final title = data['title']?.toString() ?? type;
              final notes = data['notes']?.toString() ?? '';
              final createdAt = data['createdAt'];
              String dateStr = '';
              if (createdAt is Timestamp) {
                final dt = createdAt.toDate();
                dateStr = '${dt.day}/${dt.month}/${dt.year}';
              }

              final statusColor = _statusColor(status);

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(_docIcon(type), size: 20,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor)),
                        child: Text(status.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(color: statusColor, fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ]),
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(notes, style: TextStyle(
                          fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                    if (dateStr.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(dateStr, style: TextStyle(fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, children: [
                      // Status advancement buttons (admin only for approve/reject)
                      if (status == 'draft')
                        OutlinedButton.icon(
                          onPressed: () => _updateStatus(docId, 'pending_review'),
                          icon: const Icon(Icons.send, size: 14),
                          label: Text(l.submitForReview, style: const TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 32)),
                        ),
                      if (status == 'pending_review') ...[
                        OutlinedButton.icon(
                          onPressed: () => _updateStatus(docId, 'approved'),
                          icon: const Icon(Icons.check_circle_outline, size: 14),
                          label: Text(l.approve, style: const TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 32)),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _updateStatus(docId, 'rejected'),
                          icon: const Icon(Icons.cancel_outlined, size: 14),
                          label: Text(l.reject, style: const TextStyle(fontSize: 12, color: Colors.red)),
                          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 32)),
                        ),
                      ],
                      if (status == 'approved')
                        OutlinedButton.icon(
                          onPressed: () => _updateStatus(docId, 'submitted'),
                          icon: const Icon(Icons.upload_outlined, size: 14),
                          label: Text(l.markSubmitted, style: const TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 32)),
                        ),
                    ]),
                  ]),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context),
        icon: const Icon(Icons.add),
        label: Text(l.addDocument),
      ),
    );
  }

  Future<void> _updateStatus(String docId, String newStatus) async {
    await _db.collection('export_documents').doc(docId).update({'status': newStatus});
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CreateDocSheet(
        db: _db,
        shipmentId: widget.shipmentId,
      ),
    );
  }
}

class _CreateDocSheet extends StatefulWidget {
  final FirebaseFirestore db;
  final String? shipmentId;
  const _CreateDocSheet({required this.db, this.shipmentId});

  @override
  State<_CreateDocSheet> createState() => _CreateDocSheetState();
}

class _CreateDocSheetState extends State<_CreateDocSheet> {
  String _selectedType = _kDocTypes.first.key;
  final _notesCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final docType = _kDocTypes.firstWhere((d) => d.key == _selectedType);
      await widget.db.collection('export_documents').add({
        'documentType': _selectedType,
        'title': docType.label,
        'status': 'draft',
        'notes': _notesCtrl.text.trim(),
        if (widget.shipmentId != null) 'shipmentId': widget.shipmentId,
        'createdBy': user?.uid ?? '',
        'createdByName': user?.displayName ?? user?.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.documentAdded)));
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(l.addDocument, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: InputDecoration(labelText: l.documentType, border: const OutlineInputBorder()),
            items: _kDocTypes.map((dt) => DropdownMenuItem(
                value: dt.key,
                child: Row(children: [
                  Icon(dt.icon, size: 16), const SizedBox(width: 8), Flexible(child: Text(dt.label, overflow: TextOverflow.ellipsis)),
                ]))).toList(),
            onChanged: (v) { if (v != null) setState(() => _selectedType = v); },
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: InputDecoration(labelText: l.additionalNotes, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 20),

          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _submitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l.addDocument, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          )),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}
