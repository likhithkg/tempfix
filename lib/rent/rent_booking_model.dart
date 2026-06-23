// lib/rent/rent_booking_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus {
  requested,
  accepted,
  onTheWay,
  arrived,
  working,
  completed,
  rejected;

  String get label {
    switch (this) {
      case BookingStatus.requested: return 'Requested';
      case BookingStatus.accepted: return 'Accepted';
      case BookingStatus.onTheWay: return 'On The Way';
      case BookingStatus.arrived: return 'Arrived';
      case BookingStatus.working: return 'Working';
      case BookingStatus.completed: return 'Completed';
      case BookingStatus.rejected: return 'Rejected';
    }
  }

  int get step {
    switch (this) {
      case BookingStatus.requested: return 0;
      case BookingStatus.accepted: return 1;
      case BookingStatus.onTheWay: return 2;
      case BookingStatus.arrived: return 3;
      case BookingStatus.working: return 4;
      case BookingStatus.completed: return 5;
      case BookingStatus.rejected: return -1;
    }
  }
}

class RentBooking {
  final String id;
  final String machineId;
  final String machineName;
  final String machineType;
  final String? machineImageUrl;
  final String farmerId;
  final String farmerName;
  final String ownerId;
  final String ownerName;
  final String ownerPhone;
  final int hours;
  final DateTime bookingDate;
  final double? fieldLatitude;
  final double? fieldLongitude;
  final String fieldLocation;
  final double machineCharge;
  final double travelCharge;
  final double totalCost;
  final BookingStatus status;
  final String? notes;
  final DateTime createdAt;
  final double? machineLatitude;
  final double? machineLongitude;

  const RentBooking({
    required this.id,
    required this.machineId,
    required this.machineName,
    required this.machineType,
    this.machineImageUrl,
    required this.farmerId,
    required this.farmerName,
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhone,
    required this.hours,
    required this.bookingDate,
    this.fieldLatitude,
    this.fieldLongitude,
    required this.fieldLocation,
    required this.machineCharge,
    required this.travelCharge,
    required this.totalCost,
    this.status = BookingStatus.requested,
    this.notes,
    required this.createdAt,
    this.machineLatitude,
    this.machineLongitude,
  });

  RentBooking copyWith({BookingStatus? status, String? notes}) {
    return RentBooking(
      id: id,
      machineId: machineId,
      machineName: machineName,
      machineType: machineType,
      machineImageUrl: machineImageUrl,
      farmerId: farmerId,
      farmerName: farmerName,
      ownerId: ownerId,
      ownerName: ownerName,
      ownerPhone: ownerPhone,
      hours: hours,
      bookingDate: bookingDate,
      fieldLatitude: fieldLatitude,
      fieldLongitude: fieldLongitude,
      fieldLocation: fieldLocation,
      machineCharge: machineCharge,
      travelCharge: travelCharge,
      totalCost: totalCost,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      machineLatitude: machineLatitude,
      machineLongitude: machineLongitude,
    );
  }

  Map<String, dynamic> toMap() => {
        'machineId': machineId,
        'machineName': machineName,
        'machineType': machineType,
        'machineImageUrl': machineImageUrl,
        'farmerId': farmerId,
        'farmerName': farmerName,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'ownerPhone': ownerPhone,
        'hours': hours,
        'bookingDate': Timestamp.fromDate(bookingDate),
        'fieldLatitude': fieldLatitude,
        'fieldLongitude': fieldLongitude,
        'fieldLocation': fieldLocation,
        'machineCharge': machineCharge,
        'travelCharge': travelCharge,
        'totalCost': totalCost,
        'status': status.name,
        'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
        'machineLatitude': machineLatitude,
        'machineLongitude': machineLongitude,
      };

  factory RentBooking.fromDoc(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return null;
    }

    BookingStatus parseStatus(dynamic v) {
      if (v == null) return BookingStatus.requested;
      try {
        return BookingStatus.values.firstWhere((e) => e.name == v);
      } catch (_) {
        return BookingStatus.requested;
      }
    }

    return RentBooking(
      id: doc.id,
      machineId: d['machineId'] ?? '',
      machineName: d['machineName'] ?? '',
      machineType: d['machineType'] ?? '',
      machineImageUrl: d['machineImageUrl'] as String?,
      farmerId: d['farmerId'] ?? '',
      farmerName: d['farmerName'] ?? '',
      ownerId: d['ownerId'] ?? '',
      ownerName: d['ownerName'] ?? '',
      ownerPhone: d['ownerPhone'] ?? '',
      hours: (d['hours'] ?? 1) as int,
      bookingDate: (d['bookingDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fieldLatitude: parseDouble(d['fieldLatitude']),
      fieldLongitude: parseDouble(d['fieldLongitude']),
      fieldLocation: d['fieldLocation'] ?? '',
      machineCharge: parseDouble(d['machineCharge']) ?? 0,
      travelCharge: parseDouble(d['travelCharge']) ?? 0,
      totalCost: parseDouble(d['totalCost']) ?? 0,
      status: parseStatus(d['status']),
      notes: d['notes'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      machineLatitude: parseDouble(d['machineLatitude']),
      machineLongitude: parseDouble(d['machineLongitude']),
    );
  }
}
