// lib/exporter_hub/exporter_form_page.dart
// (Advanced Add/Edit product page — uses farmerMobile and modal location search like RentListFormPage)

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

import 'exporter_model.dart';
import 'exporter_service.dart';

class ExporterFormPage extends StatefulWidget {
  final ExportProduct? existingProduct; // optional - edit mode

  const ExporterFormPage({Key? key, this.existingProduct}) : super(key: key);

  @override
  State<ExporterFormPage> createState() => _ExporterFormPageState();
}

class _ExporterFormPageState extends State<ExporterFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _svc = ExporterService();

  // Controllers
  final _productNameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _farmerNameCtrl = TextEditingController();
  final _farmerMobileCtrl = TextEditingController(); // mobile instead of farmer id
  final _locationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _customCategoryCtrl = TextEditingController();

  // UI state
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  bool _detectingLocation = false;

  // advanced fields
  String _category = 'Crops';
  String _unit = 'kg';
  File? _pickedImageFile;
  String? _imageUrl; // final image url (existing or uploaded)
  final ImagePicker _picker = ImagePicker();

  // selected place coordinates (set when user picks a suggestion or auto-detect)
  double? _selectedLat;
  double? _selectedLon;

  // predefined categories
  final List<String> _categories = [
    'Crops',
    'Fruits',
    'Vegetables',
    'Grains',
    'Spices',
    'Other'
  ];

  // LocationIQ key — you may replace this with secure loading
  static const String _locationIQKey = 'pk.56ccd9d8fb2cd5f3e9d7a656e3b52566';

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  void _loadExisting() {
    final p = widget.existingProduct;
    if (p != null) {
      _productNameCtrl.text = p.productName;
      _priceCtrl.text = p.pricePerUnit;
      final qty = p.quantity;
      final parts = qty.split(' ');
      if (parts.isNotEmpty) _quantityCtrl.text = parts[0];
      if (parts.length > 1) _unit = parts[1];
      _farmerNameCtrl.text = p.farmerName;
      _farmerMobileCtrl.text = p.farmerMobile ?? p.farmerId ?? '';
      _locationCtrl.text = p.location;
      _descriptionCtrl.text = p.description;
      _category = p.category.isNotEmpty ? p.category : _category;
      _imageUrl = p.imageUrl;

      // try to load lat/lon if present
      try {
        final dyn = p.toMap();
        if (dyn['locationLat'] != null && dyn['locationLon'] != null) {
          _selectedLat = (dyn['locationLat'] as num).toDouble();
          _selectedLon = (dyn['locationLon'] as num).toDouble();
        }
      } catch (_) {}
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
    _customCategoryCtrl.dispose();
    super.dispose();
  }

  // Image picking
  Future<void> _pickImage(ImageSource src) async {
    try {
      final picked = await _picker.pickImage(source: src, imageQuality: 80, maxWidth: 1200);
      if (picked != null) {
        setState(() => _pickedImageFile = File(picked.path));
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image pick failed: ${e.message}')));
    }
  }

  Future<String?> _uploadImage(File file) async {
    setState(() => _isUploadingImage = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? 'anon';
      final fileName = '${const Uuid().v4()}.jpg';
      final refPath = 'export_products/$uid/$fileName';
      final ref = FirebaseStorage.instance.ref().child(refPath);

      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image upload failed: ${e.toString()}')));
      return null;
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  // ----------------------------
  // Location helpers (modal search + auto-detect)
  // ----------------------------
Future<void> _openLocationSearchModal() async {
  final ctrl = TextEditingController(); // moved outside the builder so it survives rebuilds
  Map<String, dynamic>? selectedResult;

  try {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        // local state variables for the dialog UI
        List<dynamic> results = [];
        bool loading = false;
        String? error;
        Timer? debounce;

        // perform search (uses ctrl.text from outer scope)
        Future<void> doSearch(String val, void Function(void Function()) setStateDialog) async {
          if (val.trim().length < 2) {
            results = [];
            error = null;
            setStateDialog(() {}); // update UI
            return;
          }
          loading = true;
          error = null;
          setStateDialog(() {});
          final q = Uri.encodeQueryComponent(val.trim());
          final url =
              "https://us1.locationiq.com/v1/search.php?key=$_locationIQKey&q=$q&format=json&limit=8&countrycodes=in";
          try {
            final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
            if (resp.statusCode == 200) {
              final body = json.decode(resp.body);
              if (body is List) {
                results = body.where((e) => e != null && e['lat'] != null && e['lon'] != null).toList();
              } else {
                results = [];
              }
            } else {
              results = [];
              error = 'Search failed: ${resp.statusCode}';
            }
          } catch (e) {
            results = [];
            error = 'Network error';
          } finally {
            loading = false;
            setStateDialog(() {});
          }
        }

        return StatefulBuilder(
          builder: (ctx2, setStateDialog) => AlertDialog(
            title: const Text('Search location'),
            content: SizedBox(
              width: double.maxFinite,
              height: 360,
              child: Column(
                children: [
                  // USE THE OUTER ctrl here — it won't be recreated on rebuild
                  TextField(
                    controller: ctrl,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Type village, taluk or district (min 2 chars)...',
                    ),
                    onChanged: (val) {
                      error = null;
                      debounce?.cancel();
                      debounce = Timer(const Duration(milliseconds: 420), () {
                        setStateDialog(() => loading = true);
                        doSearch(val, setStateDialog);
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  if (loading) const LinearProgressIndicator(),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(error!, style: const TextStyle(color: Colors.red)),
                    ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: results.isEmpty
                        ? Center(child: Text(loading ? 'Searching...' : 'No results'))
                        : ListView.separated(
                            itemCount: results.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final r = results[i] as Map<String, dynamic>;
                              final displayName = (r['display_name'] ?? r['display'] ?? '').toString();
                              final latStr = (r['lat'] ?? '').toString();
                              final lonStr = (r['lon'] ?? '').toString();
                              final lat = double.tryParse(latStr);
                              final lon = double.tryParse(lonStr);
                              if (lat == null || lon == null) return const SizedBox.shrink();

                              final shortParts = displayName.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                              final nameShort = shortParts.isEmpty ? displayName : (shortParts.length == 1 ? shortParts[0] : '${shortParts[0]}, ${shortParts[1]}');

                              return ListTile(
                                leading: const Icon(Icons.location_on),
                                title: Text(nameShort, maxLines: 2, overflow: TextOverflow.ellipsis),
                                subtitle: Text(displayName, maxLines: 2, overflow: TextOverflow.ellipsis),
                                trailing: Text('${lat.toStringAsFixed(3)}, ${lon.toStringAsFixed(3)}', style: const TextStyle(fontSize: 12)),
                                onTap: () {
                                  // return a small payload via Navigator.pop
                                  Navigator.pop(ctx, {
                                    'display': displayName,
                                    'short': nameShort,
                                    'lat': lat,
                                    'lon': lon,
                                  });
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result != null) {
      // set controller and coords
      setState(() {
        final short = (result['short'] as String?) ?? (result['display'] as String?) ?? '';
        _locationCtrl.text = short;
        _locationCtrl.selection = TextSelection.collapsed(offset: short.length);
        _selectedLat = (result['lat'] as double?);
        _selectedLon = (result['lon'] as double?);
      });
    }
  } finally {
    // dispose controller after dialog closes
    ctrl.dispose();
  }
}


  /// Reverse-geocode lat/lon into a friendly "village, taluk" string where possible.
  /// Returns the display string or null if nothing useful.
  Future<String?> _setLocationNameFromCoords(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isEmpty) return null;
      final pm = placemarks.first;

      // Prefer locality/subLocality and subAdministrativeArea for taluk
      final villageCandidates = <String?>[pm.locality, pm.subLocality, pm.name];
      final talukCandidates = <String?>[pm.subAdministrativeArea, pm.subLocality, pm.subAdministrativeArea];

      String? village;
      String? taluk;

      for (final c in villageCandidates) {
        if (c != null && c.trim().isNotEmpty) {
          village = c.trim();
          break;
        }
      }
      for (final c in talukCandidates) {
        if (c != null && c.trim().isNotEmpty && (village == null || c.trim() != village)) {
          taluk = c.trim();
          break;
        }
      }

      String display;
      if (village != null && taluk != null) {
        display = '$village, $taluk';
      } else if (village != null) {
        display = village;
      } else if (taluk != null) {
        display = taluk;
      } else {
        final parts = [
          if (pm.locality != null && pm.locality!.isNotEmpty) pm.locality,
          if (pm.subAdministrativeArea != null && pm.subAdministrativeArea!.isNotEmpty) pm.subAdministrativeArea,
          if (pm.administrativeArea != null && pm.administrativeArea!.isNotEmpty) pm.administrativeArea,
          if (pm.country != null && pm.country!.isNotEmpty) pm.country,
        ];
        display = parts.where((p) => p != null && p.isNotEmpty).join(', ');
      }

      if (display.trim().isEmpty) return null;

      // update controller & coords (do not overwrite with empty)
      if (mounted) {
        setState(() {
          _locationCtrl.text = display;
          _locationCtrl.selection = TextSelection.collapsed(offset: display.length);
          _selectedLat = lat;
          _selectedLon = lon;
        });
      } else {
        _selectedLat = lat;
        _selectedLon = lon;
      }

      return display;
    } catch (e) {
      debugPrint('Reverse geocode failed: $e');
      return null;
    }
  }

  // Location detection (auto-detect placed in location area)
  Future<void> _detectLocation() async {
    setState(() => _detectingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _detectingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services disabled.')));
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _detectingLocation = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission denied')));
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _detectingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission permanently denied.')));
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);

      // set coords immediately
      _selectedLat = pos.latitude;
      _selectedLon = pos.longitude;

      // Try reverse geocoding into village + taluk (preferred)
      final friendly = await _setLocationNameFromCoords(pos.latitude, pos.longitude);

      // If reverse geocode returned null or empty, fall back to building a pretty string
      if (friendly == null || friendly.trim().isEmpty) {
        try {
          final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
          if (placemarks.isNotEmpty) {
            final pm = placemarks.first;
            final parts = [
              if (pm.locality != null && pm.locality!.isNotEmpty) pm.locality,
              if (pm.subAdministrativeArea != null && pm.subAdministrativeArea!.isNotEmpty) pm.subAdministrativeArea,
              if (pm.administrativeArea != null && pm.administrativeArea!.isNotEmpty) pm.administrativeArea,
              if (pm.country != null && pm.country!.isNotEmpty) pm.country,
            ];
            final prettyFallback = parts.where((s) => s != null && s.isNotEmpty).join(', ');
            setState(() {
              _locationCtrl.text = prettyFallback;
              _locationCtrl.selection = TextSelection.collapsed(offset: prettyFallback.length);
            });
          } else {
            final coordsText = '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
            setState(() {
              _locationCtrl.text = coordsText;
              _locationCtrl.selection = TextSelection.collapsed(offset: coordsText.length);
            });
          }
        } catch (e) {
          final coordsText = '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
          setState(() {
            _locationCtrl.text = coordsText;
            _locationCtrl.selection = TextSelection.collapsed(offset: coordsText.length);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to detect location: $e')));
    } finally {
      if (mounted) setState(() => _detectingLocation = false);
    }
  }

  // fetch suggestions from LocationIQ (kept for legacy use if needed)
  Future<List<Map<String, dynamic>>> _fetchLocationSuggestions(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final q = Uri.encodeQueryComponent(query);
      final url =
          'https://api.locationiq.com/v1/autocomplete.php?key=$_locationIQKey&q=$q&limit=8&format=json&countrycodes=in';
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode != 200) return [];
      final List data = json.decode(resp.body) as List;
      // Map to a simple structure: {display, lat, lon}
      return data.map<Map<String, dynamic>>((e) {
        final display = (e['display_name'] ?? '') as String;
        final lat = double.tryParse((e['lat'] ?? '').toString()) ?? 0.0;
        final lon = double.tryParse((e['lon'] ?? '').toString()) ?? 0.0;
        return {'display': display, 'lat': lat, 'lon': lon};
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Submit
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to continue')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (_pickedImageFile != null) {
        final uploaded = await _uploadImage(_pickedImageFile!);
        if (uploaded != null) _imageUrl = uploaded;
      }

      final editing = widget.existingProduct != null && widget.existingProduct!.id.isNotEmpty;
      final productId = editing ? widget.existingProduct!.id : const Uuid().v4();

      final farmerMobile = _farmerMobileCtrl.text.trim();

      // Build product object (location is display name)
      final product = ExportProduct(
        id: productId,
        productName: _productNameCtrl.text.trim(),
        pricePerUnit: _priceCtrl.text.trim(),
        quantity: '${_quantityCtrl.text.trim()} $_unit',
        farmerId: farmerMobile, // compatibility
        farmerName: _farmerNameCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        category: _category,
        farmerMobile: farmerMobile, // new canonical field
        imageUrl: _imageUrl,
        createdAt: widget.existingProduct?.createdAt,
        ownerId: user.uid,
        ownerEmail: user.email,
        ownerName: user.displayName,
        ownerPhone: user.phoneNumber,
      );

      if (editing) {
        final payload = product.toMap();
        payload['ownerId'] = user.uid;
        // add lat/lon if selected
        if (_selectedLat != null && _selectedLon != null) {
          payload['locationLat'] = _selectedLat;
          payload['locationLon'] = _selectedLon;
        }
        await _svc.updateExportProduct(productId, payload);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product updated')));
        Navigator.pop(context, true);
      } else {
        // create product via service then add lat/lon if available
        final docRef = await _svc.addExportProduct(product);
        // add lat/lon fields to the created document if user selected a suggestion or auto-detect provided coords
        if (_selectedLat != null && _selectedLon != null) {
          await docRef.update({'locationLat': _selectedLat, 'locationLon': _selectedLon});
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product created: ${docRef.id}')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // UI
  @override
  Widget build(BuildContext context) {
    final editing = widget.existingProduct != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit Product' : 'Add Export Product'),
        backgroundColor: Colors.green,
        actions: [
          if (editing)
            IconButton(
              icon: const Icon(Icons.visibility),
              tooltip: 'Preview',
              onPressed: _previewProduct,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // product name
              TextFormField(
                controller: _productNameCtrl,
                decoration: const InputDecoration(labelText: 'Product name', border: OutlineInputBorder()),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Enter product name' : null,
              ),
              const SizedBox(height: 12),

              // category
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _categories.contains(_category) ? _category : 'Other',
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _category = v);
                    },
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                if (_category == 'Other')
                  Expanded(
                    child: TextFormField(
                      controller: _customCategoryCtrl,
                      decoration: const InputDecoration(labelText: 'Custom category', border: OutlineInputBorder()),
                      onChanged: (val) => _category = val.trim(),
                    ),
                  ),
              ]),
              const SizedBox(height: 12),

              // price & qty
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Price per kg (₹)', border: OutlineInputBorder()),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Enter price' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _quantityCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder()),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Enter qty' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _unit,
                    items: const [
                      DropdownMenuItem(value: 'kg', child: Text('kg')),
                      DropdownMenuItem(value: 'tonne', child: Text('tonne')),
                      DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _unit = v);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // farmer name + mobile
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _farmerNameCtrl,
                      decoration: const InputDecoration(labelText: 'Farmer name', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 160,
                    child: TextFormField(
                      controller: _farmerMobileCtrl,
                      decoration: const InputDecoration(labelText: 'Farmer mobile', border: OutlineInputBorder(), hintText: 'e.g. +919876543210'),
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return 'Required';
                        final numeric = s.replaceAll(RegExp(r'[^0-9+]'), '');
                        if (numeric.length < 7) return 'Enter valid mobile';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Location + Auto-detect (Modal search button)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _locationCtrl,
                      decoration: const InputDecoration(labelText: 'Location (village/district)', border: OutlineInputBorder()),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Enter location' : null,
                      readOnly: true,
                      onTap: _openLocationSearchModal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _detectingLocation ? null : _detectLocation,
                    icon: const Icon(Icons.my_location),
                    label: _detectingLocation ? const Text('Detecting...') : const Text('Auto-detect'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // description
              TextFormField(
                controller: _descriptionCtrl,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              // image section
              _buildImageSection(),

              const SizedBox(height: 18),

              // submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _isSubmitting
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(editing ? 'Update Product' : 'Add Product', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(alignment: Alignment.centerLeft, child: Text('Product image', style: TextStyle(fontWeight: FontWeight.w600))),
        const SizedBox(height: 8),
        Row(
          children: [
            _imagePreviewWidget(),
            const SizedBox(width: 12),
            Column(
              children: [
                ElevatedButton.icon(onPressed: () => _pickImage(ImageSource.camera), icon: const Icon(Icons.photo_camera), label: const Text('Camera')),
                const SizedBox(height: 8),
                ElevatedButton.icon(onPressed: () => _pickImage(ImageSource.gallery), icon: const Icon(Icons.photo_library), label: const Text('Gallery')),
              ],
            ),
          ],
        ),
        if (_isUploadingImage) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
      ],
    );
  }

  Widget _imagePreviewWidget() {
    final double size = 120;
    if (_pickedImageFile != null) {
      return ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_pickedImageFile!, width: size, height: size, fit: BoxFit.cover));
    }
    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(_imageUrl!, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) {
        return Container(width: size, height: size, color: Colors.grey.shade200, child: const Icon(Icons.broken_image));
      }));
    }
    return Container(width: size, height: size, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey.shade100), child: const Icon(Icons.photo, size: 44, color: Colors.grey));
  }

  // preview helper (same as earlier)
  Future<void> _previewProduct() async {
    final preview = widget.existingProduct;
    final name = _productNameCtrl.text.trim().isNotEmpty ? _productNameCtrl.text.trim() : (preview?.productName ?? '');
    final price = _priceCtrl.text.trim().isNotEmpty ? _priceCtrl.text.trim() : (preview?.pricePerUnit ?? '');
    final qty = _quantityCtrl.text.trim().isNotEmpty ? '${_quantityCtrl.text.trim()} $_unit' : (preview?.quantity ?? '');
    final farmer = _farmerNameCtrl.text.trim().isNotEmpty ? _farmerNameCtrl.text.trim() : (preview?.farmerName ?? '');
    final loc = _locationCtrl.text.trim().isNotEmpty ? _locationCtrl.text.trim() : (preview?.location ?? '');
    final desc = _descriptionCtrl.text.trim().isNotEmpty ? _descriptionCtrl.text.trim() : (preview?.description ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(name.isEmpty ? 'Preview product' : name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_imageUrl != null || _pickedImageFile != null) SizedBox(height: 180, child: _imagePreviewWidget()),
              const SizedBox(height: 12),
              Text('Price: ₹$price'),
              const SizedBox(height: 6),
              Text('Qty: $qty'),
              const SizedBox(height: 6),
              Text('Farmer: $farmer'),
              const SizedBox(height: 6),
              Text('Location: $loc'),
              const SizedBox(height: 10),
              Text(desc),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
}
