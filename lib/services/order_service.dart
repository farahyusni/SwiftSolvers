// lib/services/order_service.dart (Fixed Version)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_model.dart';
import '../models/order_model.dart' as models;

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Create order from checkout (main function for your interface)
  Future<bool> createOrderFromCheckout({
    required Cart cart,
    required models.DeliveryAddress? deliveryAddress,
    required models.ShippingMethod shippingMethod,
    required String? pickupLocation,
    required double codFee,
    required double shippingFee,
  }) async {
    try {
      print('🚀 Starting order creation process...');

      // Enhanced validation with specific error messages
      if (currentUserId == null) {
        print('❌ User not logged in');
        throw Exception('User not authenticated. Please log in again.');
      }

      if (cart.isEmpty) {
        print('❌ Cart is empty');
        throw Exception('Cart is empty. Please add items before checkout.');
      }

      // Validate delivery address for delivery method
      if (shippingMethod == models.ShippingMethod.delivery && deliveryAddress == null) {
        print('❌ Delivery address required for delivery method');
        throw Exception('Delivery address is required for delivery orders.');
      }

      // Validate pickup location for self-pickup method
      if (shippingMethod == models.ShippingMethod.selfPickup && (pickupLocation == null || pickupLocation.isEmpty)) {
        print('❌ Pickup location required for self-pickup method');
        throw Exception('Pickup location is required for self-pickup orders.');
      }

      // Generate order ID
      final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';
      print('📝 Generated order ID: $orderId');

      // Calculate totals
      final subtotal = cart.totalPrice;
      final totalAmount = subtotal + codFee + shippingFee;

      print('💰 Order totals:');
      print('   - Subtotal: RM${subtotal.toStringAsFixed(2)}');
      print('   - COD Fee: RM${codFee.toStringAsFixed(2)}');
      print('   - Shipping Fee: RM${shippingFee.toStringAsFixed(2)}');
      print('   - Total: RM${totalAmount.toStringAsFixed(2)}');

      // Convert cart items to order items with validation
      final orderItems = cart.items.map((cartItem) {
        print('📦 Processing item: ${cartItem.name}');
        return {
          'id': cartItem.id,
          'name': cartItem.name,
          'amount': cartItem.amount,
          'unit': cartItem.unit,
          'category': cartItem.category,
          'recipeId': cartItem.recipeId,
          'recipeName': cartItem.recipeName,
          'quantity': cartItem.quantity,
          'unitPrice': cartItem.currentPrice,
          'totalPrice': cartItem.totalPrice,
        };
      }).toList();

      // Create delivery address map safely
      Map<String, dynamic>? deliveryAddressMap;
      if (deliveryAddress != null) {
        deliveryAddressMap = {
          'recipientName': deliveryAddress.recipientName,
          'phoneNumber': deliveryAddress.phoneNumber,
          'addressLine': deliveryAddress.addressLine,
          'postcode': deliveryAddress.postcode,
          'city': deliveryAddress.city,
          'state': deliveryAddress.state,
        };
        print('🏠 Delivery address: ${deliveryAddress.recipientName}');
      }

      // Create order data for Firestore
      final orderData = {
        'id': orderId,
        'userId': currentUserId!,
        'storeId': cart.selectedStore ?? 'default_store',
        'items': orderItems,
        'subtotal': subtotal,
        'shippingFee': shippingFee,
        'codFee': codFee,
        'totalAmount': totalAmount,
        'shippingMethod': shippingMethod.name,
        'deliveryAddress': deliveryAddressMap,
        'pickupLocation': pickupLocation,
        'createdAt': FieldValue.serverTimestamp(),
        'estimatedDeliveryTime': _getEstimatedDeliveryTime(shippingMethod),
        'status': 'pending',
        'paymentStatus': 'pending',
        // Add additional tracking fields
        'orderNumber': orderId.substring(6), // Short order number
        'itemCount': cart.totalItems,
      };

      print('🚚 Shipping method: ${shippingMethod.name}');
      if (pickupLocation != null) {
        print('📍 Pickup location: $pickupLocation');
      }

      // Save order to Firestore with enhanced error handling
      print('💾 Saving order to Firestore...');

      // Use a batch write for better consistency
      final batch = _firestore.batch();

      // Main order document
      final orderRef = _firestore.collection('orders').doc(orderId);
      batch.set(orderRef, orderData);

      // User's order reference (for easier querying)
      final userOrderRef = _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('orders')
          .doc(orderId);

      batch.set(userOrderRef, {
        'orderId': orderId,
        'totalAmount': totalAmount,
        'status': 'pending',
        'itemCount': cart.totalItems,
        'shippingMethod': shippingMethod.name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Execute the batch
      await batch.commit();

      print('✅ Order created successfully: $orderId');
      print('📧 Order confirmation data prepared');

      return true;

    } on FirebaseException catch (e) {
      print('❌ Firebase error creating order: ${e.code} - ${e.message}');

      // Handle specific Firebase errors
      switch (e.code) {
        case 'permission-denied':
          throw Exception('Permission denied. Please check your account permissions.');
        case 'unavailable':
          throw Exception('Service temporarily unavailable. Please try again.');
        case 'deadline-exceeded':
          throw Exception('Request timeout. Please check your connection and try again.');
        default:
          throw Exception('Database error: ${e.message}');
      }
    } catch (e) {
      print('❌ General error creating order: $e');

      // Re-throw with more user-friendly message if needed
      if (e.toString().contains('Exception:')) {
        rethrow; // Re-throw our custom exceptions as-is
      } else {
        throw Exception('Unexpected error occurred. Please try again.');
      }
    }
  }

  // Enhanced error handling for user order history
  Future<List<Map<String, dynamic>>> getUserOrderHistory() async {
    try {
      if (currentUserId == null) {
        print('❌ User not logged in for order history');
        return [];
      }

      print('📋 Fetching order history for user: $currentUserId');

      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      print('📋 Found ${snapshot.docs.length} orders');

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': data['id'] ?? doc.id,
          'totalAmount': data['totalAmount'] ?? 0.0,
          'status': data['status'] ?? 'unknown',
          'createdAt': data['createdAt'],
          'itemCount': data['itemCount'] ?? (data['items'] as List?)?.length ?? 0,
          'shippingMethod': data['shippingMethod'] ?? 'delivery',
          'orderNumber': data['orderNumber'] ?? data['id']?.toString().substring(6) ?? '',
        };
      }).toList();

    } catch (e) {
      print('❌ Error getting order history: $e');
      return [];
    }
  }

  // Get order details by ID with better error handling
  Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
    try {
      print('🔍 Fetching order details for: $orderId');

      final doc = await _firestore.collection('orders').doc(orderId).get();

      if (doc.exists) {
        print('✅ Order details found');
        return doc.data() as Map<String, dynamic>;
      } else {
        print('❌ Order not found: $orderId');
        return null;
      }
    } catch (e) {
      print('❌ Error getting order details: $e');
      return null;
    }
  }

  // Helper method to calculate estimated delivery/pickup time
  Timestamp _getEstimatedDeliveryTime(models.ShippingMethod method) {
    final now = DateTime.now();
    DateTime estimatedTime;

    switch (method) {
      case models.ShippingMethod.delivery:
        estimatedTime = now.add(const Duration(hours: 2)); // 2 hours for delivery
        break;
      case models.ShippingMethod.selfPickup:
        estimatedTime = now.add(const Duration(minutes: 30)); // 30 minutes for pickup
        break;
    }

    return Timestamp.fromDate(estimatedTime);
  }

  // Get order summary for confirmation
  Map<String, dynamic> getOrderSummary({
    required Cart cart,
    required models.ShippingMethod shippingMethod,
    required double codFee,
    required double shippingFee,
  }) {
    final subtotal = cart.totalPrice;
    final total = subtotal + codFee + shippingFee;

    return {
      'itemCount': cart.totalItems,
      'subtotal': subtotal,
      'codFee': codFee,
      'shippingFee': shippingFee,
      'total': total,
      'shippingMethod': shippingMethod.name,
      'store': cart.selectedStore ?? 'default_store',
    };
  }

  // Cancel order with better error handling
  Future<bool> cancelOrder(String orderId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      print('🚫 Cancelling order: $orderId');

      // Use batch for consistency
      final batch = _firestore.batch();

      // Update main order
      final orderRef = _firestore.collection('orders').doc(orderId);
      batch.update(orderRef, {
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      // Update user's order reference
      final userOrderRef = _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('orders')
          .doc(orderId);

      batch.update(userOrderRef, {
        'status': 'cancelled',
      });

      await batch.commit();

      print('✅ Order cancelled: $orderId');
      return true;

    } catch (e) {
      print('❌ Error cancelling order: $e');
      return false;
    }
  }
}