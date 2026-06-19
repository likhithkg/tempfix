// lib/f2b_mart/f2b_rating_service.dart
// Phase 8 — Trust System: per-farmer review subcollection

import 'package:cloud_firestore/cloud_firestore.dart';

class RatingService {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference _reviews(String farmerId) =>
      _db.collection('farmer_reviews').doc(farmerId).collection('reviews');

  static Stream<List<Map<String, dynamic>>> streamReviews(String farmerId) =>
      _reviews(farmerId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots()
          .map((s) => s.docs.map((d) {
                final m = Map<String, dynamic>.from(d.data() as Map);
                m['id'] = d.id;
                return m;
              }).toList());

  static Future<({double avg, int count})> getStats(String farmerId) async {
    final snap = await _reviews(farmerId).get();
    if (snap.docs.isEmpty) return (avg: 0.0, count: 0);
    double total = 0;
    for (final d in snap.docs) {
      final data = d.data() as Map;
      total += (data['rating'] as num? ?? 0).toDouble();
    }
    return (avg: total / snap.docs.length, count: snap.docs.length);
  }

  static Future<bool> hasReviewed(String farmerId, String buyerId) async {
    final snap = await _reviews(farmerId)
        .where('buyerId', isEqualTo: buyerId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  static Future<void> submitReview({
    required String farmerId,
    required String buyerId,
    required String buyerName,
    required double rating,
    required String comment,
    String productId = '',
    String productName = '',
  }) =>
      _reviews(farmerId).add({
        'buyerId': buyerId,
        'buyerName': buyerName,
        'rating': rating,
        'comment': comment,
        'productId': productId,
        'productName': productName,
        'createdAt': FieldValue.serverTimestamp(),
      });
}
