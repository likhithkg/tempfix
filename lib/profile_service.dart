import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? get currentUser => _auth.currentUser;

  /// Load user data from Firestore
  Future<Map<String, dynamic>?> loadUserData() async {
    if (currentUser == null) return null;

    final doc = await _firestore.collection("users").doc(currentUser!.uid).get();
    return doc.exists ? doc.data() : null;
  }

  /// Upload image to Firebase Storage
  Future<String?> uploadProfileImage(File image) async {
    try {
      final storageRef =
          _storage.ref().child("profile_pictures/${currentUser!.uid}.jpg");
      await storageRef.putFile(image);
      return await storageRef.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  /// Update profile in Firebase Auth + Firestore
  Future<void> updateProfile({
    required String name,
    required String phone,
    required String address,
    File? image,
  }) async {
    if (currentUser == null) return;

    String? photoUrl = currentUser!.photoURL;

    // Upload new image if selected
    if (image != null) {
      photoUrl = await uploadProfileImage(image);
      await currentUser!.updatePhotoURL(photoUrl);
    }

    // Update Firebase Auth displayName
    await currentUser!.updateDisplayName(name);

    // Save profile in Firestore
    await _firestore.collection("users").doc(currentUser!.uid).set({
      "name": name,
      "email": currentUser!.email,
      "photoURL": photoUrl,
      "phone": phone,
      "address": address,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await currentUser!.reload();
  }

  /// Logout user
  Future<void> logout() async {
    await _auth.signOut();
  }
}