import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ImageUploadService {
  // FOR ANDROID EMULATOR
 static const String baseUrl =
    "http://172.20.10.3:5000/api/upload";

  // FOR REAL DEVICE USE:
  // static const String baseUrl = "http://YOUR_PC_IP:5000/api/upload";

  static Future<String?> uploadImage(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(baseUrl),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData =
            jsonDecode(await response.stream.bytesToString());

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