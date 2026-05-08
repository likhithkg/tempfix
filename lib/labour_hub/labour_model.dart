// lib/labour_hub/labour_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Labour {
  final String id;
  final String name;
  final String skill;
  final String location;
  final String contact;
  final bool available;
  final String createdBy;

  // REQUIRED FOR NEARBY LABOUR FEATURE
  final double? latitude;
  final double? longitude;

  final DateTime? postedAt;

  // ==============================
  // 🔥 NEW ADVANCED FIELDS ADDED
  // ==============================

  final String? category;        // Farm Labour / Tractor Driver etc
  final int? experience;         // years
  final double? wage;            // amount
  final String? wageType;        // Per Day / Per Acre / Per Hour
  final double? rating;          // default 0.0
  final String? imageUrl;        // profile photo
  final String? description;     // worker description

  Labour({
    required this.id,
    required this.name,
    required this.skill,
    required this.location,
    required this.contact,
    required this.available,
    required this.createdBy,
    this.latitude,
    this.longitude,
    this.postedAt,

    // 🔥 New optional fields
    this.category,
    this.experience,
    this.wage,
    this.wageType,
    this.rating,
    this.imageUrl,
    this.description,
  });

  factory Labour.fromMap(Map<String, dynamic> map, String docId) {
    DateTime? parsedPostedAt;

    final pa = map['postedAt'];
    if (pa is Timestamp) parsedPostedAt = pa.toDate();
    else if (pa is String) {
      try {
        parsedPostedAt = DateTime.parse(pa);
      } catch (_) {}
    }

    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    int? _toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    return Labour(
      id: docId,
      name: map['name'] ?? '',
      skill: map['skill'] ?? '',
      location: map['location'] ?? '',
      contact: map['contact'] ?? '',
      available: map['available'] ?? true,
      createdBy: map['createdBy'] ?? '',

      // ESSENTIAL: read both formats (latitude/longitude and lat/lng)
      latitude: _toDouble(map['latitude'] ?? map['lat']),
      longitude: _toDouble(map['longitude'] ?? map['lng']),

      postedAt: parsedPostedAt,

      // 🔥 NEW FIELDS (safe read with fallback)
      category: map['category'],
      experience: _toInt(map['experience']),
      wage: _toDouble(map['wage']),
      wageType: map['wageType'],
      rating: _toDouble(map['rating']) ?? 0.0,
      imageUrl: map['imageUrl'],
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'name': name,
      'skill': skill,
      'location': location,
      'contact': contact,
      'available': available,
      'createdBy': createdBy,
      'postedAt': postedAt,
    };

    if (latitude != null) map['latitude'] = latitude;
    if (longitude != null) map['longitude'] = longitude;

    // 🔥 Add new fields only if not null (backward safe)
    if (category != null) map['category'] = category;
    if (experience != null) map['experience'] = experience;
    if (wage != null) map['wage'] = wage;
    if (wageType != null) map['wageType'] = wageType;
    if (rating != null) map['rating'] = rating;
    if (imageUrl != null) map['imageUrl'] = imageUrl;
    if (description != null) map['description'] = description;

    return map;
  }

  Labour copyWith({
    String? id,
    String? name,
    String? skill,
    String? location,
    String? contact,
    bool? available,
    String? createdBy,
    double? latitude,
    double? longitude,
    DateTime? postedAt,

    // 🔥 new fields
    String? category,
    int? experience,
    double? wage,
    String? wageType,
    double? rating,
    String? imageUrl,
    String? description,
  }) {
    return Labour(
      id: id ?? this.id,
      name: name ?? this.name,
      skill: skill ?? this.skill,
      location: location ?? this.location,
      contact: contact ?? this.contact,
      available: available ?? this.available,
      createdBy: createdBy ?? this.createdBy,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      postedAt: postedAt ?? this.postedAt,

      category: category ?? this.category,
      experience: experience ?? this.experience,
      wage: wage ?? this.wage,
      wageType: wageType ?? this.wageType,
      rating: rating ?? this.rating,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
    );
  }
}