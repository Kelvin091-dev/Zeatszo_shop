import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus { pending, confirmed, preparing, ready, completed, cancelled }

class Order {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String shopId;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? notes;
  final String? cancelReason;

  Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.shopId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.notes,
    this.cancelReason,
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Order(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      shopId: data['shopId'] ?? '',
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => OrderStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      notes: data['notes'],
      cancelReason: data['cancelReason'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'shopId': shopId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'notes': notes,
      'cancelReason': cancelReason,
    };
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 0,
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }
}
