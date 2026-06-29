import 'package:cloud_firestore/cloud_firestore.dart';

class JobApplication {
  final String id;
  final String jobId;
  final String jobTitle;
  final String labourId;
  final String labourName;
  final String labourPhone;
  final String labourPhotoUrl;
  final double labourRating;
  final List<String> labourSkills;
  final String farmerId;
  final String status; // pending | shortlisted | accepted | rejected | cancelled
  final double? counterOffer;
  final String message;
  final DateTime appliedAt;

  const JobApplication({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.labourId,
    required this.labourName,
    required this.labourPhone,
    this.labourPhotoUrl = '',
    this.labourRating = 0,
    this.labourSkills = const [],
    required this.farmerId,
    this.status = 'pending',
    this.counterOffer,
    this.message = '',
    required this.appliedAt,
  });

  static DateTime _dt(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.now();
  }

  factory JobApplication.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return JobApplication(
      id: doc.id,
      jobId: d['jobId'] as String? ?? '',
      jobTitle: d['jobTitle'] as String? ?? '',
      labourId: d['labourId'] as String? ?? '',
      labourName: d['labourName'] as String? ?? '',
      labourPhone: d['labourPhone'] as String? ?? '',
      labourPhotoUrl: d['labourPhotoUrl'] as String? ?? '',
      labourRating: (d['labourRating'] as num?)?.toDouble() ?? 0,
      labourSkills: d['labourSkills'] != null
          ? List<String>.from(d['labourSkills'] as List)
          : [],
      farmerId: d['farmerId'] as String? ?? '',
      status: d['status'] as String? ?? 'pending',
      counterOffer: d['counterOffer'] != null
          ? (d['counterOffer'] as num).toDouble()
          : null,
      message: d['message'] as String? ?? '',
      appliedAt: _dt(d['appliedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'jobId': jobId,
        'jobTitle': jobTitle,
        'labourId': labourId,
        'labourName': labourName,
        'labourPhone': labourPhone,
        'labourPhotoUrl': labourPhotoUrl,
        'labourRating': labourRating,
        'labourSkills': labourSkills,
        'farmerId': farmerId,
        'status': status,
        if (counterOffer != null) 'counterOffer': counterOffer,
        'message': message,
        'appliedAt': FieldValue.serverTimestamp(),
      };

  JobApplication copyWith({String? status}) => JobApplication(
        id: id,
        jobId: jobId,
        jobTitle: jobTitle,
        labourId: labourId,
        labourName: labourName,
        labourPhone: labourPhone,
        labourPhotoUrl: labourPhotoUrl,
        labourRating: labourRating,
        labourSkills: labourSkills,
        farmerId: farmerId,
        status: status ?? this.status,
        counterOffer: counterOffer,
        message: message,
        appliedAt: appliedAt,
      );
}
