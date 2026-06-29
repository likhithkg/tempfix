import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'rent_model.dart';
import 'package:krishimithra/rent/rent_machine_service.dart';
import '../services/image_upload_service.dart';

// ─── Theme constants (mirror RentHub palette) ────────────────────────────────
const _kPrimary = Color(0xFFE65100);
const _kDark    = Color(0xFF4E1F00);
const _kGrad    = LinearGradient(
  colors: [_kDark, _kPrimary],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ─── Machine types ────────────────────────────────────────────────────────────
const _kTypes = <(String, String)>[
  ('Tractor',    '🚜'),
  ('Harvester',  '🌾'),
  ('Rotavator',  '⚙️'),
  ('Cultivator', '🌿'),
  ('Seeder',     '🌱'),
  ('Hitachi',    '⛏️'),
  ('JCB',        '🏗️'),
  ('Lorry',      '🚚'),
  ('Other',      '🔧'),
];

class RentListFormPage extends StatefulWidget {
  final RentMachine? existingMachine;
  const RentListFormPage({super.key, this.existingMachine});

  @override
  State<RentListFormPage> createState() => _RentListFormPageState();
}

class _RentListFormPageState extends State<RentListFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _name     = TextEditingController();
  final _price    = TextEditingController();
  final _priceHr  = TextEditingController();
  final _owner    = TextEditingController();
  final _phone    = TextEditingController();
  final _locCtrl  = TextEditingController();

  String? _type;
  double? _lat;
  double? _lng;
  String? _imageUrl;
  XFile?  _picked;
  bool    _uploading  = false;
  bool    _submitting = false;

  @override
  void initState() {
    super.initState();
    final m = widget.existingMachine;
    if (m != null) {
      _name.text  = m.name;
      _price.text = m.pricePerDay.toString();
      if (m.pricePerHour > 0) _priceHr.text = m.pricePerHour.toString();
      _owner.text = m.ownerName;
      _phone.text = m.phone;
      _type       = m.type;
      _lat        = m.latitude;
      _lng        = m.longitude;
      _imageUrl   = m.imageUrl;
      _locCtrl.text = m.location ?? '';
    } else {
      // Auto-fill from Firebase Auth profile
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _owner.text = user.displayName ?? '';
        if (user.phoneNumber?.isNotEmpty == true) {
          _phone.text = user.phoneNumber!;
        }
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _priceHr.dispose();
    _owner.dispose();
    _phone.dispose();
    _locCtrl.dispose();
    super.dispose();
  }

  // ─── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final f = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (f != null) setState(() => _picked = f);
  }

  Future<void> _uploadImage() async {
    if (_picked == null) {
      _snack('Pick an image first');
      return;
    }
    try {
      setState(() => _uploading = true);
      final url = await ImageUploadService.uploadImage(File(_picked!.path));
      if (url != null) {
        setState(() => _imageUrl = url);
        _snack('Image uploaded ✅', color: const Color(0xFF4CAF50));
      } else {
        _snack('Upload failed — try again', color: Colors.red);
      }
    } catch (e) {
      _snack('Upload error: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _getLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _snack('Location permission denied');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));

      String label =
          '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
      try {
        final places =
            await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (places.isNotEmpty) {
          final pl = places.first;
          final parts = [pl.subLocality, pl.locality, pl.administrativeArea]
              .where((s) => s != null && s.isNotEmpty)
              .cast<String>()
              .toList();
          if (parts.isNotEmpty) label = parts.join(', ');
        }
      } catch (_) {}

      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _locCtrl.text = label;
      });
      _snack('Location set: $label', color: const Color(0xFF4CAF50));
    } catch (e) {
      _snack('Location error: $e');
    }
  }

  Future<void> _searchLocation() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _LocationSearchDialog(),
    );
    if (result != null) {
      setState(() {
        _locCtrl.text = result['name'] as String;
        _lat = result['lat'] as double;
        _lng = result['lon'] as double;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_type == null) {
      _snack('Select a machine type');
      return;
    }
    if (_lat == null || _lng == null) {
      _snack('Set the machine location first');
      return;
    }
    final price = double.tryParse(_price.text.trim());
    if (price == null) {
      _snack('Enter a valid price');
      return;
    }

    setState(() => _submitting = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final m = RentMachine(
        id:          widget.existingMachine?.id ?? '',
        name:        _name.text.trim(),
        type:        _type!,
        pricePerDay: price,
        pricePerHour: double.tryParse(_priceHr.text.trim()) ?? 0,
        ownerName:   _owner.text.trim(),
        ownerId:     widget.existingMachine?.ownerId ?? uid,
        phone:       _phone.text.trim(),
        latitude:    _lat!,
        longitude:   _lng!,
        imageUrl:    _imageUrl ?? '',
        createdAt:   widget.existingMachine?.createdAt ?? DateTime.now(),
        location:    _locCtrl.text.trim(),
      );

      if (widget.existingMachine == null) {
        await RentMachineService.instance.addMachine(m);
        _snack('Machine listed successfully! 🎉', color: const Color(0xFF4CAF50));
      } else {
        await RentMachineService.instance.updateMachine(m.id, m);
        _snack('Listing updated ✅', color: const Color(0xFF4CAF50));
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _snack('Failed: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingMachine != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(isEdit)),
            SliverToBoxAdapter(child: _buildImageCard()),
            SliverToBoxAdapter(child: _buildMachineCard()),
            SliverToBoxAdapter(child: _buildPricingCard()),
            SliverToBoxAdapter(child: _buildOwnerCard()),
            SliverToBoxAdapter(child: _buildLocationCard()),
            SliverToBoxAdapter(child: _buildSubmitBtn(isEdit)),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isEdit) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, topPad + 10, 16, 22),
      decoration: const BoxDecoration(gradient: _kGrad),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 4),
            Text(
              isEdit ? '✏️  Edit Machine' : '🚜  List Your Machine',
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 3),
            Text(
              isEdit
                  ? 'Update your machine details'
                  : 'Earn money by renting to nearby farmers',
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Image card ───────────────────────────────────────────────────────────────
  Widget _buildImageCard() {
    final hasPick     = _picked != null;
    final isUploaded  = _imageUrl?.isNotEmpty == true;

    return _card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(children: [
        _cardHeader('📸', 'Machine Photo', 'A good photo attracts more bookings'),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: _uploading ? null : _pickImage,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 190,
              width: double.infinity,
              color: const Color(0xFFF5F5F5),
              child: _uploading
                  ? const Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        CircularProgressIndicator(color: _kPrimary),
                        SizedBox(height: 10),
                        Text('Uploading to cloud...',
                            style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w600)),
                      ]),
                    )
                  : hasPick
                      ? Stack(fit: StackFit.expand, children: [
                          Image.file(File(_picked!.path), fit: BoxFit.cover),
                          if (!isUploaded)
                            Positioned(
                              bottom: 0, left: 0, right: 0,
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.55),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.cloud_upload_rounded,
                                          color: Colors.white, size: 15),
                                      SizedBox(width: 6),
                                      Text('Tap "Upload" button below',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700)),
                                    ]),
                              ),
                            ),
                          if (isUploaded)
                            Positioned(
                              top: 10, right: 10,
                              child: _badge(
                                  Icons.check_circle_rounded, 'Uploaded',
                                  const Color(0xFF4CAF50)),
                            ),
                        ])
                      : isUploaded
                          ? Stack(fit: StackFit.expand, children: [
                              Image.network(_imageUrl!, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const _ImagePlaceholder()),
                              Positioned(
                                top: 10, right: 10,
                                child: _badge(Icons.check_circle_rounded, 'Saved',
                                    const Color(0xFF4CAF50)),
                              ),
                            ])
                          : const _ImagePlaceholder(),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library_rounded, size: 16),
              label: const Text('Gallery', style: TextStyle(fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kPrimary,
                side: const BorderSide(color: _kPrimary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: hasPick && !_uploading ? _uploadImage : null,
              icon: const Icon(Icons.cloud_upload_rounded, size: 16),
              label: const Text('Upload', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE0E0E0),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  // ── Machine details card ─────────────────────────────────────────────────────
  Widget _buildMachineCard() {
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardHeader('🚜', 'Machine Details', null),
        const SizedBox(height: 16),
        _field(
          controller: _name,
          label: 'Machine Name',
          hint: 'e.g. Mahindra 475 Tractor',
          icon: Icons.agriculture_rounded,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Enter machine name' : null,
        ),
        const SizedBox(height: 18),
        Text('Machine Type',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey[700])),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _kTypes.map((t) {
            final sel = _type == t.$1;
            return GestureDetector(
              onTap: () => setState(() => _type = t.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: sel ? _kPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: sel ? _kPrimary : const Color(0xFFE0E0E0)),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                              color: _kPrimary.withValues(alpha: 0.28),
                              blurRadius: 8,
                              offset: const Offset(0, 3))
                        ]
                      : [],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(t.$2, style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 6),
                  Text(t.$1,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : const Color(0xFF424242))),
                ]),
              ),
            );
          }).toList(),
        ),
        if (_type == null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Select a machine type',
                style:
                    TextStyle(fontSize: 11, color: Colors.red.shade400)),
          ),
      ]),
    );
  }

  // ── Pricing card ─────────────────────────────────────────────────────────────
  Widget _buildPricingCard() {
    return _card(
      child: Column(children: [
        _cardHeader('💰', 'Pricing', null),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: _field(
              controller: _price,
              label: 'Per Day (₹)',
              hint: 'e.g. 2500',
              icon: Icons.calendar_today_rounded,
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || double.tryParse(v) == null)
                  ? 'Enter price'
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _field(
              controller: _priceHr,
              label: 'Per Hour (₹)',
              hint: 'Optional',
              icon: Icons.access_time_rounded,
              keyboardType: TextInputType.number,
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFE082)),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline_rounded,
                size: 14, color: Color(0xFFFF8F00)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hourly rate auto-calculated as Day price ÷ 10 if left empty.',
                style: TextStyle(fontSize: 11, color: Color(0xFF5D4037)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Owner card ───────────────────────────────────────────────────────────────
  Widget _buildOwnerCard() {
    return _card(
      child: Column(children: [
        _cardHeader(
            '👤', 'Your Contact Details', 'Shared with farmers after booking'),
        const SizedBox(height: 16),
        _field(
          controller: _owner,
          label: 'Full Name',
          hint: 'Your name as owner',
          icon: Icons.person_rounded,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Enter owner name' : null,
        ),
        const SizedBox(height: 14),
        _field(
          controller: _phone,
          label: 'WhatsApp / Phone',
          hint: '+91 98765 43210',
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Enter phone number' : null,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF90CAF9)),
          ),
          child: const Row(children: [
            Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF1565C0)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Your contact is only shown after a farmer confirms a booking.',
                style: TextStyle(fontSize: 11, color: Color(0xFF0D47A1)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Location card ────────────────────────────────────────────────────────────
  Widget _buildLocationCard() {
    final hasLoc = _lat != null && _lng != null;
    return _card(
      child: Column(children: [
        _cardHeader('📍', 'Machine Location', 'Where is your machine based?'),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _searchLocation,
          child: AbsorbPointer(
            child: TextFormField(
              controller: _locCtrl,
              readOnly: true,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Set machine location' : null,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
              decoration: _inputDeco(
                label: 'Location',
                hint: 'Search village, town or city...',
                icon: Icons.location_on_rounded,
                suffix: const Icon(Icons.search_rounded,
                    size: 18, color: Color(0xFF9E9E9E)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _searchLocation,
              icon: const Icon(Icons.search_rounded, size: 16),
              label: const Text('Search Place',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1565C0),
                side: const BorderSide(color: Color(0xFF1565C0)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _getLocation,
              icon: const Icon(Icons.my_location_rounded, size: 16),
              label: const Text('Use GPS',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
        if (hasLoc) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFA5D6A7)),
            ),
            child: Row(children: [
              const Icon(Icons.gps_fixed_rounded,
                  color: Color(0xFF4CAF50), size: 15),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32)),
                ),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  // ── Submit button ────────────────────────────────────────────────────────────
  Widget _buildSubmitBtn(bool isEdit) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFE0E0E0),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(isEdit ? Icons.save_rounded : Icons.rocket_launch_rounded,
                      size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isEdit ? 'Update Listing' : 'List My Machine',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ]),
        ),
      ),
    );
  }

  // ─── Small helpers ────────────────────────────────────────────────────────────

  Widget _card({required Widget child, EdgeInsets? margin}) {
    return Container(
      margin: margin ?? const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }

  Widget _cardHeader(String emoji, String title, String? sub) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF212121))),
        if (sub != null)
          Text(sub,
              style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
      ]),
    ]);
  }

  InputDecoration _inputDeco({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBDBDBD)),
      prefixIcon: Icon(icon, size: 20, color: _kPrimary),
      suffixIcon: suffix,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.5)),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: _inputDeco(label: label, hint: hint, icon: icon),
    );
  }

  Widget _badge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 13),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

