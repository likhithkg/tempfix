import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ImageUploadService {
  static const String baseUrl =
      'https://km-backend-ug96.onrender.com/api/upload';
  static const Duration _timeout = Duration(seconds: 60);

  // ── Native (Android/iOS) — backward-compatible signature. ────────────────
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();

      final request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      if (token != null) request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamed = await request.send().timeout(_timeout);
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode == 200) {
        final data = jsonDecode(body) as Map<String, dynamic>;
        return (data['data'] as Map<String, dynamic>?)?['imageUrl'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Web-safe (all platforms) — use XFile.readAsBytes(). ─────────────────
  static Future<String?> uploadImageFromXFile(XFile xfile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();

      final Uint8List bytes = await xfile.readAsBytes();
      final String mimeType =
          xfile.mimeType ?? _mimeFromName(xfile.name) ?? 'image/jpeg';

      final request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      if (token != null) request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: xfile.name,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamed = await request.send().timeout(_timeout);
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode == 200) {
        final data = jsonDecode(body) as Map<String, dynamic>;
        return (data['data'] as Map<String, dynamic>?)?['imageUrl'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static String? _mimeFromName(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return null;
    }
  }
}
