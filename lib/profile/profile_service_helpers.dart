// lib/profile/profile_service_helpers.dart
// Helper additions for ProfileService: deleteUserData and exportUserData

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileServiceHelpers {
  ProfileServiceHelpers._();

  /// Delete user-owned documents across common collections.
  /// Adjust `collectionsToCheck` to match your app's data model.
  static Future<void> deleteUserData(String uid) async {
    final firestore = FirebaseFirestore.instance;

    // Collections to attempt deletion from. Update these names to match your schema.
    final collectionsToCheck = <String>[
      'plant_vendors',
      'rentals',
      'orders',
      'machine_rentals',
      // add more collection names here that store ownerId
    ];

    // Use batched deletes where possible (max 500 per batch)
    for (final col in collectionsToCheck) {
      try {
        final query = firestore.collection(col).where('ownerId', isEqualTo: uid).limit(500);
        QuerySnapshot snapshot;
        do {
          snapshot = await query.get();
          if (snapshot.docs.isEmpty) break;
          final batch = firestore.batch();
          for (final doc in snapshot.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        } while (snapshot.docs.length == 500);
      } catch (e) {
        // ignore individual collection failure so other collections still delete
        // optionally log this error to your analytics
      }
    }

    // Finally delete user document in `users` collection (if you store one)
    try {
      await firestore.collection('users').doc(uid).delete();
    } catch (e) {
      // ignore if not found
    }
  }

  /// Export user data from common collections into a JSON file and upload to Firebase Storage.
  /// Returns the download URL of the exported file.
  static Future<String> exportUserData(String uid) async {
    final firestore = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;

    final Map<String, dynamic> export = {};

    // Helper to fetch list of docs matching ownerId
    Future<List<Map<String, dynamic>>> _fetchByOwner(String collection) async {
      try {
        final q = await firestore.collection(collection).where('ownerId', isEqualTo: uid).get();
        return q.docs.map((d) => {'id': d.id, 'data': d.data()}).toList();
      } catch (e) {
        return [];
      }
    }

    // Add user document
    try {
      final userDoc = await firestore.collection('users').doc(uid).get();
      export['user'] = userDoc.exists ? userDoc.data() : {}; 
    } catch (e) {
      export['user'] = {};
    }

    // Collections to include in the export. Tune this list for your app.
    final collectionsToExport = <String>[
      'plant_vendors',
      'rentals',
      'orders',
      'machine_rentals',
    ];

    for (final col in collectionsToExport) {
      export[col] = await _fetchByOwner(col);
    }

    // Convert to pretty JSON
    final jsonString = const JsonEncoder.withIndent('  ').convert(export);

    // Upload to Firebase Storage
    final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final path = 'exports/$uid-export-$timestamp.json';
    final ref = storage.ref().child(path);
    final bytes = utf8.encode(jsonString);

    final uploadTask = ref.putData(bytes, SettableMetadata(contentType: 'application/json'));
    final snap = await uploadTask.whenComplete(() {});
    final url = await snap.ref.getDownloadURL();

    return url;
  }
}

// Quick adapter methods you can call from your existing ProfileService
// Example usage in ProfileService (if you want to forward):
// Future<void> deleteUserData(String uid) => ProfileServiceHelpers.deleteUserData(uid);
// Future<String> exportUserData(String uid) => ProfileServiceHelpers.exportUserData(uid);
