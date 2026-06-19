// lib/exporter_hub/warehouse_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'warehouse_model.dart';

class WarehouseService {
  final _db = FirebaseFirestore.instance;
  CollectionReference get _stockRef => _db.collection('warehouse_stock');
  CollectionReference get _txRef => _db.collection('warehouse_transactions');

  // ── Lot number generator ────────────────────────────────────────────────────
  static String generateLotNumber(String crop) {
    final now = DateTime.now();
    final prefix = crop.length >= 3 ? crop.substring(0, 3).toUpperCase() : crop.toUpperCase();
    return '$prefix-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch % 10000}';
  }

  // ── Stock streams ────────────────────────────────────────────────────────────
  Stream<List<WarehouseStock>> streamStock({String? status}) {
    Query q = _stockRef.orderBy('receivedDate', descending: true);
    if (status != null) q = q.where('status', isEqualTo: status);
    return q.snapshots().map((s) => s.docs
        .map((d) => WarehouseStock.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  Stream<Map<String, double>> streamStockSummary() {
    return _stockRef.snapshots().map((snap) {
      double incoming = 0, available = 0, reserved = 0, exported = 0;
      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final qty = (data['quantity'] as num?)?.toDouble() ?? 0.0;
        switch (data['status']?.toString()) {
          case 'incoming': incoming += qty; break;
          case 'available': available += qty; break;
          case 'reserved': reserved += qty; break;
          case 'exported': exported += qty; break;
        }
      }
      return {'incoming': incoming, 'available': available, 'reserved': reserved, 'exported': exported};
    });
  }

  // ── FIFO query: get oldest available batches for a crop ──────────────────────
  Future<List<WarehouseStock>> getFifoBatches(String cropName, double needed) async {
    final snap = await _stockRef
        .where('cropName', isEqualTo: cropName)
        .where('status', isEqualTo: 'available')
        .orderBy('receivedDate')
        .get();
    final all = snap.docs
        .map((d) => WarehouseStock.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList();
    final result = <WarehouseStock>[];
    double remaining = needed;
    for (final s in all) {
      if (remaining <= 0) break;
      result.add(s);
      remaining -= s.quantity;
    }
    return result;
  }

  // ── Transactions ──────────────────────────────────────────────────────────────
  Stream<List<WarehouseTransaction>> streamTransactions({int limit = 50}) {
    return _txRef
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs
            .map((d) => WarehouseTransaction.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  // ── Write operations ──────────────────────────────────────────────────────────
  Future<String> addStock(WarehouseStock stock) async {
    final ref = await _stockRef.add(stock.toMap());
    await _recordTransaction(
      batchId: stock.batchId,
      cropName: stock.cropName,
      quantity: stock.quantity,
      unit: stock.unit,
      type: 'received',
      refId: stock.poId ?? '',
      refType: stock.poId != null ? 'po' : 'manual',
    );
    return ref.id;
  }

  Future<void> updateStockStatus(String stockId, String newStatus) async {
    await _stockRef.doc(stockId).update({'status': newStatus});
  }

  Future<void> adjustQuantity(String stockId, double newQty, String notes) async {
    final snap = await _stockRef.doc(stockId).get();
    if (!snap.exists) return;
    final data = snap.data() as Map<String, dynamic>;
    final oldQty = (data['quantity'] as num?)?.toDouble() ?? 0.0;
    await _stockRef.doc(stockId).update({'quantity': newQty});
    await _recordTransaction(
      batchId: data['batchId']?.toString() ?? '',
      cropName: data['cropName']?.toString() ?? '',
      quantity: newQty - oldQty,
      unit: data['unit']?.toString() ?? 'kg',
      type: 'adjusted',
      refId: stockId,
      refType: 'manual',
      notes: notes,
    );
  }

  Future<void> _recordTransaction({
    required String batchId,
    required String cropName,
    required double quantity,
    required String unit,
    required String type,
    required String refId,
    required String refType,
    String? notes,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    await _txRef.add({
      'batchId': batchId,
      'cropName': cropName,
      'quantity': quantity,
      'unit': unit,
      'transactionType': type,
      'referenceId': refId,
      'referenceType': refType,
      'performedBy': user?.uid ?? '',
      'performedByName': user?.displayName ?? user?.email ?? 'System',
      if (notes != null) 'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
