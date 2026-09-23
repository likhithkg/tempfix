// lib/exporter_hub/exporter_form_page.dart
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

  String _category = 'Crops';
  String _unit = 'kg';
  String? _grade;         // 'A', 'B', 'C'
  bool _isOrganic = false;
  DateTime? _harvestDate;

  // Primary image (backward-compat)
  XFile? _pickedXFile;
  Uint8List? _pickedImageBytes;
  String? _imageUrl;

  // Additional images (Phase 3 — imageUrls array)
  final List<XFile> _additionalFiles = [];
  final List<String> _additionalUrls = [];

  double? _selectedLat;
  double? _selectedLon;

  final List<String> _categories = ['Crops', 'Fruits', 'Vegetables', 'Grains', 'Spices', 'Other'];
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
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() { _pickedXFile = picked; _pickedImageBytes = bytes; });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image pick failed: ${e.message}')));
      }
    }
  }

  Future<String?> _uploadXFile(XFile xfile) async {
    setState(() => _isUploadingImage = true);
    try {
      final imageUrl = await ImageUploadService.uploadImageFromXFile(xfile);
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
            .whereType<String>().where((e) => e.isNotEmpty).join(', ');
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
      if (_pickedXFile != null) {
        final uploaded = await _uploadXFile(_pickedXFile!);
        if (uploaded != null) _imageUrl = uploaded;
      }

      // Upload additional images
      final uploadedAdditional = List<String>.from(_additionalUrls);
      for (final xfile in _additionalFiles) {
        final url = await _uploadXFile(xfile);
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
        title: Text(editing ? l.editExportProductTitle : 'Add Product'),
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
                      : Text(editing ? l.update : 'Add Product',
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

  Widget _imagePreviewWidget() {
    const double size = 120;
    if (_pickedImageBytes != null) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(_pickedImageBytes!, width: size, height: size, fit: BoxFit.cover));
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

