// lib/widgets/notification_widget_wrapper.dart
// NEW FILE - Wraps your existing homepage with notification functionality
// NO CHANGES needed to your existing files!

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../services/order_notification_bridge.dart';
import '../models/notification_models.dart';

class NotificationWidgetWrapper extends StatefulWidget {
  final Widget child;
  final bool isSeller;

  const NotificationWidgetWrapper({
    Key? key,
    required this.child,
    required this.isSeller,
  }) : super(key: key);

  @override
  State<NotificationWidgetWrapper> createState() => _NotificationWidgetWrapperState();
}

class _NotificationWidgetWrapperState extends State<NotificationWidgetWrapper> {
  final OrderNotificationBridge _notificationBridge = OrderNotificationBridge();

  @override
  void initState() {
    super.initState();

    // Initialize notification listeners with slight delay to ensure user auth is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _notificationBridge.startListening(isSeller: widget.isSeller);
        }
      });
    });
  }

  @override
  void dispose() {
    _notificationBridge.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// Notification Bell Widget - Can be added to any AppBar
class NotificationBellWidget extends StatefulWidget {
  final VoidCallback? onTap;
  final Color iconColor;
  final double iconSize;

  const NotificationBellWidget({
    Key? key,
    this.onTap,
    this.iconColor = const Color(0xFFFF5B9E),
    this.iconSize = 24,
  }) : super(key: key);

  @override
  State<NotificationBellWidget> createState() => _NotificationBellWidgetState();
}

class _NotificationBellWidgetState extends State<NotificationBellWidget>
    with TickerProviderStateMixin {
  late AnimationController _bellController;
  late Animation<double> _bellAnimation;

  @override
  void initState() {
    super.initState();

    _bellController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _bellAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bellController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _bellController.dispose();
    super.dispose();
  }

  void _animateBell() {
    _bellController.forward().then((_) {
      _bellController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, notificationService, child) {
        // Animate bell when unread count changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (notificationService.unreadCount > 0) {
            _animateBell();
          }
        });

        return GestureDetector(
          onTap: widget.onTap ?? () => _showNotificationPanel(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(right: 4),
            child: Stack(
              children: [
                ScaleTransition(
                  scale: _bellAnimation,
                  child: Icon(
                    Icons.notifications_outlined,
                    color: widget.iconColor,
                    size: widget.iconSize,
                  ),
                ),
                // Notification badge
                if (notificationService.unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        notificationService.unreadCount > 99
                            ? '99+'
                            : notificationService.unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotificationPanel(BuildContext context) {
    final notificationService = context.read<NotificationService>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationPanel(
        notifications: notificationService.notifications,
        onNotificationTap: (notificationId) {
          notificationService.markAsRead(notificationId);
        },
        onMarkAllAsRead: () {
          notificationService.markAllAsRead();
        },
      ),
    );
  }
}

// Enhanced Notification Panel
class NotificationPanel extends StatelessWidget {
  final List<NotificationModel> notifications;
  final Function(String) onNotificationTap;
  final VoidCallback onMarkAllAsRead;

  const NotificationPanel({
    Key? key,
    required this.notifications,
    required this.onNotificationTap,
    required this.onMarkAllAsRead,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (unreadCount > 0)
                      Text(
                        '$unreadCount unread',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
                if (unreadCount > 0)
                  TextButton(
                    onPressed: () {
                      onMarkAllAsRead();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Mark all as read',
                      style: TextStyle(
                        color: Color(0xFFFF5B9E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(),

          // Notifications list
          Expanded(
            child: notifications.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Order updates will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationTile(context, notification);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, NotificationModel notification) {
    return GestureDetector(
      onTap: () {
        onNotificationTap(notification.id);
        Navigator.pop(context);

        // Show order details if it's an order notification
        if (notification.orderId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order #${notification.orderId} - Tap to view details'),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'View',
                onPressed: () {
                  // Navigate to order details page when implemented
                  print('Navigate to order details: ${notification.orderId}');
                },
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : const Color(0xFFFF5B9E).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead
                ? Colors.grey.withOpacity(0.2)
                : const Color(0xFFFF5B9E).withOpacity(0.2),
          ),
          boxShadow: notification.isRead ? null : [
            BoxShadow(
              color: const Color(0xFFFF5B9E).withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: notification.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                notification.icon,
                color: notification.color,
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF5B9E),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTimestamp(notification.timestamp),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 11,
                        ),
                      ),
                      if (notification.orderId != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: notification.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Order',
                            style: TextStyle(
                              color: notification.color,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}