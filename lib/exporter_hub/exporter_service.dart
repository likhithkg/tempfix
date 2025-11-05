import 'package:cloud_firestore/cloud_firestore.dart';
import 'exporter_model.dart';

class ExporterService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _productsRef => _db.collection('export_products');
  CollectionReference get farmersRef => _db.collection('farmers');
  CollectionReference get listingsRef => _db.collection('farmer_listings');
  CollectionReference get poRef => _db.collection('purchase_orders');
  CollectionReference get qcRef => _db.collection('qc_reports');

  // --- Products stream (used by exporter_home_page.dart) ---
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

  Future<void> addExportProduct(ExportProduct product) async {
    final Map<String, dynamic> payload = product.toMap();
    // store createdAt as server Timestamp for accurate ordering (top-level only)
    payload['createdAt'] = FieldValue.serverTimestamp();
    await _productsRef.doc(product.id).set(payload);
  }

  Future<void> deleteExportProduct(String id) => _productsRef.doc(id).delete();

  // --- Purchase Orders ---

  /// Create a Purchase Order with buyer details.
  /// buyerName and buyerContact are stored for quick access without extra lookups.
  Future<DocumentReference> createPO({
    required String buyerId,
    required String buyerName,
    required String buyerContact,
    required String farmerId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    Map<String, dynamic>? paymentTerms,
  }) {
    final now = Timestamp.now();

    final data = {
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerContact': buyerContact,
      'farmerId': farmerId,
      'items': items, // items should contain client-side timestamps if you need per-item ts
      'totalAmount': totalAmount,
      'paymentTerms': paymentTerms ?? {'advancePercent': 0},
      'status': 'issued',
      // top-level server timestamps are allowed
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      // history entries must not include FieldValue.serverTimestamp() inside arrays.
      // Use client-side Timestamp.now() for array items
      'history': FieldValue.arrayUnion([
        {
          'status': 'issued',
          'by': buyerId,
          'note': 'PO created',
          'ts': now,
        }
      ]),
    };
    return poRef.add(data);
  }

  // Stream POs for a specific importer or buyer
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

  // Stream POs where the user is buyer
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

  // Stream a single PO by id
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

    // Use client-side timestamp for array entry
    final now = Timestamp.now();

    final updateData = {
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(), // top-level server ts ok
      'history': FieldValue.arrayUnion([
        {
          'status': newStatus,
          'by': byUserId,
          'note': note ?? '',
          'ts': now,
        }
      ])
    };
    await docRef.update(updateData);
  }

  /// Add a counter offer to PO
  Future<void> addCounterOffer(String poId, Map<String, dynamic> counterOffer) async {
    // include a client-side timestamp for the counter offer entry
    final payload = {...counterOffer, 'createdAt': Timestamp.now()};
    await poRef.doc(poId).update({'counterOffers': FieldValue.arrayUnion([payload])});
  }

  // --- QC reports ---
  Future<DocumentReference> createQCReport(Map<String, dynamic> data) {
    final payload = {...data, 'createdAt': FieldValue.serverTimestamp()};
    return qcRef.add(payload);
  }
}
