// lib/labour_hub/labour_hub_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'labour_model.dart';

class LabourHubService {
  static const String collectionName = 'labours';
  final _collection = FirebaseFirestore.instance.collection(collectionName);
  final _auth = FirebaseAuth.instance;

  /// Add new labour entry. Returns the created document id.
  Future<String> addLabour(Labour labour) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final doc = _collection.doc();
    final toSave = labour.copyWith(
      id: doc.id,
      createdBy: user.uid,
    );

    final map = _stripNulls(toSave.toMap());
    // Set server timestamp so rules that require server time pass.
    map['postedAt'] = FieldValue.serverTimestamp();

    await doc.set(map);
    return doc.id;
  }

  Future<void> updateLabour(String id, Labour labour) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final snap = await _collection.doc(id).get();
    if (!snap.exists) throw Exception("Labour not found");

    final owner = snap.data()?['createdBy'] as String?;
    if (owner == user.uid) {
      final updatedData = Map<String, dynamic>.from(labour.toMap());
      updatedData.remove('id');
      updatedData.remove('createdBy');
      final map = _stripNulls(updatedData);
      await _collection.doc(id).update(map);
    } else {
      throw Exception("Not allowed to update this labour");
    }
  }

  Future<void> deleteLabour(String id) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final snap = await _collection.doc(id).get();
    if (!snap.exists) throw Exception("Labour not found");

    final owner = snap.data()?['createdBy'] as String?;
    if (owner == user.uid) {
      await _collection.doc(id).delete();
    } else {
      throw Exception("Not allowed to delete this labour");
    }
  }

  /// Defensive getAll (keeps existing behavior)
  Future<List<Labour>> getAllLabours() async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot =
            await _collection.orderBy('postedAt', descending: true).get();
      } catch (_) {
        snapshot = await _collection.get();
      }

      final List<Labour> result = [];
      for (final doc in snapshot.docs) {
        try {
          result.add(Labour.fromMap(doc.data(), doc.id));
        } catch (e) {
          // ignore malformed docs but print in debug
          // ignore: avoid_print
          print('LabourHubService: failed to parse doc ${doc.id}: $e');
        }
      }
      return result;
    } catch (e) {
      throw Exception('Failed to load labours: $e');
    }
  }

  /// Stream for realtime updates (recommended)
  Stream<List<Labour>> streamLabours() {
    return _collection
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snap) {
      final List<Labour> out = [];
      for (final doc in snap.docs) {
        try {
          out.add(Labour.fromMap(doc.data(), doc.id));
        } catch (e) {
          // ignore malformed docs but log
          // ignore: avoid_print
          print('streamLabours parse error ${doc.id}: $e');
        }
      }
      return out;
    });
  }

  Future<List<Labour>> getMyLabours() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    try {
      final snapshot =
          await _collection.where('createdBy', isEqualTo: user.uid).get();

      final List<Labour> result = [];
      for (final doc in snapshot.docs) {
        try {
          result.add(Labour.fromMap(doc.data(), doc.id));
        } catch (e) {
          // ignore malformed docs
          // ignore: avoid_print
          print('LabourHubService: failed to parse my doc ${doc.id}: $e');
        }
      }
      return result;
    } catch (e) {
      throw Exception('Failed to load my labours: $e');
    }
  }

  Map<String, dynamic> _stripNulls(Map<String, dynamic> map) {
    final clean = <String, dynamic>{};
    map.forEach((k, v) {
      if (v != null) clean[k] = v;
    });
    return clean;
  }
}
