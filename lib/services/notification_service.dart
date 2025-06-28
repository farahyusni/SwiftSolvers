// lib/services/notification_service.dart (FIXED)
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/notification_models.dart'; // FIXED IMPORT PATH

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;
  bool _permissionGranted = false;
  final List<NotificationModel> _notifications = [];

  // Stream controller for real-time updates
  final StreamController<List<NotificationModel>> _notificationController =
  StreamController<List<NotificationModel>>.broadcast();

  // Getters
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get isPermissionGranted => _permissionGranted;
  Stream<List<NotificationModel>> get notificationStream =>
      _notificationController.stream;

  // Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // For now, we'll simulate initialization without external packages
    await Future.delayed(const Duration(milliseconds: 100));

    _isInitialized = true;
    print('✅ Notification service initialized');
  }

  // Request notification permission
  Future<bool> requestPermission() async {
    if (!_isInitialized) await initialize();

    // Simulate permission request
    await Future.delayed(const Duration(milliseconds: 500));

    _permissionGranted = true;
    notifyListeners();
    print('✅ Notification permission granted');
    return _permissionGranted;
  }

  // Add notification - WITH DEBUG LOGGING
  void addNotification(NotificationModel notification) {
    print('📱 Adding notification: ${notification.title}');
    print('📱 Notification type: ${notification.type}');
    print('📱 Notification message: ${notification.message}');

    _notifications.insert(0, notification);
    _notificationController.add(_notifications);
    notifyListeners();

    // Show local notification if permission is granted
    if (_permissionGranted) {
      _showLocalNotification(notification);
    }
  }

  // Show local notification (simplified for now)
  Future<void> _showLocalNotification(NotificationModel notification) async {
    // For now, just print to console
    // In a real app, you'd use flutter_local_notifications here
    print('🔔 Local notification: ${notification.title} - ${notification.message}');
  }

  // Mark notification as read
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _notificationController.add(_notifications);
      notifyListeners();
      print('✅ Notification marked as read: $notificationId');
    }
  }

  // Mark all notifications as read
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    _notificationController.add(_notifications);
    notifyListeners();
    print('✅ All notifications marked as read');
  }

  // ⚠️ DEPRECATED: Remove this method - it might be causing duplicates
  // This method should NOT be used anymore - use OrderNotificationBridge instead
  @deprecated
  void createOrderNotification({
    required String orderId,
    required String status,
    String? estimatedTime,
  }) {
    print('⚠️ WARNING: createOrderNotification() called - this method is deprecated');
    print('⚠️ This might be causing duplicate notifications');
    print('⚠️ Order ID: $orderId, Status: $status');
    print('⚠️ Use OrderNotificationBridge instead');

    // DON'T create the notification - just log the warning
    // The OrderNotificationBridge should handle all order notifications
  }

  // Create promotional notifications (this is still fine)
  void createPromotionalNotification({
    required String title,
    required String message,
  }) {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: 'promotion',
      timestamp: DateTime.now(),
      icon: Icons.local_offer,
      color: const Color(0xFFFF5B9E),
    );

    addNotification(notification);
  }

  // Clear all notifications
  void clearAllNotifications() {
    _notifications.clear();
    _notificationController.add(_notifications);
    notifyListeners();
    print('🗑️ All notifications cleared');
  }

  // Dispose
  @override
  void dispose() {
    _notificationController.close();
    super.dispose();
  }
}