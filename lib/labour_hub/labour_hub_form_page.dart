// lib/labour_hub/labour_hub_form_page.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import 'labour_model.dart';
import 'labour_hub_service.dart';

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

  File? _selectedImage;

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

  final String _locationIqKey =
      "pk.56ccd9d8fb2cd5f3e9d7a656e3b52566";

  Timer? _debounce;

  List<Map<String, String>>
      _suggestions = [];

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

    _locationController
        .addListener(() {
      _onLocationChanged(
        _locationController.text
            .trim(),
      );
    });
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

  void _onLocationChanged(
      String query) {
    _selectedLat = null;

    _selectedLng = null;

    if (_debounce?.isActive ??
        false) {
      _debounce!.cancel();
    }

    _debounce = Timer(
      const Duration(
          milliseconds: 350),
      () {
        if (query.length < 2) {
          setState(() =>
              _suggestions = []);

          return;
        }

        _fetchLocationSuggestions(
            query);
      },
    );
  }

  Future<void>
      _fetchLocationSuggestions(
          String query) async {
    final url =
        'https://us1.locationiq.com/v1/autocomplete.php?key=$_locationIqKey&q=${Uri.encodeComponent(query)}&limit=6';

    try {
      final res = await http.get(
        Uri.parse(url),
      );

      if (res.statusCode == 200) {
        final List data =
            jsonDecode(res.body);

        final items =
            data.map<
                Map<String, String>>(
          (e) {
            return {
              'display_name':
                  (e['display_name'] ??
                          '')
                      .toString(),
              'lat':
                  (e['lat'] ?? '')
                      .toString(),
              'lon':
                  (e['lon'] ?? '')
                      .toString(),
            };
          },
        ).toList();

        final seen = <String>{};

        final deduped =
            <Map<String, String>>[];

        for (final i in items) {
          if (!seen.contains(
              i['display_name'])) {
            seen.add(
                i['display_name']!);

            deduped.add(i);
          }
        }

        setState(
            () => _suggestions =
                deduped);
      } else {
        setState(() =>
            _suggestions = []);
      }
    } catch (e) {
      setState(() =>
          _suggestions = []);
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

              _input(
                controller:
                    _locationController,
                label: "Location",
                icon:
                    Icons.location_on,
                validator: (v) =>
                    v == null ||
                            v.trim()
                                .isEmpty
                        ? "Enter location"
                        : null,
              ),

              if (_suggestions
                  .isNotEmpty)
                Container(
                  margin:
                      const EdgeInsets
                          .only(top: 6),
                  padding:
                      const EdgeInsets
                          .all(6),
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius
                            .circular(
                                14),
                    border: Border.all(
                      color: Colors
                          .green
                          .shade100,
                    ),
                  ),
                  child: Column(
                    children:
                        _suggestions.map(
                      (s) {
                        return ListTile(
                          title: Text(
                            s['display_name']!,
                            maxLines: 2,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                          ),
                          onTap: () {
                            _locationController
                                    .text =
                                s[
                                    'display_name']!;

                            _selectedLat =
                                double.tryParse(
                              s['lat']!,
                            );

                            _selectedLng =
                                double.tryParse(
                              s['lon']!,
                            );

                            setState(
                                () =>
                                    _suggestions =
                                        []);
                          },
                        );
                      },
                    ).toList(),
                  ),
                ),

              const SizedBox(
                  height: 14),

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