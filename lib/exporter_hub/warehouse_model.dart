// lib/exporter_hub/warehouse_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class WarehouseStock {
  final String id;
  final String batchId;
  final String cropName;
  final String category;
  final double quantity;      // in kg
  final String unit;
  final String warehouseLocation;
  final String lotNumber;
  final DateTime receivedDate;
  final DateTime? expiryDate;
  final String status;        // incoming | available | reserved | exported | rejected
  final String? poId;
  final String? farmerId;
  final String? farmerName;
  final String? grade;
  final bool isOrganic;
  final double? moistureLevel;
  final String? notes;
  final DateTime? createdAt;

  const WarehouseStock({
    required this.id,
    required this.batchId,
    required this.cropName,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.warehouseLocation,
    required this.lotNumber,
    required this.receivedDate,
    this.expiryDate,
    required this.status,
    this.poId,
    this.farmerId,
    this.farmerName,
    this.grade,
    this.isOrganic = false,
    this.moistureLevel,
    this.notes,
    this.createdAt,
  });

  factory WarehouseStock.fromMap(String id, Map<String, dynamic> m) {
    DateTime parseDate(dynamic v, DateTime fallback) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? fallback;
      return fallback;
    }

    return WarehouseStock(
      id: id,
      batchId: m['batchId']?.toString() ?? '',
      cropName: m['cropName']?.toString() ?? '',
      category: m['category']?.toString() ?? 'Other',
      quantity: (m['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: m['unit']?.toString() ?? 'kg',
      warehouseLocation: m['warehouseLocation']?.toString() ?? '',
      lotNumber: m['lotNumber']?.toString() ?? '',
      receivedDate: parseDate(m['receivedDate'], DateTime.now()),
      expiryDate: m['expiryDate'] != null ? parseDate(m['expiryDate'], DateTime.now()) : null,
      status: m['status']?.toString() ?? 'available',
      poId: m['poId']?.toString(),
      farmerId: m['farmerId']?.toString(),
      farmerName: m['farmerName']?.toString(),
      grade: m['grade']?.toString(),
      isOrganic: m['isOrganic'] == true,
      moistureLevel: (m['moistureLevel'] as num?)?.toDouble(),
      notes: m['notes']?.toString(),
      createdAt: m['createdAt'] != null ? parseDate(m['createdAt'], DateTime.now()) : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'batchId': batchId,
    'cropName': cropName,
    'category': category,
    'quantity': quantity,
    'unit': unit,
    'warehouseLocation': warehouseLocation,
    'lotNumber': lotNumber,
    'receivedDate': Timestamp.fromDate(receivedDate),
    if (expiryDate != null) 'expiryDate': Timestamp.fromDate(expiryDate!),
    'status': status,
    if (poId != null) 'poId': poId,
    if (farmerId != null) 'farmerId': farmerId,
    if (farmerName != null) 'farmerName': farmerName,
    if (grade != null) 'grade': grade,
    'isOrganic': isOrganic,
    if (moistureLevel != null) 'moistureLevel': moistureLevel,
    if (notes != null) 'notes': notes,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

class WarehouseTransaction {
  final String id;
  final String batchId;
  final String cropName;
  final double quantity;
  final String unit;
  final String transactionType; // received | dispatched | reserved | adjusted | rejected
  final String referenceId;     // poId or shipmentId
  final String referenceType;   // 'po' | 'shipment' | 'manual'
  final String performedBy;
  final String performedByName;
  final String? notes;
  final DateTime createdAt;

  const WarehouseTransaction({
    required this.id,
    required this.batchId,
    required this.cropName,
    required this.quantity,
    required this.unit,
    required this.transactionType,
    required this.referenceId,
    required this.referenceType,
    required this.performedBy,
    required this.performedByName,
    this.notes,
    required this.createdAt,
  });

  factory WarehouseTransaction.fromMap(String id, Map<String, dynamic> m) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }
    return WarehouseTransaction(
      id: id,
      batchId: m['batchId']?.toString() ?? '',
      cropName: m['cropName']?.toString() ?? '',
      quantity: (m['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: m['unit']?.toString() ?? 'kg',
      transactionType: m['transactionType']?.toString() ?? 'received',
      referenceId: m['referenceId']?.toString() ?? '',
      referenceType: m['referenceType']?.toString() ?? 'manual',
      performedBy: m['performedBy']?.toString() ?? '',
      performedByName: m['performedByName']?.toString() ?? '',
      notes: m['notes']?.toString(),
      createdAt: parseDate(m['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'batchId': batchId,
    'cropName': cropName,
    'quantity': quantity,
    'unit': unit,
    'transactionType': transactionType,
    'referenceId': referenceId,
    'referenceType': referenceType,
    'performedBy': performedBy,
    'performedByName': performedByName,
    if (notes != null) 'notes': notes,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
