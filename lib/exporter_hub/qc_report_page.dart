// lib/exporter_hub/qc_report_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'exporter_service.dart';
import '../services/image_upload_service.dart';
import '../l10n/app_localizations.dart';

// ── QC Report Model ────────────────────────────────────────────────────────────

class QCReport {
  final String id;
  final String poId;
  final String listingId;
  final String inspectorId;
  final String inspectorName;
  final double? moistureLevel;
  final String? colorGrade;       // 'Excellent', 'Good', 'Fair', 'Poor'
  final double? foreignMatterPct; // 0–100
  final double? defectsPct;
  final String? inspectorNotes;
  final List<String> photos;
  final String approvalStatus;    // 'pending', 'approved', 'rejected'
  final DateTime? createdAt;

  const QCReport({
    this.id = '',
    required this.poId,
    required this.listingId,
    required this.inspectorId,
    required this.inspectorName,
    this.moistureLevel,
    this.colorGrade,
    this.foreignMatterPct,
    this.defectsPct,
    this.inspectorNotes,
    this.photos = const [],
    this.approvalStatus = 'pending',
    this.createdAt,
  });

  factory QCReport.fromMap(Map<String, dynamic> m, String id) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is Timestamp) return v.toDate();
      return DateTime.tryParse(v.toString());
    }

    return QCReport(
      id: id,
      poId: (m['poId'] ?? '').toString(),
      listingId: (m['listingId'] ?? '').toString(),
      inspectorId: (m['inspectorId'] ?? '').toString(),
      inspectorName: (m['inspectorName'] ?? '').toString(),
      moistureLevel: (m['moistureLevel'] as num?)?.toDouble(),
      colorGrade: m['colorGrade']?.toString(),
      foreignMatterPct: (m['foreignMatterPct'] as num?)?.toDouble(),
      defectsPct: (m['defectsPct'] as num?)?.toDouble(),
      inspectorNotes: m['inspectorNotes']?.toString(),
      photos: (m['photos'] as List?)?.map((e) => e.toString()).toList() ?? [],
      approvalStatus: (m['approvalStatus'] ?? 'pending').toString(),
      createdAt: parseDate(m['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'poId': poId,
        'listingId': listingId,
        'inspectorId': inspectorId,
        'inspectorName': inspectorName,
        if (moistureLevel != null) 'moistureLevel': moistureLevel,
        if (colorGrade != null) 'colorGrade': colorGrade,
        if (foreignMatterPct != null) 'foreignMatterPct': foreignMatterPct,
        if (defectsPct != null) 'defectsPct': defectsPct,
        if (inspectorNotes != null) 'inspectorNotes': inspectorNotes,
        'photos': photos,
        'approvalStatus': approvalStatus,
      };
}

// ── QC Report Create Page ──────────────────────────────────────────────────────

class QCReportPage extends StatefulWidget {
  final String poId;
  final String listingId;
  final bool isAdminView; // if true: can approve/reject existing reports

  const QCReportPage({
    super.key,
    required this.poId,
    required this.listingId,
    this.isAdminView = false,
  });

  @override
  State<QCReportPage> createState() => _QCReportPageState();
}

class _QCReportPageState extends State<QCReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = ExporterService();
  final _picker = ImagePicker();

  final _moistureCtrl = TextEditingController();
  final _foreignMatterCtrl = TextEditingController();
  final _defectsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _colorGrade;
  final List<File> _pickedPhotos = [];
  bool _isSubmitting = false;
  bool _isUploading = false;

  static const _colorGrades = ['Excellent', 'Good', 'Fair', 'Poor'];

  @override
  void dispose() {
    _moistureCtrl.dispose();
    _foreignMatterCtrl.dispose();
    _defectsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_pickedPhotos.length >= 5) return;
    try {
      final picked = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 80, maxWidth: 1200);
      if (picked != null) setState(() => _pickedPhotos.add(File(picked.path)));
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSignInToPerformAction)));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      setState(() => _isUploading = true);
      final photoUrls = <String>[];
      for (final file in _pickedPhotos) {
        final url = await ImageUploadService.uploadImage(file);
        if (url != null) photoUrls.add(url);
      }
      setState(() => _isUploading = false);

      final report = QCReport(
        poId: widget.poId,
        listingId: widget.listingId,
        inspectorId: user.uid,
        inspectorName: user.displayName ?? user.email ?? user.uid,
        moistureLevel: double.tryParse(_moistureCtrl.text.trim()),
        colorGrade: _colorGrade,
        foreignMatterPct: double.tryParse(_foreignMatterCtrl.text.trim()),
        defectsPct: double.tryParse(_defectsCtrl.text.trim()),
        inspectorNotes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
        photos: photoUrls,
        approvalStatus: 'pending',
      );

      await _service.createQCReport(report.toMap());

      // Also update PO status to qc_pending
      await _service.updatePOStatus(widget.poId, 'qc_pending', user.uid,
          note: 'QC report submitted by ${report.inspectorName}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.qcReportSubmitted)));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() { _isSubmitting = false; _isUploading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.qcReport),
        actions: [
          if (widget.isAdminView)
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: l.qcHistory,
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => QCHistoryPage(poId: widget.poId))),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.qcReportSubtitle,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 16),

              // Moisture Level
              TextFormField(
                controller: _moistureCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    labelText: l.moistureLevelLabel, border: const OutlineInputBorder(),
                    hintText: 'e.g. 12.5', suffixText: '%'),
              ),
              const SizedBox(height: 12),

              // Color Grade
              DropdownButtonFormField<String?>(
                value: _colorGrade,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Select color grade')),
                  ..._colorGrades.map((g) => DropdownMenuItem(value: g, child: Text(g))),
                ],
                onChanged: (v) => setState(() => _colorGrade = v),
                decoration: InputDecoration(
                    labelText: l.colorGradeLabel, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 12),

              // Foreign Matter %
              TextFormField(
                controller: _foreignMatterCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    labelText: l.foreignMatterLabel, border: const OutlineInputBorder(),
                    hintText: 'e.g. 0.5', suffixText: '%'),
              ),
              const SizedBox(height: 12),

              // Defects %
              TextFormField(
                controller: _defectsCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    labelText: l.defectsLabel, border: const OutlineInputBorder(),
                    hintText: 'e.g. 2.0', suffixText: '%'),
              ),
              const SizedBox(height: 12),

              // Inspector Notes
              TextFormField(
                controller: _notesCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                    labelText: l.inspectorNotesLabel, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              // Photos
              Text(l.qcPhotosLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._pickedPhotos.map((f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(clipBehavior: Clip.none, children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(f, width: 80, height: 80, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: -6, right: -6,
                              child: GestureDetector(
                                onTap: () => setState(() => _pickedPhotos.remove(f)),
                                child: Container(
                                  width: 22, height: 22,
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ]),
                        )),
                    if (_pickedPhotos.length < 5)
                      GestureDetector(
                        onTap: _pickPhoto,
                        child: Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5), width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.add_a_photo_outlined,
                              color: Theme.of(context).colorScheme.primary, size: 30),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (_isUploading) const LinearProgressIndicator(),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _isSubmitting
                      ? const SizedBox(height: 18, width: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(l.submitQcReport,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── QC History Page ────────────────────────────────────────────────────────────

class QCHistoryPage extends StatelessWidget {
  final String poId;
  const QCHistoryPage({super.key, required this.poId});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: Text(l.qcHistory)),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.collection('qc_reports')
            .where('poId', isEqualTo: poId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(child: Text(l.noQcReportsYet));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final report = QCReport.fromMap(data, docs[i].id);
              return _QCReportCard(report: report);
            },
          );
        },
      ),
    );
  }
}

