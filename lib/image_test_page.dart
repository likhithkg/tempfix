import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'services/image_upload_service.dart';

class ImageTestPage extends StatefulWidget {
  const ImageTestPage({super.key});

  @override
  State<ImageTestPage> createState() => _ImageTestPageState();
}

class _ImageTestPageState extends State<ImageTestPage> {
  File? selectedImage;

  String? uploadedImageUrl;

  bool isLoading = false;

  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile == null) return;

    setState(() {
      selectedImage = File(pickedFile.path);
      isLoading = true;
    });

    final imageUrl =
        await ImageUploadService.uploadImage(selectedImage!);

    setState(() {
      uploadedImageUrl = imageUrl;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("KM Image Upload"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickAndUploadImage,
              child: const Text("Pick & Upload Image"),
            ),

            const SizedBox(height: 20),

            if (isLoading)
              const CircularProgressIndicator(),

            if (uploadedImageUrl != null)
              Expanded(
                child: Image.network(
                  uploadedImageUrl!,
                  fit: BoxFit.cover,
                ),
              ),
          ],
        ),
      ),
    );
  }
}