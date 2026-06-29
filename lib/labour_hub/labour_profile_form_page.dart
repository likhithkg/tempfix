import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'labour_hub_service.dart';
import 'labour_profile_model.dart';
import '../services/image_upload_service.dart';

const _kP1 = Color(0xFF1B5E20);
const _kP2 = Color(0xFF2E7D32);
const _kGreen = Color(0xFF4CAF50);
const _kLightGreen = Color(0xFFE8F5E9);
const _kOrange = Color(0xFFE65100);
const _kDark = Color(0xFF1A2D1A);

class LabourProfileFormPage extends StatefulWidget {
  final LabourProfile? existing;

  const LabourProfileFormPage({super.key, this.existing});

  @override
  State<LabourProfileFormPage> createState() => _LabourProfileFormPageState();
}

class _LabourProfileFormPageState extends State<LabourProfileFormPage> {
  final _form = GlobalKey<FormState>();
  final _service = LabourHubService();
  bool _submitting = false;
  bool _locating = false;

  // Basic info
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String _gender = 'Male';

  // Location
  final _villageCtrl = TextEditingController();
  final _talukCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  double _lat = 0, _lon = 0;

  // Work info
  final _expCtrl = TextEditingController();
  final _wageCtrl = TextEditingController();
  String _availability = 'available';

  // Multi-select
  final Set<String> _selectedSkills = {};
  final Set<String> _selectedLangs = {};

