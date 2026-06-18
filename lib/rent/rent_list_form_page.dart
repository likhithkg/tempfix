import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'rent_model.dart';
import 'package:krishimithra/rent/rent_machine_service.dart';

import '../services/image_upload_service.dart';
import '../l10n/app_localizations.dart';

class RentListFormPage extends StatefulWidget {
  final RentMachine? existingMachine;

  const RentListFormPage({
    super.key,
    this.existingMachine,
  });

  @override
  State<RentListFormPage> createState() =>
      _RentListFormPageState();
}

class _RentListFormPageState
    extends State<RentListFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();

  final _price = TextEditingController();

  final _owner = TextEditingController();

  final _phone = TextEditingController();

  final _locationController =
      TextEditingController();

  String? _type;

  double? _lat;

  double? _lng;

  String? _imageUrl;

  XFile? _picked;

  bool _uploadingImage = false;

  final _types = const [
    'Tractor',
    'Harvester',
    'Plough',
    'Seeder',
    'Sprayer',
    'Tiller',
    'Baler',
    'Other'
  ];

  final String _locationIQApiKey =
      "pk.56ccd9d8fb2cd5f3e9d7a656e3b52566";

  @override
  void initState() {
    super.initState();

    final m = widget.existingMachine;

    if (m != null) {
      _name.text = m.name;

      _price.text =
          m.pricePerDay.toString();

      _owner.text = m.ownerName;

      _phone.text = m.phone;

      _type = m.type;

      _lat = m.latitude;

      _lng = m.longitude;

      _imageUrl = m.imageUrl;

      _locationController.text =
          m.location ?? '';
    }
  }

  @override
  void dispose() {
    _name.dispose();

    _price.dispose();

    _owner.dispose();

    _phone.dispose();

    _locationController.dispose();

    super.dispose();
  }

  Future<void> _getLocation() async {
    try {
      final perm =
          await Geolocator.requestPermission();

      if (perm ==
              LocationPermission.denied ||
          perm ==
              LocationPermission
                  .deniedForever) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission denied',
            ),
          ),
        );

        return;
      }

      final p =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy:
              LocationAccuracy.high,
        ),
      );

      setState(() {
        _lat = p.latitude;

        _lng = p.longitude;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.currentLocationSet),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text('Location error: $e'),
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    final f = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (f != null) {
      setState(() {
        _picked = f;
      });
    }
  }

  // ===============================
  // CLOUDINARY IMAGE UPLOAD
  // ===============================

  Future<void> _uploadToCloudinary() async {
    if (_picked == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.pickImageFirst),
        ),
      );

      return;
    }

    try {
      setState(() {
        _uploadingImage = true;
      });

      final imageUrl =
          await ImageUploadService
              .uploadImage(
        File(_picked!.path),
      );

      if (imageUrl != null) {
        setState(() {
          _imageUrl = imageUrl;
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Image uploaded successfully ✅',
            ),
            backgroundColor:
                Colors.green,
          ),
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.imageUploadFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint(
          "Cloudinary Upload Error: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text('Upload Error: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploadingImage = false;
        });
      }
    }
  }

  Future<void> _openLocationSearch() async {
    final result =
        await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();

        List<dynamic> results = [];

        return StatefulBuilder(
          builder: (ctx, setState) =>
              AlertDialog(
            title: const Text(
              "Set Location",
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: Column(
                children: [
                  TextField(
                    controller: ctrl,
                    decoration:
                        const InputDecoration(
                      prefixIcon:
                          Icon(Icons.search),
                      hintText:
                          "Search place...",
                    ),
                    onChanged: (val) async {
                      if (val.length < 3) {
                        return;
                      }

                      final url =
                          "https://us1.locationiq.com/v1/search.php?key=$_locationIQApiKey&q=$val&format=json";

                      final res = await http.get(
                        Uri.parse(url),
                      );

                      if (res.statusCode ==
                          200) {
                        setState(() {
                          results =
                              json.decode(
                            res.body,
                          );
                        });
                      }
                    },
                  ),

                  const SizedBox(
                      height: 10),

                  Expanded(
                    child: ListView.builder(
                      itemCount:
                          results.length,
                      itemBuilder: (_, i) {
                        final r =
                            results[i];

                        return ListTile(
                          leading:
                              const Icon(
                            Icons.location_on,
                          ),
                          title: Text(
                            r['display_name'],
                          ),
                          onTap: () =>
                              Navigator.pop(
                            ctx,
                            {
                              "name": r[
                                  'display_name'],
                              "lat": double.tryParse(
                                      r['lat'] ??
                                          '0') ??
                                  0,
                              "lon": double.tryParse(
                                      r['lon'] ??
                                          '0') ??
                                  0,
                            },
                          ),
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
        _locationController.text =
            result["name"];

        _lat = result["lat"];

        _lng = result["lon"];
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    if (_type == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.selectMachineType),
        ),
      );

      return;
    }

    if (_lat == null || _lng == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.setLocationFirst),
        ),
      );

      return;
    }

    final uid =
        FirebaseAuth.instance.currentUser
                ?.uid ??
            '';

    final priceParsed =
        double.tryParse(
      _price.text.trim(),
    );

    if (priceParsed == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a valid numeric price',
          ),
        ),
      );

      return;
    }

    final m = RentMachine(
      id:
          widget.existingMachine?.id ??
              '',
      name: _name.text.trim(),
      type: _type ?? 'Other',
      pricePerDay: priceParsed,
      ownerName: _owner.text.trim(),
      ownerId:
          widget.existingMachine
                  ?.ownerId ??
              uid,
      phone: _phone.text.trim(),
      latitude: _lat ?? 0,
      longitude: _lng ?? 0,
      imageUrl: _imageUrl ?? '',
      createdAt:
          widget.existingMachine
                  ?.createdAt ??
              DateTime.now(),
      location:
          _locationController.text
              .trim(),
    );

    try {
      if (widget.existingMachine ==
          null) {
        await RentMachineService
            .instance
            .addMachine(m);

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Listing submitted successfully',
            ),
          ),
        );

        Navigator.pop(context);
      } else {
        await RentMachineService
            .instance
            .updateMachine(
          m.id,
          m,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Listing updated successfully',
            ),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      print(
          '[RentListFormPage] submit error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to submit listing: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit =
        widget.existingMachine != null;

    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit
              ? l.editMachineTitle
              : l.listNewMachineTitle,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding:
              const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            100,
          ),
          children: [
            // IMAGE PREVIEW

            Material(
              elevation: 1,
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
              clipBehavior: Clip.antiAlias,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _uploadingImage
                    ? const Center(
                        child:
                            CircularProgressIndicator(),
                      )
                    : _picked != null
                        ? Image.file(
                            File(
                                _picked!.path),
                            fit: BoxFit.cover,
                          )
                        : (_imageUrl !=
                                    null &&
                                _imageUrl!
                                    .isNotEmpty)
                            ? Image.network(
                                _imageUrl!,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: theme
                                    .colorScheme
                                    .surfaceVariant,
                                alignment:
                                    Alignment
                                        .center,
                                child: const Text(
                                  'No image selected',
                                ),
                              ),
              ),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  onPressed:
                      _pickImage,
                  icon: const Icon(
                    Icons.image,
                  ),
                  label:
                      Text(l.pickImage),
                ),

                OutlinedButton.icon(
                  onPressed:
                      _uploadToCloudinary,
                  icon: const Icon(
                    Icons.cloud_upload,
                  ),
                  label: Text(
                    l.uploadImage,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _name,
              decoration:
                  const InputDecoration(
                labelText:
                    'Machine Name',
                prefixIcon:
                    Icon(Icons.agriculture),
              ),
              validator: (v) =>
                  (v == null ||
                          v.trim().isEmpty)
                      ? 'Enter machine name'
                      : null,
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<
                String>(
              value: _type,
              items: _types
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(t),
                    ),
                  )
                  .toList(),
              onChanged: (v) =>
                  setState(() => _type = v),
              decoration:
                  const InputDecoration(
                labelText:
                    'Machine Type',
                prefixIcon: Icon(
                  Icons.category_rounded,
                ),
              ),
              validator: (v) =>
                  v == null
                      ? 'Select a type'
                      : null,
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _price,
              keyboardType:
                  TextInputType.number,
              decoration:
                  const InputDecoration(
                labelText:
                    'Price per day (₹)',
                prefixIcon: Icon(
                  Icons.attach_money,
                ),
              ),
              validator: (v) =>
                  (v == null ||
                          double.tryParse(v) ==
                              null)
                      ? 'Enter price'
                      : null,
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _owner,
              decoration:
                  const InputDecoration(
                labelText:
                    'Owner name',
                prefixIcon: Icon(
                  Icons.person_rounded,
                ),
              ),
              validator: (v) =>
                  (v == null ||
                          v.trim().isEmpty)
                      ? 'Enter owner name'
                      : null,
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _phone,
              keyboardType:
                  TextInputType.phone,
              decoration:
                  const InputDecoration(
                labelText:
                    'Phone number',
                prefixIcon: Icon(
                  Icons.phone_rounded,
                ),
              ),
              validator: (v) =>
                  (v == null ||
                          v.trim().isEmpty)
                      ? 'Enter phone'
                      : null,
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller:
                  _locationController,
              readOnly: true,
              decoration:
                  InputDecoration(
                labelText: 'Location',
                prefixIcon: const Icon(
                  Icons
                      .location_city_rounded,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.search_rounded,
                  ),
                  onPressed:
                      _openLocationSearch,
                ),
                hintText:
                    'Search & set location',
              ),
              validator: (v) =>
                  (v == null ||
                          v.trim().isEmpty)
                      ? 'Select location'
                      : null,
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Text(
                    _lat == null
                        ? '📍 Location not set'
                        : 'Lat: ${_lat!.toStringAsFixed(4)}  Lng: ${_lng!.toStringAsFixed(4)}',
                  ),
                ),
                IconButton(
                  onPressed:
                      _getLocation,
                  icon: const Icon(
                    Icons
                        .my_location_rounded,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: _submit,
              icon: Icon(
                isEdit
                    ? Icons.save_rounded
                    : Icons.add_rounded,
              ),
              label: Text(
                isEdit
                    ? 'Update Listing'
                    : 'Submit Listing',
              ),
            ),
          ],
        ),
      ),
    );
  }
}