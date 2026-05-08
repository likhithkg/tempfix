import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../services/image_upload_service.dart';

class PostExportStockPage extends StatefulWidget {
  final bool isEdit;
  final String? docId;
  final Map<String, dynamic>? existingData;

  const PostExportStockPage({
    super.key,
    this.isEdit = false,
    this.docId,
    this.existingData,
  });

  @override
  State<PostExportStockPage> createState() =>
      _PostExportStockPageState();
}

class _PostExportStockPageState
    extends State<PostExportStockPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController farmerNameController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController productController =
      TextEditingController();

  final TextEditingController categoryController =
      TextEditingController();

  final TextEditingController quantityController =
      TextEditingController();

  final TextEditingController priceController =
      TextEditingController();

  final TextEditingController locationController =
      TextEditingController();

  bool isExportGrade = false;

  bool isLoading = false;

  // =========================
  // IMAGE VARIABLES
  // =========================

  File? selectedImage;

  String? uploadedImageUrl;

  bool uploadingImage = false;

  // =========================
  // LOCATION VARIABLES
  // =========================

  List<dynamic> locationSuggestions = [];

  bool isSearchingLocation = false;

  double? selectedLat;

  double? selectedLng;

  @override
  void initState() {
    super.initState();

    if (widget.isEdit &&
        widget.existingData != null) {
      final data = widget.existingData!;

      farmerNameController.text =
          data['farmerName'] ?? '';

      phoneController.text =
          data['farmerPhone'] ?? '';

      productController.text =
          data['productName'] ?? '';

      categoryController.text =
          data['category'] ?? '';

      quantityController.text =
          data['quantity'] ?? '';

      priceController.text =
          data['pricePerKg'] ?? '';

      locationController.text =
          data['location'] ?? '';

      isExportGrade =
          data['isExportGrade'] ?? false;

      selectedLat = data['latitude'];

      selectedLng = data['longitude'];

      uploadedImageUrl =
          data['imageUrl'];
    }
  }

  // =========================
  // IMAGE PICKER
  // =========================

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();

      final picked =
          await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );

      if (picked == null) return;

      setState(() {
        selectedImage =
            File(picked.path);
      });

      await uploadImage();
    } catch (e) {
      debugPrint(
          "Image Pick Error: $e");
    }
  }

  // =========================
  // CLOUDINARY UPLOAD
  // =========================

  Future<void> uploadImage() async {
    if (selectedImage == null) {
      return;
    }

    try {
      setState(() {
        uploadingImage = true;
      });

      final imageUrl =
          await ImageUploadService
              .uploadImage(
        selectedImage!,
      );

      if (imageUrl != null) {
        setState(() {
          uploadedImageUrl =
              imageUrl;
        });

        if (mounted) {
          ScaffoldMessenger.of(
                  context)
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
          ScaffoldMessenger.of(
                  context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                  "Image upload failed"),
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
          uploadingImage = false;
        });
      }
    }
  }

  // =========================
  // LOCATION SEARCH
  // =========================

  Future<void> searchLocation(
      String query) async {
    if (query.isEmpty) {
      setState(() =>
          locationSuggestions = []);

      return;
    }

    setState(() =>
        isSearchingLocation = true);

    const apiKey =
        "pk.56ccd9d8fb2cd5f3e9d7a656e3b52566";

    final url =
        "https://us1.locationiq.com/v1/autocomplete.php?key=$apiKey&q=$query&countrycodes=in&format=json";

    try {
      final response = await http.get(
        Uri.parse(url),
      );

      if (response.statusCode ==
          200) {
        final List<dynamic> results =
            jsonDecode(response.body);

        setState(() {
          locationSuggestions =
              results;

          isSearchingLocation =
              false;
        });
      } else {
        setState(() =>
            isSearchingLocation =
                false);
      }
    } catch (e) {
      setState(() =>
          isSearchingLocation =
              false);
    }
  }

  // =========================
  // SUBMIT LISTING
  // =========================

  Future<void> submitListing() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth
          .instance.currentUser;

      if (user == null) {
        throw Exception(
            "User not logged in");
      }

      final listingData = {
        'farmerId': user.uid,
        'farmerName':
            farmerNameController.text
                .trim(),
        'farmerPhone':
            phoneController.text
                .trim(),
        'productName':
            productController.text
                .trim(),
        'category':
            categoryController.text
                .trim(),
        'quantity':
            quantityController.text
                .trim(),
        'pricePerKg':
            priceController.text
                .trim(),
        'location':
            locationController.text
                .trim(),
        'latitude': selectedLat,
        'longitude': selectedLng,
        'isExportGrade':
            isExportGrade,
        'status': 'open',

        // =========================
        // IMAGE URL
        // =========================

        'imageUrl':
            uploadedImageUrl,
      };

      if (widget.isEdit &&
          widget.docId != null) {
        await FirebaseFirestore
            .instance
            .collection(
                'export_listings')
            .doc(widget.docId)
            .update(listingData);

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content:
                Text("Listing updated"),
          ),
        );
      } else {
        await FirebaseFirestore
            .instance
            .collection(
                'export_listings')
            .add({
          ...listingData,
          'createdAt':
              Timestamp.now(),
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Export stock posted successfully",
            ),
          ),
        );
      }

      setState(() => isLoading = false);

      Navigator.pop(context);
    } catch (e) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text("Error: $e"),
        ),
      );
    }
  }

  @override
  Widget build(
      BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEdit
              ? "Edit Export Stock"
              : "Post Export Stock",
        ),
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // =========================
              // IMAGE SECTION
              // =========================

              GestureDetector(
                onTap:
                    uploadingImage
                        ? null
                        : pickImage,
                child: Container(
                  height: 220,
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
                  ),
                  child:
                      uploadingImage
                          ? const Center(
                              child:
                                  CircularProgressIndicator(),
                            )
                          : selectedImage !=
                                  null
                              ? ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(
                                          16),
                                  child:
                                      Image.file(
                                    selectedImage!,
                                    fit: BoxFit
                                        .cover,
                                  ),
                                )
                              : (uploadedImageUrl !=
                                          null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(
                                                  16),
                                          child:
                                              Image.network(
                                            uploadedImageUrl!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [
                                            Icon(
                                              Icons.image,
                                              size:
                                                  60,
                                              color:
                                                  Colors.green,
                                            ),
                                            SizedBox(
                                                height:
                                                    10),
                                            Text(
                                              "Tap to upload product image",
                                            ),
                                          ],
                                        )),
                ),
              ),

              const SizedBox(
                  height: 20),

              buildField(
                "Farmer Name",
                farmerNameController,
              ),

              buildField(
                "Farmer Mobile Number",
                phoneController,
                keyboardType:
                    TextInputType.phone,
              ),

              buildField(
                "Product Name",
                productController,
              ),

              buildField(
                "Category (Coconut / Vegetables / etc)",
                categoryController,
              ),

              buildField(
                "Quantity (in tons/kg)",
                quantityController,
              ),

              buildField(
                "Price per Kg",
                priceController,
              ),

              // =========================
              // LOCATION FIELD
              // =========================

              Padding(
                padding:
                    const EdgeInsets.only(
                        bottom: 15),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    TextFormField(
                      controller:
                          locationController,
                      onChanged: (value) {
                        searchLocation(
                            value);
                      },
                      validator:
                          (value) =>
                              value ==
                                          null ||
                                      value
                                          .isEmpty
                                  ? "Required field"
                                  : null,
                      decoration:
                          InputDecoration(
                        labelText:
                            "Location",
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  10),
                        ),
                        suffixIcon:
                            isSearchingLocation
                                ? const Padding(
                                    padding:
                                        EdgeInsets.all(
                                            12),
                                    child:
                                        SizedBox(
                                      height:
                                          15,
                                      width:
                                          15,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2,
                                      ),
                                    ),
                                  )
                                : null,
                      ),
                    ),

                    if (locationSuggestions
                        .isNotEmpty)
                      Container(
                        height: 200,
                        margin:
                            const EdgeInsets
                                .only(
                                    top:
                                        5),
                        decoration:
                            BoxDecoration(
                          color: Colors
                              .white,
                          borderRadius:
                              BorderRadius
                                  .circular(
                                      8),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors
                                  .black12,
                              blurRadius:
                                  4,
                            ),
                          ],
                        ),
                        child:
                            ListView.builder(
                          itemCount:
                              locationSuggestions
                                  .length,
                          itemBuilder:
                              (context,
                                  index) {
                            final suggestion =
                                locationSuggestions[
                                    index];

                            return ListTile(
                              title: Text(
                                suggestion[
                                        'display_name'] ??
                                    '',
                              ),
                              onTap: () {
                                locationController
                                        .text =
                                    suggestion[
                                        'display_name'];

                                selectedLat =
                                    double.tryParse(
                                  suggestion[
                                      'lat'],
                                );

                                selectedLng =
                                    double.tryParse(
                                  suggestion[
                                      'lon'],
                                );

                                setState(() {
                                  locationSuggestions =
                                      [];
                                });
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

              SwitchListTile(
                title: const Text(
                    "Export Grade"),
                value: isExportGrade,
                onChanged: (val) =>
                    setState(() =>
                        isExportGrade =
                            val),
              ),

              const SizedBox(
                  height: 20),

              ElevatedButton(
                onPressed:
                    isLoading
                        ? null
                        : submitListing,
                child: isLoading
                    ? const CircularProgressIndicator(
                        color:
                            Colors.white,
                      )
                    : Text(
                        widget.isEdit
                            ? "Update"
                            : "Submit",
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildField(
    String label,
    TextEditingController
        controller, {
    TextInputType keyboardType =
        TextInputType.text,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
              bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType:
            keyboardType,
        validator: (value) =>
            value == null ||
                    value.isEmpty
                ? "Required field"
                : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
                    10),
          ),
        ),
      ),
    );
  }
}