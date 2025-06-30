// lib/views/buyer/order_success_page.dart - Updated with notification integration
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';
import '../../widgets/notification_permission_dialog.dart';

class OrderSuccessPage extends StatefulWidget {
  final String orderId;
  final double totalAmount;
  final String estimatedDelivery;
  final bool isDelivery;
  final String? storeName;
  final List<String>? items;

  const OrderSuccessPage({
    Key? key,
    required this.orderId,
    required this.totalAmount,
    required this.estimatedDelivery,
    required this.isDelivery,
    this.storeName,
    this.items,
  }) : super(key: key);

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _notificationDialogShown = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    // Initialize notification flow
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    final notificationService = context.read<NotificationService>();

    // Create initial order confirmation notification
    notificationService.createOrderNotification(
      orderId: widget.orderId,
      status: 'confirmed',
    );

    // Show notification permission dialog after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_notificationDialogShown) {
        _showNotificationPermissionDialog();
      }
    });

    // Simulate order progression for demo
    _simulateOrderUpdates();
  }

  void _simulateOrderUpdates() {
    final notificationService = context.read<NotificationService>();

    // Simulate order being prepared
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        notificationService.createOrderNotification(
          orderId: widget.orderId,
          status: 'preparing',
        );
      }
    });

    // Simulate delivery/pickup ready
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        notificationService.createOrderNotification(
          orderId: widget.orderId,
          status: widget.isDelivery ? 'out_for_delivery' : 'ready_for_pickup',
          estimatedTime: widget.estimatedDelivery,
        );
      }
    });
  }

  void _showNotificationPermissionDialog() {
    if (_notificationDialogShown) return;

    setState(() {
      _notificationDialogShown = true;
    });

    NotificationPermissionDialog.show(
      context,
      onAllowed: () async {
        final notificationService = context.read<NotificationService>();
        await notificationService.requestPermission();
      },
      onDenied: () {
        // Handle denial if needed
        print('User denied notification permission');
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF5B9E),
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/buyer-home',
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Order #${widget.orderId}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Success content
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Success icon with animation
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFF5B9E), Color(0xFFFF8FA3)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF5B9E).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Success message
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            const Text(
                              'Order Placed Successfully!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.isDelivery
                                  ? 'Your groceries will be delivered soon'
                                  : 'Your groceries will be ready for pickup',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Order details
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5B9E).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFFF5B9E).withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Order Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildOrderDetailRow(
                                'Order ID',
                                '#${widget.orderId}',
                              ),
                              if (widget.storeName != null)
                                _buildOrderDetailRow(
                                  'Store',
                                  widget.storeName!,
                                ),
                              _buildOrderDetailRow(
                                'Total Amount',
                                'RM ${widget.totalAmount.toStringAsFixed(2)}',
                              ),
                              _buildOrderDetailRow(
                                widget.isDelivery
                                    ? 'Estimated Delivery'
                                    : 'Ready for Pickup',
                                widget.estimatedDelivery,
                              ),
                              if (widget.items != null &&
                                  widget.items!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Text(
                                  'Items:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.items!.join(', '),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Action buttons
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Navigate directly to order detail page for this specific order
                                  Navigator.pushNamed(
                                    context,
                                    '/order-detail',
                                    arguments: {'orderId': widget.orderId},
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF5B9E),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Track My Order',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/buyer-home',
                                    (route) => false,
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFFF5B9E),
                                  side: const BorderSide(
                                    color: Color(0xFFFF5B9E),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Continue Shopping',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}