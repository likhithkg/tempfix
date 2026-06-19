// lib/exporter_hub/exporter_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ExportProduct {
  String id;
  String productName;
  String pricePerUnit;
  String quantity;
  String farmerId;
  String farmerName;
  String location;
  String description;
  String category;
  String? farmerMobile;
  String? imageUrl;
  DateTime? createdAt;

  // Owner fields
  String? ownerId;
  String? ownerEmail;
  String? ownerName;
  String? ownerPhone;

  // Phase 3 fields — all optional, backward-compatible with existing Firestore docs
  String? grade;           // 'A', 'B', 'C'
  DateTime? harvestDate;
  bool isOrganic;
  String? expectedPrice;
  String? minOrderQty;
  String? moistureLevel;
  String? variety;
  String? packagingType;
  String? storageLocation;
  String listingStatus;    // 'listed', 'under_review', 'collected', 'exported'
  int views;
  List<String> imageUrls;  // multiple images (supplements single imageUrl)

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
    // Phase 3
    this.grade,
    this.harvestDate,
    this.isOrganic = false,
    this.expectedPrice,
    this.minOrderQty,
    this.moistureLevel,
    this.variety,
    this.packagingType,
    this.storageLocation,
    this.listingStatus = 'listed',
    this.views = 0,
    this.imageUrls = const [],
  });

  factory ExportProduct.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is Timestamp) return v.toDate();
      return DateTime.tryParse(v.toString());
    }

    List<String> parseImageUrls(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      return [];
    }

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
      createdAt: parseDate(map['createdAt']),
      ownerId: map['ownerId']?.toString(),
      ownerEmail: map['ownerEmail']?.toString(),
      ownerName: map['ownerName']?.toString(),
      ownerPhone: map['ownerPhone']?.toString(),
      // Phase 3
      grade: map['grade']?.toString(),
      harvestDate: parseDate(map['harvestDate']),
      isOrganic: map['isOrganic'] == true,
      expectedPrice: map['expectedPrice']?.toString(),
      minOrderQty: map['minOrderQty']?.toString(),
      moistureLevel: map['moistureLevel']?.toString(),
      variety: map['variety']?.toString(),
      packagingType: map['packagingType']?.toString(),
      storageLocation: map['storageLocation']?.toString(),
      listingStatus: (map['listingStatus'] ?? 'listed').toString(),
      views: (map['views'] is int) ? map['views'] as int : 0,
      imageUrls: parseImageUrls(map['imageUrls']),
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
      'farmerMobile': farmerMobile ?? farmerId,
      'listingStatus': listingStatus,
      'isOrganic': isOrganic,
      'views': views,
      if (imageUrls.isNotEmpty) 'imageUrls': imageUrls,
    };

    if (createdAt != null) data['createdAt'] = createdAt!.toIso8601String();
    if (ownerId != null) data['ownerId'] = ownerId;
    if (ownerEmail != null) data['ownerEmail'] = ownerEmail;
    if (ownerName != null) data['ownerName'] = ownerName;
    if (ownerPhone != null) data['ownerPhone'] = ownerPhone;
    if (grade != null) data['grade'] = grade;
    if (harvestDate != null) data['harvestDate'] = harvestDate!.toIso8601String();
    if (expectedPrice != null) data['expectedPrice'] = expectedPrice;
    if (minOrderQty != null) data['minOrderQty'] = minOrderQty;
    if (moistureLevel != null) data['moistureLevel'] = moistureLevel;
    if (variety != null) data['variety'] = variety;
    if (packagingType != null) data['packagingType'] = packagingType;
    if (storageLocation != null) data['storageLocation'] = storageLocation;

    return data;
  }

  // Returns primary display image
  String get primaryImage {
    if (imageUrls.isNotEmpty) return imageUrls.first;
    return imageUrl ?? '';
  }

  // Parsed quantity as a number for sorting (strips unit suffixes like " kg", " MT")
  double get quantityNum {
    final cleaned = quantity.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }
}
