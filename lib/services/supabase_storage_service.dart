import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String?> uploadImage(XFile file) async {
  try {
    final fileBytes = await file.readAsBytes();
    final filePath = 'public/rent_machines/${DateTime.now().millisecondsSinceEpoch}_${file.name}';

    final response = await _client.storage
        .from('rent-machine-images')
        .uploadBinary(
          filePath,
          fileBytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );

    if (response.isEmpty) return null;

    final publicUrl = _client.storage
        .from('rent-machine-images')
        .getPublicUrl(filePath);

    return publicUrl;
  } catch (e) {
    print("Supabase Upload Failed: $e");
    return null;
  }
}
}