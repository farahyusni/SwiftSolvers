// lib/services/order_service.dart (COMPLETE FIXED VERSION)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_model.dart';
import '../models/order_model.dart' as models;
import '../services/order_notification_bridge.dart';
import '../services/notification_service.dart';
import '../models/notification_models.dart';
import '../services/inventory_service.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final OrderNotificationBridge _notificationBridge = OrderNotificationBridge();
  final InventoryService _inventoryService = InventoryService();

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // ============ BUYER FUNCTIONALITY ============

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
      if (shippingMethod == models.ShippingMethod.delivery &&
          deliveryAddress == null) {
        print('❌ Delivery address required for delivery method');
        throw Exception('Delivery address is required for delivery orders.');
      }

      // Validate pickup location for self-pickup method
      if (shippingMethod == models.ShippingMethod.selfPickup &&
          (pickupLocation == null || pickupLocation.isEmpty)) {
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
      final orderItems =
          cart.items.map((cartItem) {
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

      // *** CRITICAL: Determine sellerId for seller connection ***
      String sellerId = await _determineSellerId(cart);
      print('🏪 Order will be assigned to seller: $sellerId');

      // ⚠️ CRITICAL FIX: Add timestamp and flags to prevent duplicate notifications
      final now = DateTime.now();
      final orderData = {
        'id': orderId,
        'userId': currentUserId!,
        'sellerId':
            sellerId, // *** THIS IS THE KEY CONNECTION FOR SELLER DASHBOARD ***
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
        'status': 'pending', // ⚠️ CRITICAL: MUST start as pending
        'paymentStatus': 'pending',
        // ⚠️ NEW: Add metadata to prevent duplicate notifications
        'isNewOrder': true, // Flag to identify genuinely new orders
        'statusLastUpdated': FieldValue.serverTimestamp(),
        'createdByUser': currentUserId!, // Track who created the order
        // Add additional tracking fields
        'orderNumber': orderId.substring(6), // Short order number
        'itemCount': cart.totalItems,
      };

      print('📋 Order data prepared with status: ${orderData['status']}');
      print('🚚 Shipping method: ${shippingMethod.name}');
      if (pickupLocation != null) {
        print('📍 Pickup location: $pickupLocation');
      }

      // Save order to Firestore with enhanced error handling
      print('💾 Saving order to Firestore...');

      // Use a batch write for better consistency
      final batch = _firestore.batch();

      // Main order document (for seller to see)
      final orderRef = _firestore.collection('orders').doc(orderId);
      batch.set(orderRef, orderData);

      // User's order reference (for buyer order history)
      final userOrderRef = _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('orders')
          .doc(orderId);

      batch.set(userOrderRef, {
        'orderId': orderId,
        'sellerId': sellerId,
        'totalAmount': totalAmount,
        'status': 'pending', // ⚠️ ALSO KEEP pending here
        'itemCount': cart.totalItems,
        'shippingMethod': shippingMethod.name,
        'createdAt': FieldValue.serverTimestamp(),
        'isNewOrder': true, // ⚠️ Flag for new orders
      });

      // Execute the batch
      await batch.commit();

      print('✅ Order created successfully: $orderId');

      // 📦 REDUCE STOCK QUANTITIES FOR ORDERED ITEMS
      print('📦 Reducing stock for ordered items...');
      await _reduceStockForOrder(cart.items);

      // ⚠️ CRITICAL FIX: Only send "Order Placed" notification, NOT status update
      print('🔔 Sending ONLY order placed notification to buyer...');
      _notificationBridge.createOrderPlacedNotification(orderId, orderData);

      // ⚠️ DO NOT send any status update notification here
      // ⚠️ Status updates should only happen when seller manually changes status

      print('📧 Order confirmation data prepared - NO automatic status change');

      return true;
    } on FirebaseException catch (e) {
      print('❌ Firebase error creating order: ${e.code} - ${e.message}');

      // Handle specific Firebase errors
      switch (e.code) {
        case 'permission-denied':
          throw Exception(
            'Permission denied. Please check your account permissions.',
          );
        case 'unavailable':
          throw Exception('Service temporarily unavailable. Please try again.');
        case 'deadline-exceeded':
          throw Exception(
            'Request timeout. Please check your connection and try again.',
          );
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

  // Helper method to determine seller ID
  Future<String> _determineSellerId(Cart cart) async {
    try {
      // Method 1: Use the first available seller from stock items
      if (cart.items.isNotEmpty) {
        final firstItem = cart.items.first;

        // Try to find the seller of this item from stocks collection
        final stockQuery =
            await _firestore
                .collection('stocks')
                .where('name', isEqualTo: firstItem.name)
                .limit(1)
                .get();

        if (stockQuery.docs.isNotEmpty) {
          final stockData = stockQuery.docs.first.data();
          final sellerId =
              stockData['sellerId'] ??
              stockData['userId'] ??
              stockData['createdBy'];
          if (sellerId != null) {
            print('📍 Found seller ID from stock: $sellerId');
            return sellerId;
          }
        }

        // Method 2: Try to find from recipes collection
        final recipeQuery =
            await _firestore
                .collection('recipes')
                .where('name', isEqualTo: firstItem.recipeName)
                .limit(1)
                .get();

        if (recipeQuery.docs.isNotEmpty) {
          final recipeData = recipeQuery.docs.first.data();
          final sellerId = recipeData['createdBy'] ?? recipeData['userId'];
          if (sellerId != null) {
            print('📍 Found seller ID from recipe: $sellerId');
            return sellerId;
          }
        }
      }

      // Method 3: Find any available seller (for demo purposes)
      final sellersQuery =
          await _firestore
              .collection('users')
              .where('userType', isEqualTo: 'seller')
              .limit(1)
              .get();

      if (sellersQuery.docs.isNotEmpty) {
        final sellerId = sellersQuery.docs.first.id;
        print('📍 Using available seller: $sellerId');
        return sellerId;
      }

      // Method 4: Fall back to default seller
      print('⚠️ Using default seller - consider implementing store selection');
      return 'default_seller_id';
    } catch (e) {
      print('❌ Error determining seller ID: $e');
      return 'default_seller_id';
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

      // Fetch from main orders collection instead of user subcollection
      final snapshot =
          await _firestore
              .collection('orders') // Main collection
              .where('userId', isEqualTo: currentUserId) // Filter by user
              .orderBy('createdAt', descending: true)
              .limit(20)
              .get();

      print('📋 Found ${snapshot.docs.length} orders');

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': data['orderId'] ?? doc.id,
          'totalAmount': data['totalAmount'] ?? 0.0,
          'status': data['status'] ?? 'unknown',
          'createdAt': data['createdAt'],
          'itemCount': data['itemCount'] ?? 0,
          'shippingMethod': data['shippingMethod'] ?? 'delivery',
          'orderNumber':
              data['orderNumber'] ??
              data['orderId']?.toString().substring(6) ??
              '',
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
        'statusLastUpdated':
            FieldValue.serverTimestamp(), // ⚠️ Track when status changed
      });

      // Update user's order reference
      final userOrderRef = _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('orders')
          .doc(orderId);

      batch.update(userOrderRef, {'status': 'cancelled'});

      await batch.commit();

      print('✅ Order cancelled: $orderId');
      return true;
    } catch (e) {
      print('❌ Error cancelling order: $e');
      return false;
    }
  }

  // ============ SELLER FUNCTIONALITY ============

  // Get seller orders stream - *** THIS IS THE KEY METHOD FOR SELLER DASHBOARD ***
  Stream<QuerySnapshot> getSellerOrdersStream([String? status]) {
    if (currentUserId == null) {
      return const Stream.empty();
    }

    print('📊 Fetching ${status ?? 'all'} orders for seller: $currentUserId');

    Query query = _firestore
        .collection('orders')
        .where(
          'sellerId',
          isEqualTo: currentUserId,
        ); // Filter by current seller's ID

    // Add status filter if provided
    if (status != null && status != 'all' && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }

    return query.orderBy('createdAt', descending: true).snapshots();
  }

  // ⚠️ FIXED: Update order status (seller action) - WITH PROPER NOTIFICATIONS
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      if (currentUserId == null) {
        throw Exception('Seller not authenticated');
      }

      print('🔄 SELLER updating order $orderId to status: $newStatus');

      // First verify that this order belongs to the current seller
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final orderData = orderDoc.data();
      final orderSellerId = orderData?['sellerId'];

      if (orderSellerId != currentUserId) {
        throw Exception('You can only update your own orders');
      }

      // ⚠️ CRITICAL: Check if this is actually a status change
      final currentStatus = orderData?['status'];
      if (currentStatus == newStatus) {
        print('⚠️ Status is already $newStatus, no update needed');
        return true; // No need to update if status is the same
      }

      // Prepare update data
      Map<String, dynamic> updateData = {
        'status': newStatus,
        'statusLastUpdated':
            FieldValue.serverTimestamp(), // ⚠️ Track when changed
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': currentUserId, // Track who made the change
      };

      // Add completion timestamp for delivered orders
      if (newStatus == 'delivered') {
        updateData['completedAt'] = FieldValue.serverTimestamp();
        updateData['paymentStatus'] = 'paid'; // Mark as paid when delivered
      } else if (newStatus == 'confirmed') {
        updateData['confirmedAt'] = FieldValue.serverTimestamp();
        updateData['confirmedBy'] = currentUserId;
      }

      // Use batch for consistency
      final batch = _firestore.batch();

      // Update main order
      final orderRef = _firestore.collection('orders').doc(orderId);
      batch.update(orderRef, updateData);

      // Also update the user's order reference
      final userId = orderData?['userId'];
      if (userId != null) {
        final userOrderRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('orders')
            .doc(orderId);

        batch.update(userOrderRef, {
          'status': newStatus,
          'statusLastUpdated': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // ⚠️ CRITICAL: Only send notification for ACTUAL status changes by seller
      if (userId != null && currentStatus != newStatus) {
        print('🔔 Creating status update notification for buyer: $userId');
        print('🔔 Status changed from: $currentStatus -> $newStatus');

        final updatedOrderData = Map<String, dynamic>.from(orderData!);
        updatedOrderData['status'] = newStatus;
        updatedOrderData['statusLastUpdated'] = Timestamp.now();

        // Use the public method from notification bridge
        _notificationBridge.createStatusUpdateNotificationForBuyer(
          orderId,
          newStatus,
          updatedOrderData,
        );
      } else {
        print(
          '🚫 No notification sent - no actual status change or no user ID',
        );
      }

      print(
        '✅ Order status updated successfully from $currentStatus to $newStatus',
      );
      return true;
    } catch (e) {
      print('❌ Error updating order status: $e');
      return false;
    }
  }

  // Delete/Reject order (seller action) - WITH NOTIFICATIONS
  Future<bool> rejectOrder(String orderId) async {
    try {
      if (currentUserId == null) {
        throw Exception('Seller not authenticated');
      }

      print('🗑️ Rejecting order: $orderId');

      // First verify that this order belongs to the current seller
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final orderData = orderDoc.data();
      final orderSellerId = orderData?['sellerId'];

      if (orderSellerId != currentUserId) {
        throw Exception('You can only reject your own orders');
      }

      // Use batch for consistency
      final batch = _firestore.batch();

      // Update order status to rejected instead of deleting
      batch.update(_firestore.collection('orders').doc(orderId), {
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'statusLastUpdated': FieldValue.serverTimestamp(),
        'rejectedBy': currentUserId,
      });

      // Update user's order reference
      final userId = orderData?['userId'];
      if (userId != null) {
        batch.update(
          _firestore
              .collection('users')
              .doc(userId)
              .collection('orders')
              .doc(orderId),
          {
            'status': 'rejected',
            'rejectedAt': FieldValue.serverTimestamp(),
            'statusLastUpdated': FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();

      // 🔔 SEND REJECTION NOTIFICATION TO BUYER
      if (userId != null) {
        print('🔔 Creating rejection notification for buyer: $userId');
        final updatedOrderData = Map<String, dynamic>.from(orderData!);
        updatedOrderData['status'] = 'rejected';
        updatedOrderData['statusLastUpdated'] = Timestamp.now();

        // Use the public method from notification bridge
        _notificationBridge.createStatusUpdateNotificationForBuyer(
          orderId,
          'rejected',
          updatedOrderData,
        );
      }

      print('✅ Order rejected successfully');
      return true;
    } catch (e) {
      print('❌ Error rejecting order: $e');
      return false;
    }
  }

  // Get seller statistics for dashboard
  Future<Map<String, dynamic>> getSellerOrderStatistics() async {
    try {
      if (currentUserId == null) {
        return {
          'total': 0,
          'pending': 0,
          'processing': 0,
          'ready': 0,
          'delivered': 0,
          'cancelled': 0,
          'totalSales': 0.0,
          'todaySales': 0.0,
          'monthSales': 0.0,
          'todayOrders': 0,
          'monthOrders': 0,
        };
      }

      final snapshot =
          await _firestore
              .collection('orders')
              .where('sellerId', isEqualTo: currentUserId)
              .get();

      Map<String, dynamic> stats = {
        'total': snapshot.docs.length,
        'pending': 0,
        'processing': 0,
        'ready': 0,
        'delivered': 0,
        'cancelled': 0,
        'rejected': 0,
        'totalSales': 0.0,
        'todaySales': 0.0,
        'monthSales': 0.0,
        'todayOrders': 0,
        'monthOrders': 0,
      };

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startOfMonth = DateTime(now.year, now.month, 1);

      // ADD DEBUG: Print all orders and their statuses
      print('📊 DEBUG: Processing ${snapshot.docs.length} orders for seller statistics');

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'pending';
        final totalAmount = (data['totalAmount'] ?? 0.0).toDouble();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

        // ADD DEBUG: Print each order
        print('📊 Order ${doc.id}: status = "$status"');

        // Count by status
        if (stats.containsKey(status)) {
          stats[status] = (stats[status] ?? 0) + 1;
          print('📊 Updated $status count to: ${stats[status]}');
        } else {
          print('📊 WARNING: Unknown status "$status" - adding to stats');
          stats[status] = 1; // Add unknown statuses
        }

        // Calculate sales for paid/delivered orders
        if (status == 'delivered' || data['paymentStatus'] == 'paid') {
          stats['totalSales'] = (stats['totalSales'] ?? 0.0) + totalAmount;

          if (createdAt != null) {
            // Today's sales
            if (createdAt.isAfter(today)) {
              stats['todaySales'] = (stats['todaySales'] ?? 0.0) + totalAmount;
              stats['todayOrders'] = (stats['todayOrders'] ?? 0) + 1;
            }

            // Month's sales
            if (createdAt.isAfter(startOfMonth)) {
              stats['monthSales'] = (stats['monthSales'] ?? 0.0) + totalAmount;
              stats['monthOrders'] = (stats['monthOrders'] ?? 0) + 1;
            }
          }
        }
      }

      // ADD DEBUG: Print final stats
      print('📊 Final stats: $stats');

      return stats;
    } catch (e) {
      print('❌ Error getting order statistics: $e');
      return {
        'total': 0,
        'pending': 0,
        'processing': 0,
        'ready': 0,
        'delivered': 0,
        'cancelled': 0,
        'totalSales': 0.0,
        'todaySales': 0.0,
        'monthSales': 0.0,
        'todayOrders': 0,
        'monthOrders': 0,
      };
    }
  }

  // Get total sales for seller (enhanced method)
  Future<double> getSellerTotalSales() async {
    try {
      if (currentUserId == null) return 0.0;

      final snapshot =
          await _firestore
              .collection('orders')
              .where('sellerId', isEqualTo: currentUserId)
              .where('status', isEqualTo: 'delivered')
              .get();

      double totalSales = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalSales += (data['totalAmount'] ?? 0.0).toDouble();
      }

      return totalSales;
    } catch (e) {
      print('❌ Error calculating total sales: $e');
      return 0.0;
    }
  }

  // ============ HELPER METHODS ============

  // Helper method to calculate estimated delivery/pickup time
  Timestamp _getEstimatedDeliveryTime(models.ShippingMethod method) {
    final now = DateTime.now();
    DateTime estimatedTime;

    switch (method) {
      case models.ShippingMethod.delivery:
        estimatedTime = now.add(
          const Duration(hours: 2),
        ); // 2 hours for delivery
        break;
      case models.ShippingMethod.selfPickup:
        estimatedTime = now.add(
          const Duration(minutes: 30),
        ); // 30 minutes for pickup
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
    };
  }

  // 📦 NEW METHOD: Reduce stock for ordered items using recipe stock links
  Future<void> _reduceStockForOrder(List<CartItem> cartItems) async {
    try {
      print('📦 Starting stock reduction for ${cartItems.length} items...');

      for (final cartItem in cartItems) {
        print(
          '📦 Processing ingredient: ${cartItem.name} (quantity: ${cartItem.quantity})',
        );

        // Step 1: Get the original recipe ingredient data to find linkedStockId
        String? linkedStockId;

        try {
          // Find the recipe and get the ingredient with stock link
          final recipeQuery =
              await _firestore
                  .collection('recipes')
                  .doc(cartItem.recipeId)
                  .get();

          if (recipeQuery.exists) {
            final recipeData = recipeQuery.data();
            final ingredients =
                recipeData?['ingredients'] as List<dynamic>? ?? [];

            // Find the matching ingredient by name
            for (final ingredient in ingredients) {
              if (ingredient['name'] == cartItem.name) {
                linkedStockId = ingredient['linkedStockId'];
                print(
                  '📦 Found linked stock ID: $linkedStockId for ${cartItem.name}',
                );
                break;
              }
            }
          }
        } catch (e) {
          print('⚠️ Error finding recipe data: $e');
        }

        // Step 2: Reduce stock using the linkedStockId
        if (linkedStockId != null && linkedStockId.isNotEmpty) {
          try {
            // Get current stock
            final stockDoc =
                await _firestore.collection('stocks').doc(linkedStockId).get();

            if (stockDoc.exists) {
              final stockData = stockDoc.data()!;
              final currentStock = stockData['stock'] ?? 0;
              final newStock = currentStock - cartItem.quantity;
              final stockName = stockData['name'] ?? 'Unknown';

              print('📦 ${stockName}: $currentStock → $newStock');

              if (newStock >= 0) {
                // Update stock directly in Firestore
                await _firestore.collection('stocks').doc(linkedStockId).update(
                  {
                    'stock': newStock,
                    'updatedAt': FieldValue.serverTimestamp(),
                    'isLowStock':
                        newStock <= 10, // Auto-mark as low stock if <= 10
                  },
                );
                print('✅ Stock updated for ${stockName}');
              } else {
                print(
                  '⚠️ Warning: ${stockName} would have negative stock ($newStock)',
                );
                // Still allow the order but set stock to 0
                await _firestore.collection('stocks').doc(linkedStockId).update(
                  {
                    'stock': 0,
                    'updatedAt': FieldValue.serverTimestamp(),
                    'isLowStock': true, // Mark as low stock when it reaches 0
                  },
                );
                print('⚠️ Set stock to 0 for ${stockName}');
              }
            } else {
              print('❌ Stock document not found for ID: $linkedStockId');
            }
          } catch (e) {
            print('❌ Error updating stock for $linkedStockId: $e');
          }
        } else {
          print('⚠️ No linked stock ID found for ingredient: ${cartItem.name}');
          print(
            '💡 Seller needs to link this ingredient to stock in recipe editor',
          );
        }
      }

      print('✅ Stock reduction completed successfully');
    } catch (e) {
      print('❌ Error reducing stock: $e');
      // Don't throw error here as the order was already created successfully
    }
  }

  // Get order tracking information with real-time updates
  Stream<Map<String, dynamic>?> getOrderTrackingStream(String orderId) {
    return _firestore.collection('orders').doc(orderId).snapshots().map((doc) {
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    });
  }

  // Get order summary for quick display
  Future<Map<String, int>> getOrderStatusSummary() async {
    try {
      if (currentUserId == null) {
        return {
          'pending': 0,
          'confirmed': 0,
          'preparing': 0,
          'outForDelivery': 0,
          'delivered': 0,
          'cancelled': 0,
        };
      }

      final snapshot =
          await _firestore
              .collection('orders')
              .where('userId', isEqualTo: currentUserId)
              .get();

      Map<String, int> summary = {
        'pending': 0,
        'confirmed': 0,
        'preparing': 0,
        'outForDelivery': 0,
        'delivered': 0,
        'cancelled': 0,
      };

      for (var doc in snapshot.docs) {
        final status = doc.data()['status'] ?? 'pending';
        if (summary.containsKey(status)) {
          summary[status] = summary[status]! + 1;
        }
      }

      return summary;
    } catch (e) {
      print('❌ Error getting order summary: $e');
      return {
        'pending': 0,
        'confirmed': 0,
        'preparing': 0,
        'outForDelivery': 0,
        'delivered': 0,
        'cancelled': 0,
      };
    }
  }

  // Mark order as reviewed
  Future<bool> markOrderAsReviewed(
    String orderId,
    double rating,
    String review,
  ) async {
    try {
      print('⭐ Adding review for order: $orderId');

      await _firestore.collection('orders').doc(orderId).update({
        'rating': rating,
        'review': review,
        'reviewedAt': FieldValue.serverTimestamp(),
        'isReviewed': true,
      });

      print('✅ Review added successfully');
      return true;
    } catch (e) {
      print('❌ Error adding review: $e');
      return false;
    }
  }

  // Generate tracking number for order
  String generateTrackingNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'YC$random';
  }

  // Add tracking number to existing order
  Future<bool> addTrackingNumber(String orderId) async {
    try {
      final trackingNumber = generateTrackingNumber();

      await _firestore.collection('orders').doc(orderId).update({
        'trackingNumber': trackingNumber,
        'trackingAddedAt': FieldValue.serverTimestamp(),
      });

      print('📦 Tracking number added: $trackingNumber');
      return true;
    } catch (e) {
      print('❌ Error adding tracking number: $e');
      return false;
    }
  }

  // Get estimated delivery time based on shipping method
  DateTime getEstimatedDeliveryTime(String shippingMethod) {
    final now = DateTime.now();

    switch (shippingMethod) {
      case 'delivery':
        return now.add(const Duration(hours: 2, minutes: 30));
      case 'selfPickup':
        return now.add(const Duration(minutes: 45));
      default:
        return now.add(const Duration(hours: 3));
    }
  }

  // Check if order can be cancelled
  bool canCancelOrder(String status) {
    return ['pending', 'confirmed'].contains(status);
  }

  // Check if order can be modified
  bool canModifyOrder(String status) {
    return status == 'pending';
  }

  // Get user's recent orders (last 5)
  Future<List<Map<String, dynamic>>> getRecentOrders() async {
    try {
      if (currentUserId == null) return [];

      final snapshot =
          await _firestore
              .collection('orders')
              .where('userId', isEqualTo: currentUserId)
              .orderBy('createdAt', descending: true)
              .limit(5)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': data['id'] ?? doc.id,
          'totalAmount': data['totalAmount'] ?? 0.0,
          'status': data['status'] ?? 'pending',
          'createdAt': data['createdAt'],
          'itemCount': data['itemCount'] ?? 0,
        };
      }).toList();
    } catch (e) {
      print('❌ Error getting recent orders: $e');
      return [];
    }
  }
}