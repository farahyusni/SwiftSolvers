// lib/models/order_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_model.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  outForDelivery,
  delivered,
  cancelled,
}

enum ShippingMethod {
  delivery,
  selfPickup,
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded,
}

class DeliveryAddress {
  final String recipientName;
  final String phoneNumber;
  final String addressLine;
  final String postcode;
  final String city;
  final String state;

  DeliveryAddress({
    required this.recipientName,
    required this.phoneNumber,
    required this.addressLine,
    required this.postcode,
    required this.city,
    required this.state,
  });

  String get fullAddress {
    return '$addressLine, $postcode $city, $state';
  }

  Map<String, dynamic> toMap() {
    return {
      'recipientName': recipientName,
      'phoneNumber': phoneNumber,
      'addressLine': addressLine,
      'postcode': postcode,
      'city': city,
      'state': state,
    };
  }

  factory DeliveryAddress.fromMap(Map<String, dynamic> map) {
    return DeliveryAddress(
      recipientName: map['recipientName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      addressLine: map['addressLine'] ?? '',
      postcode: map['postcode'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
    );
  }

  DeliveryAddress copyWith({
    String? recipientName,
    String? phoneNumber,
    String? addressLine,
    String? postcode,
    String? city,
    String? state,
  }) {
    return DeliveryAddress(
      recipientName: recipientName ?? this.recipientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      addressLine: addressLine ?? this.addressLine,
      postcode: postcode ?? this.postcode,
      city: city ?? this.city,
      state: state ?? this.state,
    );
  }

  @override
  String toString() {
    return 'DeliveryAddress{recipientName: $recipientName, phoneNumber: $phoneNumber, fullAddress: $fullAddress}';
  }
}

class OrderItem {
  final String id;
  final String name;
  final String amount;
  final String unit;
  final String category;
  final String recipeId;
  final String recipeName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  OrderItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.unit,
    required this.category,
    required this.recipeId,
    required this.recipeName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItem.fromCartItem(CartItem cartItem) {
    return OrderItem(
      id: cartItem.id,
      name: cartItem.name,
      amount: cartItem.amount,
      unit: cartItem.unit,
      category: cartItem.category,
      recipeId: cartItem.recipeId,
      recipeName: cartItem.recipeName,
      quantity: cartItem.quantity,
      unitPrice: cartItem.currentPrice,
      totalPrice: cartItem.totalPrice,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'unit': unit,
      'category': category,
      'recipeId': recipeId,
      'recipeName': recipeName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      amount: map['amount'] ?? '',
      unit: map['unit'] ?? '',
      category: map['category'] ?? '',
      recipeId: map['recipeId'] ?? '',
      recipeName: map['recipeName'] ?? '',
      quantity: map['quantity'] ?? 1,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() {
    return 'OrderItem{id: $id, name: $name, quantity: $quantity, unitPrice: $unitPrice, totalPrice: $totalPrice}';
  }
}

class Order {
  final String id;
  final String userId;
  final String storeId;
  final List<OrderItem> items;
  final double subtotal;
  final double shippingFee;
  final double codFee;
  final double totalAmount;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final ShippingMethod shippingMethod;
  final DeliveryAddress? deliveryAddress;
  final String? pickupLocation;
  final DateTime createdAt;
  final DateTime? estimatedDeliveryTime;
  final DateTime? completedAt;
  final String? notes;
  final String? trackingNumber;

  Order({
    required this.id,
    required this.userId,
    required this.storeId,
    required this.items,
    required this.subtotal,
    required this.shippingFee,
    required this.codFee,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    required this.shippingMethod,
    this.deliveryAddress,
    this.pickupLocation,
    required this.createdAt,
    this.estimatedDeliveryTime,
    this.completedAt,
    this.notes,
    this.trackingNumber,
  });

  factory Order.fromCart({
    required String userId,
    required Cart cart,
    required ShippingMethod shippingMethod,
    required double shippingFee,
    required double codFee,
    DeliveryAddress? deliveryAddress,
    String? pickupLocation,
    String? notes,
  }) {
    final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';
    final orderItems = cart.items.map((cartItem) => OrderItem.fromCartItem(cartItem)).toList();
    final subtotal = cart.totalPrice;
    final totalAmount = subtotal + shippingFee + codFee;

    return Order(
      id: orderId,
      userId: userId,
      storeId: cart.selectedStore,
      items: orderItems,
      subtotal: subtotal,
      shippingFee: shippingFee,
      codFee: codFee,
      totalAmount: totalAmount,
      status: OrderStatus.pending,
      paymentStatus: PaymentStatus.pending,
      shippingMethod: shippingMethod,
      deliveryAddress: deliveryAddress,
      pickupLocation: pickupLocation,
      createdAt: DateTime.now(),
      estimatedDeliveryTime: _calculateEstimatedDelivery(shippingMethod),
      notes: notes,
    );
  }

  static DateTime _calculateEstimatedDelivery(ShippingMethod method) {
    final now = DateTime.now();
    switch (method) {
      case ShippingMethod.delivery:
        return now.add(const Duration(hours: 2)); // 2 hours for delivery
      case ShippingMethod.selfPickup:
        return now.add(const Duration(minutes: 30)); // 30 minutes for pickup
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'storeId': storeId,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'codFee': codFee,
      'totalAmount': totalAmount,
      'status': status.name,
      'paymentStatus': paymentStatus.name,
      'shippingMethod': shippingMethod.name,
      'deliveryAddress': deliveryAddress?.toMap(),
      'pickupLocation': pickupLocation,
      'createdAt': Timestamp.fromDate(createdAt),
      'estimatedDeliveryTime': estimatedDeliveryTime != null
          ? Timestamp.fromDate(estimatedDeliveryTime!)
          : null,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'notes': notes,
      'trackingNumber': trackingNumber,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      storeId: map['storeId'] ?? '',
      items: (map['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      shippingFee: (map['shippingFee'] as num?)?.toDouble() ?? 0.0,
      codFee: (map['codFee'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: OrderStatus.values.firstWhere(
            (status) => status.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
            (status) => status.name == map['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      shippingMethod: ShippingMethod.values.firstWhere(
            (method) => method.name == map['shippingMethod'],
        orElse: () => ShippingMethod.delivery,
      ),
      deliveryAddress: map['deliveryAddress'] != null
          ? DeliveryAddress.fromMap(map['deliveryAddress'] as Map<String, dynamic>)
          : null,
      pickupLocation: map['pickupLocation'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      estimatedDeliveryTime: (map['estimatedDeliveryTime'] as Timestamp?)?.toDate(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      notes: map['notes'],
      trackingNumber: map['trackingNumber'],
    );
  }

  Order copyWith({
    String? id,
    String? userId,
    String? storeId,
    List<OrderItem>? items,
    double? subtotal,
    double? shippingFee,
    double? codFee,
    double? totalAmount,
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    ShippingMethod? shippingMethod,
    DeliveryAddress? deliveryAddress,
    String? pickupLocation,
    DateTime? createdAt,
    DateTime? estimatedDeliveryTime,
    DateTime? completedAt,
    String? notes,
    String? trackingNumber,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      storeId: storeId ?? this.storeId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      shippingFee: shippingFee ?? this.shippingFee,
      codFee: codFee ?? this.codFee,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      shippingMethod: shippingMethod ?? this.shippingMethod,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      createdAt: createdAt ?? this.createdAt,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      trackingNumber: trackingNumber ?? this.trackingNumber,
    );
  }

  // Helper getters
  String get statusDisplayName {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready for ${shippingMethod == ShippingMethod.delivery ? 'Delivery' : 'Pickup'}';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return shippingMethod == ShippingMethod.delivery ? 'Delivered' : 'Picked Up';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get paymentStatusDisplayName {
    switch (paymentStatus) {
      case PaymentStatus.pending:
        return 'Pending Payment';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.failed:
        return 'Payment Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  String get shippingMethodDisplayName {
    switch (shippingMethod) {
      case ShippingMethod.delivery:
        return 'Cash on Delivery';
      case ShippingMethod.selfPickup:
        return 'Self-Pickup';
    }
  }

  bool get isActive {
    return status != OrderStatus.delivered &&
        status != OrderStatus.cancelled;
  }

  bool get canBeCancelled {
    return status == OrderStatus.pending || status == OrderStatus.confirmed;
  }

  int get totalItemCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  Map<String, List<OrderItem>> get itemsByRecipe {
    Map<String, List<OrderItem>> grouped = {};
    for (var item in items) {
      if (!grouped.containsKey(item.recipeId)) {
        grouped[item.recipeId] = [];
      }
      grouped[item.recipeId]!.add(item);
    }
    return grouped;
  }

  @override
  String toString() {
    return 'Order{id: $id, status: $status, totalAmount: $totalAmount, itemCount: ${items.length}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}