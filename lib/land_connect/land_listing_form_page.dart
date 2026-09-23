import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../services/image_upload_service.dart';
import '../services/distance_service.dart';
import 'land_listing_model.dart';
import 'land_connect_service.dart';
import 'land_connect_constants.dart';

const _kPrimary = Color(kLcPrimary);

class LandListingFormPage extends StatefulWidget {
  final LandListing? existing;
  const LandListingFormPage({super.key, this.existing});

  @override
  State<LandListingFormPage> createState() => _LandListingFormPageState();
}

class _LandListingFormPageState extends State<LandListingFormPage> {
  final _formKey = GlobalKey<FormState>();
  int _step = 0;

  // Basic info
  final _titleCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _totalAcresCtrl = TextEditingController();
  final _availAcresCtrl = TextEditingController();
  String _landType = 'Agricultural';

  // Location
  double? _lat, _lng;
  final _locCtrl = TextEditingController(); // visible search field
  final _villageCtrl = TextEditingController();
  final _talukCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  bool _fetchingLocation = false;

  // Land details
  String _soilType = '';
  String _waterAvail = '';
  String _irrigType = '';
  bool _electricity = false;
  bool _road = false;
  bool _equipment = false;
  bool _fencing = false;
  bool _storage = false;

  // Crops
  final Set<String> _selectedCrops = {};

  // Arrangement
  String _arrangement = 'negotiable';
  final _rentCtrl = TextEditingController();
  String _rentPeriod = 'Yearly';
  final _shareCtrl = TextEditingController();

  // Availability
  DateTime? _startDate;
  DateTime? _endDate;

