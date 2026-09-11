import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'labour_hub_service.dart';
import 'labour_profile_model.dart';
import 'location_search_dialog.dart';
import '../services/image_upload_service.dart';
import '../theme.dart';


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

  // Personal info
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String _gender = 'Male';

  // Location
  final _villageCtrl = TextEditingController();
  final _talukCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  double _lat = 0, _lon = 0;

  // Work info
  final _expCtrl = TextEditingController();
  final _dailyWageCtrl = TextEditingController();
  final _hourlyWageCtrl = TextEditingController();
  final _monthlyWageCtrl = TextEditingController();
  String _preferredWageType = 'daily';
  String _availability = 'available';
  final Set<String> _availabilityTypes = {};
  int _workingRadiusKm = 20;

  // Skills & languages
  final Set<String> _selectedSkills = {};
  final Set<String> _selectedLangs = {};

  // Description
  final _descCtrl = TextEditingController();

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
      _whatsappCtrl.text = p.whatsappNumber;
      _ageCtrl.text = p.age.toString();
      _gender = p.gender;
      _villageCtrl.text = p.village;
      _talukCtrl.text = p.taluk;
      _districtCtrl.text = p.district;
      _stateCtrl.text = p.state;
      _pincodeCtrl.text = p.pincode;
      _lat = p.latitude;
      _lon = p.longitude;
      _expCtrl.text = p.experienceYears.toString();
      _dailyWageCtrl.text =
          p.dailyWage > 0 ? p.dailyWage.toStringAsFixed(0) : '';
      _hourlyWageCtrl.text =
          p.hourlyWage > 0 ? p.hourlyWage.toStringAsFixed(0) : '';
      _monthlyWageCtrl.text =
          p.monthlyWage > 0 ? p.monthlyWage.toStringAsFixed(0) : '';
      _preferredWageType = p.preferredWageType;
      _availability = p.availabilityStatus;
      _availabilityTypes.addAll(p.availabilityTypes);
      _workingRadiusKm = p.workingRadiusKm;
      _selectedSkills.addAll(p.skills);
      _selectedLangs.addAll(p.languages);
      _photoUrl = p.photoUrl;
      _descCtrl.text = p.description;
    } else if (user != null) {
      _nameCtrl.text = user.displayName ?? '';
      _phoneCtrl.text = user.phoneNumber ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _ageCtrl.dispose();
    _villageCtrl.dispose();
    _talukCtrl.dispose();
    _districtCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _expCtrl.dispose();
    _dailyWageCtrl.dispose();
    _hourlyWageCtrl.dispose();
    _monthlyWageCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      // uploadImageFromXFile works on all platforms (Android, iOS, Web).
      final url = await ImageUploadService.uploadImageFromXFile(picked);
      if (!mounted) return;
      if (url != null) {
        setState(() => _photoUrl = url);
        _snack('Photo uploaded successfully!');
      } else {
        _snack('Photo upload failed. Please try again.', isError: true);
      }
    } catch (e) {
      if (mounted) _snack('Photo upload failed: unable to reach server.', isError: true);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _openLocationSearch() async {
    final result = await showDialog<LocationResult>(
      context: context,
      builder: (_) => const LocationSearchDialog(),
    );
    if (result != null && mounted) {
      setState(() {
        _villageCtrl.text = result.village.isNotEmpty
            ? result.village
            : result.displayName.split(',').first.trim();
        if (result.district.isNotEmpty) _districtCtrl.text = result.district;
        if (result.state.isNotEmpty) _stateCtrl.text = result.state;
        if (result.pincode.isNotEmpty) _pincodeCtrl.text = result.pincode;
        if (result.lat != 0) _lat = result.lat;
        if (result.lon != 0) _lon = result.lon;
      });
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
          _stateCtrl.text = pl.administrativeArea ?? '';
          _pincodeCtrl.text = pl.postalCode ?? '';
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
        whatsappNumber: _whatsappCtrl.text.trim(),
        village: _villageCtrl.text.trim(),
        taluk: _talukCtrl.text.trim(),
        district: _districtCtrl.text.trim(),
        state: _stateCtrl.text.trim(),
        pincode: _pincodeCtrl.text.trim(),
        latitude: _lat,
        longitude: _lon,
        experienceYears: int.tryParse(_expCtrl.text) ?? 0,
        dailyWage: double.tryParse(_dailyWageCtrl.text) ?? 0,
        hourlyWage: double.tryParse(_hourlyWageCtrl.text) ?? 0,
        monthlyWage: double.tryParse(_monthlyWageCtrl.text) ?? 0,
        preferredWageType: _preferredWageType,
        availabilityStatus: _availability,
        availabilityTypes: _availabilityTypes.toList(),
        workingRadiusKm: _workingRadiusKm,
        skills: _selectedSkills.toList(),
        languages: _selectedLangs.toList(),
        photoUrl: _photoUrl,
        description: _descCtrl.text.trim(),
        createdAt: widget.existing?.createdAt ?? now,
        updatedAt: now,
        lastActive: now,
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
      backgroundColor: isError ? Colors.red : KMColors.primary,
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
            // ── Header ────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [KMColors.primaryDark, KMColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 12, 16, 24),
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
                            Text('Build your worker profile',
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

            // ── Profile Photo ────────────────────────────────────────────────
            _SliverCard(child: _buildPhotoSection()),

            // ── Personal Details ─────────────────────────────────────────────
            _SliverCard(
              child: _buildSection(
                  'Personal Details', Icons.person_rounded, [
                _field('Full Name', _nameCtrl,
                    validator: (v) =>
                        v!.trim().isEmpty ? 'Name is required' : null),
                _field('Mobile Number', _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        v!.trim().isEmpty ? 'Phone is required' : null),
                _field('WhatsApp Number', _whatsappCtrl,
                    keyboardType: TextInputType.phone,
                    hint: 'Same as mobile or different'),
                _field('Age', _ageCtrl,
                    keyboardType: TextInputType.number,
                    hint: 'e.g. 25'),
                _label('Gender'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Male', 'Female', 'Other'].map((g) {
                    return ChoiceChip(
                      label: Text(g),
                      selected: _gender == g,
                      selectedColor: KMColors.primary,
                      labelStyle: TextStyle(
                          color: _gender == g ? Colors.white : KMColors.textPrimary),
                      onSelected: (_) => setState(() => _gender = g),
                    );
                  }).toList(),
                ),
              ]),
            ),

            // ── Location ─────────────────────────────────────────────────────
            _SliverCard(
              child: _buildSection('Location', Icons.location_on_rounded, [
                // Display field
                GestureDetector(
                  onTap: _openLocationSearch,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FDF8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _villageCtrl.text.isNotEmpty
                            ? KMColors.primary
                            : Colors.grey.shade300,
                        width: _villageCtrl.text.isNotEmpty ? 2 : 1,
                      ),
                    ),
                    child: Row(children: [
                      Icon(Icons.location_on_rounded,
                          color: _villageCtrl.text.isNotEmpty
                              ? KMColors.primary
                              : const Color(0xFFE65100),
                          size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _villageCtrl.text.isNotEmpty
                              ? [
                                  _villageCtrl.text,
                                  if (_districtCtrl.text.isNotEmpty)
                                    _districtCtrl.text,
                                  if (_stateCtrl.text.isNotEmpty)
                                    _stateCtrl.text,
                                ].join(', ')
                              : 'Location',
                          style: TextStyle(
                            fontSize: 14,
                            color: _villageCtrl.text.isNotEmpty
                                ? KMColors.textPrimary
                                : Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.search_rounded,
                          color: Colors.grey.shade400, size: 20),
                    ]),
                  ),
                ),
                const SizedBox(height: 10),

                // Search Place + Use GPS buttons
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openLocationSearch,
                      icon: const Icon(Icons.search_rounded, size: 16),
                      label: const Text('Search Place',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: KMColors.primary,
                        side: const BorderSide(color: KMColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _locating ? null : _getGPS,
                      icon: _locating
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.my_location_rounded, size: 16),
                      label: Text(_locating ? 'Locating…' : 'Use GPS',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ]),

                if (_lat != 0) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.check_circle_rounded,
                        color: KMColors.available, size: 16),
                    const SizedBox(width: 6),
                    Text(
                        'GPS: ${_lat.toStringAsFixed(4)}, ${_lon.toStringAsFixed(4)}',
                        style:
                            const TextStyle(fontSize: 12, color: KMColors.available)),
                  ]),
                ],

                const SizedBox(height: 12),
                _label('Working Radius'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: kWorkingRadii.map((r) {
                    final sel = _workingRadiusKm == r;
                    return ChoiceChip(
                      label: Text('$r km'),
                      selected: sel,
                      selectedColor: KMColors.primary,
                      labelStyle: TextStyle(
                          color: sel ? Colors.white : KMColors.textPrimary, fontSize: 12),
                      onSelected: (_) =>
                          setState(() => _workingRadiusKm = r),
                    );
                  }).toList(),
                ),
              ]),
            ),

            // ── Skills ───────────────────────────────────────────────────────
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
                      label: Text(s, style: const TextStyle(fontSize: 12)),
                      selected: sel,
                      selectedColor: KMColors.primary,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                          color: sel ? Colors.white : KMColors.textPrimary),
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

            // ── Wage Details ─────────────────────────────────────────────────
            _SliverCard(
              child: _buildSection(
                  'Wage & Experience', Icons.currency_rupee_rounded, [
                _field('Years of Experience', _expCtrl,
                    keyboardType: TextInputType.number,
                    hint: 'e.g. 3'),
                _label('Preferred Wage Type'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: kWageTypeLabels.entries.map((e) {
                    final sel = _preferredWageType == e.key;
                    return ChoiceChip(
                      label:
                          Text(e.value, style: const TextStyle(fontSize: 12)),
                      selected: sel,
                      selectedColor: KMColors.primary,
                      labelStyle: TextStyle(
                          color: sel ? Colors.white : KMColors.textPrimary),
                      onSelected: (_) =>
                          setState(() => _preferredWageType = e.key),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                      child: _field('Daily Wage (₹)', _dailyWageCtrl,
                          keyboardType: TextInputType.number,
                          hint: 'e.g. 500')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _field('Hourly Wage (₹)', _hourlyWageCtrl,
                          keyboardType: TextInputType.number,
                          hint: 'e.g. 80')),
                ]),
                _field('Monthly Wage (₹)', _monthlyWageCtrl,
                    keyboardType: TextInputType.number,
                    hint: 'e.g. 12000'),
              ]),
            ),

            // ── Availability ─────────────────────────────────────────────────
            _SliverCard(
              child: _buildSection(
                  'Availability', Icons.event_available_rounded, [
                _label('Current Status'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ('available', '✅ Available', KMColors.available),
                    ('busy', '⏳ Busy', Colors.orange),
                    ('unavailable', '❌ Unavailable', Colors.red),
                  ].map((e) {
                    final (val, lbl, col) = e;
                    final sel = _availability == val;
                    return ChoiceChip(
                      label: Text(lbl, style: const TextStyle(fontSize: 12)),
                      selected: sel,
                      selectedColor: col.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                          color: sel ? col : Colors.grey.shade600,
                          fontWeight:
                              sel ? FontWeight.bold : FontWeight.normal),
                      side: BorderSide(
                          color: sel ? col : Colors.grey.shade300),
                      onSelected: (_) =>
                          setState(() => _availability = val),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                _label('When are you available? (select all that apply)'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kAvailabilityTypeLabels.entries.map((e) {
                    final sel = _availabilityTypes.contains(e.key);
                    return FilterChip(
                      label:
                          Text(e.value, style: const TextStyle(fontSize: 12)),
                      selected: sel,
                      selectedColor: KMColors.available,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                          color: sel ? Colors.white : KMColors.textPrimary),
                      onSelected: (v) {
                        setState(() {
                          v
                              ? _availabilityTypes.add(e.key)
                              : _availabilityTypes.remove(e.key);
                        });
                      },
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
                      selectedColor: KMColors.primary,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                          color: sel ? Colors.white : KMColors.textPrimary),
                      onSelected: (v) => setState(() {
                        v
                            ? _selectedLangs.add(l)
                            : _selectedLangs.remove(l);
                      }),
                    );
                  }).toList(),
                ),
              ]),
            ),

            // ── About / Description ──────────────────────────────────────────
            _SliverCard(
              child: _buildSection(
                  'About You', Icons.description_rounded, [
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  maxLength: 300,
                  decoration: InputDecoration(
                    hintText:
                        'Tell farmers about yourself — your experience, work style, specialties…',
                    filled: true,
                    fillColor: const Color(0xFFF8FDF8),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: KMColors.primary, width: 2)),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ]),
            ),

            // ── Save Button ──────────────────────────────────────────────────
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
                      backgroundColor: KMColors.primary,
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

  void _showPhotoOptions() {
    if (_uploadingPhoto) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded,
                color: KMColors.primary),
            title: Text(_photoUrl.isNotEmpty
                ? 'Change Photo'
                : 'Upload Photo'),
            onTap: () {
              Navigator.pop(context);
              _pickPhoto();
            },
          ),
          if (_photoUrl.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: Colors.red),
              title: const Text('Remove Photo',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                setState(() => _photoUrl = '');
              },
            ),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Cancel'),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(children: [
      const Text('Profile Photo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 16),
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _showPhotoOptions,
        child: Stack(alignment: Alignment.bottomRight, children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: KMColors.cardTint,
            child: ClipOval(
              child: _photoUrl.isNotEmpty
                  ? Image.network(
                      _photoUrl,
                      width: 104,
                      height: 104,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person_rounded,
                        size: 52,
                        color: KMColors.primary,
                      ),
                    )
                  : const Icon(Icons.person_rounded,
                      size: 52, color: KMColors.primary),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
                color: KMColors.primary, shape: BoxShape.circle),
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
      Text(
        _uploadingPhoto
            ? 'Uploading…'
            : _photoUrl.isNotEmpty
                ? 'Tap to change or remove'
                : 'Tap to upload photo',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
    ]);
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 18, color: KMColors.primary),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: KMColors.textPrimary)),
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
              borderSide: const BorderSide(color: KMColors.primary, width: 2)),
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
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: child,
      ),
    );
  }
}
