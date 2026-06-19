// lib/f2b_mart/f2b_wishlist_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../exporter_hub/exporter_model.dart';

class WishlistService {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference _items(String uid) =>
      _db.collection('wishlist').doc(uid).collection('items');

  /// Stream of saved product IDs — emits whenever wishlist changes.
  static Stream<Set<String>> stream(String uid) => _items(uid)
      .snapshots()
      .map((s) => s.docs.map((d) => d.id).toSet());

  /// Add product to wishlist if not already there; remove it if it is.
  static Future<bool> toggle(String uid, String productId) async {
    final ref = _items(uid).doc(productId);
    final doc = await ref.get();
    if (doc.exists) {
      await ref.delete();
      return false; // removed
    } else {
      await ref.set({'savedAt': FieldValue.serverTimestamp()});
      return true; // added
    }
  }

  /// Fetch all saved ExportProducts for a user (batched by 10 for whereIn).
  static Future<List<ExportProduct>> fetchSaved(String uid) async {
    final snap = await _items(uid)
        .orderBy('savedAt', descending: true)
        .get();
    final ids = snap.docs.map((d) => d.id).toList();
    if (ids.isEmpty) return [];

    final products = <ExportProduct>[];
    for (int i = 0; i < ids.length; i += 10) {
      final batch = ids.sublist(i, (i + 10).clamp(0, ids.length));
      final q = await _db
          .collection('export_products')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      for (final doc in q.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        products.add(ExportProduct.fromMap(data));
      }
    }
    return products;
  }
}
