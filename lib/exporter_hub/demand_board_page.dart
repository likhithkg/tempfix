// lib/exporter_hub/demand_board_page.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../l10n/app_localizations.dart';
import '../services/content_translation_service.dart';
import '../services/image_upload_service.dart';
import '../labour_hub/location_search_dialog.dart';

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
  final _picker = ImagePicker();

  final _cropCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _gradeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _unit = 'MT';
  DateTime? _deliveryDeadline;
  bool _isSubmitting = false;

  File? _imageFile;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _cropCtrl.dispose();
    _quantityCtrl.dispose();
    _gradeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Camera'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (source == null) return;
    final picked = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 1200);
    if (picked != null && mounted) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    try {
      String? imageUrl;
      if (_imageFile != null) {
        setState(() => _isUploadingImage = true);
        imageUrl = await ImageUploadService.uploadImage(_imageFile!);
        if (mounted) setState(() => _isUploadingImage = false);
      }

      await _db.collection('export_demand').add({
        'crop': _cropCtrl.text.trim(),
        'quantity': '${_quantityCtrl.text.trim()} $_unit',
        'grade': _gradeCtrl.text.trim(),
        'deliveryDeadline': _deliveryDeadline?.toIso8601String(),
        'notes': _notesCtrl.text.trim(),
        'imageUrl': imageUrl ?? '',
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
                decoration: const InputDecoration(
                    labelText: 'Product Name', border: OutlineInputBorder(),
                    hintText: 'e.g. Tomatoes, Basmati Rice, Alphonso Mangoes'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // ── Demand image ──
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400, width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.shade50,
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity),
                        )
                      : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 38, color: Colors.grey.shade400),
                          const SizedBox(height: 6),
                          Text('Add Product Image (optional)',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                        ]),
                ),
              ),
              if (_isUploadingImage)
                const Padding(padding: EdgeInsets.only(top: 6), child: LinearProgressIndicator()),
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

    final l = AppLocalizations.of(context)!;
    final farmerNameCtrl = TextEditingController(text: user.displayName ?? '');
    final phoneCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final quantityCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    File? productPhoto;
    bool isSubmitting = false;
    bool isLocating = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
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
                  decoration: const InputDecoration(labelText: 'Your Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),

                // ── Enhanced location field ──
                Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    onTap: () async {
                      final result = await showDialog<LocationResult>(
                        context: sheetCtx,
                        builder: (_) => const LocationSearchDialog(),
                      );
                      if (result != null) setSheet(() => locationCtrl.text = result.displayName);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        const Icon(Icons.location_on_rounded, color: Color(0xFFE65100), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: locationCtrl,
                            builder: (_, val, __) => Text(
                              val.text.isNotEmpty ? val.text : 'Location (Village / District)',
                              style: TextStyle(
                                fontSize: 14,
                                color: val.text.isNotEmpty ? Colors.black87 : Colors.grey.shade500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final result = await showDialog<LocationResult>(
                          context: sheetCtx,
                          builder: (_) => const LocationSearchDialog(),
                        );
                        if (result != null) setSheet(() => locationCtrl.text = result.displayName);
                      },
                      icon: const Icon(Icons.search_rounded, size: 16),
                      label: const Text('Search Place', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green.shade700,
                        side: BorderSide(color: Colors.green.shade700),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isLocating ? null : () async {
                        setSheet(() => isLocating = true);
                        try {
                          bool svcEnabled = await Geolocator.isLocationServiceEnabled();
                          if (!svcEnabled) return;
                          LocationPermission perm = await Geolocator.checkPermission();
                          if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
                          if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;
                          final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
                          final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
                          if (marks.isNotEmpty) {
                            final pm = marks.first;
                            final loc = [pm.locality, pm.subAdministrativeArea, pm.administrativeArea]
                                .where((e) => e != null && e.isNotEmpty).join(', ');
                            setSheet(() => locationCtrl.text = loc);
                          }
                        } catch (_) {} finally {
                          setSheet(() => isLocating = false);
                        }
                      },
                      icon: isLocating
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.my_location_rounded, size: 16),
                      label: Text(isLocating ? 'Locating…' : 'Use GPS',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),

                TextField(
                  controller: quantityCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l.canSupplyQty, border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: l.additionalNotes, border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 12),

                // ── Product photo ──
                GestureDetector(
                  onTap: () async {
                    final src = await showModalBottomSheet<ImageSource>(
                      context: sheetCtx,
                      builder: (_) => SafeArea(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          ListTile(
                            leading: const Icon(Icons.photo_camera),
                            title: const Text('Camera'),
                            onTap: () => Navigator.pop(sheetCtx, ImageSource.camera),
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text('Gallery'),
                            onTap: () => Navigator.pop(sheetCtx, ImageSource.gallery),
                          ),
                        ]),
                      ),
                    );
                    if (src == null) return;
                    final picked = await ImagePicker().pickImage(source: src, imageQuality: 80, maxWidth: 1200);
                    if (picked != null) setSheet(() => productPhoto = File(picked.path));
                  },
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400, width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.shade50,
                    ),
                    child: productPhoto != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Image.file(productPhoto!, fit: BoxFit.cover, width: double.infinity),
                          )
                        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 36, color: Colors.grey.shade400),
                            const SizedBox(height: 6),
                            Text('Add Product Photo (optional)',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                          ]),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : () async {
                      setSheet(() => isSubmitting = true);
                      setState(() => _responding = true);
                      try {
                        String? photoUrl;
                        if (productPhoto != null) {
                          photoUrl = await ImageUploadService.uploadImage(productPhoto!);
                        }
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
                              'productPhotoUrl': photoUrl ?? '',
                              'respondedAt': DateTime.now().toIso8601String(),
                            }
                          ]),
                        });
                        if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l.responseSubmitted)));
                        }
                      } catch (e) {
                        if (sheetCtx.mounted) {
                          ScaffoldMessenger.of(sheetCtx).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      } finally {
                        if (mounted) setState(() => _responding = false);
                        setSheet(() => isSubmitting = false);
                      }
                    },
                    child: isSubmitting
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(l.submitResponse),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );

    farmerNameCtrl.dispose();
    phoneCtrl.dispose();
    locationCtrl.dispose();
    quantityCtrl.dispose();
    notesCtrl.dispose();
  }

  void _showFarmerContactSheet(BuildContext context, String name, String phone, String location, String qty, String notes, String photoUrl) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                if (photoUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(photoUrl, width: 60, height: 60, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                  )
                else
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.person, color: Colors.green.shade400, size: 32),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    if (location.isNotEmpty)
                      Text(location, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    if (qty.isNotEmpty)
                      Text('Can supply: $qty', style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(notes, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              ],
              const SizedBox(height: 20),
              if (phone.isNotEmpty) ...[
                Row(children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final uri = Uri(scheme: 'tel', path: phone);
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      },
                      icon: const Icon(Icons.call),
                      label: const Text('Call', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final msg = Uri.encodeComponent('Hello $name, I saw your response to our export demand.');
                        final uri = Uri.parse('https://wa.me/91${phone.replaceAll(RegExp(r'\D'), '')}?text=$msg');
                        if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.message),
                      label: const Text('Message', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ]),
              ] else
                Text('No phone number provided', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
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
                final rPhoto = (r['productPhotoUrl'] ?? '').toString();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _showFarmerContactSheet(context, rName, rPhone, rLocation, rQty, rNotes, rPhoto),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (rPhoto.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(rPhoto, width: 54, height: 54, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                            )
                          else
                            Container(
                              width: 54, height: 54,
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(Icons.person, color: Colors.green.shade300, size: 28),
                            ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(rName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                if (rPhone.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Row(children: [
                                    Icon(Icons.phone, size: 12, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(rPhone, style: const TextStyle(fontSize: 12)),
                                  ]),
                                ],
                                if (rLocation.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Row(children: [
                                    Icon(Icons.location_on, size: 12, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Expanded(child: Text(rLocation, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  ]),
                                ],
                                if (rQty.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text('Supply: $rQty', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green)),
                                ],
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
                        ],
                      ),
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