  // Photo
  String _photoUrl = '';
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  void _prefill() {
    final user = FirebaseAuth.instance.currentUser;
    final p = widget.existing;
    if (p != null) {
      _nameCtrl.text = p.name;
      _phoneCtrl.text = p.phone;
      _ageCtrl.text = p.age.toString();
      _gender = p.gender;
      _villageCtrl.text = p.village;
      _talukCtrl.text = p.taluk;
      _districtCtrl.text = p.district;
      _lat = p.latitude;
      _lon = p.longitude;
      _expCtrl.text = p.experienceYears.toString();
      _wageCtrl.text = p.dailyWage.toStringAsFixed(0);
      _availability = p.availabilityStatus;
      _selectedSkills.addAll(p.skills);
      _selectedLangs.addAll(p.languages);
      _photoUrl = p.photoUrl;
    } else if (user != null) {
      _nameCtrl.text = user.displayName ?? '';
      _phoneCtrl.text = user.phoneNumber ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _ageCtrl.dispose();
    _villageCtrl.dispose();
    _talukCtrl.dispose();
    _districtCtrl.dispose();
    _expCtrl.dispose();
    _wageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      final url = await ImageUploadService.uploadImage(File(picked.path));
      if (url != null && mounted) setState(() => _photoUrl = url);
    } catch (_) {
      _snack('Photo upload failed', isError: true);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _getGPS() async {
    setState(() => _locating = true);
    try {
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _snack('Location permission denied', isError: true);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
      final places =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (places.isNotEmpty && mounted) {
        final pl = places.first;
        setState(() {
          _lat = pos.latitude;
          _lon = pos.longitude;
          _villageCtrl.text = pl.subLocality ?? pl.locality ?? '';
          _talukCtrl.text = pl.subAdministrativeArea ?? '';
          _districtCtrl.text = pl.administrativeArea ?? '';
        });
      }
    } catch (_) {
      _snack('Could not get location', isError: true);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_selectedSkills.isEmpty) {
      _snack('Please select at least one skill', isError: true);
      return;
    }
    setState(() => _submitting = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final now = DateTime.now();
      final profile = LabourProfile(
        id: uid,
        uid: uid,
        name: _nameCtrl.text.trim(),
        age: int.tryParse(_ageCtrl.text) ?? 18,
        gender: _gender,
        phone: _phoneCtrl.text.trim(),
        village: _villageCtrl.text.trim(),
        taluk: _talukCtrl.text.trim(),
        district: _districtCtrl.text.trim(),
        latitude: _lat,
        longitude: _lon,
        experienceYears: int.tryParse(_expCtrl.text) ?? 0,
        dailyWage: double.tryParse(_wageCtrl.text) ?? 0,
        availabilityStatus: _availability,
        skills: _selectedSkills.toList(),
        languages: _selectedLangs.toList(),
        photoUrl: _photoUrl,
        createdAt: widget.existing?.createdAt ?? now,
        updatedAt: now,
      );
      await _service.saveProfile(profile);
      if (mounted) {
        _snack('Profile saved successfully!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      _snack('Failed to save: $e', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : _kP2,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F2),
      body: Form(
        key: _form,
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [_kP1, _kP2, Color(0xFF388E3C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Row(children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Professional Profile',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            Text('Create your worker profile',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),

            // ── Photo Card ──────────────────────────────────────────────────
            _SliverCard(
              child: _buildPhotoSection(),
            ),

            // ── Basic Info ──────────────────────────────────────────────────
            _SliverCard(
              child: _buildSection('Personal Details', Icons.person_rounded, [
                _field('Full Name', _nameCtrl,
                    validator: (v) =>
                        v!.trim().isEmpty ? 'Name is required' : null),
                _field('Phone Number', _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        v!.trim().isEmpty ? 'Phone is required' : null),
                _field('Age', _ageCtrl, keyboardType: TextInputType.number),
                _label('Gender'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Male', 'Female', 'Other'].map((g) {
                    return ChoiceChip(
                      label: Text(g),
                      selected: _gender == g,
                      selectedColor: _kP2,
                      labelStyle: TextStyle(
                          color: _gender == g ? Colors.white : _kDark),
                      onSelected: (_) => setState(() => _gender = g),
                    );
                  }).toList(),
                ),
              ]),
            ),

            // ── Location ─────────────────────────────────────────────────────
            _SliverCard(
              child: _buildSection('Location', Icons.location_on_rounded, [
                _field('Village / Town', _villageCtrl,
                    validator: (v) =>
                        v!.trim().isEmpty ? 'Village is required' : null),
                _field('Taluk', _talukCtrl),
                _field('District', _districtCtrl,
                    validator: (v) =>
                        v!.trim().isEmpty ? 'District is required' : null),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _locating ? null : _getGPS,
                    icon: _locating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _kP2))
                        : const Icon(Icons.my_location_rounded,
                            color: _kP2),
                    label: Text(_locating ? 'Getting location…' : 'Use GPS'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: _kP2,
                        side: const BorderSide(color: _kP2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                ),
                if (_lat != 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(children: [
                      const Icon(Icons.check_circle_rounded,
                          color: _kGreen, size: 16),
                      const SizedBox(width: 6),
                      Text(
                          'GPS: ${_lat.toStringAsFixed(4)}, ${_lon.toStringAsFixed(4)}',
                          style: const TextStyle(
                              fontSize: 12, color: _kGreen)),
                    ]),
                  ),
              ]),
            ),

            // ── Skills ────────────────────────────────────────────────────────
            _SliverCard(
              child: _buildSection(
                  'Skills (select all that apply)',
                  Icons.handyman_rounded, [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kLabourSkills.map((s) {
                    final sel = _selectedSkills.contains(s);
                    return FilterChip(
                      label: Text(s),
                      selected: sel,
                      selectedColor: _kP2,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                          color: sel ? Colors.white : _kDark,
                          fontSize: 12),
                      onSelected: (v) {
                        setState(() {
                          v
                              ? _selectedSkills.add(s)
                              : _selectedSkills.remove(s);
                        });
                      },
                    );
                  }).toList(),
                ),
              ]),
            ),

            // ── Work Details ──────────────────────────────────────────────────
            _SliverCard(
              child: _buildSection('Work Details', Icons.work_rounded, [
                _field('Experience (years)', _expCtrl,
                    keyboardType: TextInputType.number,
                    hint: 'e.g. 3'),
                _field('Daily Wage (₹)', _wageCtrl,
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v!.trim().isEmpty ? 'Wage is required' : null),
                _label('Availability'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ('available', '✅ Available', _kGreen),
                    ('busy', '⏳ Busy', Colors.orange),
                    ('unavailable', '❌ Unavailable', Colors.red),
                  ].map((e) {
                    final (val, lbl, col) = e;
                    final sel = _availability == val;
                    return ChoiceChip(
                      label: Text(lbl, style: const TextStyle(fontSize: 12)),
                      selected: sel,
                      selectedColor: col.withOpacity(0.15),
                      labelStyle: TextStyle(
                          color: sel ? col : Colors.grey.shade600,
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal),
                      side: BorderSide(color: sel ? col : Colors.grey.shade300),
                      onSelected: (_) =>
                          setState(() => _availability = val),
                    );
                  }).toList(),
                ),
              ]),
            ),

            // ── Languages ────────────────────────────────────────────────────
            _SliverCard(
              child: _buildSection(
                  'Languages Known', Icons.translate_rounded, [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kLanguages.map((l) {
                    final sel = _selectedLangs.contains(l);
                    return FilterChip(
                      label: Text(l, style: const TextStyle(fontSize: 12)),
                      selected: sel,
                      selectedColor: _kP2,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                          color: sel ? Colors.white : _kDark),
                      onSelected: (v) => setState(() {
                        v ? _selectedLangs.add(l) : _selectedLangs.remove(l);
                      }),
                    );
                  }).toList(),
                ),
              ]),
            ),

            // ── Submit ────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded),
                  label: Text(_submitting ? 'Saving…' : 'Save Profile',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _kP2,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(children: [
      const Text('Profile Photo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 16),
      GestureDetector(
        onTap: _pickPhoto,
        child: Stack(alignment: Alignment.bottomRight, children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: _kLightGreen,
            backgroundImage:
                _photoUrl.isNotEmpty ? NetworkImage(_photoUrl) : null,
            child: _photoUrl.isEmpty
                ? const Icon(Icons.person_rounded, size: 50, color: _kP2)
                : null,
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
                color: _kP2, shape: BoxShape.circle),
            child: _uploadingPhoto
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.camera_alt_rounded,
                    color: Colors.white, size: 14),
          ),
        ]),
      ),
      const SizedBox(height: 8),
      Text('Tap to upload photo',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
    ]);
  }

  Widget _buildSection(
      String title, IconData icon, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 18, color: _kP2),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _kDark)),
      ]),
      const SizedBox(height: 16),
      ...children,
    ]);
  }

  Widget _field(String label, TextEditingController ctrl,
      {TextInputType? keyboardType,
      String? hint,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFF8FDF8),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kP2, width: 2)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700)),
    );
  }
}

class _SliverCard extends StatelessWidget {
  final Widget child;

  const _SliverCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: child,
      ),
    );
  }
}
