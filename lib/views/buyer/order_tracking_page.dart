// lib/views/buyer/order_tracking_page.dart
import 'package:flutter/material.dart';
import '../../services/order_service.dart';
import '../../models/order_model.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';

class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({Key? key}) : super(key: key);

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderService _orderService = OrderService();
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() => isLoading = true);
      final orderHistory = await _orderService.getUserOrderHistory();
      setState(() {
        orders = orderHistory;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print('Error loading orders: $e');
    }
  }

  List<Map<String, dynamic>> _getOrdersByStatus(String status) {
    if (status == 'All') return orders;
    return orders.where((order) => order['status'] == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF5B9E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Purchases',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: const Color(0xFFFF5B9E),
              labelColor: const Color(0xFFFF5B9E),
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'To Pay'),
                Tab(text: 'To Ship'),
                Tab(text: 'To Receive'),
                Tab(text: 'Completed'),
                Tab(text: 'Return/Refund'),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOrderList('pending'), // To Pay
                        _buildOrderList('confirmed'), // To Ship
                        _buildOrderList('ready'), // To Receive
                        _buildOrderList('delivered'), // Completed
                        _buildOrderList('cancelled'), // Return/Refund
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(String status) {
    List<Map<String, dynamic>> filteredOrders = _getOrdersByStatus(status);

    if (filteredOrders.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredOrders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(filteredOrders[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Orders Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your orders will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/buyer-home',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5B9E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text('Start Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final String orderId = order['id'] ?? '';
    final double totalAmount = (order['totalAmount'] ?? 0.0).toDouble();
    final String status = order['status'] ?? 'pending';
    final int itemCount = order['itemCount'] ?? 0;
    final String shippingMethod = order['shippingMethod'] ?? 'delivery';

    return GestureDetector(
      onTap: () => _viewOrderDetails(orderId), // 🎯 ADD THIS LINE
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey[200]!,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.store_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Jaya Grocer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusDisplayName(status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Order Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.grey[400],
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #${orderId.substring(0, 8).toUpperCase()}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$itemCount items • ${shippingMethod == 'delivery' ? 'Delivery' : 'Pickup'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'RM${totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF5B9E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey[400]),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Action Buttons
                  Row(
                    children: [
                      if (status == 'pending') ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _cancelOrder(orderId),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _payNow(orderId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF5B9E),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Pay Now'),
                          ),
                        ),
                      ] else if (status == 'delivered') ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _reorderItems(orderId),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFF5B9E),
                              side: const BorderSide(color: Color(0xFFFF5B9E)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Buy Again'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _rateOrder(orderId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF5B9E),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Rate'),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _contactSeller(orderId),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFF5B9E),
                              side: const BorderSide(color: Color(0xFFFF5B9E)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Contact Seller'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _viewOrderDetails(orderId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF5B9E),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Track Order'),
                          ),
                        ),
                      ],
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

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'pending':
        return 'Pending Payment';
      case 'confirmed':
        return 'To Ship';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready';
      case 'outForDelivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
      case 'preparing':
        return Colors.blue;
      case 'ready':
      case 'outForDelivery':
        return Colors.green;
      case 'delivered':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Action Methods
  void _cancelOrder(String orderId) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Order'),
            content: const Text('Are you sure you want to cancel this order?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (result == true) {
      try {
        await _orderService.cancelOrder(orderId);
        _loadOrders(); // Refresh orders
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to cancel order: $e')));
      }
    }
  }

  void _payNow(String orderId) {
    // Navigate to payment page
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Redirecting to payment...')));
  }

  void _reorderItems(String orderId) {
    // Add items to cart again
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Items added to cart!')));
  }

  void _rateOrder(String orderId) {
    // Navigate to rating page
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening rating page...')));
  }

  void _contactSeller(String orderId) {
    // Navigate to chat with seller
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening chat with seller...')),
    );
  }

  void _viewOrderDetails(String orderId) {
    Navigator.pushNamed(
      context,
      '/order-detail',
      arguments: {'orderId': orderId},
    );
  }
}