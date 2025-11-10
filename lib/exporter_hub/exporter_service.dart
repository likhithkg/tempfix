// lib/exporter_hub/exporter_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'exporter_model.dart';
import 'package:flutter/foundation.dart';

class ExporterService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _productsRef => _db.collection('export_products');
  CollectionReference get farmersRef => _db.collection('farmers');
  CollectionReference get listingsRef => _db.collection('farmer_listings');
  CollectionReference get poRef => _db.collection('purchase_orders');
  CollectionReference get qcRef => _db.collection('qc_reports');

  // --------------------------------------------------------------------------
  // Export Products
  // --------------------------------------------------------------------------

  /// Stream all export products (public)
  Stream<List<ExportProduct>> getExportProducts() {
    return _productsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return ExportProduct.fromMap(data);
            }).toList());
  }

  /// Stream only products owned by a specific user
  Stream<List<ExportProduct>> getMyExportProducts(String uid) {
    return _productsRef
        .where('ownerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return ExportProduct.fromMap(data);
            }).toList());
  }

  /// Add a new export product. This method attaches ownership fields from the current user.
  Future<DocumentReference> addExportProduct(ExportProduct product) async {
    final user = FirebaseAuth.instance.currentUser;

    final payload = product.toMap();
    payload['createdAt'] = FieldValue.serverTimestamp();

    // Attach owner info if available
    if (user != null) {
      payload['ownerId'] = user.uid;
      payload['ownerEmail'] = user.email;
      payload['ownerName'] = user.displayName;
      payload['ownerPhone'] = user.phoneNumber;
    }

    final docRef = await _productsRef.add(payload);
    return docRef;
  }

  /// Update an existing export product. Only owners will be allowed by Firestore rules.
  Future<void> updateExportProduct(String id, Map<String, dynamic> payload) async {
    // Add server-side updatedAt for bookkeeping
    payload['updatedAt'] = FieldValue.serverTimestamp();
    await _productsRef.doc(id).update(payload);
  }

  /// Delete a product by id
  Future<void> deleteExportProduct(String id) async {
    await _productsRef.doc(id).delete();
  }

  // --------------------------------------------------------------------------
  // Purchase Orders
  // --------------------------------------------------------------------------

  /// Create PO (generic). Accept optional farmerName/farmerPhone so callers
  /// can provide seller contact info when available.
  Future<DocumentReference> createPO({
    required String buyerId,
    required String buyerName,
    required String buyerContact,
    required String farmerId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    String? listingId,
    String? farmerName,      // optional seller name to save inside PO
    String? farmerPhone,     // optional seller phone to save inside PO
    Map<String, dynamic>? paymentTerms,
  }) {
    final now = Timestamp.now();
    final data = {
      if (listingId != null) 'listingId': listingId,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerContact': buyerContact,
      'farmerId': farmerId,
      if (farmerName != null) 'farmerName': farmerName,
      if (farmerPhone != null) 'farmerPhone': farmerPhone,
      'items': items,
      'totalAmount': totalAmount,
      'paymentTerms': paymentTerms ?? {'advancePercent': 0},
      'status': 'issued',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'history': FieldValue.arrayUnion([
        {'status': 'issued', 'by': buyerId, 'note': 'PO created', 'ts': now}
      ]),
    };
    return poRef.add(data);
  }

  /// Convenience: create a PO given a listingId (resolves the listing owner automatically)
  Future<DocumentReference> createPOForListing({
  required String listingId,
  required String buyerId,
  required String buyerName,
  required String buyerContact,
  required List<Map<String, dynamic>> items,
  required double totalAmount,
  Map<String, dynamic>? paymentTerms,
}) async {
  // Resolve owner id from known collections/fields
  final ownerId = await _resolveOwnerForListing(listingId);
  if (ownerId == null || ownerId.isEmpty) {
    throw Exception('Could not determine listing owner for id: $listingId');
  }

  String? sellerName;
  String? sellerPhone;

  // 1) Try export_products document (common case)
  try {
    final pSnap = await _productsRef.doc(listingId).get();
    if (pSnap.exists) {
      final pdata = pSnap.data() as Map<String, dynamic>? ?? {};
      sellerName ??= (pdata['ownerName'] ?? pdata['farmerName'] ?? pdata['sellerName'] ?? pdata['name'])?.toString();
      sellerPhone ??= (pdata['ownerPhone'] ?? pdata['farmerMobile'] ?? pdata['sellerPhone'] ?? pdata['phone'])?.toString();
    }
  } catch (e) {
    debugPrint('createPOForListing: export_products read failed: $e');
  }

  // 2) If still missing contact, try farmer_listings doc (some apps keep owner info there)
  if (sellerPhone == null || sellerPhone.isEmpty || sellerName == null || sellerName.isEmpty) {
    try {
      final lSnap = await listingsRef.doc(listingId).get();
      if (lSnap.exists) {
        final ldata = lSnap.data() as Map<String, dynamic>? ?? {};
        sellerName ??= (ldata['ownerName'] ?? ldata['farmerName'] ?? ldata['sellerName'] ?? ldata['name'])?.toString();
        sellerPhone ??= (ldata['ownerPhone'] ?? ldata['farmerMobile'] ?? ldata['sellerPhone'] ?? ldata['phone'])?.toString();
      }
    } catch (e) {
      debugPrint('createPOForListing: farmer_listings read failed: $e');
    }
  }

  // 3) Final fallback: read users/{ownerId}
  if (sellerPhone == null || sellerPhone.isEmpty || sellerName == null || sellerName.isEmpty) {
    try {
      final uSnap = await _db.collection('users').doc(ownerId).get();
      if (uSnap.exists) {
        final udata = uSnap.data() as Map<String, dynamic>;
        sellerName ??= (udata['displayName'] ?? udata['name'])?.toString();
        sellerPhone ??= (udata['phone'] ?? udata['phoneNumber'] ?? udata['contact'])?.toString();
      }
    } catch (e) {
      debugPrint('createPOForListing: users read failed: $e');
    }
  }

  // create PO with resolved farmerId and any contact info found
  return createPO(
    buyerId: buyerId,
    buyerName: buyerName,
    buyerContact: buyerContact,
    farmerId: ownerId,
    listingId: listingId,
    farmerName: (sellerName != null && sellerName.isNotEmpty) ? sellerName : null,
    farmerPhone: (sellerPhone != null && sellerPhone.isNotEmpty) ? sellerPhone : null,
    items: items,
    totalAmount: totalAmount,
    paymentTerms: paymentTerms,
  );
}

  /// Try to resolve the owner/farmer id from common places:
  /// - farmer_listings/{listingId}
  /// - export_products/{listingId}
  /// checks fields: ownerId, farmerId, sellerId, createdBy, userId
  Future<String?> _resolveOwnerForListing(String listingId) async {
    // 1) Check farmer_listings
    try {
      final lSnap = await listingsRef.doc(listingId).get();
      if (lSnap.exists) {
        final data = lSnap.data() as Map<String, dynamic>? ?? {};
        final owner = _extractOwnerFromMap(data);
        if (owner != null && owner.isNotEmpty) return owner;
      }
    } catch (e) {
      debugPrint('resolveOwner: farmer_listings read error: $e');
    }

    // 2) Check export_products
    try {
      final pSnap = await _productsRef.doc(listingId).get();
      if (pSnap.exists) {
        final pdata = pSnap.data() as Map<String, dynamic>? ?? {};
        final owner = _extractOwnerFromMap(pdata);
        if (owner != null && owner.isNotEmpty) return owner;
      }
    } catch (e) {
      debugPrint('resolveOwner: export_products read error: $e');
    }

    // 3) As a last resort, check a farmer document with same id (unlikely, but included)
    try {
      final fSnap = await farmersRef.doc(listingId).get();
      if (fSnap.exists) {
        // maybe farmer doc has ownerId/uid
        final fdata = fSnap.data() as Map<String, dynamic>? ?? {};
        final owner = _extractOwnerFromMap(fdata);
        if (owner != null && owner.isNotEmpty) return owner;
      }
    } catch (e) {
      debugPrint('resolveOwner: farmers read error: $e');
    }

    return null;
  }

  String? _extractOwnerFromMap(Map<String, dynamic> m) {
    final candidates = [
      m['ownerId'],
      m['farmerId'],
      m['sellerId'],
      m['createdBy'],
      m['userId'],
    ];
    for (final c in candidates) {
      if (c is String && c.isNotEmpty) return c;
    }
    return null;
  }

  /// One-time helper: patch existing POs that are missing farmerId or have empty farmerId.
  /// Use cautiously (run once from a debug screen / admin flow).
  Future<void> patchMissingFarmerIds({bool onlyMissing = true}) async {
    final snap = await poRef.get();
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final currentFarmer = (data['farmerId'] ?? '').toString();
      if (onlyMissing && currentFarmer.isNotEmpty) continue;

      final listingId = data['listingId'] as String?;
      if (listingId == null || listingId.isEmpty) {
        debugPrint('patchMissingFarmerIds: skipping ${doc.id} (no listingId)');
        continue;
      }

      final owner = await _resolveOwnerForListing(listingId);
      if (owner != null && owner.isNotEmpty) {
        await doc.reference.update({'farmerId': owner});
        debugPrint('patched PO ${doc.id} -> farmerId=$owner');
      } else {
        debugPrint('could not resolve owner for PO ${doc.id} listing=$listingId');
      }
    }
  }

  /// One-time helper: fill missing farmerName/farmerPhone for existing POs
  /// Run this from a debug/admin screen once (then remove or comment out).
  Future<void> patchMissingFarmerContacts({bool onlyMissing = true}) async {
    final snap = await poRef.get();
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final currentFarmer = (data['farmerId'] ?? '').toString();
      if (currentFarmer.isEmpty) {
        debugPrint('patchMissingFarmerContacts: skipping ${doc.id} (no farmerId)');
        continue;
      }

      final hasName = (data['farmerName'] ?? '').toString().isNotEmpty;
      final hasPhone = (data['farmerPhone'] ?? '').toString().isNotEmpty;
      if (onlyMissing && hasName && hasPhone) continue;

      String? sellerName;
      String? sellerPhone;

      // try to use listingId on PO first
      final listingId = data['listingId'] as String?;
      if (listingId != null && listingId.isNotEmpty) {
        final prod = await _productsRef.doc(listingId).get();
        if (prod.exists) {
          final pd = prod.data() as Map<String, dynamic>;
          sellerName = pd['ownerName'] ?? pd['farmerName'] ?? pd['productOwner'] ?? pd['sellerName']?.toString();
          sellerPhone = pd['ownerPhone'] ?? pd['farmerMobile'] ?? pd['ownerPhoneNumber'] ?? pd['sellerPhone']?.toString();
        }
      }

      // fallback: read users collection by farmerId
      if ((sellerName == null || sellerPhone == null) && currentFarmer.isNotEmpty) {
        try {
          final uSnap = await _db.collection('users').doc(currentFarmer).get();
          if (uSnap.exists) {
            final ud = uSnap.data() as Map<String, dynamic>;
            sellerName ??= ud['displayName'] ?? ud['name'];
            sellerPhone ??= ud['phone'] ?? ud['phoneNumber'] ?? ud['contact'];
          }
        } catch (e) {
          debugPrint('patchMissingFarmerContacts: users lookup failed for $currentFarmer: $e');
        }
      }

      final update = <String, dynamic>{};
      if (sellerName != null && sellerName.isNotEmpty && !hasName) update['farmerName'] = sellerName;
      if (sellerPhone != null && sellerPhone.isNotEmpty && !hasPhone) update['farmerPhone'] = sellerPhone;
      if (update.isNotEmpty) {
        await doc.reference.update(update);
        debugPrint('patched PO ${doc.id} with $update');
      } else {
        debugPrint('no contact data found for PO ${doc.id}');
      }
    }
  }

  /// Stream POs for a specific importer
  Stream<List<Map<String, dynamic>>> streamPOsForImporter(String importerId) {
    return poRef
        .where('importerId', isEqualTo: importerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final m = d.data() as Map<String, dynamic>;
              m['id'] = d.id;
              return m;
            }).toList());
  }

  /// Stream POs where the user is buyer
  Stream<List<Map<String, dynamic>>> streamPOsForBuyer(String buyerId) {
    return poRef
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final m = d.data() as Map<String, dynamic>;
              m['id'] = d.id;
              return m;
            }).toList());
  }

  /// Stream POs where the user is farmer (seller)
  Stream<List<Map<String, dynamic>>> streamPOsForFarmer(String farmerId) {
    return poRef
        .where('farmerId', isEqualTo: farmerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final m = d.data() as Map<String, dynamic>;
              m['id'] = d.id;
              return m;
            }).toList());
  }

  /// Stream a single PO by id
  Stream<Map<String, dynamic>?> streamPOById(String poId) {
    return poRef.doc(poId).snapshots().map((snap) {
      if (!snap.exists) return null;
      final m = snap.data() as Map<String, dynamic>;
      m['id'] = snap.id;
      return m;
    });
  }

  /// Update PO status and append to history
  Future<void> updatePOStatus(String poId, String newStatus, String byUserId, {String? note}) async {
    final docRef = poRef.doc(poId);
    final now = Timestamp.now();

    final updateData = {
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
      'history': FieldValue.arrayUnion([
        {'status': newStatus, 'by': byUserId, 'note': note ?? '', 'ts': now}
      ]),
    };

    await docRef.update(updateData);
  }

  /// Add a counter offer to PO
  Future<void> addCounterOffer(String poId, Map<String, dynamic> counterOffer) async {
    final payload = {...counterOffer, 'createdAt': Timestamp.now()};
    await poRef.doc(poId).update({'counterOffers': FieldValue.arrayUnion([payload])});
  }

  // --------------------------------------------------------------------------
  // QC Reports
  // --------------------------------------------------------------------------

  Future<DocumentReference> createQCReport(Map<String, dynamic> data) {
    final payload = {...data, 'createdAt': FieldValue.serverTimestamp()};
    return qcRef.add(payload);
  }
}
