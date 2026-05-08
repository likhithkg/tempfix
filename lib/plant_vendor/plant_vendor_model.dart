import 'package:cloud_firestore/cloud_firestore.dart';

class PlantVendor {
  final String id;
  final String plantName;
  final String type;
  final double price;
  final int quantity;
  final String vendorName;
  final String phone;
  final String location;
  final String address;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String createdBy; // who added this vendor
  final String ownerId; // owner fallback / compatibility
  final String description; // textual description
  final String? imageUrl;

  PlantVendor({
    required this.id,
    required this.plantName,
    required this.type,
    required this.price,
    required this.quantity,
    required this.vendorName,
    required this.phone,
    required this.location,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.createdBy,
    required this.ownerId,
    required this.description,
    this.imageUrl,
  });

  // Helper to safely parse numeric values (int/double/string)
  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  // Robust timestamp parsing
  static DateTime _parseTimestamp(dynamic raw) {
    if (raw == null) return DateTime.now();
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String) {
      final n = int.tryParse(raw);
      if (n != null) return DateTime.fromMillisecondsSinceEpoch(n);
      final dt = DateTime.tryParse(raw);
      if (dt != null) return dt;
    }
    return DateTime.now();
  }

  factory PlantVendor.fromMap(Map<String, dynamic> map, String docId) {
    // normalize keys and provide safe defaults
    final plantName = (map['plantName'] ?? map['name'] ?? '').toString();
    final type = (map['type'] ?? '').toString();
    final price = _toDouble(map['price'] ?? map['rate'] ?? 0);
    final quantity = _toInt(map['quantity'] ?? map['qty'] ?? 0);
    final vendorName = (map['vendorName'] ?? map['vendor'] ?? '').toString();
    final phone = (map['phone'] ?? '').toString();

    // IMPORTANT: Prefer a GeoPoint 'location' if present (new recommended format).
    // If location is a GeoPoint, extract lat/lng from it and use address/display for location string.
    String locationStr = '';
    String address = (map['address'] ?? '').toString();

    double latitude = 0.0;
    double longitude = 0.0;

    final locRaw = map['location'];
    if (locRaw is GeoPoint) {
      // location stored as GeoPoint — prefer this
      latitude = locRaw.latitude;
      longitude = locRaw.longitude;
      // keep readable location text if provided in address or 'display' field; fallback to empty
      locationStr = address.isNotEmpty ? address : (map['display'] ?? map['locationName'] ?? '').toString();
    } else {
      // not a GeoPoint — fall back to older fields
      locationStr = (map['location'] ?? '').toString();
      latitude = _toDouble(map['latitude'] ?? map['lat'] ?? 0);
      longitude = _toDouble(map['longitude'] ?? map['lng'] ?? 0);
      // if address empty but a display-like field exists, use it
      if (address.isEmpty) {
        address = (map['display'] ?? map['address_display'] ?? '').toString();
      }
    }

    final rawTs = map['timestamp'];
    final timestamp = _parseTimestamp(rawTs);

    // support both createdBy and ownerId fields (compatibility)
    final createdBy = (map['createdBy'] ?? map['creator'] ?? '').toString();
    final ownerId = (map['ownerId'] ?? map['createdBy'] ?? '').toString();

    final description = (map['description'] ?? map['desc'] ?? '').toString();
    final imageUrl = map['imageUrl'] != null ? map['imageUrl'].toString() : null;

    return PlantVendor(
      id: docId,
      plantName: plantName,
      type: type,
      price: price,
      quantity: quantity,
      vendorName: vendorName,
      phone: phone,
      location: locationStr,
      address: address,
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp,
      createdBy: createdBy,
      ownerId: ownerId,
      description: description,
      imageUrl: imageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'plantName': plantName,
      'type': type,
      'price': price,
      'quantity': quantity,
      'vendorName': vendorName,
      'phone': phone,
      'location': location,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      // Add GeoPoint 'location' for map-friendly queries if coords exist
      if (latitude != 0.0 || longitude != 0.0) 'location': GeoPoint(latitude, longitude),
      // note: prefer server timestamp when writing from client; callers may override
      'timestamp': Timestamp.fromDate(timestamp),
      'createdBy': createdBy,
      'ownerId': ownerId,
      'description': description,
      'imageUrl': imageUrl,
    };
  }

  PlantVendor copyWith({
    String? id,
    String? plantName,
    String? type,
    double? price,
    int? quantity,
    String? vendorName,
    String? phone,
    String? location,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    String? createdBy,
    String? ownerId,
    String? description,
    String? imageUrl,
  }) {
    return PlantVendor(
      id: id ?? this.id,
      plantName: plantName ?? this.plantName,
      type: type ?? this.type,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      vendorName: vendorName ?? this.vendorName,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      createdBy: createdBy ?? this.createdBy,
      ownerId: ownerId ?? this.ownerId,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
