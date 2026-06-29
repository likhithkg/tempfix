// lib/rent/rent_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum MachineAvailability {
  available,
  busy,
  underMaintenance,
  offline;

  String get label {
    switch (this) {
      case MachineAvailability.available: return 'Available';
      case MachineAvailability.busy: return 'Busy';
      case MachineAvailability.underMaintenance: return 'Under Maintenance';
      case MachineAvailability.offline: return 'Offline';
    }
  }
}

enum MachineBadge {
  trustedOwner,
  topRated,
  fastResponse,
  newFeature;

  String get label {
    switch (this) {
      case MachineBadge.trustedOwner: return 'Trusted Owner';
      case MachineBadge.topRated: return 'Top Rated';
      case MachineBadge.fastResponse: return 'Fast Response';
      case MachineBadge.newFeature: return 'New';
    }
  }

  String get emoji {
    switch (this) {
      case MachineBadge.trustedOwner: return '🛡';
      case MachineBadge.topRated: return '⭐';
      case MachineBadge.fastResponse: return '⚡';
      case MachineBadge.newFeature: return '🆕';
    }
  }
}

class RentMachine {
  final String id;
  final String name;
  final String type;
  final double pricePerDay;
  final double pricePerHour;
  final String ownerName;
  final String ownerId;
  final String phone;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final DateTime createdAt;
  final String? location;
  final MachineAvailability availability;
  final double rating;
  final int completedJobs;
  final double acceptanceRate;
  final int yearsInService;
  final List<MachineBadge> badges;
  final double reliabilityScore;
  final String? ownerPhotoUrl;

  const RentMachine({
    required this.id,
    required this.name,
    required this.type,
    required this.pricePerDay,
    this.pricePerHour = 0,
    required this.ownerName,
    required this.ownerId,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.createdAt,
    this.location,
    this.availability = MachineAvailability.available,
    this.rating = 4.5,
    this.completedJobs = 0,
    this.acceptanceRate = 1.0,
    this.yearsInService = 1,
    this.badges = const [],
    this.reliabilityScore = 80.0,
    this.ownerPhotoUrl,
  });

  double get effectiveHourlyRate =>
      pricePerHour > 0 ? pricePerHour : (pricePerDay / 10.0);

  RentMachine copyWith({
    String? id,
    String? name,
    String? type,
    double? pricePerDay,
    double? pricePerHour,
    String? ownerName,
    String? ownerId,
    String? phone,
    double? latitude,
    double? longitude,
    String? imageUrl,
    DateTime? createdAt,
    String? location,
    MachineAvailability? availability,
    double? rating,
    int? completedJobs,
    double? acceptanceRate,
    int? yearsInService,
    List<MachineBadge>? badges,
    double? reliabilityScore,
    String? ownerPhotoUrl,
  }) {
    return RentMachine(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      ownerName: ownerName ?? this.ownerName,
      ownerId: ownerId ?? this.ownerId,
      phone: phone ?? this.phone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      location: location ?? this.location,
      availability: availability ?? this.availability,
      rating: rating ?? this.rating,
      completedJobs: completedJobs ?? this.completedJobs,
      acceptanceRate: acceptanceRate ?? this.acceptanceRate,
      yearsInService: yearsInService ?? this.yearsInService,
      badges: badges ?? this.badges,
      reliabilityScore: reliabilityScore ?? this.reliabilityScore,
      ownerPhotoUrl: ownerPhotoUrl ?? this.ownerPhotoUrl,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'title': name,
        'type': type,
        'pricePerDay': pricePerDay,
        'ratePerDay': pricePerDay,
        'pricePerHour': pricePerHour,
        'ownerName': ownerName,
        'ownerId': ownerId,
        'phone': phone,
        'latitude': latitude,
        'longitude': longitude,
        'imageUrl': imageUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'location': location,
        'availability': availability.name,
        'rating': rating,
        'completedJobs': completedJobs,
        'acceptanceRate': acceptanceRate,
        'yearsInService': yearsInService,
        'badges': badges.map((b) => b.name).toList(),
        'reliabilityScore': reliabilityScore,
        'ownerPhotoUrl': ownerPhotoUrl,
      };

  factory RentMachine.fromDoc(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    final nameValue = (d['name'] ?? d['title'] ?? '') as String;

    double parseNum(dynamic p, [double fallback = 0]) {
      if (p == null) return fallback;
      if (p is num) return p.toDouble();
      if (p is String) return double.tryParse(p) ?? fallback;
      return fallback;
    }

    MachineAvailability parseAvailability(dynamic v) {
      if (v == null) return MachineAvailability.available;
      try {
        return MachineAvailability.values.firstWhere((e) => e.name == v);
      } catch (_) {
        return MachineAvailability.available;
      }
    }

    List<MachineBadge> parseBadges(dynamic v) {
      if (v == null || v is! List) return [];
      return v.map<MachineBadge>((b) {
        try {
          return MachineBadge.values.firstWhere((e) => e.name == b.toString());
        } catch (_) {
          return MachineBadge.newFeature;
        }
      }).toList();
    }

    return RentMachine(
      id: doc.id,
      name: nameValue,
      type: (d['type'] ?? 'Other') as String,
      pricePerDay: parseNum(d['pricePerDay'] ?? d['ratePerDay']),
      pricePerHour: parseNum(d['pricePerHour']),
      ownerName: (d['ownerName'] ?? '') as String,
      ownerId: (d['ownerId'] ?? '') as String,
      phone: (d['phone'] ?? '') as String,
      latitude: parseNum(d['latitude']),
      longitude: parseNum(d['longitude']),
      imageUrl: (d['imageUrl'] ?? '') as String,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: d['location'] as String?,
      availability: parseAvailability(d['availability']),
      rating: parseNum(d['rating'], 4.5),
      completedJobs: parseNum(d['completedJobs']).toInt(),
      acceptanceRate: parseNum(d['acceptanceRate'], 1.0),
      yearsInService: parseNum(d['yearsInService'], 1.0).toInt(),
      badges: parseBadges(d['badges']),
      reliabilityScore: parseNum(d['reliabilityScore'], 80.0),
      ownerPhotoUrl: d['ownerPhotoUrl'] as String?,
    );
  }

  @override
  String toString() =>
      'RentMachine($name, $type, ₹$pricePerDay/day @ $latitude,$longitude)';
}
