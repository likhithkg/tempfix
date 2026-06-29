import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'green_bazaar_models.dart';

class GreenBazaarService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ─── Cart ────────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _cartCol() =>
      _db.collection('gb_cart').doc(_uid).collection('items');

  Stream<List<CartItem>> streamCart() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _cartCol()
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => CartItem.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> addToCart(CartItem item) async {
    final uid = _uid;
    if (uid == null) return;
    // Use vendorId as doc key so same plant = same doc
    final ref = _cartCol().doc(item.vendorId);
    final existing = await ref.get();
    if (existing.exists) {
      final current = CartItem.fromMap(existing.data()!, existing.id);
      await ref.update({'orderQty': current.orderQty + 1});
    } else {
      await ref.set(item.copyWith(orderQty: 1).toMap());
    }
  }

  Future<void> updateCartQty(String vendorId, int qty) async {
    if (_uid == null) return;
    if (qty <= 0) {
      await _cartCol().doc(vendorId).delete();
    } else {
      await _cartCol().doc(vendorId).update({'orderQty': qty});
    }
  }

  Future<void> removeFromCart(String vendorId) async {
    if (_uid == null) return;
    await _cartCol().doc(vendorId).delete();
  }

  Future<void> clearCart() async {
    if (_uid == null) return;
    final snap = await _cartCol().get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<bool> isInCart(String vendorId) async {
    if (_uid == null) return false;
    final doc = await _cartCol().doc(vendorId).get();
    return doc.exists;
  }

  // ─── Wishlist ─────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _wishCol() =>
      _db.collection('gb_wishlist').doc(_uid).collection('items');

  Stream<List<WishlistItem>> streamWishlist() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _wishCol()
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => WishlistItem.fromMap(d.data(), d.id))
            .toList());
  }

  Future<bool> isWishlisted(String vendorId) async {
    if (_uid == null) return false;
    final doc = await _wishCol().doc(vendorId).get();
    return doc.exists;
  }

  Future<void> toggleWishlist(WishlistItem item) async {
    if (_uid == null) return;
    final ref = _wishCol().doc(item.vendorId);
    final doc = await ref.get();
    if (doc.exists) {
      await ref.delete();
    } else {
      await ref.set(item.toMap());
    }
  }

  Future<void> removeFromWishlist(String vendorId) async {
    if (_uid == null) return;
    await _wishCol().doc(vendorId).delete();
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
}
