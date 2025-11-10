// lib/exporter_hub/exporter_model.dart

class ExportProduct {
  String id;
  String productName;
  String pricePerUnit;
  String quantity;
  String farmerId; // kept for compatibility (we will also store farmerMobile)
  String farmerName;
  String location;
  String description;
  String category;
  String? farmerMobile; // NEW: primary mobile number for farmer
  String? imageUrl;
  DateTime? createdAt;

  // Owner fields
  String? ownerId;
  String? ownerEmail;
  String? ownerName;
  String? ownerPhone;

  ExportProduct({
    this.id = '',
    required this.productName,
    required this.pricePerUnit,
    required this.quantity,
    required this.farmerId,
    required this.farmerName,
    required this.location,
    required this.description,
    this.category = '',
    this.farmerMobile,
    this.imageUrl,
    this.createdAt,
    this.ownerId,
    this.ownerEmail,
    this.ownerName,
    this.ownerPhone,
  });

  factory ExportProduct.fromMap(Map<String, dynamic> map) {
    return ExportProduct(
      id: map['id'] ?? '',
      productName: (map['productName'] ?? '').toString(),
      pricePerUnit: (map['pricePerUnit'] ?? '').toString(),
      quantity: (map['quantity'] ?? '').toString(),
      farmerId: (map['farmerId'] ?? '').toString(),
      farmerName: (map['farmerName'] ?? '').toString(),
      location: (map['location'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      farmerMobile: map['farmerMobile']?.toString(),
      imageUrl: map['imageUrl']?.toString(),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is DateTime
              ? map['createdAt']
              : DateTime.tryParse(map['createdAt'].toString()))
          : null,
      ownerId: map['ownerId']?.toString(),
      ownerEmail: map['ownerEmail']?.toString(),
      ownerName: map['ownerName']?.toString(),
      ownerPhone: map['ownerPhone']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
      'productName': productName,
      'pricePerUnit': pricePerUnit,
      'quantity': quantity,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'location': location,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      // we include farmerMobile explicitly (preferred new field)
      'farmerMobile': farmerMobile ?? farmerId,
    };

    if (createdAt != null) data['createdAt'] = createdAt!.toIso8601String();
    if (ownerId != null) data['ownerId'] = ownerId;
    if (ownerEmail != null) data['ownerEmail'] = ownerEmail;
    if (ownerName != null) data['ownerName'] = ownerName;
    if (ownerPhone != null) data['ownerPhone'] = ownerPhone;

    return data;
  }
}
