import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'green_bazaar_models.dart';

class GreenBazaarService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ─── Cart ────────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _cartCol(String uid) =>
      _db.collection('gb_cart').doc(uid).collection('items');

  Stream<List<CartItem>> streamCart() {
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
      if (user == null) return const Stream.empty();
      return _db
          .collection('gb_cart')
          .doc(user.uid)
          .collection('items')
          .orderBy('addedAt', descending: true)
          .snapshots()
          .map((s) => s.docs
              .map((d) => CartItem.fromMap(d.data(), d.id))
              .toList());
    });
  }

  Future<void> addToCart(CartItem item) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in');
    if (item.vendorId.isEmpty) throw Exception('Invalid plant ID');
    final col = _cartCol(uid);
    final ref = col.doc(item.vendorId);
    final existing = await ref.get();
    if (existing.exists) {
      final current = CartItem.fromMap(existing.data()!, existing.id);
      await ref.update({'orderQty': current.orderQty + 1});
    } else {
      await ref.set(item.copyWith(orderQty: 1).toMap());
    }
  }

  Future<void> updateCartQty(String vendorId, int qty) async {
    final uid = _uid;
    if (uid == null) return;
    final col = _cartCol(uid);
    if (qty <= 0) {
      await col.doc(vendorId).delete();
    } else {
      await col.doc(vendorId).update({'orderQty': qty});
    }
  }

  Future<void> removeFromCart(String vendorId) async {
    final uid = _uid;
    if (uid == null) return;
    await _cartCol(uid).doc(vendorId).delete();
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

  Future<bool> isInCart(String vendorId) async {
    final uid = _uid;
    if (uid == null) return false;
    final doc = await _cartCol(uid).doc(vendorId).get();
    return doc.exists;
  }

  // ─── Wishlist ─────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _wishCol(String uid) =>
      _db.collection('gb_wishlist').doc(uid).collection('items');

  Stream<List<WishlistItem>> streamWishlist() {
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
      if (user == null) return const Stream.empty();
      return _db
          .collection('gb_wishlist')
          .doc(user.uid)
          .collection('items')
          .orderBy('savedAt', descending: true)
          .snapshots()
          .map((s) => s.docs
              .map((d) => WishlistItem.fromMap(d.data(), d.id))
              .toList());
    });
  }

  Future<bool> isWishlisted(String vendorId) async {
    final uid = _uid;
    if (uid == null) return false;
    final doc = await _wishCol(uid).doc(vendorId).get();
    return doc.exists;
  }

  Future<void> toggleWishlist(WishlistItem item) async {
    final uid = _uid;
    if (uid == null) return;
    final ref = _wishCol(uid).doc(item.vendorId);
    final doc = await ref.get();
    if (doc.exists) {
      await ref.delete();
    } else {
      await ref.set(item.toMap());
    }
  }

  Future<void> removeFromWishlist(String vendorId) async {
    final uid = _uid;
    if (uid == null) return;
    await _wishCol(uid).doc(vendorId).delete();
  }

  Future<void> moveWishlistToCart(WishlistItem wi) async {
    final uid = _uid;
    if (uid == null) return;
    final cartItem = CartItem(
      id: wi.vendorId,
      vendorId: wi.vendorId,
      plantName: wi.plantName,
      vendorName: wi.vendorName,
      price: wi.price,
      imageUrl: wi.imageUrl,
      type: wi.type,
      orderQty: 1,
      userId: uid,
      addedAt: DateTime.now(),
    );
    await addToCart(cartItem);
    await removeFromWishlist(wi.vendorId);
  }

  // ─── Orders ───────────────────────────────────────────────────────────────

  Stream<List<PlantOrder>> streamMyOrders() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('gb_orders')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => PlantOrder.fromMap(d.data(), d.id))
            .toList());
  }

  Future<PlantOrder?> getOrder(String orderId) async {
    final doc = await _db.collection('gb_orders').doc(orderId).get();
    if (!doc.exists) return null;
    return PlantOrder.fromMap(doc.data()!, doc.id);
  }

  Future<String> placeOrder(PlantOrder order) async {
    final ref = _db.collection('gb_orders').doc();
    final data = {
      ...order.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await ref.set(data);
    await clearCart();
    return ref.id;
  }

  Future<String> placeTakeAwayOrder({
    required List<CartItem> items,
    required String buyerName,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in');

    final total =
        items.fold(0.0, (s, i) => s + i.price * i.orderQty);

    // Create order document
    final orderRef = _db.collection('gb_orders').doc();
    // Look up each unique seller first
    final sellerUids = <String>{};
    for (final item in items) {
      try {
        final plantDoc =
            await _db.collection('plant_vendors').doc(item.vendorId).get();
        if (plantDoc.exists) {
          final d = plantDoc.data()!;
          final sellerUid =
              (d['createdBy'] as String? ?? '').isNotEmpty
                  ? d['createdBy'] as String
                  : d['ownerId'] as String? ?? '';
          if (sellerUid.isNotEmpty && sellerUid != uid) {
            sellerUids.add(sellerUid);
          }
        }
      } catch (_) {}
    }

    await orderRef.set({
      'userId': uid,
      'userName': buyerName,
      'items': items
          .map((c) => {
                'vendorId': c.vendorId,
                'plantName': c.plantName,
                'vendorName': c.vendorName,
                'price': c.price,
                'quantity': c.orderQty,
                'imageUrl': c.imageUrl,
                'type': c.type,
              })
          .toList(),
      'itemsTotal': total,
      'deliveryCharge': 0,
      'orderType': 'takeaway',
      'paymentMethod': 'cash_on_pickup',
      'status': 'placed',
      'sellerUids': sellerUids.toList(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Order is now created — clear cart regardless of what happens next.
    await clearCart();

    // Best-effort: notify each seller. Failures are logged but do not
    // surface to the user since the order is already placed.
    if (sellerUids.isNotEmpty) {
      try {
        final plantNames =
            items.map((i) => '${i.plantName} ×${i.orderQty}').join(', ');
        final batch = _db.batch();
        for (final sellerUid in sellerUids) {
          final notifRef = _db.collection('km_notifications').doc();
          batch.set(notifRef, {
            'userId': sellerUid,
            'title': '🌿 New Takeaway Order!',
            'body': 'Pickup order received: $plantNames',
            'type': 'takeaway_order',
            'orderId': orderRef.id,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      } catch (e) {
        // Non-fatal: order and cart are already handled.
        debugPrint('GreenBazaarService: seller notification failed: $e');
      }
    }

    return orderRef.id;
  }

  // ─── Seller order management ──────────────────────────────────────────────

  Stream<List<PlantOrder>> streamSellerOrders() {
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
      if (user == null) return const Stream.empty();
      return _db
          .collection('gb_orders')
          .where('sellerUids', arrayContains: user.uid)
          .snapshots()
          .map((s) {
        final orders = s.docs
            .map((d) => PlantOrder.fromMap(d.data(), d.id))
            .toList();
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return orders;
      });
    });
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _db.collection('gb_orders').doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
