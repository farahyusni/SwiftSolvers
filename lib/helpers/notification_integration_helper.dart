// lib/helpers/notification_integration_helper.dart
// NEW FILE - Helper methods to integrate notifications with your existing OrderService
// NO CHANGES needed to your existing files!

import '../services/order_notification_bridge.dart';

class NotificationIntegrationHelper {
  static final OrderNotificationBridge _bridge = OrderNotificationBridge();

  // Call this method in your OrderService after successfully creating an order
  static void onOrderCreated(String orderId, Map<String, dynamic> orderData) {
    try {
      // Create notification for buyer that order was placed
      _bridge.createOrderPlacedNotification(orderId, orderData);

      // The seller notification will be created automatically by the listener
      // when the order document is added to Firestore

      print('✅ Order notifications initiated for: $orderId');
    } catch (e) {
      print('❌ Error creating order notifications: $e');
    }
  }

  // Call this method in your OrderService after successfully updating order status
  static void onOrderStatusUpdated(String orderId, String newStatus, String buyerUserId) {
    try {
      // The buyer notification will be created automatically by the listener
      // when the order document is updated in Firestore

      print('✅ Status update notification will be sent for: $orderId -> $newStatus');
    } catch (e) {
      print('❌ Error handling status update notification: $e');
    }
  }

  // Call this method in your OrderService after successfully rejecting an order
  static void onOrderRejected(String orderId, String buyerUserId) {
    try {
      // The rejection notification will be created automatically by the listener
      // when the order status changes to 'rejected' or 'cancelled'

      print('✅ Rejection notification will be sent for: $orderId');
    } catch (e) {
      print('❌ Error handling rejection notification: $e');
    }
  }

  // Initialize notification system for a user session
  static void initializeForUser({required bool isSeller}) {
    try {
      _bridge.startListening(isSeller: isSeller);
      print('✅ Notification system initialized for ${isSeller ? 'seller' : 'buyer'}');
    } catch (e) {
      print('❌ Error initializing notification system: $e');
    }
  }

  // Cleanup when user logs out
  static void cleanup() {
    try {
      _bridge.stopListening();
      print('✅ Notification system cleaned up');
    } catch (e) {
      print('❌ Error cleaning up notification system: $e');
    }
  }
}