  // Images
  final List<XFile> _pickedImages = [];
  final List<Uint8List> _previewBytes = [];
  final List<String> _uploadedUrls = [];
  bool _uploadingImages = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.ownerName.isNotEmpty ? e.ownerName : e.title;
      _phoneCtrl.text = e.ownerPhone;
      _descCtrl.text = e.description;
      _totalAcresCtrl.text = e.totalAcres.toString();
      _availAcresCtrl.text = e.availableAcres.toString();
      _landType = e.landType;
      _lat = e.latitude;
      _lng = e.longitude;
      _villageCtrl.text = e.village;
      _talukCtrl.text = e.taluk;
      _districtCtrl.text = e.district;
      _stateCtrl.text = e.state;
      _pincodeCtrl.text = e.pincode;
      final locParts = [e.village, e.district, e.state].where((s) => s.isNotEmpty).toList();
      if (locParts.isNotEmpty) _locCtrl.text = locParts.join(', ');
      _soilType = e.soilType;
      _waterAvail = e.waterAvailability;
      _irrigType = e.irrigationType;
      _electricity = e.electricityAvailable;
      _road = e.roadAccess;
      _equipment = e.farmEquipmentAvailable;
      _fencing = e.fencingAvailable;
      _storage = e.storageAvailable;
      _selectedCrops.addAll(e.preferredCrops);
      _arrangement = e.arrangementType;
      _rentCtrl.text = e.expectedRent > 0 ? e.expectedRent.toStringAsFixed(0) : '';
      _rentPeriod = e.rentPeriod;
      _shareCtrl.text =
          e.revenueSharePercentage > 0 ? e.revenueSharePercentage.toStringAsFixed(0) : '';
      _startDate = e.availabilityStartDate;
      _endDate = e.availabilityEndDate;
      _uploadedUrls.addAll(e.images);
    } else {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _titleCtrl.text = user.displayName ?? user.email ?? '';
        _phoneCtrl.text = user.phoneNumber ?? '';
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _phoneCtrl.dispose();
    _descCtrl.dispose();
    _totalAcresCtrl.dispose();
    _availAcresCtrl.dispose();
    _locCtrl.dispose();
    _villageCtrl.dispose();
    _talukCtrl.dispose();
    _districtCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _rentCtrl.dispose();
    _shareCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Future<void> _detectLocation() async {
    setState(() => _fetchingLocation = true);
    final pos = await DistanceService.getUserLocation();
    if (pos != null && mounted) {
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _fetchingLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS coordinates captured. Please fill address details.')),
      );
    } else if (mounted) {
      setState(() => _fetchingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get location. Please enter address manually.')),
      );
    }
  }

  Future<void> _searchLocation() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _LandLocationSearchDialog(),
    );
    if (result != null && mounted) {
      setState(() {
        _locCtrl.text = result['display'] as String;
        _villageCtrl.text = result['village'] as String? ?? '';
        _talukCtrl.text = '';
        _districtCtrl.text = result['district'] as String? ?? '';
        _stateCtrl.text = result['state'] as String? ?? '';
        _pincodeCtrl.text = result['pincode'] as String? ?? '';
        _lat = result['lat'] as double?;
        _lng = result['lon'] as double?;
      });
    }
  }

  Future<void> _pickImages() async {
    if (_uploadedUrls.length + _pickedImages.length >= kMaxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum $kMaxImages images allowed')),
      );
      return;
    }
    final picker = ImagePicker();
    final remaining = kMaxImages - _uploadedUrls.length - _pickedImages.length;
    final picked = await picker.pickMultiImage(limit: remaining);
    if (picked.isEmpty) return;
    for (final xfile in picked) {
      final bytes = await xfile.readAsBytes();
      setState(() {
        _pickedImages.add(xfile);
        _previewBytes.add(bytes);
      });
    }
  }

  void _removePickedImage(int index) {
    setState(() {
      _pickedImages.removeAt(index);
      _previewBytes.removeAt(index);
    });
  }

  void _removeUploadedImage(int index) {
    setState(() => _uploadedUrls.removeAt(index));
  }

  Future<void> _uploadAllImages() async {
    setState(() => _uploadingImages = true);
    for (final xfile in _pickedImages) {
      final url = await ImageUploadService.uploadImageFromXFile(xfile);
      if (url != null) _uploadedUrls.add(url);
    }
    _pickedImages.clear();
    _previewBytes.clear();
    setState(() => _uploadingImages = false);
  }

  Future<void> _submit() async {
    if (_step < 5) {
      if (!_validateCurrentStep()) return;
      setState(() => _step++);
      return;
    }

    // Final submission
    if (_pickedImages.isNotEmpty) await _uploadAllImages();
    if (!mounted) return;

    setState(() => _submitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not signed in');

      final now = DateTime.now();
      final ownerName = _titleCtrl.text.trim();
      final listing = LandListing(
        id: widget.existing?.id ?? '',
        ownerId: user.uid,
        ownerName: ownerName,
        ownerPhone: _phoneCtrl.text.trim(),
        title: ownerName,
        description: _descCtrl.text.trim(),
        images: _uploadedUrls,
        totalAcres: double.tryParse(_totalAcresCtrl.text) ?? 0,
        availableAcres: double.tryParse(_availAcresCtrl.text) ?? 0,
        latitude: _lat,
        longitude: _lng,
        village: _villageCtrl.text.trim(),
        taluk: _talukCtrl.text.trim(),
        district: _districtCtrl.text.trim(),
        state: _stateCtrl.text.trim(),
        pincode: _pincodeCtrl.text.trim(),
        soilType: _soilType,
        waterAvailability: _waterAvail,
        irrigationType: _irrigType,
        electricityAvailable: _electricity,
        roadAccess: _road,
        farmEquipmentAvailable: _equipment,
        fencingAvailable: _fencing,
        storageAvailable: _storage,
        preferredCrops: _selectedCrops.toList(),
        landType: _landType,
        availabilityStartDate: _startDate,
        availabilityEndDate: _endDate,
        arrangementType: _arrangement,
        expectedRent: double.tryParse(_rentCtrl.text) ?? 0,
        rentPeriod: _rentPeriod,
        revenueSharePercentage: double.tryParse(_shareCtrl.text) ?? 0,
        status: 'active',
        createdAt: widget.existing?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.existing != null) {
        await LandConnectService.updateListing(listing);
      } else {
        await LandConnectService.createListing(listing);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Land listing published successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save listing: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  bool _validateCurrentStep() {
    if (_step == 0) {
      if (_titleCtrl.text.trim().isEmpty) {
        _showErr('Please enter your name');
        return false;
      }
      if (_phoneCtrl.text.trim().isEmpty) {
        _showErr('Please enter your phone number');
        return false;
      }
      if (double.tryParse(_totalAcresCtrl.text) == null ||
          double.tryParse(_totalAcresCtrl.text)! <= 0) {
        _showErr('Please enter valid total acres');
        return false;
      }
    }
    if (_step == 1) {
      if (_locCtrl.text.trim().isEmpty) {
        _showErr('Please search and select a location for your land');
        return false;
      }
    }
    return true;
  }

  void _showErr(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _kPrimary,
        title: Text(isEdit ? 'Edit Land Listing' : 'List Your Land',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Step indicator
          _StepIndicator(currentStep: _step, totalSteps: 6),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: _buildCurrentStep(context, cs),
              ),
            ),
          ),
          // Bottom bar
          _BottomBar(
            step: _step,
            totalSteps: 6,
            submitting: _submitting || _uploadingImages,
            onBack: _step > 0 ? () => setState(() => _step--) : null,
            onNext: _submit,
            nextLabel: _step == 5 ? (isEdit ? 'Update Listing' : 'Publish Listing') : 'Next',
            primaryColor: _kPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context, ColorScheme cs) {
    switch (_step) {
      case 0:
        return _buildBasicInfo(cs);
      case 1:
        return _buildLocation(cs);
      case 2:
        return _buildLandDetails(cs);
      case 3:
        return _buildCrops(cs);
      case 4:
        return _buildArrangement(cs);
      case 5:
        return _buildPhotosAndAvailability(cs);
      default:
        return const SizedBox();
    }
  }

  // ── Step 0: Basic Info ────────────────────────────────────────────────────────
  Widget _buildBasicInfo(ColorScheme cs) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _StepTitle('Basic Information',
          'Describe your land and how much is available'),
      const SizedBox(height: 16),
      _field('Owner Name *', _titleCtrl, hint: 'Your full name'),
      const SizedBox(height: 12),
      _field('Phone Number *', _phoneCtrl, hint: '+91 98765 43210', phone: true),
      const SizedBox(height: 12),
      _field('Description', _descCtrl, hint: 'Tell cultivators about your land', maxLines: 3),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _field('Total Acres *', _totalAcresCtrl, hint: '5.0', numeric: true)),
        const SizedBox(width: 12),
        Expanded(child: _field('Available Acres *', _availAcresCtrl, hint: '3.0', numeric: true)),
      ]),
      const SizedBox(height: 12),
      _label('Land Type'),
      const SizedBox(height: 6),
      Wrap(
        spacing: 8,
        children: kLandTypes.map((t) => ChoiceChip(
          label: Text(t),
          selected: _landType == t,
          onSelected: (_) => setState(() => _landType = t),
          selectedColor: const Color(kLcPrimary).withValues(alpha: 0.15),
        )).toList(),
      ),
    ]);
  }

  // ── Step 1: Location ──────────────────────────────────────────────────────────
  Widget _buildLocation(ColorScheme cs) {
    final hasLoc = _locCtrl.text.isNotEmpty;
    final hasGps = _lat != null && _lng != null;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _StepTitle('Location', 'Help cultivators find your land'),
      const SizedBox(height: 16),

      // Search box (tappable)
      GestureDetector(
        onTap: _searchLocation,
        child: AbsorbPointer(
          child: TextFormField(
            controller: _locCtrl,
            readOnly: true,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: 'Land Location',
              hintText: 'Search village, town or city...',
              prefixIcon: const Icon(Icons.location_on_rounded),
              suffixIcon: const Icon(Icons.search_rounded, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),

      // Action buttons
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _searchLocation,
            icon: const Icon(Icons.search_rounded, size: 16),
            label: const Text('Search Place', style: TextStyle(fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kPrimary,
              side: const BorderSide(color: Color(kLcPrimary)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _fetchingLocation ? null : _detectLocation,
            icon: _fetchingLocation
                ? const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.my_location_rounded, size: 16),
            label: const Text('Use GPS', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]),

      // Selected location confirmation
      if (hasLoc) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: Row(children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_locCtrl.text,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
      ],

      // GPS status
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hasGps ? Colors.green.shade50 : cs.primaryContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: hasGps ? Colors.green.shade200 : cs.primaryContainer),
        ),
        child: Row(children: [
          Icon(hasGps ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
              size: 15,
              color: hasGps ? Colors.green : cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasGps
                  ? 'GPS: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}'
                  : 'GPS not set — "Use GPS" gives precise distance to cultivators',
              style: TextStyle(fontSize: 12,
                  color: hasGps ? Colors.green.shade700 : cs.onSurfaceVariant),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 4),
      Text('Exact GPS is kept private. Cultivators see only distance.',
          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
    ]);
  }

  // ── Step 2: Land Details ──────────────────────────────────────────────────────
  Widget _buildLandDetails(ColorScheme cs) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _StepTitle('Land Details', 'Tell cultivators about soil, water and facilities'),
      const SizedBox(height: 16),
      _dropLabel('Soil Type', kSoilTypes, _soilType,
          (v) => setState(() => _soilType = v ?? '')),
      const SizedBox(height: 12),
      _dropLabel('Water Availability', kWaterSources, _waterAvail,
          (v) => setState(() => _waterAvail = v ?? '')),
      const SizedBox(height: 12),
      _dropLabel('Irrigation Type', kIrrigationTypes, _irrigType,
          (v) => setState(() => _irrigType = v ?? '')),
      const SizedBox(height: 16),
      _label('Facilities Available'),
      const SizedBox(height: 8),
      _toggleRow('Electricity', _electricity, (v) => setState(() => _electricity = v)),
      _toggleRow('Road Access', _road, (v) => setState(() => _road = v)),
      _toggleRow('Farm Equipment', _equipment, (v) => setState(() => _equipment = v)),
      _toggleRow('Fencing', _fencing, (v) => setState(() => _fencing = v)),
      _toggleRow('Storage', _storage, (v) => setState(() => _storage = v)),
    ]);
  }

  // ── Step 3: Crops ─────────────────────────────────────────────────────────────
  Widget _buildCrops(ColorScheme cs) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _StepTitle('Preferred Crops',
          'Select crops suitable for your land (choose as many as applicable)'),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children: kCrops.map((crop) {
          final sel = _selectedCrops.contains(crop);
          return FilterChip(
            label: Text(crop),
            selected: sel,
            onSelected: (v) => setState(() => v
                ? _selectedCrops.add(crop)
                : _selectedCrops.remove(crop)),
            selectedColor: const Color(kLcPrimary).withValues(alpha: 0.15),
            checkmarkColor: _kPrimary,
          );
        }).toList(),
      ),
      if (_selectedCrops.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text('Selected: ${_selectedCrops.join(', ')}',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      ],
    ]);
  }

  // ── Step 4: Arrangement ───────────────────────────────────────────────────────
  Widget _buildArrangement(ColorScheme cs) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _StepTitle('Arrangement', 'Choose how you want to work with the cultivator'),
      const SizedBox(height: 16),
      RadioGroup<String>(
        groupValue: _arrangement,
        onChanged: (v) => setState(() => _arrangement = v!),
        child: Column(
          children: kArrangements.map((arr) => RadioListTile<String>(
            value: arr,
            title: Text(kArrangementLabels[arr] ?? arr,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(_arrangementDesc(arr),
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            activeColor: _kPrimary,
          )).toList(),
        ),
      ),
      const SizedBox(height: 12),
      if (_arrangement == 'fixed_rent') ...[
        Row(children: [
          Expanded(child: _field('Expected Rent (₹)', _rentCtrl,
              hint: '30000', numeric: true)),
          const SizedBox(width: 12),
          Expanded(child: _dropLabel('Period', kRentPeriods, _rentPeriod,
              (v) => setState(() => _rentPeriod = v ?? 'Yearly'))),
        ]),
      ],
      if (_arrangement == 'revenue_share')
        _field('Revenue Share (%)', _shareCtrl,
            hint: '40', numeric: true),
    ]);
  }

  // ── Step 5: Photos + Availability ────────────────────────────────────────────
  Widget _buildPhotosAndAvailability(ColorScheme cs) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _StepTitle('Photos & Availability', 'Add photos and set when the land is available'),
      const SizedBox(height: 16),
      _label('Land Photos (up to $kMaxImages)'),
      const SizedBox(height: 8),
      // Existing (uploaded) images
      if (_uploadedUrls.isNotEmpty)
        Wrap(spacing: 8, runSpacing: 8, children: [
          ..._uploadedUrls.asMap().entries.map((e) => _ImageThumb(
                networkUrl: e.value,
                onRemove: () => _removeUploadedImage(e.key),
              )),
        ]),
      // Newly picked (preview) images
      if (_previewBytes.isNotEmpty)
        Wrap(spacing: 8, runSpacing: 8, children: [
          ..._previewBytes.asMap().entries.map((e) => _ImageThumb(
                bytes: e.value,
                onRemove: () => _removePickedImage(e.key),
              )),
        ]),
      const SizedBox(height: 8),
      if (_uploadedUrls.length + _pickedImages.length < kMaxImages)
        OutlinedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Add Photos'),
          style: OutlinedButton.styleFrom(foregroundColor: _kPrimary,
              side: const BorderSide(color: Color(kLcPrimary))),
        ),
      const SizedBox(height: 20),
      _label('Availability Period (optional)'),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _DateField(
          label: 'Available From',
          value: _startDate,
          onPick: (d) => setState(() => _startDate = d),
        )),
        const SizedBox(width: 12),
        Expanded(child: _DateField(
          label: 'Available Until',
          value: _endDate,
          onPick: (d) => setState(() => _endDate = d),
        )),
      ]),
    ]);
  }

  // ── Shared widget helpers ─────────────────────────────────────────────────────

  Widget _field(String label, TextEditingController ctrl,
      {String hint = '', int maxLines = 1, bool numeric = false, bool phone = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(label),
      const SizedBox(height: 4),
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: phone
            ? TextInputType.phone
            : numeric
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
        decoration: InputDecoration(hintText: hint),
      ),
    ]);
  }

  Widget _label(String text) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13));

  Widget _dropLabel(String label, List<String> items, String value,
      void Function(String?) onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(label),
      const SizedBox(height: 4),
      DropdownButtonFormField<String>(
        initialValue: value.isEmpty ? null : value,
        hint: Text('Select $label'),
        items: items
            .map((i) => DropdownMenuItem(value: i, child: Text(i)))
            .toList(),
        onChanged: onChanged,
        decoration: const InputDecoration(),
      ),
    ]);
  }

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      activeThumbColor: _kPrimary,
      onChanged: onChanged,
    );
  }

  String _arrangementDesc(String arr) {
    switch (arr) {
      case 'fixed_rent':
        return 'Cultivator pays a fixed rent amount (e.g. ₹30,000/year)';
      case 'revenue_share':
        return 'You receive a percentage of crop revenue';
      case 'negotiable':
        return 'Terms to be discussed and agreed directly';
      default:
        return '';
    }
  }
}