// ─── Location search dialog ────────────────────────────────────────────────────
class _LocationSearchDialog extends StatefulWidget {
  const _LocationSearchDialog();

  @override
  State<_LocationSearchDialog> createState() => _LocationSearchDialogState();
}

class _LocationSearchDialogState extends State<_LocationSearchDialog> {
  final _ctrl    = TextEditingController();
  List<dynamic> _results = [];
  bool          _searching = false;
  final _api     = 'pk.56ccd9d8fb2cd5f3e9d7a656e3b52566';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String val) async {
    if (val.length < 3) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final url =
          'https://us1.locationiq.com/v1/search.php?key=$_api&q=$val&format=json&limit=8';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200 && mounted) {
        setState(() => _results = json.decode(res.body));
      }
    } catch (_) {}
    if (mounted) setState(() => _searching = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Row(children: [
            Icon(Icons.location_on_rounded, color: _kPrimary),
            SizedBox(width: 8),
            Text('Search Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            onChanged: _search,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              hintText: 'Village, town or city...',
              prefixIcon: const Icon(Icons.search_rounded, color: _kPrimary),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _kPrimary)))
                  : null,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 260,
            child: _results.isEmpty
                ? const Center(
                    child: Text('Type at least 3 characters to search',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 13)))
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFF0F0F0)),
                    itemBuilder: (_, i) {
                      final r = _results[i];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on_rounded,
                            color: _kPrimary, size: 18),
                        title: Text(r['display_name'],
                            style: const TextStyle(fontSize: 12.5),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        onTap: () => Navigator.pop(context, {
                          'name': r['display_name'],
                          'lat':
                              double.tryParse(r['lat'] ?? '0') ?? 0.0,
                          'lon':
                              double.tryParse(r['lon'] ?? '0') ?? 0.0,
                        }),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}

// ─── Image placeholder ────────────────────────────────────────────────────────
class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.add_photo_alternate_rounded, size: 44, color: _kPrimary),
        SizedBox(height: 10),
        Text('Tap to add machine photo',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF616161))),
        SizedBox(height: 4),
        Text('JPG or PNG recommended',
            style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
      ]),
    );
  }
}
