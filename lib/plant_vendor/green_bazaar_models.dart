import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Cart Item ──────────────────────────────────────────────────────────────

class CartItem {
  final String id;
  final String vendorId;
  final String plantName;
  final String vendorName;
  final double price;
  final String? imageUrl;
  final String type;
  final int orderQty;
  final String userId;
  final DateTime addedAt;

  CartItem({
    required this.id,
    required this.vendorId,
    required this.plantName,
    required this.vendorName,
    required this.price,
    this.imageUrl,
    required this.type,
    required this.orderQty,
    required this.userId,
    required this.addedAt,
  });

  factory CartItem.fromMap(Map<String, dynamic> m, String docId) => CartItem(
        id: docId,
        vendorId: m['vendorId'] ?? '',
        plantName: m['plantName'] ?? '',
        vendorName: m['vendorName'] ?? '',
        price: (m['price'] as num? ?? 0).toDouble(),
        imageUrl: m['imageUrl'] as String?,
        type: m['type'] ?? '',
        orderQty: (m['orderQty'] as num? ?? 1).toInt(),
        userId: m['userId'] ?? '',
        addedAt: m['addedAt'] is Timestamp
            ? (m['addedAt'] as Timestamp).toDate()
            : DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'vendorId': vendorId,
        'plantName': plantName,
        'vendorName': vendorName,
        'price': price,
        'imageUrl': imageUrl,
        'type': type,
        'orderQty': orderQty,
        'userId': userId,
        'addedAt': Timestamp.fromDate(addedAt),
      };

  CartItem copyWith({int? orderQty}) => CartItem(
        id: id,
        vendorId: vendorId,
        plantName: plantName,
        vendorName: vendorName,
        price: price,
        imageUrl: imageUrl,
        type: type,
        orderQty: orderQty ?? this.orderQty,
        userId: userId,
        addedAt: addedAt,
      );
}

// ─── Wishlist Item ──────────────────────────────────────────────────────────

class WishlistItem {
  final String id;
  final String vendorId;
  final String plantName;
  final String vendorName;
  final double price;
  final String? imageUrl;
  final String type;
  final String userId;
  final DateTime savedAt;

  WishlistItem({
    required this.id,
    required this.vendorId,
    required this.plantName,
    required this.vendorName,
    required this.price,
    this.imageUrl,
    required this.type,
    required this.userId,
    required this.savedAt,
  });

  factory WishlistItem.fromMap(Map<String, dynamic> m, String docId) =>
      WishlistItem(
        id: docId,
        vendorId: m['vendorId'] ?? '',
        plantName: m['plantName'] ?? '',
        vendorName: m['vendorName'] ?? '',
        price: (m['price'] as num? ?? 0).toDouble(),
        imageUrl: m['imageUrl'] as String?,
        type: m['type'] ?? '',
        userId: m['userId'] ?? '',
        savedAt: m['savedAt'] is Timestamp
            ? (m['savedAt'] as Timestamp).toDate()
            : DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'vendorId': vendorId,
        'plantName': plantName,
        'vendorName': vendorName,
        'price': price,
        'imageUrl': imageUrl,
        'type': type,
        'userId': userId,
        'savedAt': Timestamp.fromDate(savedAt),
      };
}

// ─── Delivery Address ───────────────────────────────────────────────────────

class DeliveryAddress {
  final String name;
  final String phone;
  final String addressLine;
  final String city;
  final String state;
  final String pincode;

  const DeliveryAddress({
    required this.name,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.pincode,
  });

  factory DeliveryAddress.fromMap(Map<String, dynamic> m) => DeliveryAddress(
        name: m['name'] ?? '',
        phone: m['phone'] ?? '',
        addressLine: m['addressLine'] ?? '',
        city: m['city'] ?? '',
        state: m['state'] ?? '',
        pincode: m['pincode'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'addressLine': addressLine,
        'city': city,
        'state': state,
        'pincode': pincode,
      };

  String get formatted => '$addressLine, $city, $state - $pincode';
}

// ─── Order Line Item ────────────────────────────────────────────────────────

class OrderLineItem {
  final String vendorId;
  final String plantName;
  final String vendorName;
  final double price;
  final int quantity;
  final String? imageUrl;
  final String type;

