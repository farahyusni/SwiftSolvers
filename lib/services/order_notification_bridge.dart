// lib/services/order_notification_bridge.dart (COMPLETE - NO SYNTAX ERRORS)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
import '../models/notification_models.dart';
import 'dart:async';

class OrderNotificationBridge {
  static final OrderNotificationBridge _instance = OrderNotificationBridge._internal();
  factory OrderNotificationBridge() => _instance;
  OrderNotificationBridge._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  String? get currentUserId => _auth.currentUser?.uid;

  StreamSubscription<QuerySnapshot>? _sellerOrderSubscription;
  StreamSubscription<QuerySnapshot>? _buyerOrderSubscription;

  // Track processed orders to avoid duplicates
  final Set<String> _processedOrders = {};

  // Track last processed timestamp to avoid old orders
  DateTime? _lastProcessedTime;

  // Initialize notification listeners
  void startListening({required bool isSeller}) {
    stopListening(); // Stop any existing listeners

    if (currentUserId == null) {
      print('❌ Cannot start notification listeners: No current user');
      return;
    }

    // Set the initial timestamp filter to NOW (avoid processing old orders)
    _lastProcessedTime = DateTime.now().subtract(const Duration(minutes: 1));
    print('🕐 Setting timestamp filter: $_lastProcessedTime');

    if (isSeller) {
      _startSellerNotifications();
    } else {
      _startBuyerNotifications();
    }
  }

  void stopListening() {
    _sellerOrderSubscription?.cancel();
    _buyerOrderSubscription?.cancel();
    _processedOrders.clear();
    _lastProcessedTime = null;
    print('🛑 Stopped notification listeners');
  }

