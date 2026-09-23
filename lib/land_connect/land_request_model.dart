import 'package:cloud_firestore/cloud_firestore.dart';

class LandRequest {
  final String id;
  final String listingId;
  final String cultivatorId;
  final String cultivatorName;
  final String cultivatorPhone;
  final int cultivatorExperience;
  final String ownerId;
  final String ownerName;
  final String ownerPhone;
  final String landTitle;
  final String landLocation; // village + district
  final String cropName;
  final double requestedAcres;
  final int durationMonths;
  final String proposedArrangement;
  final double proposedAmount;
  final String message;

  // Status: pending | accepted | rejected | withdrawn | expired
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const LandRequest({
    required this.id,
    required this.listingId,
    required this.cultivatorId,
    this.cultivatorName = '',
    this.cultivatorPhone = '',
    this.cultivatorExperience = 0,
    required this.ownerId,
    this.ownerName = '',
    this.ownerPhone = '',
    this.landTitle = '',
    this.landLocation = '',
    required this.cropName,
    required this.requestedAcres,
    required this.durationMonths,
    required this.proposedArrangement,
    this.proposedAmount = 0,
    this.message = '',
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory LandRequest.fromDoc(DocumentSnapshot doc) =>
      LandRequest.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  factory LandRequest.fromMap(Map<String, dynamic> d, String id) {
    double dbl(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    int intVal(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    DateTime dt(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return LandRequest(
      id: id,
      listingId: d['listingId'] ?? '',
      cultivatorId: d['cultivatorId'] ?? '',
      cultivatorName: d['cultivatorName'] ?? '',
      cultivatorPhone: d['cultivatorPhone'] ?? '',
      cultivatorExperience: intVal(d['cultivatorExperience']),
      ownerId: d['ownerId'] ?? '',
      ownerName: d['ownerName'] ?? '',
      ownerPhone: d['ownerPhone'] ?? '',
      landTitle: d['landTitle'] ?? '',
      landLocation: d['landLocation'] ?? '',
      cropName: d['cropName'] ?? '',
      requestedAcres: dbl(d['requestedAcres']),
      durationMonths: intVal(d['durationMonths']),
      proposedArrangement: d['proposedArrangement'] ?? 'negotiable',
      proposedAmount: dbl(d['proposedAmount']),
      message: d['message'] ?? '',
      status: d['status'] ?? 'pending',
      createdAt: dt(d['createdAt']),
      updatedAt: d['updatedAt'] != null ? dt(d['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'listingId': listingId,
        'cultivatorId': cultivatorId,
        'cultivatorName': cultivatorName,
        'cultivatorPhone': cultivatorPhone,
        'cultivatorExperience': cultivatorExperience,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'ownerPhone': ownerPhone,
        'landTitle': landTitle,
        'landLocation': landLocation,
        'cropName': cropName,
        'requestedAcres': requestedAcres,
        'durationMonths': durationMonths,
        'proposedArrangement': proposedArrangement,
        'proposedAmount': proposedAmount,
        'message': message,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
        if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      };
}