  const OrderLineItem({
    required this.vendorId,
    required this.plantName,
    required this.vendorName,
    required this.price,
    required this.quantity,
    this.imageUrl,
    required this.type,
  });

  factory OrderLineItem.fromMap(Map<String, dynamic> m) => OrderLineItem(
        vendorId: m['vendorId'] ?? '',
        plantName: m['plantName'] ?? '',
        vendorName: m['vendorName'] ?? '',
        price: (m['price'] as num? ?? 0).toDouble(),
        quantity: (m['quantity'] as num? ?? 1).toInt(),
        imageUrl: m['imageUrl'] as String?,
        type: m['type'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'vendorId': vendorId,
        'plantName': plantName,
        'vendorName': vendorName,
        'price': price,
        'quantity': quantity,
        'imageUrl': imageUrl,
        'type': type,
      };
}

// ─── Plant Order ────────────────────────────────────────────────────────────

class PlantOrder {
  final String id;
  final String userId;
  final String userName;
  final List<OrderLineItem> items;
  final double itemsTotal;
  final double deliveryCharge;
  final String paymentMethod;
  final DeliveryAddress? address;
  final String status;
  final String orderType; // 'takeaway' | 'delivery'
  final List<String> sellerUids;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PlantOrder({
    required this.id,
    required this.userId,
    required this.userName,
    required this.items,
    required this.itemsTotal,
    required this.deliveryCharge,
    required this.paymentMethod,
    this.address,
    required this.status,
    this.orderType = 'takeaway',
    this.sellerUids = const [],
    required this.createdAt,
    this.updatedAt,
  });

  double get grandTotal => itemsTotal + deliveryCharge;

  bool get isTakeaway => orderType == 'takeaway';

  static List<String> statusStepsForType(String type) => type == 'takeaway'
      ? ['placed', 'confirmed', 'ready', 'collected']
      : ['placed', 'confirmed', 'packed', 'out_for_delivery', 'delivered'];

  static String statusLabel(String s) {
    switch (s) {
      case 'placed':        return 'Order Placed';
      case 'confirmed':     return 'Seller Confirmed';
      case 'ready':         return 'Ready for Pickup';
      case 'collected':     return 'Collected';
      case 'packed':        return 'Packed';
      case 'out_for_delivery': return 'Out for Delivery';
      case 'delivered':     return 'Delivered';
      case 'cancelled':     return 'Cancelled';
      default:              return s;
    }
  }

  factory PlantOrder.fromMap(Map<String, dynamic> m, String docId) {
    final itemsList = (m['items'] as List<dynamic>? ?? [])
        .map((e) => OrderLineItem.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    final addressMap = m['address'] as Map?;

    return PlantOrder(
      id: docId,
      userId: m['userId'] ?? '',
      userName: m['userName'] ?? '',
      items: itemsList,
      itemsTotal: (m['itemsTotal'] as num? ?? 0).toDouble(),
      deliveryCharge: (m['deliveryCharge'] as num? ?? 0).toDouble(),
      paymentMethod: m['paymentMethod'] ?? 'cash_on_pickup',
      address: addressMap != null
          ? DeliveryAddress.fromMap(Map<String, dynamic>.from(addressMap))
          : null,
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

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'items': items.map((e) => e.toMap()).toList(),
        'itemsTotal': itemsTotal,
        'deliveryCharge': deliveryCharge,
        'paymentMethod': paymentMethod,
        if (address != null) 'address': address!.toMap(),
        'status': status,
        'orderType': orderType,
        'sellerUids': sellerUids,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt':
            updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };
}
