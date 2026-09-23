import 'package:cloud_firestore/cloud_firestore.dart';

class LandListing {
  final String id;
  final String ownerId;
  final String ownerName;
  final String ownerPhone;
  final String title;
  final String description;
  final List<String> images;
  final double totalAcres;
  final double availableAcres;

  // Location (approx — never expose GPS publicly on listing cards)
  final double? latitude;
  final double? longitude;
  final String village;
  final String taluk;
  final String district;
  final String state;
  final String pincode;

  // Land details
  final String soilType;
  final String waterAvailability;
  final String irrigationType;
  final bool electricityAvailable;
  final bool roadAccess;
  final bool farmEquipmentAvailable;
  final bool fencingAvailable;
  final bool storageAvailable;

  // Cultivation preferences
  final List<String> preferredCrops;
  final String landType;

  // Availability
  final DateTime? availabilityStartDate;
  final DateTime? availabilityEndDate;

  // Arrangement
  final String arrangementType; // fixed_rent | revenue_share | negotiable
  final double expectedRent;
  final String rentPeriod; // yearly | monthly | seasonal
  final double revenueSharePercentage;

  // Status: draft | active | paused | occupied | expired | deleted
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LandListing({
    required this.id,
    required this.ownerId,
    this.ownerName = '',
    this.ownerPhone = '',
    required this.title,
    this.description = '',
    this.images = const [],
    required this.totalAcres,
    required this.availableAcres,
    this.latitude,
    this.longitude,
    this.village = '',
    this.taluk = '',
    this.district = '',
    this.state = '',
    this.pincode = '',
    this.soilType = '',
    this.waterAvailability = '',
    this.irrigationType = '',
    this.electricityAvailable = false,
    this.roadAccess = false,
    this.farmEquipmentAvailable = false,
    this.fencingAvailable = false,
    this.storageAvailable = false,
    this.preferredCrops = const [],
    this.landType = 'Agricultural',
    this.availabilityStartDate,
    this.availabilityEndDate,
    required this.arrangementType,
    this.expectedRent = 0,
    this.rentPeriod = 'Yearly',
    this.revenueSharePercentage = 0,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LandListing.fromDoc(DocumentSnapshot doc) =>
      LandListing.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  factory LandListing.fromMap(Map<String, dynamic> d, String id) {
    double dbl(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    DateTime dt(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    List<String> strList(dynamic v) {
      if (v == null) return [];
      if (v is List) return v.map((e) => e.toString()).toList();
      return [];
    }

    return LandListing(
      id: id,
      ownerId: d['ownerId'] ?? '',
      ownerName: d['ownerName'] ?? '',
      ownerPhone: d['ownerPhone'] ?? '',
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      images: strList(d['images']),
      totalAcres: dbl(d['totalAcres']),
      availableAcres: dbl(d['availableAcres']),
      latitude: d['latitude'] != null ? dbl(d['latitude']) : null,
      longitude: d['longitude'] != null ? dbl(d['longitude']) : null,
      village: d['village'] ?? '',
      taluk: d['taluk'] ?? '',
      district: d['district'] ?? '',
      state: d['state'] ?? '',
      pincode: d['pincode'] ?? '',
      soilType: d['soilType'] ?? '',
      waterAvailability: d['waterAvailability'] ?? '',
      irrigationType: d['irrigationType'] ?? '',
      electricityAvailable: d['electricityAvailable'] ?? false,
      roadAccess: d['roadAccess'] ?? false,
      farmEquipmentAvailable: d['farmEquipmentAvailable'] ?? false,
      fencingAvailable: d['fencingAvailable'] ?? false,
      storageAvailable: d['storageAvailable'] ?? false,
      preferredCrops: strList(d['preferredCrops']),
      landType: d['landType'] ?? 'Agricultural',
      availabilityStartDate:
          d['availabilityStartDate'] != null ? dt(d['availabilityStartDate']) : null,
      availabilityEndDate:
          d['availabilityEndDate'] != null ? dt(d['availabilityEndDate']) : null,
      arrangementType: d['arrangementType'] ?? 'negotiable',
      expectedRent: dbl(d['expectedRent']),
      rentPeriod: d['rentPeriod'] ?? 'Yearly',
      revenueSharePercentage: dbl(d['revenueSharePercentage']),
      status: d['status'] ?? 'active',
      createdAt: dt(d['createdAt']),
      updatedAt: dt(d['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'ownerName': ownerName,
        'ownerPhone': ownerPhone,
        'title': title,
        'description': description,
        'images': images,
        'totalAcres': totalAcres,
        'availableAcres': availableAcres,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'village': village,
        'taluk': taluk,
        'district': district,
        'state': state,
        'pincode': pincode,
        'soilType': soilType,
        'waterAvailability': waterAvailability,
        'irrigationType': irrigationType,
        'electricityAvailable': electricityAvailable,
        'roadAccess': roadAccess,
        'farmEquipmentAvailable': farmEquipmentAvailable,
        'fencingAvailable': fencingAvailable,
        'storageAvailable': storageAvailable,
        'preferredCrops': preferredCrops,
        'landType': landType,
        if (availabilityStartDate != null)
          'availabilityStartDate': Timestamp.fromDate(availabilityStartDate!),
        if (availabilityEndDate != null)
          'availabilityEndDate': Timestamp.fromDate(availabilityEndDate!),
        'arrangementType': arrangementType,
        'expectedRent': expectedRent,
        'rentPeriod': rentPeriod,
        'revenueSharePercentage': revenueSharePercentage,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  LandListing copyWith({
    String? id,
    String? ownerId,
    String? ownerName,
    String? ownerPhone,
    String? title,
    String? description,
    List<String>? images,
    double? totalAcres,
    double? availableAcres,
    double? latitude,
    double? longitude,
    String? village,
    String? taluk,
    String? district,
    String? state,
    String? pincode,
    String? soilType,
    String? waterAvailability,
    String? irrigationType,
    bool? electricityAvailable,
    bool? roadAccess,
    bool? farmEquipmentAvailable,
    bool? fencingAvailable,
    bool? storageAvailable,
    List<String>? preferredCrops,
    String? landType,
    DateTime? availabilityStartDate,
    DateTime? availabilityEndDate,
    String? arrangementType,
    double? expectedRent,
    String? rentPeriod,
    double? revenueSharePercentage,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      LandListing(
        id: id ?? this.id,
        ownerId: ownerId ?? this.ownerId,
        ownerName: ownerName ?? this.ownerName,
        ownerPhone: ownerPhone ?? this.ownerPhone,
        title: title ?? this.title,
        description: description ?? this.description,
        images: images ?? this.images,
        totalAcres: totalAcres ?? this.totalAcres,
        availableAcres: availableAcres ?? this.availableAcres,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        village: village ?? this.village,
        taluk: taluk ?? this.taluk,
        district: district ?? this.district,
        state: state ?? this.state,
        pincode: pincode ?? this.pincode,
        soilType: soilType ?? this.soilType,
        waterAvailability: waterAvailability ?? this.waterAvailability,
        irrigationType: irrigationType ?? this.irrigationType,
        electricityAvailable: electricityAvailable ?? this.electricityAvailable,
        roadAccess: roadAccess ?? this.roadAccess,
        farmEquipmentAvailable: farmEquipmentAvailable ?? this.farmEquipmentAvailable,
        fencingAvailable: fencingAvailable ?? this.fencingAvailable,
        storageAvailable: storageAvailable ?? this.storageAvailable,
        preferredCrops: preferredCrops ?? this.preferredCrops,
        landType: landType ?? this.landType,
        availabilityStartDate: availabilityStartDate ?? this.availabilityStartDate,
        availabilityEndDate: availabilityEndDate ?? this.availabilityEndDate,
        arrangementType: arrangementType ?? this.arrangementType,
        expectedRent: expectedRent ?? this.expectedRent,
        rentPeriod: rentPeriod ?? this.rentPeriod,
        revenueSharePercentage: revenueSharePercentage ?? this.revenueSharePercentage,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  String get locationDisplay {
    final parts = [village, district].where((s) => s.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(', ') : state;
  }

  bool get isAvailableNow {
    if (availabilityStartDate == null) return true;
    return availabilityStartDate!.isBefore(DateTime.now());
  }
}
