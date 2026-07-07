import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Cart Item ──────────────────────────────────────────────────────────────

class F2BCartItem {
  final String id;
  final String productId;
  final String productName;
  final String farmerName;
  final String farmerId;
  final double price;
  final String priceUnit;
  final String? imageUrl;
  final String category;
  final int qty;
  final String userId;
  final DateTime addedAt;

  F2BCartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.farmerName,
    required this.farmerId,
    required this.price,
    required this.priceUnit,
    this.imageUrl,
    required this.category,
    required this.qty,
    required this.userId,
    required this.addedAt,
  });

  factory F2BCartItem.fromMap(Map<String, dynamic> m, String docId) =>
      F2BCartItem(
        id: docId,
        productId: m['productId'] ?? '',
        productName: m['productName'] ?? '',
        farmerName: m['farmerName'] ?? '',
        farmerId: m['farmerId'] ?? '',
        price: (m['price'] as num? ?? 0).toDouble(),
        priceUnit: m['priceUnit'] ?? '',
        imageUrl: m['imageUrl'] as String?,
        category: m['category'] ?? '',
        qty: (m['qty'] as num? ?? 1).toInt(),
        userId: m['userId'] ?? '',
        addedAt: m['addedAt'] is Timestamp
            ? (m['addedAt'] as Timestamp).toDate()
            : DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'farmerName': farmerName,
        'farmerId': farmerId,
        'price': price,
        'priceUnit': priceUnit,
        'imageUrl': imageUrl,
        'category': category,
        'qty': qty,
        'userId': userId,
        'addedAt': Timestamp.fromDate(addedAt),
      };

  F2BCartItem copyWith({int? qty}) => F2BCartItem(
        id: id,
        productId: productId,
        productName: productName,
        farmerName: farmerName,
        farmerId: farmerId,
        price: price,
        priceUnit: priceUnit,
        imageUrl: imageUrl,
        category: category,
        qty: qty ?? this.qty,
        userId: userId,
        addedAt: addedAt,
      );
}

// ─── Order Line Item ────────────────────────────────────────────────────────

class F2BOrderLineItem {
  final String productId;
  final String productName;
  final String farmerName;
  final double price;
  final String priceUnit;
  final int qty;
  final String? imageUrl;
  final String category;

  const F2BOrderLineItem({
    required this.productId,
    required this.productName,
    required this.farmerName,
    required this.price,
    required this.priceUnit,
    required this.qty,
    this.imageUrl,
    required this.category,
  });

  factory F2BOrderLineItem.fromMap(Map<String, dynamic> m) => F2BOrderLineItem(
        productId: m['productId'] ?? '',
        productName: m['productName'] ?? '',
        farmerName: m['farmerName'] ?? '',
        price: (m['price'] as num? ?? 0).toDouble(),
        priceUnit: m['priceUnit'] ?? '',
        qty: (m['qty'] as num? ?? 1).toInt(),
        imageUrl: m['imageUrl'] as String?,
        category: m['category'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'farmerName': farmerName,
        'price': price,
        'priceUnit': priceUnit,
        'qty': qty,
        'imageUrl': imageUrl,
        'category': category,
      };
}

// ─── Order ──────────────────────────────────────────────────────────────────

class F2BOrder {
  final String id;
  final String userId;
  final String userName;
  final List<F2BOrderLineItem> items;
  final double itemsTotal;
  final String status;
  final String orderType;
  final List<String> sellerUids;
  final DateTime createdAt;
  final DateTime? updatedAt;

  F2BOrder({
    required this.id,
    required this.userId,
    required this.userName,
    required this.items,
    required this.itemsTotal,
    required this.status,
    this.orderType = 'takeaway',
    this.sellerUids = const [],
    required this.createdAt,
    this.updatedAt,
  });

  static String statusLabel(String s) {
    switch (s) {
      case 'placed':    return 'Order Placed';
      case 'confirmed': return 'Seller Confirmed';
      case 'ready':     return 'Ready for Pickup';
      case 'collected': return 'Collected';
      case 'cancelled': return 'Cancelled';
      default:          return s;
    }
  }

  factory F2BOrder.fromMap(Map<String, dynamic> m, String docId) {
    final itemsList = (m['items'] as List<dynamic>? ?? [])
        .map((e) => F2BOrderLineItem.fromMap(
            Map<String, dynamic>.from(e as Map)))
        .toList();
    return F2BOrder(
      id: docId,
      userId: m['userId'] ?? '',
      userName: m['userName'] ?? '',
      items: itemsList,
      itemsTotal: (m['itemsTotal'] as num? ?? 0).toDouble(),
      status: m['status'] ?? 'placed',
      orderType: m['orderType'] as String? ?? 'takeaway',
      sellerUids: List<String>.from(m['sellerUids'] as List? ?? []),
      createdAt: m['createdAt'] is Timestamp
          ? (m['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: m['updatedAt'] is Timestamp
          ? (m['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
