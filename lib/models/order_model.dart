import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,
  preparing,
  ready,
  completed,
  cancelled,
}

class OrderItem {
  final String itemId;
  final String itemName;
  final double price;
  final int quantity;

  OrderItem({
    required this.itemId,
    required this.itemName,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'price': price,
      'quantity': quantity,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
    );
  }
}

class OrderModel {
  final String orderId;
  final String userId;
  final String userName;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final DateTime orderDate;
  final int? counterNumber;
  final String? specialInstructions;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.userName,
    required this.items,
    required this.totalAmount,
    this.status = OrderStatus.pending,
    DateTime? orderDate,
    this.counterNumber,
    this.specialInstructions,
  }) : orderDate = orderDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'userName': userName,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status.name,
      'orderDate': Timestamp.fromDate(orderDate),
      'counterNumber': counterNumber,
      'specialInstructions': specialInstructions,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      orderId: map['orderId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      orderDate: (map['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      counterNumber: map['counterNumber'],
      specialInstructions: map['specialInstructions'],
    );
  }

  String getStatusText() {
    switch (status) {
      case OrderStatus.pending:
        return 'Order Placed';
      case OrderStatus.preparing:
        return 'Preparing Your Food';
      case OrderStatus.ready:
        return 'Ready for Pickup';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  OrderModel copyWith({
    String? orderId,
    String? userId,
    String? userName,
    List<OrderItem>? items,
    double? totalAmount,
    OrderStatus? status,
    DateTime? orderDate,
    int? counterNumber,
    String? specialInstructions,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      orderDate: orderDate ?? this.orderDate,
      counterNumber: counterNumber ?? this.counterNumber,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }
}