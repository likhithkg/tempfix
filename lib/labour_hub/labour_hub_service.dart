// labour_hub_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'labour_model.dart';

class LabourHubService {
  final _collection = FirebaseFirestore.instance.collection('labours');
  final _auth = FirebaseAuth.instance;

  /// ✅ Add new labour entry
  Future<void> addLabour(Labour labour) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final doc = _collection.doc();
    final toSave = labour.copyWith(
      id: doc.id,
      createdBy: user.uid, // 👈 store creator UID
    );

    await doc.set(toSave.toMap());
  }

  /// ✅ Update labour (only if createdBy == currentUser.uid)
  Future<void> updateLabour(String id, Labour labour) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final snap = await _collection.doc(id).get();
    if (!snap.exists) throw Exception("Labour not found");

    if (snap.data()?['createdBy'] == user.uid) {
      final updatedData = labour.toMap()
        ..remove('id')
        ..remove('createdBy'); // 👈 don’t overwrite ownership

      await _collection.doc(id).update(updatedData);
    } else {
      throw Exception("Not allowed to update this labour");
    }
  }

  /// ✅ Delete labour (only if createdBy == currentUser.uid)
  Future<void> deleteLabour(String id) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final snap = await _collection.doc(id).get();
    if (!snap.exists) throw Exception("Labour not found");

    if (snap.data()?['createdBy'] == user.uid) {
      await _collection.doc(id).delete();
    } else {
      throw Exception("Not allowed to delete this labour");
    }
  }

  /// ✅ Get all labours (newest first)
  Future<List<Labour>> getAllLabours() async {
    final snapshot = await _collection.get();
    return snapshot.docs
        .map((doc) => Labour.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// ✅ Get only current user’s labours
  Future<List<Labour>> getMyLabours() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final snapshot = await _collection
        .where('createdBy', isEqualTo: user.uid)
        .get();

    return snapshot.docs
        .map((doc) => Labour.fromMap(doc.data(), doc.id))
        .toList();
  }
}