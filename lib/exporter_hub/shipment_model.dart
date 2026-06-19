// lib/exporter_hub/shipment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Shipment {
  final String id;
  final String shipmentId;       // auto-generated KM-SHIP-YYYYMMDD-seq
  final String containerNumber;
  final String destinationCountry;
  final String buyerName;
  final String buyerEmail;
  final String shippingLine;
  final String portOfLoading;
  final String portOfDischarge;
  final DateTime? etd;            // estimated time of departure
  final DateTime? eta;            // estimated time of arrival
  final String status;            // ready_for_export|packed|container_loaded|customs_cleared|shipped|delivered
  final List<Map<String, dynamic>> products; // [{productName, quantity, unit, grade, value}]
  final double totalWeight;       // kg
  final double totalValue;        // INR
  final String? createdBy;
  final String? notes;
  final DateTime? createdAt;

  const Shipment({
    required this.id,
    required this.shipmentId,
    required this.containerNumber,
    required this.destinationCountry,
    required this.buyerName,
    required this.buyerEmail,
    required this.shippingLine,
    required this.portOfLoading,
    required this.portOfDischarge,
    this.etd,
    this.eta,
    required this.status,
    required this.products,
    required this.totalWeight,
    required this.totalValue,
    this.createdBy,
    this.notes,
    this.createdAt,
  });

  static const List<String> statusFlow = [
    'ready_for_export',
    'packed',
    'container_loaded',
    'customs_cleared',
    'shipped',
    'delivered',
  ];

  factory Shipment.fromMap(String id, Map<String, dynamic> m) {
    DateTime? parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    final rawProducts = m['products'];
    final products = rawProducts is List
        ? rawProducts.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];

    return Shipment(
      id: id,
      shipmentId: m['shipmentId']?.toString() ?? id,
      containerNumber: m['containerNumber']?.toString() ?? '',
      destinationCountry: m['destinationCountry']?.toString() ?? '',
      buyerName: m['buyerName']?.toString() ?? '',
      buyerEmail: m['buyerEmail']?.toString() ?? '',
      shippingLine: m['shippingLine']?.toString() ?? '',
      portOfLoading: m['portOfLoading']?.toString() ?? '',
      portOfDischarge: m['portOfDischarge']?.toString() ?? '',
      etd: parseDate(m['etd']),
      eta: parseDate(m['eta']),
      status: m['status']?.toString() ?? 'ready_for_export',
      products: products,
      totalWeight: (m['totalWeight'] as num?)?.toDouble() ?? 0.0,
      totalValue: (m['totalValue'] as num?)?.toDouble() ?? 0.0,
      createdBy: m['createdBy']?.toString(),
      notes: m['notes']?.toString(),
      createdAt: parseDate(m['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'shipmentId': shipmentId,
    'containerNumber': containerNumber,
    'destinationCountry': destinationCountry,
    'buyerName': buyerName,
    'buyerEmail': buyerEmail,
    'shippingLine': shippingLine,
    'portOfLoading': portOfLoading,
    'portOfDischarge': portOfDischarge,
    if (etd != null) 'etd': Timestamp.fromDate(etd!),
    if (eta != null) 'eta': Timestamp.fromDate(eta!),
    'status': status,
    'products': products,
    'totalWeight': totalWeight,
    'totalValue': totalValue,
    if (createdBy != null) 'createdBy': createdBy,
    if (notes != null) 'notes': notes,
    'createdAt': FieldValue.serverTimestamp(),
  };

  static String generateShipmentId() {
    final now = DateTime.now();
    final seq = now.millisecondsSinceEpoch % 10000;
    return 'KM-SHIP-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$seq';
  }
}
