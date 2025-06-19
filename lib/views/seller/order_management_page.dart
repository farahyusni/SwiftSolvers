// lib/views/seller/order_management_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderManagementPage extends StatefulWidget {
  const OrderManagementPage({Key? key}) : super(key: key);

  @override
  State<OrderManagementPage> createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage>
    with SingleTickerProviderStateMixin {
  String _getCleanAddress(dynamic address) {
    if (address == null) return 'N/A';

    if (address is Map<String, dynamic>) {
      List<String> parts = [];
      if (address['street'] != null) parts.add(address['street']);
      if (address['city'] != null) parts.add(address['city']);
      if (address['state'] != null) parts.add(address['state']);
      if (address['zipCode'] != null) parts.add(address['zipCode']);
      return parts.join(', ');
    }

    if (address is String) {
      return address
          .replaceAll(RegExp(r',?\s*Tel:\s*[0-9-]+'), '')
          .replaceAll(RegExp(r',?\s*phoneNumber:\s*[0-9-]+'), '')
          .trim();
    }

    return 'N/A';
  }

  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEECEE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEECEE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Order Management',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF5B9E),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFFF5B9E),
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'New'),
            Tab(text: 'Processing'),
            Tab(text: 'Ready'),
            Tab(text: 'Delivered'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList('pending'),
          _buildOrderList('processing'),
          _buildOrderList('ready'),
          _buildOrderList('delivered'),
        ],
      ),
    );
  }

  Widget _buildOrderList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('orders')
              .where('status', isEqualTo: status)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5B9E)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(status);
        }

        // Sort the documents by createdAt manually
        List<QueryDocumentSnapshot> sortedDocs = List.from(snapshot.data!.docs);
        sortedDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['createdAt'];
          final bTime = bData['createdAt'];

          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;

          if (aTime is Timestamp && bTime is Timestamp) {
            return bTime.compareTo(aTime); // Descending order (newest first)
          }

          return 0;
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            final doc = sortedDocs[index];
            final orderData = doc.data() as Map<String, dynamic>;
            return _buildOrderCard(doc.id, orderData, status);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String status) {
    String message;
    IconData icon;

    switch (status) {
      case 'pending':
        message = 'No new orders';
        icon = Icons.inbox_outlined;
        break;
      case 'processing':
        message = 'No orders being processed';
        icon = Icons.hourglass_empty;
        break;
      case 'ready':
        message = 'No orders ready';
        icon = Icons.check_circle_outline;
        break;
      case 'delivered':
        message = 'No delivered orders';
        icon = Icons.local_shipping_outlined;
        break;
      default:
        message = 'No orders found';
        icon = Icons.shopping_bag_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(
    String orderId,
    Map<String, dynamic> orderData,
    String status,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.all(16),
        leading: _buildMethodIcon(orderData['shippingMethod']),
        title: Text(
          'Order #${orderData['orderNumber'] ?? orderId.replaceFirst("order_", "")}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Total: RM${(orderData['totalAmount'] ?? 0.0).toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFFFF5B9E),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              status == 'pending'
                  ? 'Waiting for acceptance'
                  : 'ETA: ${_formatDateTime(orderData['estimatedDeliveryTime'])}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: _buildStatusBadge(status),
        children: [
          _buildOrderDetails(orderData, status),
          if (status == 'pending') _buildActionButtons(orderId),
          if (status == 'processing') _buildProcessingButtons(orderId),
          if (status == 'ready') _buildReadyButtons(orderId),
        ],
      ),
    );
  }

  Widget _buildMethodIcon(String? method) {
    IconData icon;
    Color color;

    switch (method) {
      case 'selfPickup':
        icon = Icons.store;
        color = Colors.orange;
        break;
      case 'delivery':
        icon = Icons.local_shipping;
        color = Colors.blue;
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildStatusIcon(String status) {
    IconData icon;
    Color color;

    switch (status) {
      case 'pending':
        icon = Icons.new_releases_outlined;
        color = Colors.orange;
        break;
      case 'processing':
        icon = Icons.hourglass_empty;
        color = Colors.blue;
        break;
      case 'ready':
        icon = Icons.check_circle_outline;
        color = Colors.green;
        break;
      case 'delivered':
        icon = Icons.local_shipping_outlined;
        color = Colors.purple;
        break;
      default:
        icon = Icons.shopping_bag_outlined;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        text = 'NEW';
        break;
      case 'processing':
        color = Colors.blue;
        text = 'PROCESSING';
        break;
      case 'ready':
        color = Colors.green;
        text = 'READY';
        break;
      case 'delivered':
        color = Colors.purple;
        text = 'DELIVERED';
        break;
      default:
        color = Colors.grey;
        text = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildOrderDetails(Map<String, dynamic> orderData, String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Information
          _buildDetailSection('Customer Information', [
            _buildCustomerInfo(orderData['userId']),
            _buildDetailRow('Payment Status', _getPaymentMethod(orderData)),
          ]),
          const SizedBox(height: 16),

          // Delivery Information
          _buildDetailSection('Delivery Information', [
            _buildDetailRow(
              'Method',
              _getShippingMethodText(orderData['shippingMethod']),
            ),
            if (orderData['pickupLocation'] != null)
              _buildDetailRow('Pickup Location', orderData['pickupLocation']),
            if (orderData['deliveryAddress'] != null)
              _buildDetailRow(
                'Delivery Address',
                _getCleanAddress(orderData['deliveryAddress']),
              ),
            _buildDetailRow(
              'Estimated Time',
              status == 'pending'
                  ? 'To be determined'
                  : _formatDateTime(orderData['estimatedDeliveryTime']),
            ),
          ]),
          const SizedBox(height: 16),

          // Order Summary
          _buildDetailSection('Order Summary', [
            _buildDetailRow(
              'Subtotal',
              'RM${(orderData['subtotal'] ?? 0.0).toStringAsFixed(2)}',
            ),
            _buildDetailRow(
              'Shipping Fee',
              'RM${(orderData['shippingFee'] ?? 0.0).toStringAsFixed(2)}',
            ),
            _buildDetailRow(
              'COD Fee',
              'RM${(orderData['codFee'] ?? 0.0).toStringAsFixed(2)}',
            ),
            _buildDetailRow(
              'Total Amount',
              'RM${(orderData['totalAmount'] ?? 0.0).toStringAsFixed(2)}',
              isTotal: true,
            ),
          ]),
          const SizedBox(height: 16),

          // Items List
          _buildItemsList(orderData['items']),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFFFF5B9E),
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? const Color(0xFFFF5B9E) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(dynamic items) {
    if (items == null || items is! List || items.isEmpty) {
      return const Text('No items found');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Items',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFFFF5B9E),
          ),
        ),
        const SizedBox(height: 8),
        ...items.map<Widget>((item) => _buildItemRow(item)).toList(),
      ],
    );
  }

  Widget _buildItemRow(dynamic item) {
    if (item is! Map<String, dynamic>) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Item icon based on category
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getCategoryColor(item['category']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCategoryIcon(item['category']),
              color: _getCategoryColor(item['category']),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'Unknown Item',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item['quantity'] ?? 0} ${item['unit'] ?? 'pcs'} • ${item['recipeName'] ?? 'Recipe'}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ],
            ),
          ),
          // Price
          Text(
            'RM${(item['totalPrice'] ?? 0.0).toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFFFF5B9E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String orderId) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateOrderStatus(orderId, 'processing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 20),
                  SizedBox(width: 4),
                  Text('Accept', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showRejectDialog(orderId),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel, size: 20),
                  SizedBox(width: 4),
                  Text('Reject', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingButtons(String orderId) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateOrderStatus(orderId, 'ready'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 20),
                  SizedBox(width: 4),
                  Text('Ready', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showCancelDialog(orderId),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel, size: 20),
                  SizedBox(width: 4),
                  Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyButtons(String orderId) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateOrderStatus(orderId, 'delivered'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping, size: 20),
                  SizedBox(width: 4),
                  Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showCancelDialog(orderId),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel, size: 20),
                  SizedBox(width: 4),
                  Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order updated to "$newStatus"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectOrder(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order rejected and removed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRejectDialog(String orderId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reject Order'),
            content: const Text('Are you sure you want to reject this order?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _rejectOrder(orderId);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Reject'),
              ),
            ],
          ),
    );
  }

  void _showCancelDialog(String orderId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Order'),
            content: const Text('Are you sure you want to cancel this order?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _updateOrderStatus(orderId, 'cancelled');
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Cancel Order'),
              ),
            ],
          ),
    );
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        return 'Invalid date';
      }

      // Format without using intl package to avoid import issues
      return '${_getMonthName(dateTime.month)} ${dateTime.day}, ${dateTime.year} ${_formatTime(dateTime)}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }

  String _formatTime(DateTime dateTime) {
    int hour = dateTime.hour;
    int minute = dateTime.minute;
    String period = hour >= 12 ? 'PM' : 'AM';

    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;

    String minuteStr = minute.toString().padLeft(2, '0');
    return '$hour:$minuteStr $period';
  }

  Widget _buildCustomerInfo(String? userId) {
    if (userId == null) {
      return Column(
        children: [
          _buildDetailRow('Name', 'N/A'),
          _buildDetailRow('Contact', 'N/A'),
        ],
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: [
              _buildDetailRow('Name', 'Loading...'),
              _buildDetailRow('Contact', 'Loading...'),
            ],
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Column(
            children: [
              _buildDetailRow('Name', 'N/A'),
              _buildDetailRow('Contact', 'N/A'),
            ],
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final name = userData['fullName'] ?? 'N/A';
        final contact = userData['phone'] ?? 'N/A';

        return Column(
          children: [
            _buildDetailRow('Name', name),
            _buildDetailRow('Contact', contact),
          ],
        );
      },
    );
  }

  Widget _buildAddressRow(String label, dynamic address) {
    String addressText = 'N/A';

    if (address != null) {
      if (address is Map<String, dynamic>) {
        // Extract address components (excluding phone number)
        List<String> addressParts = [];
        if (address['street'] != null) addressParts.add(address['street']);
        if (address['city'] != null) addressParts.add(address['city']);
        if (address['state'] != null) addressParts.add(address['state']);
        if (address['zipCode'] != null) addressParts.add(address['zipCode']);

        addressText = addressParts.isNotEmpty ? addressParts.join(', ') : 'N/A';
      } else {
        // If it's a string, clean it up to remove phone numbers
        String rawAddress = address.toString();
        // Remove phone number patterns like "Tel: 012-8078917" or phoneNumber fields
        rawAddress = rawAddress.replaceAll(RegExp(r',?\s*Tel:\s*[0-9-]+'), '');
        rawAddress = rawAddress.replaceAll(
          RegExp(r',?\s*phoneNumber:\s*[0-9-]+'),
          '',
        );
        addressText = rawAddress.trim();
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  addressText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPaymentMethod(Map<String, dynamic> orderData) {
    final shippingMethod = orderData['shippingMethod'] as String?;

    // For delivery orders, payment is usually COD
    if (shippingMethod == 'delivery') {
      return 'Cash on Delivery';
    }

    // For self pickup, could be cash on pickup
    if (shippingMethod == 'selfPickup') {
      return 'Cash on Pickup';
    }

    // Fallback
    return orderData['paymentStatus'] ?? 'pending';
  }

  String _getShippingMethodText(String? method) {
    switch (method) {
      case 'selfPickup':
        return 'Self Pickup';
      case 'delivery':
        return 'Delivery';
      default:
        return method ?? 'Unknown';
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'grains':
        return Icons.grain;
      case 'protein':
        return Icons.egg;
      case 'vegetables':
        return Icons.eco;
      case 'dairy':
        return Icons.local_drink;
      case 'spices':
        return Icons.spa;
      case 'sauces':
        return Icons.liquor;
      case 'basic':
        return Icons.kitchen;
      default:
        return Icons.shopping_cart;
    }
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'grains':
        return Colors.amber;
      case 'protein':
        return Colors.red;
      case 'vegetables':
        return Colors.green;
      case 'dairy':
        return Colors.blue;
      case 'spices':
        return Colors.orange;
      case 'sauces':
        return Colors.brown;
      case 'basic':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
