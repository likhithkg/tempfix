// lib/rent/rent_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class RentMachine {
  final String id;
  final String name;
  final String type;
  final double pricePerDay;
  final String ownerName;
  final String ownerId; // firebase uid of the poster
  final String phone;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final DateTime createdAt;
  final String? location; // NEW: human readable location/address

  const RentMachine({
    required this.id,
    required this.name,
    required this.type,
    required this.pricePerDay,
    required this.ownerName,
    required this.ownerId,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.createdAt,
    this.location,
  });

  RentMachine copyWith({
    String? id,
    String? name,
    String? type,
    double? pricePerDay,
    String? ownerName,
    String? ownerId,
    String? phone,
    double? latitude,
    double? longitude,
    String? imageUrl,
    DateTime? createdAt,
    String? location,
  }) {
    return RentMachine(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      ownerName: ownerName ?? this.ownerName,
      ownerId: ownerId ?? this.ownerId,
      phone: phone ?? this.phone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      location: location ?? this.location,
    );
  }

  Map<String, dynamic> toMap() => {
        // Keep original keys your app expects
        'name': name,
        'type': type,
        'pricePerDay': pricePerDay,
        'ownerName': ownerName,
        'ownerId': ownerId,
        'phone': phone,
        'latitude': latitude,
        'longitude': longitude,
        'imageUrl': imageUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'location': location,
        // ALSO write the keys your Firestore rules require (title & ratePerDay)
        'title': name,
        'ratePerDay': pricePerDay,
      };

  factory RentMachine.fromDoc(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};

    // name may be stored as 'name' or older/newer 'title'
    final nameValue = (d['name'] ?? d['title'] ?? '') as String;

    // pricePerDay may be stored as 'pricePerDay' or 'ratePerDay'
    double parsePrice(dynamic p) {
      if (p == null) return 0;
      if (p is num) return p.toDouble();
      if (p is String) return double.tryParse(p) ?? 0;
      return 0;
    }

    final price = parsePrice(d['pricePerDay'] ?? d['ratePerDay']);

    return RentMachine(
      id: doc.id,
      name: nameValue,
      type: (d['type'] ?? 'Other') as String,
      pricePerDay: price,
      ownerName: (d['ownerName'] ?? '') as String,
      ownerId: (d['ownerId'] ?? '') as String,
      phone: (d['phone'] ?? '') as String,
      latitude: ((d['latitude'] ?? 0) as num).toDouble(),
      longitude: ((d['longitude'] ?? 0) as num).toDouble(),
      imageUrl: (d['imageUrl'] ?? '') as String,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: d['location'] as String?,
    );
  }

  @override
  String toString() =>
      'RentMachine($name, $type, ₹$pricePerDay/day @ $latitude,$longitude)';
}
