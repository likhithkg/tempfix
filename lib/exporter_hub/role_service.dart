// lib/exporter_hub/role_service.dart
// Reads user role from Firestore: users/{uid}/role: 'farmer' | 'admin'
// All cached in-memory for the app session to minimize reads.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleService {
  static final _db = FirebaseFirestore.instance;

  // In-memory cache: uid → role
  static final Map<String, String> _cache = {};

  /// Fetch role for a specific uid. Returns 'farmer' if not found.
  static Future<String> getRole(String uid) async {
    if (_cache.containsKey(uid)) return _cache[uid]!;
    try {
      final snap = await _db.collection('users').doc(uid).get();
      final role = snap.data()?['role']?.toString() ?? 'farmer';
      _cache[uid] = role;
      return role;
    } catch (_) {
      return 'farmer';
    }
  }

  /// Returns role for the currently signed-in user, or 'farmer'.
  static Future<String> currentRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'farmer';
    return getRole(uid);
  }

  /// Stream the current user's role (live updates).
  static Stream<String> streamCurrentRole() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value('farmer');
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      final role = snap.data()?['role']?.toString() ?? 'farmer';
      _cache[uid] = role;
      return role;
    });
  }

  /// Set role for a user (admin operation).
  static Future<void> setRole(String uid, String role) async {
    await _db.collection('users').doc(uid).set({'role': role}, SetOptions(merge: true));
    _cache[uid] = role;
  }

  static bool isAdmin(String role) => role == 'admin';
  static bool isFarmer(String role) => role == 'farmer';

  static void clearCache() => _cache.clear();
}
