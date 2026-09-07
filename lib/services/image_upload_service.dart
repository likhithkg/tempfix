import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ImageUploadService {
  static const String baseUrl =
      "https://km-backend-ug96.onrender.com/api/upload";

  static Future<String?> uploadImage(File imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();

      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = jsonDecode(await response.stream.bytesToString());
        return responseData['data']['imageUrl'];
      } else {
        return null;
      }
    } catch (e) {
      print("Upload Error: $e");
      return null;
    }
  }
}