// ── QC Report Card ─────────────────────────────────────────────────────────────

class _QCReportCard extends StatelessWidget {
  final QCReport report;
  const _QCReportCard({required this.report});

  Color get _statusColor {
    switch (report.approvalStatus) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final color = _statusColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(children: [
              Icon(Icons.science_outlined, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l.qcInspectorLabel(report.inspectorName),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color),
                ),
                child: Text(report.approvalStatus.toUpperCase(),
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ]),
            const SizedBox(height: 12),

            // Metrics grid
            Wrap(spacing: 16, runSpacing: 8, children: [
              if (report.moistureLevel != null)
                _MetricChip(label: l.moistureLevelLabel, value: '${report.moistureLevel}%'),
              if (report.colorGrade != null)
                _MetricChip(label: l.colorGradeLabel, value: report.colorGrade!),
              if (report.foreignMatterPct != null)
                _MetricChip(label: l.foreignMatterLabel, value: '${report.foreignMatterPct}%'),
              if (report.defectsPct != null)
                _MetricChip(label: l.defectsLabel, value: '${report.defectsPct}%'),
            ]),

            if (report.inspectorNotes?.isNotEmpty ?? false) ...[
              const SizedBox(height: 10),
              Text(report.inspectorNotes!,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],

            // Photos row
            if (report.photos.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: report.photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(report.photos[i], width: 70, height: 70, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(width: 70, height: 70,
                            color: Colors.grey.shade200, child: const Icon(Icons.broken_image))),
                  ),
                ),
              ),
            ],

            // Admin approve/reject buttons
            if (report.approvalStatus == 'pending')
              _AdminQCActions(report: report),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    ]);
  }
}

class _AdminQCActions extends StatefulWidget {
  final QCReport report;
  const _AdminQCActions({required this.report});

  @override
  State<_AdminQCActions> createState() => _AdminQCActionsState();
}

class _AdminQCActionsState extends State<_AdminQCActions> {
  bool _loading = false;

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _loading = true);
    try {
      final db = FirebaseFirestore.instance;
      await db.collection('qc_reports').doc(widget.report.id).update({'approvalStatus': newStatus});

      // Update the linked PO status
      final svc = ExporterService();
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (newStatus == 'approved') {
        await svc.updatePOStatus(widget.report.poId, 'qc_approved', uid, note: 'QC approved by admin');
      } else if (newStatus == 'rejected') {
        await svc.updatePOStatus(widget.report.poId, 'qc_rejected', uid, note: 'QC rejected by admin');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.qcStatusUpdated)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (_loading) return const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator());
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(children: [
        ElevatedButton.icon(
          onPressed: () => _updateStatus('approved'),
          icon: const Icon(Icons.check_circle_outline),
          label: Text(l.approve),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: () => _updateStatus('rejected'),
          icon: const Icon(Icons.cancel_outlined),
          label: Text(l.reject),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
        ),
      ]),
    );
  }
}
