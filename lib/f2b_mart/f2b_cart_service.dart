import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../exporter_hub/exporter_model.dart';
import 'f2b_models.dart';

class F2BCartService {
  final _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference _cartCol(String uid) =>
      _db.collection('f2b_cart').doc(uid).collection('items');

  // ─── Cart ─────────────────────────────────────────────────────────────────

  Stream<List<F2BCartItem>> streamCart() {
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
      if (user == null) return const Stream.empty();
      return _cartCol(user.uid)
          .orderBy('addedAt', descending: true)
          .snapshots()
          .map((s) => s.docs
              .map((d) => F2BCartItem.fromMap(
                  d.data() as Map<String, dynamic>, d.id))
              .toList());
    });
  }

  Future<void> addToCart(ExportProduct product, {int qty = 1}) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in');
    if (product.id.isEmpty) throw Exception('Invalid product ID');

    final price = double.tryParse(
            product.pricePerUnit.replaceAll(RegExp(r'[^\d.]'), '')) ??
        0.0;

    final ref = _cartCol(uid).doc(product.id);
    final snap = await ref.get();
    if (snap.exists) {
      final current = (snap.data() as Map<String, dynamic>)['qty'] as int? ?? 0;
      await ref.update({'qty': current + qty});
    } else {
      await ref.set({
        'productId': product.id,
        'productName': product.productName,
        'farmerName': product.farmerName,
        'farmerId': product.farmerId,
        'price': price,
        'priceUnit': product.pricePerUnit,
        'imageUrl': product.primaryImage.isNotEmpty ? product.primaryImage : null,
        'category': product.category,
        'qty': qty,
        'userId': uid,
        'addedAt': Timestamp.now(),
      });
    }
  }

  Future<void> removeFromCart(String productId) async {
    final uid = _uid;
    if (uid == null) return;
    await _cartCol(uid).doc(productId).delete();
  }

  Future<void> updateQty(String productId, int qty) async {
    final uid = _uid;
    if (uid == null) return;
    if (qty <= 0) {
      await removeFromCart(productId);
    } else {
      await _cartCol(uid).doc(productId).update({'qty': qty});
    }
  }

  Future<void> clearCart() async {
    final uid = _uid;
    if (uid == null) return;
    final snap = await _cartCol(uid).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ─── Orders ───────────────────────────────────────────────────────────────

  Future<String> placeTakeAwayOrder({
    required List<F2BCartItem> items,
    required String buyerName,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in');

    final total = items.fold(0.0, (s, i) => s + i.price * i.qty);

    // Collect unique seller UIDs directly from cart items (farmerId IS the UID)
    final sellerUids =
        items.map((i) => i.farmerId).where((id) => id != uid && id.isNotEmpty).toSet();

    final orderRef = _db.collection('f2b_orders').doc();

    await orderRef.set({
      'userId': uid,
      'userName': buyerName,
      'items': items
          .map((c) => {
                'productId': c.productId,
                'productName': c.productName,
                'farmerName': c.farmerName,
                'price': c.price,
                'priceUnit': c.priceUnit,
                'qty': c.qty,
                'imageUrl': c.imageUrl,
                'category': c.category,
              })
          .toList(),
      'itemsTotal': total,
      'orderType': 'takeaway',
      'paymentMethod': 'cash_on_pickup',
      'status': 'placed',
      'sellerUids': sellerUids.toList(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Clear cart immediately — independent of notification success
    await clearCart();

    // Best-effort seller notification
    if (sellerUids.isNotEmpty) {
      try {
        final productNames =
            items.map((i) => '${i.productName} ×${i.qty}').join(', ');
        final batch = _db.batch();
        for (final sellerUid in sellerUids) {
          final notifRef = _db.collection('km_notifications').doc();
          batch.set(notifRef, {
            'userId': sellerUid,
            'title': '🌾 New Takeaway Order!',
            'body': 'Pickup order received: $productNames',
            'type': 'takeaway_order',
            'orderId': orderRef.id,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      } catch (e) {
        debugPrint('F2BCartService: seller notification failed: $e');
      }
    }

    return orderRef.id;
  }

  Stream<List<F2BOrder>> streamSellerOrders() {
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
      if (user == null) return const Stream.empty();
      return _db
          .collection('f2b_orders')
          .where('sellerUids', arrayContains: user.uid)
          .snapshots()
          .map((s) {
        final orders = s.docs
            .map((d) => F2BOrder.fromMap(d.data(), d.id))
            .toList();
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return orders;
      });
    });
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _db.collection('f2b_orders').doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
