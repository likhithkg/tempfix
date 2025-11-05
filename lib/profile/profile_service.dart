// lib/profile/profile_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  ProfileService._();
  static final instance = ProfileService._();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _supabase = Supabase.instance.client;

  // Upload file to Supabase storage and return public URL
  Future<String> uploadProfileImage(File file) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final bucket = 'profile-photos'; // ensure this bucket exists in Supabase
    final path = '${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      final bytes = await file.readAsBytes();

      // Attempt upload. Different supabase_flutter versions return different shapes.
      // We don't rely on a specific response shape; instead, catch exceptions.
      await _supabase.storage.from(bucket).uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );

      // Get public URL. Some versions return a String directly, others return an object.
      final publicRes = _supabase.storage.from(bucket).getPublicUrl(path);

      // Guard: convert to string so it works regardless of return type.
      final publicUrl = publicRes?.toString() ?? '';
      if (publicUrl.isEmpty) {
        throw Exception('Failed to get public URL from Supabase.');
      }
      return publicUrl;
    } catch (e) {
      // Re-throw with clearer message
      throw Exception('Supabase upload failed: $e');
    }
  }

  // Update Firebase user's photoURL
  Future<void> updateFirebasePhotoUrl(String url) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await user.updatePhotoURL(url);
    await user.reload();
  }

  // Save additional profile fields to Firestore
  Future<void> saveProfileFields({
    required String uid,
    String? defaultLocation,
    String? language,
  }) async {
    final ref = _firestore.collection('users').doc(uid);
    final data = <String, dynamic>{};
    if (defaultLocation != null) data['defaultLocation'] = defaultLocation;
    if (language != null) data['language'] = language;
    await ref.set(data, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>> getProfileFields(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return {};
    return doc.data() ?? {};
  }

  // Theme preference
  Future<void> setDarkMode(bool isDark) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('isDarkMode', isDark);
  }

  Future<bool> getDarkMode() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool('isDarkMode') ?? false;
  }
}
