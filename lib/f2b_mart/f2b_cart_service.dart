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

  Future<List<F2BCartItem>> getCart() async {
    final uid = _uid;
    if (uid == null) return [];
    final snap = await _cartCol(uid).get();
    final items = snap.docs
        .map((d) => F2BCartItem.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();
    items.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return items;
  }

  Stream<List<F2BCartItem>> streamCart() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _cartCol(uid)
        .snapshots()
        .map((s) {
          final items = s.docs
              .map((d) => F2BCartItem.fromMap(
                  d.data() as Map<String, dynamic>, d.id))
              .toList();
          items.sort((a, b) => b.addedAt.compareTo(a.addedAt));
          return items;
        });
  }

  Future<void> addToCart(ExportProduct product, {int qty = 1}) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in');
    if (product.id.isEmpty) throw Exception('Invalid product ID');

    final rawPrice =
        product.pricePerUnit.replaceAll(RegExp(r'[^\d.]'), '');
    final price = double.tryParse(rawPrice) ?? 0.0;
    if (price <= 0) {
      throw Exception(
          'Cannot add "${product.productName}" to cart: price is invalid (${product.pricePerUnit}). '
          'Please contact the seller to update their listing.');
    }

    final ref = _cartCol(uid).doc(product.id);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) {
        final current = (snap.data() as Map<String, dynamic>)['qty'] as int? ?? 0;
        tx.update(ref, {'qty': current + qty});
      } else {
        tx.set(ref, {
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
    });
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
    String? buyerPhone,
    String? buyerLocation,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in');

    final total = items.fold(0.0, (s, i) => s + i.price * i.qty);

    // Collect unique seller UIDs directly from cart items (farmerId IS the UID)
    final sellerUids =
        items.map((i) => i.farmerId).where((id) => id != uid && id.isNotEmpty).toSet();

    // Fetch buyer email to embed alongside the phone they provided
    String? buyerEmail;
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final d = userDoc.data() as Map<String, dynamic>;
        buyerEmail = (d['email'] as String? ?? '').trim();
        if (buyerEmail.isEmpty) buyerEmail = null;
      }
    } catch (_) {}

    // Fetch seller contact from their first export_products listing
    String? sellerPhone;
    String? sellerLocation;
    if (sellerUids.isNotEmpty) {
      try {
        final sellerSnap = await _db
            .collection('export_products')
            .where('ownerId', isEqualTo: sellerUids.first)
            .limit(1)
            .get();
        if (sellerSnap.docs.isNotEmpty) {
          final d = sellerSnap.docs.first.data();
          sellerPhone = (d['farmerMobile'] as String? ?? '').trim();
          sellerLocation = (d['location'] as String? ?? '').trim();
          if (sellerPhone.isEmpty) sellerPhone = null;
          if (sellerLocation.isEmpty) sellerLocation = null;
        }
      } catch (_) {}
    }

    final orderRef = _db.collection('f2b_orders').doc();

    await orderRef.set({
      'userId': uid,
      'userName': buyerName,
      if (buyerPhone != null && buyerPhone.isNotEmpty) 'buyerPhone': buyerPhone,
      if (buyerEmail != null) 'buyerEmail': buyerEmail,
      if (buyerLocation != null && buyerLocation.isNotEmpty) 'buyerLocation': buyerLocation,
      if (sellerPhone != null) 'sellerPhone': sellerPhone,
      if (sellerLocation != null) 'sellerLocation': sellerLocation,
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
            'title': 'New Takeaway Order!',
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

  Stream<List<F2BOrder>> streamBuyerOrders() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('f2b_orders')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((s) {
      final orders = s.docs
          .map((d) => F2BOrder.fromMap(d.data(), d.id))
          .toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  Stream<List<F2BOrder>> streamSellerOrders() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('f2b_orders')
        .where('sellerUids', arrayContains: uid)
        .snapshots()
        .map((s) {
      final orders = s.docs
          .map((d) => F2BOrder.fromMap(d.data(), d.id))
          .toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in');

    // Verify the caller is actually a seller on this order before updating.
    final snap = await _db.collection('f2b_orders').doc(orderId).get();
    if (!snap.exists) throw Exception('Order not found');
    final data = snap.data() as Map<String, dynamic>;
    final sellerUids = List<String>.from(data['sellerUids'] as List? ?? []);
    if (!sellerUids.contains(uid)) {
      throw Exception('Not authorised to update this order');
    }

    await _db.collection('f2b_orders').doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
