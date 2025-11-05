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
  final String createdBy; // ✅ who added this vendor
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
    this.imageUrl,
  });

  factory PlantVendor.fromMap(Map<String, dynamic> map, String docId) {
    return PlantVendor(
      id: docId,
      plantName: map['plantName'] ?? '',
      type: map['type'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: (map['quantity'] ?? 0).toInt(),
      vendorName: map['vendorName'] ?? '',
      phone: map['phone'] ?? '',
      location: map['location'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      createdBy: map['createdBy'] ?? '',
      imageUrl: map['imageUrl'],
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
      'timestamp': timestamp,
      'createdBy': createdBy,
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
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}