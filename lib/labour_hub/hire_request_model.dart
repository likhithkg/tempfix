// lib/labour_hub/hire_request_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Simple status helper (optional use)
class HireRequestStatus {
  static const pending = 'pending';
  static const accepted = 'accepted';
  static const rejected = 'rejected';
  static const cancelled = 'cancelled';
}

class HireRequest {
  final String id;            // Firestore doc id
  final String labourId;      // Which labour this request is for
  final String requestedBy;   // UID of the user making the request
  final DateTime date;        // Work date (start date)
  final int duration;         // How many units (hours/days)
  final String durationUnit;  // 'hours' or 'days'
  final String workType;      // e.g., Harvesting, Plumbing
  final String location;      // Job location
  final String? notes;        // Optional extra info
  final String status;        // pending/accepted/rejected/cancelled
  final DateTime createdAt;
  final DateTime updatedAt;

  HireRequest({
    required this.id,
    required this.labourId,
    required this.requestedBy,
    required this.date,
    required this.duration,
    required this.durationUnit,
    required this.workType,
    required this.location,
    this.notes,
    this.status = HireRequestStatus.pending,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Robust Timestamp/DateTime parser for Firestore maps
  static DateTime _parseDate(dynamic v, {DateTime? fallback}) {
    if (v == null) return fallback ?? DateTime.now();
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return DateTime.tryParse(v.toString()) ?? (fallback ?? DateTime.now());
  }

  factory HireRequest.fromMap(Map<String, dynamic> map, String docId) {
    int _toInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return HireRequest(
      id: docId,
      labourId: map['labourId'] ?? '',
      requestedBy: map['requestedBy'] ?? '',
      date: _parseDate(map['date']),
      duration: _toInt(map['duration']),
      durationUnit: map['durationUnit'] ?? 'days',
      workType: map['workType'] ?? '',
      location: map['location'] ?? '',
      notes: map['notes'],
      status: map['status'] ?? HireRequestStatus.pending,
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'labourId': labourId,
      'requestedBy': requestedBy,
      'date': Timestamp.fromDate(date),
      'duration': duration,
      'durationUnit': durationUnit,
      'workType': workType,
      'location': location,
      'notes': notes,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  HireRequest copyWith({
    String? id,
    String? labourId,
    String? requestedBy,
    DateTime? date,
    int? duration,
    String? durationUnit,
    String? workType,
    String? location,
    String? notes,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HireRequest(
      id: id ?? this.id,
      labourId: labourId ?? this.labourId,
      requestedBy: requestedBy ?? this.requestedBy,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      durationUnit: durationUnit ?? this.durationUnit,
      workType: workType ?? this.workType,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}