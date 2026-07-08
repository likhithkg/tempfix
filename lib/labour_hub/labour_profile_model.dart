import 'package:cloud_firestore/cloud_firestore.dart';

const kLabourSkills = [
  'Harvesting', 'Planting', 'Weeding', 'Pruning', 'Spraying',
  'Drip Irrigation', 'Tractor Driver', 'Harvester Operator',
  'JCB Operator', 'Hitachi Operator', 'Lorry Driver',
  'Coconut Tree Climber', 'Sugarcane Cutting', 'Rice Farming',
  'Coffee Picking', 'Cardamom Harvesting', 'Tea Plantation Work',
  'Vegetable Farming', 'Fruit Picking', 'Dairy Farm Worker',
  'Poultry Farm Worker', 'Livestock Care', 'Organic Farming',
  'Greenhouse Work', 'Machine Operator',
];

const kLanguages = [
  'Kannada', 'Telugu', 'Tamil', 'Hindi', 'Malayalam', 'Marathi', 'English',
];

const kAvailabilityLabels = {
  'available': 'Available',
  'busy': 'Busy',
  'unavailable': 'Unavailable',
};

const kWageTypeLabels = {
  'daily': 'Per Day',
  'hourly': 'Per Hour',
  'monthly': 'Monthly',
};

const kAvailabilityTypeLabels = {
  'today': 'Available Today',
  'tomorrow': 'Available Tomorrow',
  'this_week': 'This Week',
  'full_time': 'Full Time',
  'part_time': 'Part Time',
};

const kWorkingRadii = [5, 10, 20, 50, 100];

class LabourProfile {
  final String id;
  final String uid;
  final String name;
  final int age;
  final String gender;
  final String phone;
  final String whatsappNumber;
  final String village;
  final String taluk;
  final String district;
  final String state;
  final String pincode;
  final double latitude;
  final double longitude;
  final int experienceYears;
  final double dailyWage;
  final double hourlyWage;
  final double monthlyWage;
  final String preferredWageType; // 'daily' | 'hourly' | 'monthly'
  final String availabilityStatus; // 'available' | 'busy' | 'unavailable'
  final List<String> availabilityTypes; // 'today','tomorrow','this_week','full_time','part_time'
  final int workingRadiusKm;
  final List<String> skills;
  final List<String> languages;
  final String photoUrl;
  final List<String> galleryUrls;
  final bool isVerified;
  final bool isAadhaarVerified;
  final String description;
  final double rating;
  final int reviewCount;
  final int completedJobs;
  final bool onlineStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastActive;

