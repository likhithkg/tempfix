class SoilSample {
  final String id;
  final String fieldName;
  final double ph;
  final bool isAI;
  final double nitrogen;
  final double phosphorus;
  final double potassium;
  final String soilType;
  final DateTime date;

  SoilSample({
    required this.id,
    required this.fieldName,
    required this.ph,
    this.isAI = false,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    this.soilType = "Loam",
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'fieldName': fieldName,
        'ph': ph,
        'isAI': isAI,
        'nitrogen': nitrogen,
        'phosphorus': phosphorus,
        'potassium': potassium,
        'soilType': soilType,
        'date': date.toIso8601String(),
      };

  factory SoilSample.fromMap(Map<String, dynamic> map) => SoilSample(
        id: map['id'],
        fieldName: map['fieldName'],
        ph: map['ph'],
        isAI: map['isAI'],
        nitrogen: map['nitrogen'],
        phosphorus: map['phosphorus'],
        potassium: map['potassium'],
        soilType: map['soilType'],
        date: DateTime.parse(map['date']),
      );
}
