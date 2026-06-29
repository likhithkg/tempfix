import 'package:cloud_firestore/cloud_firestore.dart';

class LabourReview {
  final String id;
  final String labourId;
  final String reviewerId;
  final String reviewerName;
  final double rating;
  final String comment;
  final String jobTitle;
  final DateTime createdAt;

  const LabourReview({
    required this.id,
    required this.labourId,
    required this.reviewerId,
    required this.reviewerName,
    required this.rating,
    this.comment = '',
    this.jobTitle = '',
    required this.createdAt,
  });

  static DateTime _dt(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.now();
  }

  factory LabourReview.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return LabourReview(
      id: doc.id,
      labourId: d['labourId'] as String? ?? '',
      reviewerId: d['reviewerId'] as String? ?? '',
      reviewerName: d['reviewerName'] as String? ?? '',
      rating: (d['rating'] as num?)?.toDouble() ?? 0,
      comment: d['comment'] as String? ?? '',
      jobTitle: d['jobTitle'] as String? ?? '',
      createdAt: _dt(d['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'labourId': labourId,
        'reviewerId': reviewerId,
        'reviewerName': reviewerName,
        'rating': rating,
        'comment': comment,
        'jobTitle': jobTitle,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