// ── Location search dialog ────────────────────────────────────────────────────

class _LandLocationSearchDialog extends StatefulWidget {
  const _LandLocationSearchDialog();

  @override
  State<_LandLocationSearchDialog> createState() => _LandLocationSearchDialogState();
}

class _LandLocationSearchDialogState extends State<_LandLocationSearchDialog> {
  final _ctrl = TextEditingController();
  List<dynamic> _results = [];
  bool _searching = false;
  static const _api = 'pk.56ccd9d8fb2cd5f3e9d7a656e3b52566';

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
      final uri = Uri.parse(
          'https://us1.locationiq.com/v1/search.php?key=$_api&q=${Uri.encodeComponent(val)}&format=json&limit=8&addressdetails=1');
      final res = await http.get(uri);
      if (res.statusCode == 200 && mounted) {
        setState(() => _results = json.decode(res.body));
      }
    } catch (_) {}
    if (mounted) setState(() => _searching = false);
  }

  Map<String, dynamic> _parseResult(Map r) {
    final addr = r['address'] as Map? ?? {};
    final village = (addr['village'] as String?)?.isNotEmpty == true
        ? addr['village'] as String
        : (addr['town'] as String?)?.isNotEmpty == true
            ? addr['town'] as String
            : (addr['city'] as String?)?.isNotEmpty == true
                ? addr['city'] as String
                : (addr['county'] as String?) ?? '';
    final district = (addr['county'] as String?)
        ?? (addr['state_district'] as String?)
        ?? '';
    final state = (addr['state'] as String?) ?? '';
    final pincode = (addr['postcode'] as String?) ?? '';
    return {
      'display': r['display_name'] as String,
      'village': village,
      'district': district,
      'state': state,
      'pincode': pincode,
      'lat': double.tryParse(r['lat'] as String? ?? '0') ?? 0.0,
      'lon': double.tryParse(r['lon'] as String? ?? '0') ?? 0.0,
    };
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
                          width: 16, height: 16,
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
                        style: TextStyle(color: Colors.grey, fontSize: 13)))
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFF0F0F0)),
                    itemBuilder: (_, i) {
                      final r = _results[i] as Map;
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on_rounded,
                            color: _kPrimary, size: 18),
                        title: Text(r['display_name'] as String,
                            style: const TextStyle(fontSize: 12.5),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        onTap: () =>
                            Navigator.pop(context, _parseResult(r)),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _StepTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _StepTitle(this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(subtitle, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
    ]);
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  const _StepIndicator({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    final labels = ['Basic', 'Location', 'Details', 'Crops', 'Arrangement', 'Photos'];
    return Container(
      color: const Color(kLcPrimary).withValues(alpha: 0.06),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: List.generate(totalSteps, (i) {
          final active = i == currentStep;
          final done = i < currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: done
                            ? const Color(kLcPrimary)
                            : active
                                ? const Color(kLcPrimary)
                                : Colors.grey.shade300,
                        child: done
                            ? const Icon(Icons.check, size: 12, color: Colors.white)
                            : Text('${i + 1}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: active ? Colors.white : Colors.grey.shade600)),
                      ),
                      const SizedBox(height: 2),
                      Text(labels[i],
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: active ? FontWeight.bold : FontWeight.normal,
                              color: active ? const Color(kLcPrimary) : Colors.grey)),
                    ],
                  ),
                ),
                if (i < totalSteps - 1)
                  Expanded(
                    flex: 0,
                    child: Container(
                      width: 16, height: 1,
                      color: done ? const Color(kLcPrimary) : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int step;
  final int totalSteps;
  final bool submitting;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final String nextLabel;
  final Color primaryColor;

  const _BottomBar({
    required this.step,
    required this.totalSteps,
    required this.submitting,
    this.onBack,
    required this.onNext,
    required this.nextLabel,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          if (onBack != null)
            OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor)),
              child: const Text('Back'),
            ),
          if (onBack != null) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: submitting ? null : onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: submitting
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(nextLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ImageThumb extends StatelessWidget {
  final String? networkUrl;
  final Uint8List? bytes;
  final VoidCallback onRemove;

  const _ImageThumb({this.networkUrl, this.bytes, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 80, height: 80,
          child: networkUrl != null
              ? Image.network(networkUrl!, fit: BoxFit.cover)
              : Image.memory(bytes!, fit: BoxFit.cover),
        ),
      ),
      Positioned(
        top: 2, right: 2,
        child: GestureDetector(
          onTap: onRemove,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 16),
          ),
        ),
      ),
    ]);
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;

  const _DateField({required this.label, this.value, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 30)),
          lastDate: DateTime.now().add(const Duration(days: 1825)),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value != null
                  ? '${value!.day}/${value!.month}/${value!.year}'
                  : label,
              style: TextStyle(
                  fontSize: 13,
                  color: value != null ? null : Colors.grey),
            ),
          ),
        ]),
      ),
    );
  }
}
