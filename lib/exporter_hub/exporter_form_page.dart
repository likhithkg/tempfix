// lib/exporter_hub/exporter_form_page.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'export_constants.dart';
import 'exporter_model.dart';
import 'exporter_service.dart';
import '../services/image_upload_service.dart';
import '../l10n/app_localizations.dart';
import '../labour_hub/location_search_dialog.dart';

class ExporterFormPage extends StatefulWidget {
  final ExportProduct? existingProduct;
  final String listingSource;

  const ExporterFormPage({
    Key? key,
    this.existingProduct,
    this.listingSource = 'export_hub',
  }) : super(key: key);

  @override
  State<ExporterFormPage> createState() => _ExporterFormPageState();
}

class _ExporterFormPageState extends State<ExporterFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _svc = ExporterService();
  final _picker = ImagePicker();

  // ── Basic Controllers ──
  final _productNameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _farmerNameCtrl = TextEditingController();
  final _farmerMobileCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  // ── Phase 3 Controllers ──
  final _expectedPriceCtrl = TextEditingController();
  final _minOrderQtyCtrl = TextEditingController();
  final _varietyCtrl = TextEditingController();
  final _moistureLevelCtrl = TextEditingController();
  final _storageLocationCtrl = TextEditingController();
  final _packagingTypeCtrl = TextEditingController();

  // ── State ──
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  bool _detectingLocation = false;
  bool _advancedExpanded = false;

  String _category = 'Crops';
  String _unit = 'kg';
  String? _grade;         // 'A', 'B', 'C'
  bool _isOrganic = false;
  DateTime? _harvestDate;

  // Primary image (backward-compat)
  File? _pickedImageFile;
  String? _imageUrl;

  // Additional images (Phase 3 — imageUrls array)
  final List<File> _additionalFiles = [];
  final List<String> _additionalUrls = [];

  double? _selectedLat;
  double? _selectedLon;

  final List<String> _categories = ['Crops', 'Fruits', 'Vegetables', 'Grains', 'Spices', 'Other'];
  final List<String?> _grades = [null, 'A', 'B', 'C'];

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  void _loadExisting() {
    final p = widget.existingProduct;
    if (p == null) return;

    _productNameCtrl.text = p.productName;
    _priceCtrl.text = p.pricePerUnit;

    final parts = p.quantity.split(' ');
    _quantityCtrl.text = parts.isNotEmpty ? parts[0] : p.quantity;
    if (parts.length > 1) _unit = parts[1];

    _farmerNameCtrl.text = p.farmerName;
    _farmerMobileCtrl.text = p.farmerMobile ?? p.farmerId;
    _locationCtrl.text = p.location;
    _descriptionCtrl.text = p.description;
    _category = p.category.isNotEmpty ? p.category : _category;
    _imageUrl = p.imageUrl;

    // Phase 3
    _grade = p.grade;
    _isOrganic = p.isOrganic;
    _harvestDate = p.harvestDate;
    _expectedPriceCtrl.text = p.expectedPrice ?? '';
    _minOrderQtyCtrl.text = p.minOrderQty ?? '';
    _varietyCtrl.text = p.variety ?? '';
    _moistureLevelCtrl.text = p.moistureLevel ?? '';
    _storageLocationCtrl.text = p.storageLocation ?? '';
    _packagingTypeCtrl.text = p.packagingType ?? '';
    _additionalUrls.addAll(p.imageUrls.where((u) => u != _imageUrl));

    if (_grade != null || _isOrganic || _harvestDate != null ||
        _expectedPriceCtrl.text.isNotEmpty || _minOrderQtyCtrl.text.isNotEmpty) {
      _advancedExpanded = true;
    }
  }

  @override
  void dispose() {
    _productNameCtrl.dispose();
    _priceCtrl.dispose();
    _quantityCtrl.dispose();
    _farmerNameCtrl.dispose();
    _farmerMobileCtrl.dispose();
    _locationCtrl.dispose();
    _descriptionCtrl.dispose();
    _expectedPriceCtrl.dispose();
    _minOrderQtyCtrl.dispose();
    _varietyCtrl.dispose();
    _moistureLevelCtrl.dispose();
    _storageLocationCtrl.dispose();
    _packagingTypeCtrl.dispose();
    super.dispose();
  }

  // ── Image Picker ──

  Future<void> _pickImage(ImageSource src) async {
    try {
      final picked = await _picker.pickImage(source: src, imageQuality: 80, maxWidth: 1200);
      if (picked != null) setState(() => _pickedImageFile = File(picked.path));
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image pick failed: ${e.message}')));
      }
    }
  }

  Future<void> _pickAdditionalImage() async {
    if (_additionalFiles.length + _additionalUrls.length >= 4) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Max 4 additional images')));
      }
      return;
    }
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1200);
      if (picked != null) setState(() => _additionalFiles.add(File(picked.path)));
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image pick failed: ${e.message}')));
      }
    }
  }

  Future<String?> _uploadImage(File file) async {
    setState(() => _isUploadingImage = true);
    try {
      final imageUrl = await ImageUploadService.uploadImage(file);
      if (imageUrl == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.imageUploadFailed)));
      }
      return imageUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload Error: $e')));
      }
      return null;
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  // ── Location ──


  Future<void> _detectLocation() async {
    setState(() => _detectingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services disabled')));
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission denied')));
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      _selectedLat = pos.latitude;
      _selectedLon = pos.longitude;
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final pm = placemarks.first;
        final parts = [pm.locality, pm.subAdministrativeArea, pm.administrativeArea]
            .where((e) => e != null).join(', ');
        if (mounted) setState(() => _locationCtrl.text = parts);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location error: $e')));
    } finally {
      if (mounted) setState(() => _detectingLocation = false);
    }
  }

  // ── Save ──

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login first')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Upload primary image
      if (_pickedImageFile != null) {
        final uploaded = await _uploadImage(_pickedImageFile!);
        if (uploaded != null) _imageUrl = uploaded;
      }

      // Upload additional images
      final uploadedAdditional = List<String>.from(_additionalUrls);
      for (final file in _additionalFiles) {
        final url = await _uploadImage(file);
        if (url != null) uploadedAdditional.add(url);
      }

      // Build imageUrls list (primary + additional)
      final allImageUrls = <String>[];
      if (_imageUrl != null && _imageUrl!.isNotEmpty) allImageUrls.add(_imageUrl!);
      allImageUrls.addAll(uploadedAdditional);

      final editing = widget.existingProduct != null && widget.existingProduct!.id.isNotEmpty;
      final productId = editing
          ? widget.existingProduct!.id
          : DateTime.now().millisecondsSinceEpoch.toString();

      final farmerMobile = _farmerMobileCtrl.text.trim();

      final product = ExportProduct(
        id: productId,
        productName: _productNameCtrl.text.trim(),
        pricePerUnit: _priceCtrl.text.trim(),
        quantity: '${_quantityCtrl.text.trim()} $_unit',
        farmerId: user.uid,
        farmerName: _farmerNameCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        category: _category,
        farmerMobile: farmerMobile,
        imageUrl: _imageUrl,
        createdAt: widget.existingProduct?.createdAt,
        ownerId: user.uid,
        ownerEmail: user.email,
        ownerName: user.displayName,
        ownerPhone: user.phoneNumber,
        // Phase 3 fields
        grade: _grade,
        isOrganic: _isOrganic,
        harvestDate: _harvestDate,
        expectedPrice: _expectedPriceCtrl.text.trim().isNotEmpty ? _expectedPriceCtrl.text.trim() : null,
        minOrderQty: _minOrderQtyCtrl.text.trim().isNotEmpty ? _minOrderQtyCtrl.text.trim() : null,
        variety: _varietyCtrl.text.trim().isNotEmpty ? _varietyCtrl.text.trim() : null,
        moistureLevel: _moistureLevelCtrl.text.trim().isNotEmpty ? _moistureLevelCtrl.text.trim() : null,
        storageLocation: _storageLocationCtrl.text.trim().isNotEmpty ? _storageLocationCtrl.text.trim() : null,
        packagingType: _packagingTypeCtrl.text.trim().isNotEmpty ? _packagingTypeCtrl.text.trim() : null,
        listingStatus: widget.existingProduct?.listingStatus ?? ListingStatus.active,
        listingSource: widget.existingProduct?.listingSource.isNotEmpty == true
            ? widget.existingProduct!.listingSource
            : widget.listingSource,
        imageUrls: allImageUrls,
      );

      if (editing) {
        final payload = product.toMap();
        payload['ownerId'] = user.uid;
        if (_selectedLat != null && _selectedLon != null) {
          payload['locationLat'] = _selectedLat;
          payload['locationLon'] = _selectedLon;
        }
        await _svc.updateExportProduct(productId, payload);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.productUpdatedSuccessfully)));
        Navigator.pop(context, true);
      } else {
        final docRef = await _svc.addExportProduct(product);
        if (_selectedLat != null && _selectedLon != null) {
          await docRef.update({'locationLat': _selectedLat, 'locationLon': _selectedLon});
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.productAddedSuccessfully)));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── UI ──

  @override
  Widget build(BuildContext context) {
    final editing = widget.existingProduct != null;
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? l.editExportProductTitle : l.addExportProductTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Basic Fields ──
              _Field(child: TextFormField(
                controller: _productNameCtrl,
                decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Enter product name' : null,
              )),
              _Field(child: DropdownButtonFormField<String>(
                value: _category,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) { if (v != null) setState(() => _category = v); },
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              )),
              _Field(child: TextFormField(
                controller: _priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Price per unit/KG (₹)', border: OutlineInputBorder()),
              )),
              _Field(child: Row(children: [
                Expanded(child: TextFormField(
                  controller: _quantityCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Available Quantity', border: OutlineInputBorder()),
                )),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _unit,
                  items: ['kg', 'MT', 'quintal', 'ton', 'piece']
                      .map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (v) { if (v != null) setState(() => _unit = v); },
                ),
              ])),
              _Field(child: TextFormField(
                controller: _farmerNameCtrl,
                decoration: const InputDecoration(labelText: 'Farmer Name', border: OutlineInputBorder()),
              )),
              _Field(child: TextFormField(
                controller: _farmerMobileCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Farmer Mobile', border: OutlineInputBorder()),
              )),
              _Field(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(12),
                    child: GestureDetector(
                      onTap: () async {
                        final result = await showDialog<LocationResult>(
                          context: context,
                          builder: (_) => const LocationSearchDialog(),
                        );
                        if (result != null && mounted) {
                          setState(() {
                            _locationCtrl.text = result.displayName;
                            _selectedLat = result.lat;
                            _selectedLon = result.lon;
                          });
                        }
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
                            child: Text(
                              _locationCtrl.text.isNotEmpty ? _locationCtrl.text : 'Location (Village / District)',
                              style: TextStyle(
                                fontSize: 14,
                                color: _locationCtrl.text.isNotEmpty ? Colors.black87 : Colors.grey.shade500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
                            context: context,
                            builder: (_) => const LocationSearchDialog(),
                          );
                          if (result != null && mounted) {
                            setState(() {
                              _locationCtrl.text = result.displayName;
                              _selectedLat = result.lat;
                              _selectedLon = result.lon;
                            });
                          }
                        },
                        icon: const Icon(Icons.search_rounded, size: 16),
                        label: const Text('Search Place', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green.shade700,
                          side: BorderSide(color: Colors.green.shade700),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _detectingLocation ? null : _detectLocation,
                        icon: _detectingLocation
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.my_location_rounded, size: 16),
                        label: Text(_detectingLocation ? 'Locating…' : 'Use GPS',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ]),
                ],
              )),
              _Field(child: TextFormField(
                controller: _descriptionCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              )),

              // ── Primary Image ──
              _buildPrimaryImageSection(l),

              const SizedBox(height: 16),

              // ── Advanced Details (Phase 3) ──
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: _advancedExpanded,
                  onExpansionChanged: (v) => setState(() => _advancedExpanded = v),
                  title: Row(children: [
                    Icon(Icons.tune, color: Theme.of(context).colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(l.advancedDetails,
                        style: TextStyle(fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary)),
                  ]),
                  children: [
                    _Field(child: DropdownButtonFormField<String?>(
                      value: _grade,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('No grade selected')),
                        ..._grades.skip(1).map((g) => DropdownMenuItem(value: g, child: Text('Grade $g'))),
                      ],
                      onChanged: (v) => setState(() => _grade = v),
                      decoration: InputDecoration(labelText: l.grade, border: const OutlineInputBorder()),
                    )),
                    _Field(child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.organic),
                      subtitle: Text(l.isOrganicSubtitle),
                      value: _isOrganic,
                      onChanged: (v) => setState(() => _isOrganic = v),
                    )),
                    _Field(child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _harvestDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setState(() => _harvestDate = picked);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(labelText: l.harvestDate, border: const OutlineInputBorder()),
                        child: Text(
                          _harvestDate != null
                              ? '${_harvestDate!.day}/${_harvestDate!.month}/${_harvestDate!.year}'
                              : 'Tap to select date',
                          style: TextStyle(
                              color: _harvestDate != null ? null : Colors.grey.shade500),
                        ),
                      ),
                    )),
                    _Field(child: TextFormField(
                      controller: _varietyCtrl,
                      decoration: InputDecoration(labelText: l.varietyLabel, border: const OutlineInputBorder(),
                          hintText: 'e.g. Alphonso, Basmati'),
                    )),
                    _Field(child: TextFormField(
                      controller: _expectedPriceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: '${l.expectedPriceLabel} (₹)', border: const OutlineInputBorder()),
                    )),
                    _Field(child: TextFormField(
                      controller: _minOrderQtyCtrl,
                      decoration: InputDecoration(labelText: l.minOrder, border: const OutlineInputBorder(),
                          hintText: 'e.g. 100 kg'),
                    )),
                    _Field(child: TextFormField(
                      controller: _moistureLevelCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: l.moistureLevelLabel, border: const OutlineInputBorder(),
                          hintText: 'e.g. 12.5'),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                    )),
                    _Field(child: TextFormField(
                      controller: _storageLocationCtrl,
                      decoration: InputDecoration(labelText: l.storageLocationLabel, border: const OutlineInputBorder()),
                    )),
                    _Field(child: TextFormField(
                      controller: _packagingTypeCtrl,
                      decoration: InputDecoration(labelText: l.packagingTypeLabel, border: const OutlineInputBorder(),
                          hintText: 'e.g. Jute bags, Poly bags'),
                    )),

                    // ── Additional Images ──
                    _buildAdditionalImagesSection(l),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(editing ? l.update : l.addExportProductTitle,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryImageSection(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.productImageLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Row(children: [
            _imagePreviewWidget(),
            const SizedBox(width: 12),
            Column(children: [
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.photo_camera),
                label: Text(l.camera),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: Text(l.gallery),
              ),
            ]),
          ]),
          if (_isUploadingImage)
            const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildAdditionalImagesSection(AppLocalizations l) {
    final allPreviews = <Widget>[];

    // Existing uploaded URLs
    for (final url in _additionalUrls) {
      allPreviews.add(_AdditionalImageThumb(
        url: url,
        onRemove: () => setState(() => _additionalUrls.remove(url)),
      ));
    }

    // Newly picked files
    for (final file in _additionalFiles) {
      allPreviews.add(_AdditionalFileThumb(
        file: file,
        onRemove: () => setState(() => _additionalFiles.remove(file)),
      ));
    }

    // Add button
    if (_additionalFiles.length + _additionalUrls.length < 4) {
      allPreviews.add(GestureDetector(
        onTap: _pickAdditionalImage,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.add_photo_alternate_outlined,
              color: Theme.of(context).colorScheme.primary, size: 32),
        ),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.additionalImagesLabel,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: allPreviews.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => allPreviews[i],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePreviewWidget() {
    const double size = 120;
    if (_pickedImageFile != null) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(_pickedImageFile!, width: size, height: size, fit: BoxFit.cover));
    }
    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(_imageUrl!, width: size, height: size, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
                width: size, height: size, color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image))),
      );
    }
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey.shade100),
      child: const Icon(Icons.photo, size: 44, color: Colors.grey),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final Widget child;
  const _Field({required this.child});

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(bottom: 12), child: child);
}

class _AdditionalImageThumb extends StatelessWidget {
  final String url;
  final VoidCallback onRemove;
  const _AdditionalImageThumb({required this.url, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(url, width: 80, height: 80, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(width: 80, height: 80, color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image))),
        ),
        Positioned(
          top: -6, right: -6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22, height: 22,
              decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5)),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _AdditionalFileThumb extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;
  const _AdditionalFileThumb({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
        ),
        Positioned(
          top: -6, right: -6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22, height: 22,
              decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5)),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
