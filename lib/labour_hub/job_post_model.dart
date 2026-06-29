import 'package:cloud_firestore/cloud_firestore.dart';

class JobPost {
  final String id;
  final String farmerId;
  final String farmerName;
  final String farmerPhone;
  final String title;
  final String description;
  final List<String> requiredSkills;
  final String location;
  final double latitude;
  final double longitude;
  final DateTime startDate;
  final DateTime endDate;
  final int workersRequired;
  final int workersHired;
  final double dailyWage;
  final String workingHours;
  final bool foodIncluded;
  final bool accommodationIncluded;
  final String status; // open | in_progress | completed | cancelled
  final int applicantCount;
  final DateTime createdAt;

  const JobPost({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    this.farmerPhone = '',
    required this.title,
    this.description = '',
    required this.requiredSkills,
    required this.location,
    this.latitude = 0,
    this.longitude = 0,
    required this.startDate,
    required this.endDate,
    required this.workersRequired,
    this.workersHired = 0,
    required this.dailyWage,
    this.workingHours = '8 AM – 5 PM',
    this.foodIncluded = false,
    this.accommodationIncluded = false,
    this.status = 'open',
    this.applicantCount = 0,
    required this.createdAt,
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

  factory JobPost.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return JobPost(
      id: doc.id,
      farmerId: d['farmerId'] as String? ?? '',
      farmerName: d['farmerName'] as String? ?? '',
      farmerPhone: d['farmerPhone'] as String? ?? '',
      title: d['title'] as String? ?? '',
      description: d['description'] as String? ?? '',
      requiredSkills: _sl(d['requiredSkills']),
      location: d['location'] as String? ?? '',
      latitude: _d(d['latitude']),
      longitude: _d(d['longitude']),
      startDate: _dt(d['startDate']),
      endDate: _dt(d['endDate']),
      workersRequired: _i(d['workersRequired'], 1),
      workersHired: _i(d['workersHired']),
      dailyWage: _d(d['dailyWage']),
      workingHours: d['workingHours'] as String? ?? '8 AM – 5 PM',
      foodIncluded: d['foodIncluded'] as bool? ?? false,
      accommodationIncluded: d['accommodationIncluded'] as bool? ?? false,
      status: d['status'] as String? ?? 'open',
      applicantCount: _i(d['applicantCount']),
      createdAt: _dt(d['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'farmerId': farmerId,
        'farmerName': farmerName,
        'farmerPhone': farmerPhone,
        'title': title,
        'description': description,
        'requiredSkills': requiredSkills,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'workersRequired': workersRequired,
        'workersHired': workersHired,
        'dailyWage': dailyWage,
        'workingHours': workingHours,
        'foodIncluded': foodIncluded,
        'accommodationIncluded': accommodationIncluded,
        'status': status,
        'applicantCount': applicantCount,
        'createdAt': FieldValue.serverTimestamp(),
      };

  int get daysUntilStart {
    final diff = startDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  int get durationDays => endDate.difference(startDate).inDays + 1;

  bool get isOpen => status == 'open';
  bool get isFull => workersHired >= workersRequired;
  int get spotsLeft => workersRequired - workersHired;

  double get totalBudget => dailyWage * durationDays * workersRequired;
}
