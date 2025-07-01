// lib/views/buyer/order_detail_page.dart
import 'package:flutter/material.dart';
import '../../services/order_service.dart';
import 'package:intl/intl.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;

  const OrderDetailPage({Key? key, required this.orderId}) : super(key: key);

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final OrderService _orderService = OrderService();
  Map<String, dynamic>? orderDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    try {
      setState(() => isLoading = true);
      final details = await _orderService.getOrderDetails(widget.orderId);
      setState(() {
        orderDetails = details;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print('Error loading order details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF5B9E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Order Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orderDetails == null
              ? _buildErrorState()
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildOrderStatus(),
                      const SizedBox(height: 8),
                      _buildTrackingTimeline(),
                      const SizedBox(height: 8),
                      _buildDeliveryInfo(),
                      const SizedBox(height: 8),
                      _buildOrderItems(),
                      const SizedBox(height: 8),
                      _buildPricingDetails(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
      bottomNavigationBar: orderDetails != null ? _buildBottomActions() : null,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Order not found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This order may have been deleted or doesn\'t exist',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatus() {
    final status = orderDetails!['status'] ?? 'pending';
    final orderId = orderDetails!['id'] ?? '';
    final createdAt = orderDetails!['createdAt'];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${orderId.substring(0, 8).toUpperCase()}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
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
          const SizedBox(height: 8),
          if (createdAt != null)
            Text(
              'Placed on ${DateFormat('MMM dd, yyyy at hh:mm a').format(createdAt.toDate())}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrackingTimeline() {
    final status = orderDetails!['status'] ?? 'pending';
    
    List<Map<String, dynamic>> timelineSteps = [
      {
        'title': 'Order Placed',
        'subtitle': 'We have received your order',
        'icon': Icons.shopping_cart,
        'isCompleted': true,
      },
      {
        'title': 'Payment Confirmed',
        'subtitle': 'Payment has been processed',
        'icon': Icons.payment,
        'isCompleted': status != 'pending',
      },
      {
        'title': 'Ready for Pickup/Delivery',     
        'subtitle': 'Your order is ready',       
        'icon': Icons.check_circle,              
        'isCompleted': ['ready', 'delivered'].contains(status),  
      },
      {
        'title': 'Out for Delivery',
        'subtitle': 'Your order is on the way',
        'icon': Icons.local_shipping,
        'isCompleted': ['outForDelivery', 'delivered'].contains(status),
      },
      {
        'title': 'Delivered',
        'subtitle': 'Order has been delivered',
        'icon': Icons.check_circle,
        'isCompleted': status == 'delivered',
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
          const Text(
            'Order Tracking',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...timelineSteps.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> step = entry.value;
            bool isLast = index == timelineSteps.length - 1;
            
            return Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: step['isCompleted'] 
                            ? const Color(0xFFFF5B9E) 
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        step['icon'],
                        color: step['isCompleted'] ? Colors.white : Colors.grey[600],
                        size: 20,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 40,
                        color: step['isCompleted'] 
                            ? const Color(0xFFFF5B9E) 
                            : Colors.grey[300],
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['title'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: step['isCompleted'] ? Colors.black : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step['subtitle'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (!isLast) const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    final shippingMethod = orderDetails!['shippingMethod'] ?? 'delivery';
    final deliveryAddress = orderDetails!['deliveryAddress'];
    final pickupLocation = orderDetails!['pickupLocation'];
    final estimatedDeliveryTime = orderDetails!['estimatedDeliveryTime'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Icon(
                shippingMethod == 'delivery' ? Icons.local_shipping : Icons.store,
                color: const Color(0xFFFF5B9E),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                shippingMethod == 'delivery' ? 'Delivery Information' : 'Pickup Information',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (shippingMethod == 'delivery' && deliveryAddress != null) ...[
            _buildInfoRow('Recipient', deliveryAddress['recipientName'] ?? 'N/A'),
            _buildInfoRow('Phone', deliveryAddress['phoneNumber'] ?? 'N/A'),
            _buildInfoRow('Address', 
              '${deliveryAddress['streetAddress'] ?? ''}, ${deliveryAddress['city'] ?? ''}, ${deliveryAddress['state'] ?? ''} ${deliveryAddress['postalCode'] ?? ''}'),
          ] else if (shippingMethod == 'selfPickup') ...[
            _buildInfoRow('Pickup Location', pickupLocation ?? 'Main Store'),
            _buildInfoRow('Store Hours', '9:00 AM - 10:00 PM'),
          ],
          if (estimatedDeliveryTime != null)
            _buildInfoRow(
              shippingMethod == 'delivery' ? 'Estimated Delivery' : 'Ready for Pickup',
              DateFormat('MMM dd, yyyy at hh:mm a').format(estimatedDeliveryTime.toDate()),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderItems() {
    final items = orderDetails!['items'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
          const Text(
            'Order Items',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const Text('No items found')
          else
            ...items.map((item) => _buildOrderItem(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    final name = item['name'] ?? 'Unknown Item';
    final quantity = item['quantity'] ?? 0;
    final price = (item['price'] ?? 0.0).toDouble();
    final total = quantity * price;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.shopping_basket,
              color: Colors.grey[400],
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: $quantity × RM${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            'RM${total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF5B9E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingDetails() {
    final subtotal = (orderDetails!['subtotal'] ?? 0.0).toDouble();
    final shippingFee = (orderDetails!['shippingFee'] ?? 0.0).toDouble();
    final codFee = (orderDetails!['codFee'] ?? 0.0).toDouble();
    final totalAmount = (orderDetails!['totalAmount'] ?? 0.0).toDouble();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
          const Text(
            'Payment Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPriceRow('Subtotal', subtotal),
          if (shippingFee > 0) _buildPriceRow('Shipping Fee', shippingFee),
          if (codFee > 0) _buildPriceRow('COD Fee', codFee),
          const Divider(height: 24),
          _buildPriceRow('Total', totalAmount, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.grey[600],
            ),
          ),
          Text(
            'RM${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: isTotal ? const Color(0xFFFF5B9E) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final status = orderDetails!['status'] ?? 'pending';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (status == 'pending') ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => _cancelOrder(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cancel Order'),
              ),
            ),
          ] else if (status == 'delivered') ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => _reorderItems(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF5B9E),
                  side: const BorderSide(color: Color(0xFFFF5B9E)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Buy Again'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _rateOrder(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5B9E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Rate Order'),
              ),
            ),
          ] else ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => _contactSeller(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF5B9E),
                  side: const BorderSide(color: Color(0xFFFF5B9E)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Contact Seller'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _trackOrder(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5B9E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Refresh Status'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'pending':
        return 'Pending Payment';
      case 'confirmed':
        return 'Confirmed';
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
  void _cancelOrder() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
        await _orderService.cancelOrder(widget.orderId);
        _loadOrderDetails(); // Refresh order details
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel order: $e')),
        );
      }
    }
  }

  void _payNow() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Redirecting to payment...')),
    );
  }

  void _reorderItems() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Items added to cart!')),
    );
  }

  void _rateOrder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening rating page...')),
    );
  }

  void _contactSeller() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening chat with seller...')),
    );
  }

  void _trackOrder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refreshing order status...')),
    );
    _loadOrderDetails();
  }
}