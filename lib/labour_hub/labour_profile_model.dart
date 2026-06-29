import 'package:cloud_firestore/cloud_firestore.dart';

const kLabourSkills = [
  'Harvesting', 'Planting', 'Weeding', 'Pruning', 'Spraying',
  'Drip Irrigation', 'Tractor Driver', 'Harvester Operator',
  'JCB Operator', 'Hitachi Operator', 'Lorry Driver',
  'Coconut Tree Climber', 'Coffee Picking', 'Cardamom Harvesting',
  'Tea Plantation Work', 'Dairy Farm Worker', 'Poultry Farm Worker',
  'Organic Farming', 'Greenhouse Work',
];

const kLanguages = [
  'Kannada', 'Telugu', 'Tamil', 'Hindi', 'Malayalam', 'Marathi', 'English',
];

const kAvailabilityLabels = {
  'available': 'Available',
  'busy': 'Busy',
  'unavailable': 'Unavailable',
};

class LabourProfile {
  final String id;
  final String uid;
  final String name;
  final int age;
  final String gender;
  final String phone;
  final String village;
  final String taluk;
  final String district;
  final double latitude;
  final double longitude;
  final int experienceYears;
  final double dailyWage;
  final String availabilityStatus;
  final List<String> skills;
  final List<String> languages;
  final String photoUrl;
  final bool isVerified;
  final bool isAadhaarVerified;
  final double rating;
  final int reviewCount;
  final int completedJobs;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LabourProfile({
    required this.id,
    required this.uid,
    required this.name,
    this.age = 18,
    this.gender = 'Male',
    required this.phone,
    required this.village,
    this.taluk = '',
    this.district = '',
    this.latitude = 0,
    this.longitude = 0,
    this.experienceYears = 0,
    required this.dailyWage,
    this.availabilityStatus = 'available',
    required this.skills,
    this.languages = const [],
    this.photoUrl = '',
    this.isVerified = false,
    this.isAadhaarVerified = false,
    this.rating = 0,
    this.reviewCount = 0,
    this.completedJobs = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  static double _d(dynamic v, [double d = 0]) =>
      v == null ? d : (v as num).toDouble();
  static int _i(dynamic v, [int d = 0]) =>
      v == null ? d : (v as num).toInt();
  static List<String> _sl(dynamic v) =>
      v == null ? [] : List<String>.from(v as List);
  static DateTime _dt(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.now();
  }

  factory LabourProfile.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return LabourProfile(
      id: doc.id,
      uid: d['uid'] as String? ?? doc.id,
      name: d['name'] as String? ?? '',
      age: _i(d['age'], 18),
      gender: d['gender'] as String? ?? 'Male',
      phone: d['phone'] as String? ?? '',
      village: d['village'] as String? ?? '',
      taluk: d['taluk'] as String? ?? '',
      district: d['district'] as String? ?? '',
      latitude: _d(d['latitude']),
      longitude: _d(d['longitude']),
      experienceYears: _i(d['experienceYears']),
      dailyWage: _d(d['dailyWage']),
      availabilityStatus: d['availabilityStatus'] as String? ?? 'available',
      skills: _sl(d['skills']),
      languages: _sl(d['languages']),
      photoUrl: d['photoUrl'] as String? ?? '',
      isVerified: d['isVerified'] as bool? ?? false,
      isAadhaarVerified: d['isAadhaarVerified'] as bool? ?? false,
      rating: _d(d['rating']),
      reviewCount: _i(d['reviewCount']),
      completedJobs: _i(d['completedJobs']),
      createdAt: _dt(d['createdAt']),
      updatedAt: _dt(d['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'age': age,
        'gender': gender,
        'phone': phone,
        'village': village,
        'taluk': taluk,
        'district': district,
        'latitude': latitude,
        'longitude': longitude,
        'experienceYears': experienceYears,
        'dailyWage': dailyWage,
        'availabilityStatus': availabilityStatus,
        'skills': skills,
        'languages': languages,
        'photoUrl': photoUrl,
        'isVerified': isVerified,
        'isAadhaarVerified': isAadhaarVerified,
        'rating': rating,
        'reviewCount': reviewCount,
        'completedJobs': completedJobs,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  LabourProfile copyWith({
    String? availabilityStatus,
    String? photoUrl,
    double? rating,
    int? reviewCount,
    int? completedJobs,
    bool? isVerified,
  }) =>
      LabourProfile(
        id: id,
        uid: uid,
        name: name,
        age: age,
        gender: gender,
        phone: phone,
        village: village,
        taluk: taluk,
        district: district,
        latitude: latitude,
        longitude: longitude,
        experienceYears: experienceYears,
        dailyWage: dailyWage,
        availabilityStatus: availabilityStatus ?? this.availabilityStatus,
        skills: skills,
        languages: languages,
        photoUrl: photoUrl ?? this.photoUrl,
        isVerified: isVerified ?? this.isVerified,
        isAadhaarVerified: isAadhaarVerified,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        completedJobs: completedJobs ?? this.completedJobs,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  String get locationDisplay {
    if (village.isNotEmpty && district.isNotEmpty) return '$village, $district';
    if (village.isNotEmpty) return village;
    if (district.isNotEmpty) return district;
    return 'Location not set';
  }

  bool get hasLocation => latitude != 0 && longitude != 0;
}
