// lib/plant_vendor/plant_list_form_page.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import 'package:krishimithra/plant_vendor/plant_vendor_model.dart';
import 'package:krishimithra/plant_vendor/plant_vendor_service.dart';

import '../services/image_upload_service.dart';

// ---------- CONFIG ----------
const String LOCATIONIQ_API_KEY =
    'pk.56ccd9d8fb2cd5f3e9d7a656e3b52566';
// ----------------------------

class PlantListFormPage extends StatefulWidget {
  final PlantVendor? existingVendor;

  const PlantListFormPage({
    super.key,
    this.existingVendor,
  });

  @override
  State<PlantListFormPage> createState() =>
      _PlantListFormPageState();
}

class _PlantListFormPageState
    extends State<PlantListFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _plantNameController =
      TextEditingController();

  final _typeController =
      TextEditingController();

  final _priceController =
      TextEditingController();

  final _quantityController =
      TextEditingController();

  final _vendorNameController =
      TextEditingController();

  final _phoneController =
      TextEditingController();

  final _locationController =
      TextEditingController();

  final _descriptionController =
      TextEditingController();

  // For storing the selected suggestion
  LocationSuggestion? _selectedSuggestion;

  // Product category
  String _productCategory = 'Plant';

  bool _saving = false;

  // =========================
  // IMAGE VARIABLES
  // =========================

  File? _selectedImage;

  String? _uploadedImageUrl;

  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();

    final v = widget.existingVendor;

    if (v != null) {
      final savedType = v.type;

      if (savedType.contains(' - ')) {
        final parts = savedType.split(' - ');

        if (parts.length >= 2 &&
            (parts[0].toLowerCase() ==
                    'seeds' ||
                parts[0].toLowerCase() ==
                    'plant')) {
          _productCategory = parts[0];

          _typeController.text =
              parts.sublist(1).join(' - ');
        } else {
          _typeController.text = savedType;
        }
      } else {
        _typeController.text = savedType;
      }

      _plantNameController.text =
          v.plantName;

      _priceController.text =
          v.price.toStringAsFixed(2);

      _quantityController.text =
          v.quantity.toString();

      _vendorNameController.text =
          v.vendorName;

      _phoneController.text = v.phone;

      _locationController.text =
          v.location;

      _descriptionController.text =
          v.description;

      // IMAGE URL
      _uploadedImageUrl = v.imageUrl;

      if ((v.address).isNotEmpty ||
          (v.latitude != 0 &&
              v.longitude != 0)) {
        _selectedSuggestion =
            LocationSuggestion(
          display: v.location.isNotEmpty
              ? v.location
              : v.address,
          address: v.address,
          lat: v.latitude,
          lon: v.longitude,
        );
      }
    }
  }

  @override
  void dispose() {
    _plantNameController.dispose();
    _typeController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _vendorNameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  // =========================
  // IMAGE PICKER + UPLOAD
  // =========================

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();

      final pickedFile =
          await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile == null) return;

      setState(() {
        _selectedImage =
            File(pickedFile.path);

        _uploadingImage = true;
      });

      final imageUrl =
          await ImageUploadService
              .uploadImage(
        _selectedImage!,
      );

      if (imageUrl != null) {
        setState(() {
          _uploadedImageUrl = imageUrl;
        });

        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                "Image uploaded successfully",
              ),
              backgroundColor:
                  Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                "Image upload failed",
              ),
              backgroundColor:
                  Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint(
        "Image Upload Error: $e",
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploadingImage = false;
        });
      }
    }
  }

  // ---------- LocationIQ helper ----------
  Future<List<LocationSuggestion>>
      _fetchLocationSuggestions(
    String query,
  ) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final uri = Uri.parse(
      'https://us1.locationiq.com/v1/search.php?key=$LOCATIONIQ_API_KEY&q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=6',
    );

    try {
      final resp = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 8),
          );

      if (resp.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(resp.body);

      if (data is! List) {
        return [];
      }

      return data
          .map<LocationSuggestion>(
              (item) {
        final display =
            (item['display_name'] ?? '')
                .toString();

        final lat = double.tryParse(
              item['lat']
                      ?.toString() ??
                  '',
            ) ??
            0.0;

        final lon = double.tryParse(
              item['lon']
                      ?.toString() ??
                  '',
            ) ??
            0.0;

        String address = display;

        if (item['address'] != null &&
            item['address'] is Map) {
          final map =
              item['address']
                  as Map<String, dynamic>;

          address = map.values
              .where((e) => e != null)
              .join(', ');
        }

        return LocationSuggestion(
          display: display,
          address: address,
          lat: lat,
          lon: lon,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ---------- Dialog UI ----------
  Future<void> _openLocationDialog() async {
    final selected =
        await showDialog<
            LocationSuggestion?>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return _LocationPickerDialog(
          fetch:
              _fetchLocationSuggestions,
          initialText:
              _locationController.text,
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedSuggestion =
            selected;

        _locationController.text =
            selected.display;
      });
    }
  }

  // ---------- Save ----------
  Future<void> _save() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    setState(() => _saving = true);

    final isEdit =
        widget.existingVendor != null;

    final user =
        FirebaseAuth.instance.currentUser;

    final combinedType =
        '${_productCategory.trim()} - ${_typeController.text.trim()}';

    final selected =
        _selectedSuggestion;

    final address = selected
            ?.address ??
        (isEdit
            ? widget
                .existingVendor!
                .address
            : '');

    final latitude = selected?.lat ??
        (isEdit
            ? widget
                .existingVendor!
                .latitude
            : 0.0);

    final longitude =
        selected?.lon ??
            (isEdit
                ? widget
                    .existingVendor!
                    .longitude
                : 0.0);

    final timestamp = isEdit
        ? widget
            .existingVendor!
            .timestamp
        : DateTime.now();

    final createdBy = isEdit
        ? (widget.existingVendor!
                .createdBy
                .isNotEmpty
            ? widget
                .existingVendor!
                .createdBy
            : (user?.uid ?? ''))
        : (user?.uid ?? '');

    final ownerId = isEdit
        ? (widget.existingVendor!
                .ownerId
                .isNotEmpty
            ? widget
                .existingVendor!
                .ownerId
            : (user?.uid ?? ''))
        : (user?.uid ?? '');

    final vendor = PlantVendor(
      id: isEdit
          ? widget.existingVendor!.id
          : '',
      plantName:
          _plantNameController.text
              .trim(),
      type: combinedType,
      price: double.tryParse(
              _priceController.text
                  .trim()) ??
          0.0,
      quantity: int.tryParse(
              _quantityController.text
                  .trim()) ??
          0,
      vendorName:
          _vendorNameController.text
              .trim(),
      phone: _phoneController.text
          .trim(),
      location:
          _locationController.text
              .trim(),
      address: address,
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp,
      createdBy: createdBy,
      ownerId: ownerId,
      description:
          _descriptionController.text
              .trim(),

      // =====================
      // IMAGE URL SAVE
      // =====================

      imageUrl:
          _uploadedImageUrl ??
              (isEdit
                  ? widget
                      .existingVendor!
                      .imageUrl
                  : null),
    );

    try {
      final service =
          PlantVendorService();

      if (isEdit) {
        await service
            .updatePlantVendor(
          vendor,
        );
      } else {
        await service.addPlantVendor(
          vendor,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Listing updated!'
                  : 'Listing added!',
            ),
            backgroundColor:
                Colors.green,
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Save failed: $e',
            ),
            backgroundColor:
                Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(
            () => _saving = false);
      }
    }
  }

  Widget _field({
    required TextEditingController
        controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType =
        TextInputType.text,
    int maxLines = 1,
    String? Function(String?)?
        validator,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
              vertical: 8),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
                    12),
          ),
          filled: true,
          suffixIcon: readOnly
              ? const Icon(
                  Icons.chevron_right)
              : null,
        ),
        validator: validator ??
            (v) => (v == null ||
                    v.trim().isEmpty)
                ? 'Enter $label'
                : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit =
        widget.existingVendor != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit
              ? 'Edit Listing'
              : 'Add Listing',
        ),
      ),
      body: _saving
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.all(
                      16),
              child: Card(
                elevation: 6,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                    16,
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                          16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // =========================
                        // IMAGE UPLOAD UI
                        // =========================

                        GestureDetector(
                          onTap:
                              _uploadingImage
                                  ? null
                                  : _pickAndUploadImage,
                          child: Container(
                            height: 180,
                            width:
                                double.infinity,
                            decoration:
                                BoxDecoration(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                16,
                              ),
                              border:
                                  Border.all(
                                color: Colors
                                    .green
                                    .shade300,
                              ),
                              color: Colors
                                  .green
                                  .shade50,
                            ),
                            child:
                                _uploadingImage
                                    ? const Center(
                                        child:
                                            CircularProgressIndicator(),
                                      )
                                    : _selectedImage !=
                                            null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(
                                                    16),
                                            child:
                                                Image.file(
                                              _selectedImage!,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : (_uploadedImageUrl !=
                                                null
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        16),
                                                child:
                                                    Image.network(
                                                  _uploadedImageUrl!,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: const [
                                                  Icon(
                                                    Icons.add_a_photo,
                                                    size: 50,
                                                    color: Colors.green,
                                                  ),
                                                  SizedBox(
                                                      height:
                                                          10),
                                                  Text(
                                                    "Tap to upload plant image",
                                                    style:
                                                        TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              )),
                          ),
                        ),

                        const SizedBox(
                            height: 16),

                        _field(
                          controller:
                              _plantNameController,
                          label:
                              'Plant Name',
                          icon: Icons
                              .local_florist,
                        ),

                        Padding(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 8,
                          ),
                          child:
                              InputDecorator(
                            decoration:
                                InputDecoration(
                              labelText:
                                  'Category',
                              prefixIcon:
                                  const Icon(
                                Icons.tag,
                              ),
                              border:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                        12),
                              ),
                              filled: true,
                            ),
                            child:
                                DropdownButtonHideUnderline(
                              child:
                                  DropdownButton<
                                      String>(
                                value:
                                    _productCategory,
                                isExpanded:
                                    true,
                                items:
                                    const [
                                  DropdownMenuItem(
                                    value:
                                        'Plant',
                                    child:
                                        Text(
                                      'Plant',
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value:
                                        'Seeds',
                                    child:
                                        Text(
                                      'Seeds',
                                    ),
                                  ),
                                ],
                                onChanged:
                                    (v) {
                                  if (v !=
                                      null) {
                                    setState(
                                        () {
                                      _productCategory =
                                          v;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),

                        _field(
                          controller:
                              _typeController,
                          label:
                              'Type (e.g., Tomato, Rose)',
                          icon: Icons
                              .category,
                        ),

                        _field(
                          controller:
                              _priceController,
                          label:
                              'Price (₹)',
                          icon: Icons
                              .currency_rupee,
                          keyboardType:
                              const TextInputType
                                  .numberWithOptions(
                            decimal: true,
                          ),
                          validator:
                              (v) {
                            final d =
                                double.tryParse(
                                    v ??
                                        '');

                            if (d ==
                                    null ||
                                d < 0) {
                              return 'Enter valid price';
                            }

                            return null;
                          },
                        ),

                        _field(
                          controller:
                              _quantityController,
                          label:
                              'Quantity',
                          icon: Icons
                              .confirmation_num_outlined,
                          keyboardType:
                              TextInputType
                                  .number,
                          validator:
                              (v) {
                            final n =
                                int.tryParse(
                                    v ??
                                        '');

                            if (n ==
                                    null ||
                                n < 0) {
                              return 'Enter valid quantity';
                            }

                            return null;
                          },
                        ),

                        _field(
                          controller:
                              _vendorNameController,
                          label:
                              'Vendor Name',
                          icon:
                              Icons.person,
                        ),

                        _field(
                          controller:
                              _phoneController,
                          label:
                              'Phone',
                          icon:
                              Icons.phone,
                          keyboardType:
                              TextInputType
                                  .phone,
                          validator:
                              (v) {
                            final s =
                                (v ?? '')
                                    .trim();

                            if (s
                                .isEmpty) {
                              return 'Enter Phone';
                            }

                            if (s.length <
                                8) {
                              return 'Enter valid phone';
                            }

                            return null;
                          },
                        ),

                        // LOCATION FIELD

                        _field(
                          controller:
                              _locationController,
                          label:
                              'Location (tap to search)',
                          icon: Icons
                              .location_on,
                          readOnly: true,
                          onTap:
                              _openLocationDialog,
                        ),

                        const SizedBox(
                            height: 8),

                        TextFormField(
                          controller:
                              _descriptionController,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Description (optional)',
                            prefixIcon:
                                Icon(Icons
                                    .description),
                            border:
                                OutlineInputBorder(),
                            filled: true,
                          ),
                          maxLines: 4,
                          validator:
                              (v) => null,
                        ),

                        const SizedBox(
                            height: 12),

                        SizedBox(
                          width:
                              double.infinity,
                          child:
                              ElevatedButton
                                  .icon(
                            icon: const Icon(
                              Icons.save,
                            ),
                            label: Text(
                              isEdit
                                  ? 'Update'
                                  : 'Save',
                            ),
                            onPressed:
                                _save,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

/// LOCATION PICKER DIALOG

class _LocationPickerDialog
    extends StatefulWidget {
  final Future<
          List<LocationSuggestion>>
      Function(String) fetch;

  final String initialText;

  const _LocationPickerDialog({
    required this.fetch,
    required this.initialText,
  });

  @override
  State<_LocationPickerDialog>
      createState() =>
          _LocationPickerDialogState();
}

class _LocationPickerDialogState
    extends State<
        _LocationPickerDialog> {
  final _ctl = TextEditingController();

  Timer? _debounce;

  List<LocationSuggestion> _items =
      [];

  bool _loading = false;

  @override
  void initState() {
    super.initState();

    _ctl.text = widget.initialText;

    if (_ctl.text
        .trim()
        .isNotEmpty) {
      _search(_ctl.text.trim());
    }

    _ctl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _ctl.removeListener(_onChanged);

    _ctl.dispose();

    _debounce?.cancel();

    super.dispose();
  }

  void _onChanged() {
    final q = _ctl.text.trim();

    _debounce?.cancel();

    _debounce = Timer(
      const Duration(milliseconds: 350),
      () {
        _search(q);
      },
    );
  }

  Future<void> _search(
      String q) async {
    if (q.isEmpty) {
      setState(() {
        _items = [];
        _loading = false;
      });

      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final res =
          await widget.fetch(q);

      if (mounted) {
        setState(() {
          _items = res;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _items = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(
      BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(28),
      ),
      insetPadding:
          const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(
          maxHeight: 420,
        ),
        child: Padding(
          padding:
              const EdgeInsets.all(
                  16.0),
          child: Column(
            children: [
              const Text(
                'Set Location',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(
                  height: 12),

              TextField(
                controller: _ctl,
                autofocus: true,
                decoration:
                    InputDecoration(
                  prefixIcon:
                      const Icon(
                    Icons.search,
                  ),
                  border:
                      const UnderlineInputBorder(),
                  hintText:
                      'Search location (city, town, village...)',
                  suffixIcon:
                      _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,
                              ),
                            )
                          : null,
                ),
                onSubmitted: (s) =>
                    _search(
                        s.trim()),
              ),

              const SizedBox(
                  height: 12),

              Expanded(
                child:
                    _items.isEmpty
                        ? Center(
                            child: Text(
                              _loading
                                  ? 'Searching...'
                                  : 'No suggestions',
                            ),
                          )
                        : ListView
                            .separated(
                            itemCount:
                                _items
                                    .length,
                            separatorBuilder:
                                (_, __) =>
                                    const Divider(
                              height: 1,
                            ),
                            itemBuilder:
                                (ctx, i) {
                              final s =
                                  _items[
                                      i];

                              return ListTile(
                                leading:
                                    const Icon(
                                  Icons
                                      .location_on,
                                ),
                                title:
                                    Text(
                                  s.display,
                                  maxLines:
                                      2,
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                                subtitle:
                                    Text(
                                  s.address,
                                  maxLines:
                                      1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                                onTap: () =>
                                    Navigator.pop(
                                  context,
                                  s,
                                ),
                              );
                            },
                          ),
              ),

              const SizedBox(
                  height: 8),

              Align(
                alignment:
                    Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pop(
                    context,
                    null,
                  ),
                  child:
                      const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// LOCATION MODEL

class LocationSuggestion {
  final String display;

  final String address;

  final double lat;

  final double lon;

  LocationSuggestion({
    required this.display,
    required this.address,
    required this.lat,
    required this.lon,
  });
}