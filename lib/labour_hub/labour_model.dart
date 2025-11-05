// labour_model.dart

class Labour {
  final String id;
  final String name;
  final String skill;
  final String location;
  final String contact;
  final bool available;
  final String createdBy; // 👈 NEW FIELD (owner UID)

  Labour({
    required this.id,
    required this.name,
    required this.skill,
    required this.location,
    required this.contact,
    required this.available,
    required this.createdBy, // 👈 added to constructor
  });

  factory Labour.fromMap(Map<String, dynamic> map, String docId) {
    return Labour(
      id: docId,
      name: map['name'] ?? '',
      skill: map['skill'] ?? '',
      location: map['location'] ?? '',
      contact: map['contact'] ?? '',
      available: map['available'] ?? true,
      createdBy: map['createdBy'] ?? '', // 👈 read owner UID
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'skill': skill,
      'location': location,
      'contact': contact,
      'available': available,
      'createdBy': createdBy, // 👈 save owner UID
    };
  }

  // Optional: easy copy method
  Labour copyWith({
    String? id,
    String? name,
    String? skill,
    String? location,
    String? contact,
    bool? available,
    String? createdBy,
  }) {
    return Labour(
      id: id ?? this.id,
      name: name ?? this.name,
      skill: skill ?? this.skill,
      location: location ?? this.location,
      contact: contact ?? this.contact,
      available: available ?? this.available,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}