  // 🔔 FIXED: Listen for new orders for sellers ONLY (with timestamp filter)
  void _startSellerNotifications() {
    print('🔔 Starting SELLER notification listener for: $currentUserId');

    _sellerOrderSubscription = _firestore
        .collection('orders')
        .where('sellerId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(_lastProcessedTime!))
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        final orderData = change.doc.data() as Map<String, dynamic>?;
        if (orderData == null) continue;

        // ONLY create notification for newly ADDED pending orders
        if (change.type == DocumentChangeType.added) {
          final orderId = change.doc.id;
          final createdAt = (orderData['createdAt'] as Timestamp?)?.toDate();
          final isNewOrder = orderData['isNewOrder'] as bool? ?? false;
          final createdByUser = orderData['createdByUser'] as String?;

          print('🔍 Seller - New order detected: $orderId');
          print('🔍 Created by: $createdByUser, Is new order: $isNewOrder');

          // ⚠️ CRITICAL: Only process genuinely new orders
          if (isNewOrder != true) {
            print('🚫 Skipping - not marked as new order');
            continue;
          }

          if (createdByUser == currentUserId) {
            print('🚫 Skipping - seller created their own order');
            continue;
          }

          // Double-check timestamp to ensure it's truly new
          if (createdAt != null &&
              _lastProcessedTime != null &&
              createdAt.isAfter(_lastProcessedTime!)) {

            // Avoid duplicate notifications
            if (!_processedOrders.contains(orderId)) {
              _processedOrders.add(orderId);
              _createNewOrderNotificationForSeller(orderId, orderData);
              print('✅ New order notification sent for: $orderId at ${createdAt}');
            } else {
              print('⚠️ Skipped duplicate order: $orderId');
            }
          } else {
            print('⏰ Skipped old order: $orderId (created: $createdAt)');
          }
        }
      }
    }, onError: (error) {
      print('❌ Error in seller notification listener: $error');
    });
  }

  // 🔔 FIXED: Listen for order status changes for buyers ONLY (with better filtering)
  void _startBuyerNotifications() {
    print('🔔 Starting BUYER notification listener for: $currentUserId');

    _buyerOrderSubscription = _firestore
        .collection('orders')
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        final orderData = change.doc.data() as Map<String, dynamic>?;
        if (orderData == null) continue;

        // 🚨 ONLY listen for MODIFIED documents (status changes)
        if (change.type == DocumentChangeType.modified) {
          final orderId = change.doc.id;
          final currentStatus = orderData['status'] as String?;
          final statusLastUpdated = (orderData['statusLastUpdated'] as Timestamp?)?.toDate();
          final updatedBy = orderData['updatedBy'] as String?;
          final isNewOrder = orderData['isNewOrder'] as bool? ?? false;

          print('🔍 Order $orderId status changed to: $currentStatus');
          print('🔍 Updated by: $updatedBy, Is new order: $isNewOrder');

          // ⚠️ CRITICAL: Skip notifications for new orders or self-updates
          if (isNewOrder == true) {
            print('🚫 Skipping notification for new order (not a real status change)');
            continue;
          }

          if (updatedBy == currentUserId) {
            print('🚫 Skipping notification for self-update (buyer updated their own order)');
            continue;
          }

          // Check if this is a meaningful status change for buyer
          if (currentStatus != null && _shouldNotifyBuyer(currentStatus)) {

            // Create unique key for this status change
            final notificationKey = '${orderId}_$currentStatus';

            // Check if we've already processed this exact status change
            if (!_processedOrders.contains(notificationKey)) {

              // Additional timestamp check for buyer notifications
              if (statusLastUpdated != null &&
                  _lastProcessedTime != null &&
                  statusLastUpdated.isAfter(_lastProcessedTime!)) {

                _processedOrders.add(notificationKey);
                createStatusUpdateNotificationForBuyer(orderId, currentStatus, orderData);
                print('✅ Status update notification sent: $orderId -> $currentStatus');
              } else {
                print('⏰ Skipped old status update: $orderId -> $currentStatus');
              }
            } else {
              print('⚠️ Skipped duplicate status update: $orderId -> $currentStatus');
            }
          } else {
            print('🚫 No notification needed for status: $currentStatus');
          }
        }
      }
    }, onError: (error) {
      print('❌ Error in buyer notification listener: $error');
    });
  }

  // 🔔 Helper: Determine if buyer should be notified for this status
  bool _shouldNotifyBuyer(String status) {
    // CRITICAL: Only notify buyers for status changes that happen AFTER seller action
    // DO NOT notify for 'pending' status (that's when order is first created)
    const notifiableStatuses = [
      'confirmed',   // When seller manually confirms order
      'processing',  // When seller accepts order (same as confirmed)
      'preparing',   // When order is being prepared
      'ready',       // When order is ready
      'delivered',   // When order is delivered/completed
      'rejected',    // When order is rejected
      'cancelled',   // When order is cancelled
    ];

    final shouldNotify = notifiableStatuses.contains(status.toLowerCase());

    // Extra debug logging
    if (shouldNotify) {
      print('🔔 WILL notify buyer for status: $status');
    } else {
      print('🚫 Will NOT notify buyer for status: $status');
    }

    return shouldNotify;
  }

  // Create notification when seller receives new order
  void _createNewOrderNotificationForSeller(String orderId, Map<String, dynamic> orderData) {
    final itemCount = orderData['itemCount'] ?? 0;
    final totalAmount = (orderData['totalAmount'] ?? 0.0).toDouble();
    final shippingMethod = orderData['shippingMethod'] ?? 'delivery';
    final shortOrderId = _getShortOrderId(orderId);

    _notificationService.addNotification(
      NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '🛒 New Order Received!',
        message: 'Order #$shortOrderId - $itemCount items, RM ${totalAmount.toStringAsFixed(2)} (${_getShippingText(shippingMethod)})',
        type: 'new_order',
        timestamp: DateTime.now(),
        orderId: orderId,
        icon: Icons.shopping_bag,
        color: const Color(0xFFFF5B9E),
      ),
    );

    print('✅ Created new order notification for SELLER: $shortOrderId');
  }

  // 🔔 PUBLIC METHOD: Create notification when buyer's order status changes
  void createStatusUpdateNotificationForBuyer(String orderId, String status, Map<String, dynamic> orderData) {
    final shortOrderId = _getShortOrderId(orderId);
    final shippingMethod = orderData['shippingMethod'] ?? 'delivery';
    final isDelivery = shippingMethod == 'delivery';

    String title;
    String message;
    IconData icon;
    Color color;

    switch (status.toLowerCase()) {
      case 'processing':
      case 'confirmed':
        title = '✅ Order Confirmed!';
        message = 'Great! Your order #$shortOrderId has been confirmed and is being processed.';
        icon = Icons.check_circle;
        color = Colors.green;
        break;

      case 'preparing':
        title = '👨‍🍳 Order Being Prepared!';
        message = 'Your order #$shortOrderId is now being prepared with care.';
        icon = Icons.restaurant;
        color = Colors.orange;
        break;

      case 'ready':
        title = isDelivery ? '🚚 Order Ready for Delivery!' : '🎉 Order Ready for Pickup!';
        message = isDelivery
            ? 'Your order #$shortOrderId is ready and will be delivered soon!'
            : 'Your order #$shortOrderId is ready for pickup at the store!';
        icon = isDelivery ? Icons.delivery_dining : Icons.store;
        color = Colors.blue;
        break;

      case 'delivered':
        title = '🎊 Order Delivered!';
        message = 'Your order #$shortOrderId has been delivered successfully. Enjoy your meal!';
        icon = Icons.check_circle;
        color = Colors.green;
        break;

      case 'cancelled':
      case 'rejected':
        title = '❌ Order Cancelled';
        message = 'Sorry, your order #$shortOrderId has been cancelled. You will be refunded shortly.';
        icon = Icons.cancel;
        color = Colors.red;
        break;

      default:
        print('⚠️ Unknown status change: $status for order $shortOrderId');
        return;
    }

    _notificationService.addNotification(
      NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        type: 'order_status_update',
        timestamp: DateTime.now(),
        orderId: orderId,
        icon: icon,
        color: color,
      ),
    );

    print('✅ Created status update notification for BUYER: $shortOrderId -> $status');
  }

  // 🔔 FIXED: Manual notification creation for order placed (BUYER ONLY)
  void createOrderPlacedNotification(String orderId, Map<String, dynamic> orderData) {
    final shortOrderId = _getShortOrderId(orderId);

    // Only send to buyer when order is placed
    _notificationService.addNotification(
      NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '📝 Order Placed Successfully!',
        message: 'Your order #$shortOrderId has been placed and is waiting for store confirmation.',
        type: 'order_placed',
        timestamp: DateTime.now(),
        orderId: orderId,
        icon: Icons.receipt,
        color: Colors.green,
      ),
    );

    print('✅ Created order placed notification for BUYER: $shortOrderId');
  }

  // 🆕 NEW: Method to manually trigger notification for existing orders (for testing)
  Future<void> testNotificationForOrder(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        final orderData = doc.data() as Map<String, dynamic>;
        _createNewOrderNotificationForSeller(orderId, orderData);
      }
    } catch (e) {
      print('❌ Error testing notification: $e');
    }
  }

  // 🆕 PUBLIC: Method to create test seller notification
  void createTestSellerNotification() {
    print('🔔 Creating test seller notification...');
    _createNewOrderNotificationForSeller(
      'test_order_seller_123',
      {
        'itemCount': 5,
        'totalAmount': 45.50,
        'shippingMethod': 'delivery',
      },
    );
  }

  // Helper methods
  String _getShortOrderId(String orderId) {
    if (orderId.length > 10) {
      return orderId.substring(orderId.length - 8);
    }
    return orderId.replaceFirst('order_', '');
  }

  String _getShippingText(String method) {
    switch (method) {
      case 'delivery':
        return 'Delivery';
      case 'selfPickup':
        return 'Pickup';
      default:
        return 'Unknown';
    }
  }

  // Dispose method
  void dispose() {
    stopListening();
  }
}