  const LabourProfile({
    required this.id,
    required this.uid,
    required this.name,
    this.age = 18,
    this.gender = 'Male',
    required this.phone,
    this.whatsappNumber = '',
    required this.village,
    this.taluk = '',
    this.district = '',
    this.state = '',
    this.pincode = '',
    this.latitude = 0,
    this.longitude = 0,
    this.experienceYears = 0,
    required this.dailyWage,
    this.hourlyWage = 0,
    this.monthlyWage = 0,
    this.preferredWageType = 'daily',
    this.availabilityStatus = 'available',
    this.availabilityTypes = const [],
    this.workingRadiusKm = 20,
    required this.skills,
    this.languages = const [],
    this.photoUrl = '',
    this.galleryUrls = const [],
    this.isVerified = false,
    this.isAadhaarVerified = false,
    this.description = '',
    this.rating = 0,
    this.reviewCount = 0,
    this.completedJobs = 0,
    this.onlineStatus = false,
    required this.createdAt,
    required this.updatedAt,
    required this.lastActive,
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
      whatsappNumber: d['whatsappNumber'] as String? ?? '',
      village: d['village'] as String? ?? '',
      taluk: d['taluk'] as String? ?? '',
      district: d['district'] as String? ?? '',
      state: d['state'] as String? ?? '',
      pincode: d['pincode'] as String? ?? '',
      latitude: _d(d['latitude']),
      longitude: _d(d['longitude']),
      experienceYears: _i(d['experienceYears']),
      dailyWage: _d(d['dailyWage']),
      hourlyWage: _d(d['hourlyWage']),
      monthlyWage: _d(d['monthlyWage']),
      preferredWageType: d['preferredWageType'] as String? ?? 'daily',
      availabilityStatus: d['availabilityStatus'] as String? ?? 'available',
      availabilityTypes: _sl(d['availabilityTypes']),
      workingRadiusKm: _i(d['workingRadiusKm'], 20),
      skills: _sl(d['skills']),
      languages: _sl(d['languages']),
      photoUrl: d['photoUrl'] as String? ?? '',
      galleryUrls: _sl(d['galleryUrls']),
      isVerified: d['isVerified'] as bool? ?? false,
      isAadhaarVerified: d['isAadhaarVerified'] as bool? ?? false,
      description: d['description'] as String? ?? '',
      rating: _d(d['rating']),
      reviewCount: _i(d['reviewCount']),
      completedJobs: _i(d['completedJobs']),
      onlineStatus: d['onlineStatus'] as bool? ?? false,
      createdAt: _dt(d['createdAt']),
      updatedAt: _dt(d['updatedAt']),
      lastActive: _dt(d['lastActive'] ?? d['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'age': age,
    'gender': gender,
    'phone': phone,
    'whatsappNumber': whatsappNumber,
    'village': village,
    'taluk': taluk,
    'district': district,
    'state': state,
    'pincode': pincode,
    'latitude': latitude,
    'longitude': longitude,
    'experienceYears': experienceYears,
    'dailyWage': dailyWage,
    'hourlyWage': hourlyWage,
    'monthlyWage': monthlyWage,
    'preferredWageType': preferredWageType,
    'availabilityStatus': availabilityStatus,
    'availabilityTypes': availabilityTypes,
    'workingRadiusKm': workingRadiusKm,
    'skills': skills,
    'languages': languages,
    'photoUrl': photoUrl,
    'galleryUrls': galleryUrls,
    'isVerified': isVerified,
    'isAadhaarVerified': isAadhaarVerified,
    'description': description,
    'rating': rating,
    'reviewCount': reviewCount,
    'completedJobs': completedJobs,
    'onlineStatus': onlineStatus,
    'updatedAt': FieldValue.serverTimestamp(),
    'lastActive': FieldValue.serverTimestamp(),
  };

  LabourProfile copyWith({
    String? availabilityStatus,
    List<String>? availabilityTypes,
    String? photoUrl,
    List<String>? galleryUrls,
    double? rating,
    int? reviewCount,
    int? completedJobs,
    bool? isVerified,
    bool? onlineStatus,
    String? description,
  }) =>
      LabourProfile(
        id: id,
        uid: uid,
        name: name,
        age: age,
        gender: gender,
        phone: phone,
        whatsappNumber: whatsappNumber,
        village: village,
        taluk: taluk,
        district: district,
        state: state,
        pincode: pincode,
        latitude: latitude,
        longitude: longitude,
        experienceYears: experienceYears,
        dailyWage: dailyWage,
        hourlyWage: hourlyWage,
        monthlyWage: monthlyWage,
        preferredWageType: preferredWageType,
        availabilityStatus: availabilityStatus ?? this.availabilityStatus,
        availabilityTypes: availabilityTypes ?? this.availabilityTypes,
        workingRadiusKm: workingRadiusKm,
        skills: skills,
        languages: languages,
        photoUrl: photoUrl ?? this.photoUrl,
        galleryUrls: galleryUrls ?? this.galleryUrls,
        isVerified: isVerified ?? this.isVerified,
        isAadhaarVerified: isAadhaarVerified,
        description: description ?? this.description,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        completedJobs: completedJobs ?? this.completedJobs,
        onlineStatus: onlineStatus ?? this.onlineStatus,
        createdAt: createdAt,
        updatedAt: updatedAt,
        lastActive: lastActive,
      );

  String get locationDisplay {
    if (village.isNotEmpty && district.isNotEmpty) return '$village, $district';
    if (village.isNotEmpty) return village;
    if (district.isNotEmpty) return district;
    return 'Location not set';
  }

  bool get hasLocation => latitude != 0 && longitude != 0;

  bool get isAvailableToday =>
      availabilityTypes.contains('today') && availabilityStatus == 'available';

  String get wageDisplay {
    switch (preferredWageType) {
      case 'hourly':
        return hourlyWage > 0
            ? '₹${hourlyWage.toStringAsFixed(0)}/hr'
            : '₹${dailyWage.toStringAsFixed(0)}/day';
      case 'monthly':
        return monthlyWage > 0
            ? '₹${monthlyWage.toStringAsFixed(0)}/mo'
            : '₹${dailyWage.toStringAsFixed(0)}/day';
      default:
        return '₹${dailyWage.toStringAsFixed(0)}/day';
    }
  }

  String get lastSeenText {
    final diff = DateTime.now().difference(lastActive);
    if (onlineStatus || diff.inMinutes < 5) return 'Online';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
