// lib/labour_hub/labour_hub_form_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';

import 'labour_model.dart';
import 'labour_hub_service.dart';
import 'location_search_dialog.dart';

import '../services/image_upload_service.dart';
import '../l10n/app_localizations.dart';

class LabourHubFormPage extends StatefulWidget {
  final Labour? labour;

  const LabourHubFormPage({
    Key? key,
    this.labour,
  }) : super(key: key);

  @override
  State<LabourHubFormPage> createState() =>
      _LabourHubFormPageState();
}

class _LabourHubFormPageState
    extends State<LabourHubFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _service = LabourHubService();

  final TextEditingController
      _nameController =
      TextEditingController();

  final TextEditingController
      _skillController =
      TextEditingController();

  final TextEditingController
      _locationController =
      TextEditingController();

  final TextEditingController
      _contactController =
      TextEditingController();

  // ==========================
  // NEW CONTROLLERS
  // ==========================

  final TextEditingController
      _experienceController =
      TextEditingController();

  final TextEditingController
      _wageController =
      TextEditingController();

  final TextEditingController
      _descriptionController =
      TextEditingController();

  // ==========================
  // IMAGE VARIABLES
  // ==========================

  XFile? _selectedImage;

  String? _uploadedImageUrl;

  bool _uploadingImage = false;

  String? _selectedCategory;

  String? _selectedWageType;

  double _rating = 0.0;

  final List<String> _categories = [
    "Farm Labour",
    "Tractor Driver",
    "Plantation Worker",
    "Sprayer Operator",
    "Harvester Operator",
    "Machine Technician",
    "Dairy Worker",
  ];

  final List<String> _wageTypes = [
    "Per Day",
    "Per Acre",
    "Per Hour",
    "Contract",
  ];

  bool _available = true;
  bool _locating = false;

  double? _selectedLat;

  double? _selectedLng;

  final String headerImageUrl =
      "/mnt/data/e197c40d-db36-4f5f-ad56-9d5c5aec7599.png";

  @override
  void initState() {
    super.initState();

    if (widget.labour != null) {
      final l = widget.labour!;

      _nameController.text = l.name;

      _skillController.text =
          l.skill;

      _locationController.text =
          l.location;

      _contactController.text =
          l.contact;

      _available = l.available;

      _selectedLat = l.latitude;

      _selectedLng = l.longitude;

      // ==========================
      // PREFILL ADVANCED FIELDS
      // ==========================

      _experienceController.text =
          l.experience?.toString() ??
              '';

      _wageController.text =
          l.wage?.toString() ?? '';

      _descriptionController.text =
          l.description ?? '';

      _selectedCategory =
          l.category;

      _selectedWageType =
          l.wageType;

      _rating = l.rating ?? 0.0;

      _uploadedImageUrl =
          l.imageUrl;
    }

  }

  @override
  void dispose() {
    _nameController.dispose();
    _skillController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    _experienceController.dispose();
    _wageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _openLocationSearch() async {
    final result = await showDialog<LocationResult>(
      context: context,
      builder: (_) => const LocationSearchDialog(),
    );
    if (result != null && mounted) {
      setState(() {
        _locationController.text = result.displayName;
        _selectedLat = result.lat;
        _selectedLng = result.lon;
      });
    }
  }

  Future<void> _useGPS() async {
    setState(() => _locating = true);
    try {
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.medium));
      final places = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (places.isNotEmpty && mounted) {
        final pl = places.first;
        final loc = [pl.subLocality, pl.locality, pl.administrativeArea]
            .where((s) => s != null && s.isNotEmpty)
            .join(', ');
        setState(() {
          _locationController.text = loc;
          _selectedLat = pos.latitude;
          _selectedLng = pos.longitude;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get location')),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  // ==========================
  // IMAGE PICKER + CLOUDINARY
  // ==========================

  Future<void>
      _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();

      final pickedFile =
          await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile == null) {
        return;
      }

      setState(() {
        _selectedImage = pickedFile;
        _uploadingImage = true;
      });

      final imageUrl =
          await ImageUploadService
              .uploadImageFromXFile(pickedFile);

      if (imageUrl != null) {
        setState(() {
          _uploadedImageUrl =
              imageUrl;
        });

        if (mounted) {
          final l2 = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(
                  context)
              .showSnackBar(
            SnackBar(
              content: Text(
                l2.imageUploadedSuccessfully,
              ),
              backgroundColor:
                  Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          final l2 = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(
                  context)
              .showSnackBar(
            SnackBar(
              content: Text(
                l2.imageUploadFailed,
              ),
              backgroundColor:
                  Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint(
          "Upload Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _uploadingImage =
              false;
        });
      }
    }
  }

  Future<void> _saveLabour() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    final user = FirebaseAuth
        .instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
              'You must be logged in'),
        ),
      );

      return;
    }

    final labour = Labour(
      id: widget.labour?.id ?? '',
      name:
          _nameController.text.trim(),
      skill:
          _skillController.text
              .trim(),
      location:
          _locationController.text
              .trim(),
      contact:
          _contactController.text
              .trim(),
      available: _available,
      createdBy:
          widget.labour?.createdBy ??
              user.uid,
      latitude: _selectedLat,
      longitude: _selectedLng,
      postedAt:
          widget.labour?.postedAt ??
              DateTime.now(),

      // ==========================
      // ADVANCED FIELDS
      // ==========================

      category:
          _selectedCategory,

      experience: int.tryParse(
        _experienceController.text
            .trim(),
      ),

      wage: double.tryParse(
        _wageController.text
            .trim(),
      ),

      wageType:
          _selectedWageType,

      rating: _rating,

      imageUrl:
          _uploadedImageUrl,

      description:
          _descriptionController
              .text
              .trim(),
    );

    try {
      if (widget.labour ==
          null) {
        final createdId =
            await _service
                .addLabour(
          labour,
        );

        final saved =
            await FirebaseFirestore
                .instance
                .collection(
                    'labours')
                .doc(createdId)
                .get();

        print(
            'Created labour doc: ${saved.data()}');
      } else {
        await _service
            .updateLabour(
          widget.labour!.id,
          labour,
        );

        final saved =
            await FirebaseFirestore
                .instance
                .collection(
                    'labours')
                .doc(
                    widget.labour!.id)
                .get();

        print(
            'Updated labour doc: ${saved.data()}');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text('Saved'),
        ),
      );

      Navigator.of(context)
          .pop(true);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
              'Save failed: ${e.message}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text('Error: $e'),
        ),
      );
    }
  }

  Widget _buildHeader() {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(16),
      child: Image.network(
        headerImageUrl,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) =>
                Container(
          height: 140,
          color:
              Colors.green.shade100,
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController
        controller,
    required String label,
    required IconData icon,
    String? Function(String?)?
        validator,
    void Function(String)?
        onChanged,
  }) {
    return Material(
      elevation: 2,
      borderRadius:
          BorderRadius.circular(16),
      child: TextFormField(
        controller: controller,
        validator: validator,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: Colors.green,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
                    16),
            borderSide:
                BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(
      BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor:
          Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          widget.labour == null
              ? l.addLabourTitle
              : l.editLabourTitle,
        ),
        backgroundColor:
            Colors.green.shade700,
        elevation: 2,
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(14),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildHeader(),

              const SizedBox(
                  height: 16),

              _input(
                controller:
                    _nameController,
                label: "Name",
                icon: Icons.person,
                validator: (v) =>
                    v == null ||
                            v.trim()
                                .isEmpty
                        ? "Enter name"
                        : null,
              ),

              const SizedBox(
                  height: 14),

              _input(
                controller:
                    _skillController,
                label:
                    "Skill (optional)",
                icon:
                    Icons.work_outline,
              ),

              const SizedBox(
                  height: 14),

              // ── Location picker ──────────────────────────────────────
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(16),
                child: GestureDetector(
                  onTap: _openLocationSearch,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(children: [
                      const Icon(Icons.location_on_rounded,
                          color: Color(0xFFE65100), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _locationController.text.isNotEmpty
                              ? _locationController.text
                              : 'Location',
                          style: TextStyle(
                            fontSize: 14,
                            color: _locationController.text.isNotEmpty
                                ? Colors.black87
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
              ),

              const SizedBox(height: 10),

              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openLocationSearch,
                    icon: const Icon(Icons.search_rounded, size: 16),
                    label: const Text('Search Place',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade700,
                      side: BorderSide(color: Colors.green.shade700),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _locating ? null : _useGPS,
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

              const SizedBox(height: 14),

              _input(
                controller:
                    _contactController,
                label:
                    "Contact Number",
                icon: Icons.phone,
                validator: (v) =>
                    v == null ||
                            v.trim()
                                .isEmpty
                        ? "Enter contact number"
                        : null,
              ),

              const SizedBox(
                  height: 14),

              DropdownButtonFormField<
                  String>(
                value:
                    _selectedCategory,
                decoration:
                    InputDecoration(
                  labelText:
                      "Category",
                  prefixIcon: Icon(
                    Icons.category,
                    color: Colors.green,
                  ),
                  filled: true,
                  fillColor:
                      Colors.white,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                                16),
                    borderSide:
                        BorderSide.none,
                  ),
                ),
                items: _categories
                    .map(
                      (c) =>
                          DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    setState(() =>
                        _selectedCategory =
                            v),
              ),

              const SizedBox(
                  height: 14),

              _input(
                controller:
                    _experienceController,
                label:
                    "Experience (years)",
                icon:
                    Icons.timeline,
              ),

              const SizedBox(
                  height: 14),

              _input(
                controller:
                    _wageController,
                label:
                    "Expected Wage",
                icon: Icons
                    .currency_rupee,
              ),

              const SizedBox(
                  height: 14),

              DropdownButtonFormField<
                  String>(
                value:
                    _selectedWageType,
                decoration:
                    InputDecoration(
                  labelText:
                      "Wage Type",
                  prefixIcon: Icon(
                    Icons.payments,
                    color: Colors.green,
                  ),
                  filled: true,
                  fillColor:
                      Colors.white,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                                16),
                    borderSide:
                        BorderSide.none,
                  ),
                ),
                items: _wageTypes
                    .map(
                      (w) =>
                          DropdownMenuItem(
                        value: w,
                        child: Text(w),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    setState(() =>
                        _selectedWageType =
                            v),
              ),

              const SizedBox(
                  height: 14),

              // ==========================
              // IMAGE UPLOAD UI
              // ==========================

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
                                16),
                    border: Border.all(
                      color: Colors
                          .green
                          .shade200,
                    ),
                    color:
                        Colors.white,
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
                                      Image.network(
                                    _selectedImage!.path,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _uploadedImageUrl != null
                                            ? Image.network(_uploadedImageUrl!, fit: BoxFit.cover)
                                            : const Icon(Icons.broken_image, size: 60, color: Colors.grey),
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
                                              Icons.person,
                                              size:
                                                  60,
                                              color:
                                                  Colors.green,
                                            ),
                                            SizedBox(
                                                height:
                                                    10),
                                            Text(
                                              "Tap to upload worker photo",
                                            ),
                                          ],
                                        )),
                ),
              ),

              const SizedBox(
                  height: 14),

              Material(
                elevation: 2,
                borderRadius:
                    BorderRadius.circular(
                        16),
                child: TextFormField(
                  controller:
                      _descriptionController,
                  maxLines: 3,
                  decoration:
                      InputDecoration(
                    labelText:
                        "Description",
                    prefixIcon: Icon(
                      Icons.description,
                      color:
                          Colors.green,
                    ),
                    filled: true,
                    fillColor:
                        Colors.white,
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                                  16),
                      borderSide:
                          BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                  height: 16),

              Container(
                padding: const EdgeInsets.symmetric(
  horizontal: 12,
  vertical: 10,
),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius
                          .circular(
                              16),
                  border: Border.all(
                    color: Colors
                        .green
                        .shade100,
                  ),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                  children: [
                    const Text(
                      "Available",
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    Switch(
                      value:
                          _available,
                      onChanged: (v) =>
                          setState(() =>
                              _available =
                                  v),
                      activeColor:
                          Colors.green,
                    ),
                  ],
                ),
              ),

              const SizedBox(
                  height: 22),

              SizedBox(
                height: 52,
                child:
                    ElevatedButton.icon(
                  onPressed:
                      _saveLabour,
                  icon: const Icon(
                    Icons.save,
                  ),
                  label: Text(
                    l.saveLabour,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        Colors
                            .green
                            .shade700,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                                  16),
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
}