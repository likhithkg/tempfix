// lib/exporter_hub/exporter_form_page.dart
// Advanced Add/Edit product page with:
// ✅ Cloudinary Upload
// ✅ MongoDB-ready image URLs
// ✅ Auto location
// ✅ Location search
// ✅ Image preview
// ✅ Edit support

import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

import 'exporter_model.dart';
import 'exporter_service.dart';

import '../services/image_upload_service.dart';
import '../l10n/app_localizations.dart';

class ExporterFormPage extends StatefulWidget {
  final ExportProduct? existingProduct;

  const ExporterFormPage({
    Key? key,
    this.existingProduct,
  }) : super(key: key);

  @override
  State<ExporterFormPage> createState() =>
      _ExporterFormPageState();
}

class _ExporterFormPageState
    extends State<ExporterFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _svc = ExporterService();

  // Controllers

  final _productNameCtrl =
      TextEditingController();

  final _priceCtrl =
      TextEditingController();

  final _quantityCtrl =
      TextEditingController();

  final _farmerNameCtrl =
      TextEditingController();

  final _farmerMobileCtrl =
      TextEditingController();

  final _locationCtrl =
      TextEditingController();

  final _descriptionCtrl =
      TextEditingController();

  final _customCategoryCtrl =
      TextEditingController();

  // UI state

  bool _isSubmitting = false;

  bool _isUploadingImage = false;

  bool _detectingLocation = false;

  // advanced fields

  String _category = 'Crops';

  String _unit = 'kg';

  File? _pickedImageFile;

  String? _imageUrl;

  final ImagePicker _picker =
      ImagePicker();

  double? _selectedLat;

  double? _selectedLon;

  final List<String> _categories = [
    'Crops',
    'Fruits',
    'Vegetables',
    'Grains',
    'Spices',
    'Other'
  ];

  static const String _locationIQKey =
      'pk.56ccd9d8fb2cd5f3e9d7a656e3b52566';

  @override
  void initState() {
    super.initState();

    _loadExisting();
  }

  void _loadExisting() {
    final p = widget.existingProduct;

    if (p != null) {
      _productNameCtrl.text =
          p.productName;

      _priceCtrl.text =
          p.pricePerUnit;

      final qty = p.quantity;

      final parts = qty.split(' ');

      if (parts.isNotEmpty) {
        _quantityCtrl.text =
            parts[0];
      }

      if (parts.length > 1) {
        _unit = parts[1];
      }

      _farmerNameCtrl.text =
          p.farmerName;

      _farmerMobileCtrl.text =
          p.farmerMobile ??
              p.farmerId;

      _locationCtrl.text =
          p.location;

      _descriptionCtrl.text =
          p.description;

      _category =
          p.category.isNotEmpty
              ? p.category
              : _category;

      _imageUrl = p.imageUrl;
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

  // =========================
  // IMAGE PICKER
  // =========================

  Future<void> _pickImage(
    ImageSource src,
  ) async {
    try {
      final picked =
          await _picker.pickImage(
        source: src,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (picked != null) {
        setState(() {
          _pickedImageFile =
              File(picked.path);
        });
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Image pick failed: ${e.message}',
          ),
        ),
      );
    }
  }

  // =========================
  // CLOUDINARY IMAGE UPLOAD
  // =========================

  Future<String?> _uploadImage(
    File file,
  ) async {
    setState(() {
      _isUploadingImage = true;
    });

    try {
      final imageUrl =
          await ImageUploadService
              .uploadImage(file);

      if (imageUrl != null) {
        return imageUrl;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.imageUploadFailed),
        ),
      );

      return null;
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text('Upload Error: $e'),
        ),
      );

      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  // =========================
  // LOCATION SEARCH MODAL
  // =========================

  Future<void>
      _openLocationSearchModal() async {
    final ctrl =
        TextEditingController();

    try {
      final result = await showDialog<
          Map<String, dynamic>>(
        context: context,
        builder: (ctx) {
          List<dynamic> results = [];

          bool loading = false;

          String? error;

          Timer? debounce;

          Future<void> doSearch(
            String val,
            void Function(void Function())
                setStateDialog,
          ) async {
            if (val.trim().length < 2) {
              results = [];

              error = null;

              setStateDialog(() {});

              return;
            }

            loading = true;

            error = null;

            setStateDialog(() {});

            final q =
                Uri.encodeQueryComponent(
                    val.trim());

            final url =
                "https://us1.locationiq.com/v1/search.php?key=$_locationIQKey&q=$q&format=json&limit=8&countrycodes=in";

            try {
              final resp = await http
                  .get(Uri.parse(url))
                  .timeout(
                    const Duration(
                        seconds: 8),
                  );

              if (resp.statusCode ==
                  200) {
                final body =
                    json.decode(
                        resp.body);

                if (body is List) {
                  results = body;
                }
              }
            } catch (e) {
              error = 'Network error';
            } finally {
              loading = false;

              setStateDialog(() {});
            }
          }

          return StatefulBuilder(
            builder: (
              ctx2,
              setStateDialog,
            ) =>
                AlertDialog(
              title: const Text(
                  'Search location'),
              content: SizedBox(
                width:
                    double.maxFinite,
                height: 360,
                child: Column(
                  children: [
                    TextField(
                      controller: ctrl,
                      decoration:
                          const InputDecoration(
                        prefixIcon:
                            Icon(Icons
                                .search),
                        hintText:
                            'Type location...',
                      ),
                      onChanged: (val) {
                        debounce
                            ?.cancel();

                        debounce = Timer(
                          const Duration(
                              milliseconds:
                                  400),
                          () {
                            doSearch(
                              val,
                              setStateDialog,
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(
                        height: 10),

                    if (loading)
                      const LinearProgressIndicator(),

                    if (error != null)
                      Padding(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 8,
                        ),
                        child: Text(
                          error!,
                          style:
                              const TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),

                    const SizedBox(
                        height: 8),

                    Expanded(
                      child:
                          results.isEmpty
                              ? Center(
                                  child: Text(
                                    loading
                                        ? 'Searching...'
                                        : 'No results',
                                  ),
                                )
                              : ListView
                                  .builder(
                                  itemCount:
                                      results
                                          .length,
                                  itemBuilder:
                                      (_, i) {
                                    final r =
                                        results[
                                            i];

                                    return ListTile(
                                      leading:
                                          const Icon(
                                        Icons
                                            .location_on,
                                      ),
                                      title:
                                          Text(
                                        r['display_name'],
                                        maxLines:
                                            2,
                                        overflow:
                                            TextOverflow.ellipsis,
                                      ),
                                      onTap:
                                          () {
                                        Navigator.pop(
                                          ctx,
                                          {
                                            'display':
                                                r['display_name'],
                                            'lat':
                                                double.tryParse(
                                                      r['lat'],
                                                    ) ??
                                                    0,
                                            'lon':
                                                double.tryParse(
                                                      r['lon'],
                                                    ) ??
                                                    0,
                                          },
                                        );
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
        setState(() {
          _locationCtrl.text =
              result['display'];

          _selectedLat =
              result['lat'];

          _selectedLon =
              result['lon'];
        });
      }
    } finally {
      ctrl.dispose();
    }
  }

  // =========================
  // AUTO DETECT LOCATION
  // =========================

  Future<void> _detectLocation() async {
    setState(() {
      _detectingLocation = true;
    });

    try {
      bool serviceEnabled =
          await Geolocator
              .isLocationServiceEnabled();

      if (!serviceEnabled) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
                'Location services disabled'),
          ),
        );

        return;
      }

      LocationPermission permission =
          await Geolocator
              .checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator
                .requestPermission();
      }

      if (permission ==
              LocationPermission
                  .denied ||
          permission ==
              LocationPermission
                  .deniedForever) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
                'Location permission denied'),
          ),
        );

        return;
      }

      final pos =
          await Geolocator
              .getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.best,
      );

      _selectedLat = pos.latitude;

      _selectedLon = pos.longitude;

      final placemarks =
          await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      if (placemarks.isNotEmpty) {
        final pm =
            placemarks.first;

        final parts = [
          if (pm.locality != null)
            pm.locality,
          if (pm.subAdministrativeArea !=
              null)
            pm.subAdministrativeArea,
          if (pm.administrativeArea !=
              null)
            pm.administrativeArea,
        ];

        final loc = parts
            .where(
                (e) => e != null)
            .join(', ');

        setState(() {
          _locationCtrl.text = loc;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text('Location error: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _detectingLocation =
              false;
        });
      }
    }
  }

  // =========================
  // SAVE PRODUCT
  // =========================

  Future<void> _save() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    final user =
        FirebaseAuth
            .instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text('Please login first'),
        ),
      );

      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_pickedImageFile != null) {
        final uploaded =
            await _uploadImage(
          _pickedImageFile!,
        );

        if (uploaded != null) {
          _imageUrl = uploaded;
        }
      }

      final editing =
          widget.existingProduct !=
                  null &&
              widget.existingProduct!
                  .id
                  .isNotEmpty;

      final productId = editing
          ? widget.existingProduct!.id
          : DateTime.now()
              .millisecondsSinceEpoch
              .toString();

      final farmerMobile =
          _farmerMobileCtrl.text
              .trim();

      final product =
          ExportProduct(
        id: productId,
        productName:
            _productNameCtrl.text
                .trim(),
        pricePerUnit:
            _priceCtrl.text.trim(),
        quantity:
            '${_quantityCtrl.text.trim()} $_unit',
        farmerId: farmerMobile,
        farmerName:
            _farmerNameCtrl.text
                .trim(),
        location:
            _locationCtrl.text
                .trim(),
        description:
            _descriptionCtrl.text
                .trim(),
        category: _category,
        farmerMobile:
            farmerMobile,
        imageUrl: _imageUrl,
        createdAt: widget
            .existingProduct
            ?.createdAt,
        ownerId: user.uid,
        ownerEmail:
            user.email,
        ownerName:
            user.displayName,
        ownerPhone:
            user.phoneNumber,
      );

      if (editing) {
        final payload =
            product.toMap();

        payload['ownerId'] =
            user.uid;

        if (_selectedLat != null &&
            _selectedLon != null) {
          payload['locationLat'] =
              _selectedLat;

          payload['locationLon'] =
              _selectedLon;
        }

        await _svc
            .updateExportProduct(
          productId,
          payload,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.productUpdatedSuccessfully),
          ),
        );

        Navigator.pop(
          context,
          true,
        );
      } else {
        final docRef =
            await _svc
                .addExportProduct(
          product,
        );

        if (_selectedLat != null &&
            _selectedLon != null) {
          await docRef.update({
            'locationLat':
                _selectedLat,
            'locationLon':
                _selectedLon,
          });
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.productAddedSuccessfully,
            ),
          ),
        );

        Navigator.pop(
          context,
          true,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text('Save failed: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // =========================
  // UI
  // =========================

  @override
  Widget build(BuildContext context) {
    final editing =
        widget.existingProduct !=
            null;

    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          editing
              ? l.editExportProductTitle
              : l.addExportProductTitle,
        ),
        backgroundColor:
            Colors.green,
      ),
      body:
          SingleChildScrollView(
        padding:
            const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller:
                    _productNameCtrl,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Product Name',
                  border:
                      OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v ?? '')
                            .trim()
                            .isEmpty
                        ? 'Enter product name'
                        : null,
              ),

              const SizedBox(
                  height: 12),

              DropdownButtonFormField<
                  String>(
                value: _category,
                items: _categories
                    .map(
                      (c) =>
                          DropdownMenuItem(
                        value: c,
                        child:
                            Text(c),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _category =
                          v;
                    });
                  }
                },
                decoration:
                    const InputDecoration(
                  labelText:
                      'Category',
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                  height: 12),

              TextFormField(
                controller:
                    _priceCtrl,
                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),
                decoration:
                    const InputDecoration(
                  labelText:
                      'Price',
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                  height: 12),

              TextFormField(
                controller:
                    _quantityCtrl,
                keyboardType:
                    TextInputType
                        .number,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Quantity',
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                  height: 12),

              TextFormField(
                controller:
                    _farmerNameCtrl,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Farmer Name',
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                  height: 12),

              TextFormField(
                controller:
                    _farmerMobileCtrl,
                keyboardType:
                    TextInputType
                        .phone,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Farmer Mobile',
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                  height: 12),

              Row(
                children: [
                  Expanded(
                    child:
                        TextFormField(
                      controller:
                          _locationCtrl,
                      readOnly:
                          true,
                      onTap:
                          _openLocationSearchModal,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Location',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),
                  ),

                  const SizedBox(
                      width: 8),

                  ElevatedButton.icon(
                    onPressed:
                        _detectingLocation
                            ? null
                            : _detectLocation,
                    icon:
                        const Icon(
                      Icons
                          .my_location,
                    ),
                    label: Text(
                      _detectingLocation
                          ? 'Detecting'
                          : 'Auto',
                    ),
                  ),
                ],
              ),

              const SizedBox(
                  height: 12),

              TextFormField(
                controller:
                    _descriptionCtrl,
                maxLines: 4,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Description',
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                  height: 16),

              _buildImageSection(),

              const SizedBox(
                  height: 20),

              SizedBox(
                width:
                    double.infinity,
                child:
                    ElevatedButton(
                  onPressed:
                      _isSubmitting
                          ? null
                          : _save,
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        Colors.green,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 14,
                    ),
                  ),
                  child:
                      _isSubmitting
                          ? const SizedBox(
                              height:
                                  18,
                              width:
                                  18,
                              child:
                                  CircularProgressIndicator(
                                color: Colors
                                    .white,
                                strokeWidth:
                                    2,
                              ),
                            )
                          : Text(
                              editing
                                  ? l.update
                                  : l.addExportProductTitle,
                              style:
                                  const TextStyle(
                                fontSize:
                                    16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // IMAGE UI
  // =========================

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Image',
          style: TextStyle(
            fontWeight:
                FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            _imagePreviewWidget(),

            const SizedBox(width: 12),

            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () =>
                      _pickImage(
                    ImageSource.camera,
                  ),
                  icon: const Icon(
                    Icons.photo_camera,
                  ),
                  label:
                      Text(AppLocalizations.of(context)!.camera),
                ),

                const SizedBox(
                    height: 8),

                ElevatedButton.icon(
                  onPressed: () =>
                      _pickImage(
                    ImageSource.gallery,
                  ),
                  icon: const Icon(
                    Icons.photo_library,
                  ),
                  label:
                      Text(AppLocalizations.of(context)!.gallery),
                ),
              ],
            ),
          ],
        ),

        if (_isUploadingImage)
          const Padding(
            padding:
                EdgeInsets.only(top: 8),
            child:
                LinearProgressIndicator(),
          ),
      ],
    );
  }

  Widget _imagePreviewWidget() {
    const double size = 120;

    if (_pickedImageFile != null) {
      return ClipRRect(
        borderRadius:
            BorderRadius.circular(8),
        child: Image.file(
          _pickedImageFile!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    if (_imageUrl != null &&
        _imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius:
            BorderRadius.circular(8),
        child: Image.network(
          _imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder:
              (_, __, ___) {
            return Container(
              width: size,
              height: size,
              color:
                  Colors.grey.shade200,
              child: const Icon(
                Icons.broken_image,
              ),
            );
          },
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(8),
        color: Colors.grey.shade100,
      ),
      child: const Icon(
        Icons.photo,
        size: 44,
        color: Colors.grey,
      ),
    );
  }
}