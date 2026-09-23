// lib/profile/profile_service.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_service_helpers.dart';

class ProfileService {
  ProfileService._();
  static final instance = ProfileService._();

  static const String _backendBase = 'https://km-backend-ug96.onrender.com';

  /// Notifier that drives live theme changes across the app.
  final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // ── Profile photo upload ──────────────────────────────────────────────────

  /// Uploads [bytes] to MongoDB GridFS via the backend and returns the public
  /// HTTPS URL for the stored image.
  ///
  /// Uses [picked.readAsBytes()] on the call-site so this works on Flutter Web
  /// (no dart:io File involved).
  Future<String> uploadProfileImage(Uint8List bytes, String mimeType) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final token = await user.getIdToken();
    if (token == null) throw Exception('Authentication failed');

    final result = await _doUpload(bytes, mimeType, token);

    // If the backend doesn't have a MongoDB record yet (e.g. startup sync
    // timed out on a cold Render instance), sync now and retry once.
    if (result == null) {
      await _syncWithBackend(token);
      final retry = await _doUpload(bytes, mimeType, token);
      if (retry == null) {
        throw Exception(
            'Upload failed: could not create user record. Please try again.');
      }
      return retry;
    }

    return result;
  }

  /// Sends the multipart request and returns the image URL, or null when the
  /// backend says the MongoDB user record is missing (404 "User not found").
  /// Throws for all other errors.
  Future<String?> _doUpload(
      Uint8List bytes, String mimeType, String token) async {
    final uri = Uri.parse('$_backendBase/api/profile/photo');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes(
        'photo',
        bytes,
        filename: 'profile.jpg',
        contentType: MediaType.parse(mimeType),
      ));

    late http.StreamedResponse streamed;
    try {
      streamed = await request.send().timeout(const Duration(seconds: 60));
    } catch (e) {
      // In Flutter Web, CORS failures and network timeouts both surface here.
      throw Exception('Upload failed: $e');
    }

    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200) {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final url = data['imageUrl'] as String?;
      if (url == null || url.isEmpty) {
        throw Exception('Server returned no image URL');
      }
      return url;
    }

    // 404 "User not found" — signal the caller to sync and retry.
    if (streamed.statusCode == 404) {
      try {
        final data = jsonDecode(body) as Map<String, dynamic>;
        final msg = data['error'] as String? ?? '';
        if (msg.toLowerCase().contains('user not found')) return null;
      } catch (_) {}
    }

    // All other errors — surface the backend's message.
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final msg = data['error'] as String?;
      throw Exception(msg ?? 'Upload failed (HTTP ${streamed.statusCode})');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Upload failed (HTTP ${streamed.statusCode})');
    }
  }

  /// Calls /api/auth/verify to create or update the MongoDB user record.
  Future<void> _syncWithBackend(String token) async {
    try {
      await http
          .post(
            Uri.parse('$_backendBase/api/auth/verify'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 45));
    } catch (_) {
      // Best-effort — the retry upload will surface any remaining error.
    }
  }

  // ── Firebase photoURL ─────────────────────────────────────────────────────

  Future<void> updateFirebasePhotoUrl(String url) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    await user.updatePhotoURL(url);
    await user.reload();
  }

  // ── Firestore profile fields ──────────────────────────────────────────────

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

  // ── Theme preference ──────────────────────────────────────────────────────

  Future<void> setDarkMode(bool isDark) async {
    final uid = _auth.currentUser?.uid;
    final key = uid != null ? 'isDarkMode_$uid' : 'isDarkMode';
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(key, isDark);
    themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<bool> getDarkMode() async {
    final uid = _auth.currentUser?.uid;
    final key = uid != null ? 'isDarkMode_$uid' : 'isDarkMode';
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(key) ?? false;
  }

  // ── Account management (delegated to helpers) ─────────────────────────────

  Future<void> deleteUserData(String uid) async {
    return ProfileServiceHelpers.deleteUserData(uid);
  }

  Future<String> exportUserData(String uid) async {
    return ProfileServiceHelpers.exportUserData(uid);
  }
}
