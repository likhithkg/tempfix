class ExportProduct {
  final String id;
  final String farmerId;
  final String farmerName;
  final String productName;
  final String category;
  final String quantity; // keep string for flexible units ("1200 kg" or "1.2 ton")
  final String pricePerUnit;
  final String location;
  final String description;
  final String imageUrl;
  final DateTime createdAt;

  ExportProduct({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.productName,
    required this.category,
    required this.quantity,
    required this.pricePerUnit,
    required this.location,
    required this.description,
    required this.imageUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'productName': productName,
      'category': category,
      'quantity': quantity,
      'pricePerUnit': pricePerUnit,
      'location': location,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ExportProduct.fromMap(Map<String, dynamic> map) {
    return ExportProduct(
      id: map['id'] ?? '',
      farmerId: map['farmerId'] ?? '',
      farmerName: map['farmerName'] ?? '',
      productName: map['productName'] ?? '',
      category: map['category'] ?? '',
      quantity: map['quantity'] ?? '',
      pricePerUnit: map['pricePerUnit'] ?? '',
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
