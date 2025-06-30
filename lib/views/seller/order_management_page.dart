// lib/views/seller/order_management_page.dart (Clean Fixed Version)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/order_service.dart';

class OrderManagementPage extends StatefulWidget {
  const OrderManagementPage({Key? key}) : super(key: key);

  @override
  State<OrderManagementPage> createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderService _orderService = OrderService();
  String _getCleanAddress(dynamic address) {
    if (address == null) return 'N/A';

    if (address is Map<String, dynamic>) {
      List<String> parts = [];
      if (address['recipientName'] != null) parts.add(address['recipientName']);
      if (address['addressLine'] != null) parts.add(address['addressLine']);
      if (address['city'] != null) parts.add(address['city']);
      if (address['state'] != null) parts.add(address['state']);
      if (address['postcode'] != null) parts.add(address['postcode']);
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
          onPressed: () => Navigator.pop(context, true),
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
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildStatisticsCard(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList('pending'),
                _buildOrderList('processing'),
                _buildOrderList('ready'),
                _buildOrderList('delivered'),
                _buildOrderList('cancelled'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _orderService.getSellerOrderStatistics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Loading statistics...'),
              ],
            );
          }

          final stats = snapshot.data ?? <String, dynamic>{};

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Order Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5B9E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Today: RM${(stats['todaySales'] ?? 0.0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF5B9E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total',
                      '${stats['total'] ?? 0}',
                      Icons.shopping_bag_outlined,
                      const Color(0xFF8B4B5C),
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Pending',
                      '${stats['pending'] ?? 0}',
                      Icons.access_time,
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Processing',
                      '${stats['processing'] ?? 0}',
                      Icons.hourglass_empty,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Completed',
                      '${stats['delivered'] ?? 0}',
                      Icons.check_circle_outline,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Cancelled',
                      '${stats['cancelled'] ?? 0}',
                      Icons.cancel_outlined,
                      Colors.red,
                    ),
                  ),
                ],
              ),
              if ((stats['totalSales'] ?? 0.0) > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5B9E).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: Color(0xFFFF5B9E),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Total Sales: RM${(stats['totalSales'] ?? 0.0).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF5B9E),
                          ),
                        ),
                      ),
                      Text(
                        'Monthly: RM${(stats['monthSales'] ?? 0.0).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOrderList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: _orderService.getSellerOrdersStream(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5B9E)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5B9E),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(status);
        }

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
            return bTime.compareTo(aTime);
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
    String subtitle;

    switch (status) {
      case 'pending':
        message = 'No new orders';
        icon = Icons.inbox_outlined;
        subtitle = 'New orders will appear here when customers place them';
        break;
      case 'processing':
        message = 'No orders being processed';
        icon = Icons.hourglass_empty;
        subtitle = 'Orders you\'ve accepted will appear here';
        break;
      case 'ready':
        message = 'No orders ready';
        icon = Icons.check_circle_outline;
        subtitle = 'Orders marked as ready will appear here';
        break;
      case 'delivered':
        message = 'No delivered orders';
        icon = Icons.local_shipping_outlined;
        subtitle = 'Completed orders will appear here';
        break;
      case 'cancelled':
        message = 'No cancelled orders';
        icon = Icons.cancel_outlined;
        subtitle = 'Orders that were cancelled will appear here';
        break;
      default:
        message = 'No orders found';
        icon = Icons.shopping_bag_outlined;
        subtitle = 'Orders will appear here';
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
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
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

  Widget _buildOrderCard(String orderId, Map<String, dynamic> orderData, String status) {
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
          // Cancelled orders won't have any buttons - which is correct
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
      case 'cancelled':
        color = Colors.red;
        text = 'CANCELLED';
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
          _buildDetailSection('Customer Information', [
            _buildCustomerInfo(orderData['userId']),
            _buildDetailRow('Payment Status', _getPaymentMethod(orderData)),
          ]),
          const SizedBox(height: 16),
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
      final success = await _orderService.updateOrderStatus(orderId, newStatus);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order updated to "$newStatus"'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update order'),
            backgroundColor: Colors.red,
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
      final success = await _orderService.rejectOrder(orderId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reject order'),
            backgroundColor: Colors.red,
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
      builder: (context) => AlertDialog(
        title: const Text('Reject Order'),
        content: const Text('Are you sure you want to reject this order? This action cannot be undone.'),
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
      builder: (context) => AlertDialog(
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

      return '${_getMonthName(dateTime.month)} ${dateTime.day}, ${dateTime.year} ${_formatTime(dateTime)}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _getMonthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
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
        final name = userData['fullName'] ?? userData['name'] ?? userData['displayName'] ?? 'N/A';
        final contact = userData['phone'] ?? userData['phoneNumber'] ?? userData['contactNumber'] ?? 'N/A';

        return Column(
          children: [
            _buildDetailRow('Name', name),
            _buildDetailRow('Contact', contact),
          ],
        );
      },
    );
  }
  String _getPaymentMethod(Map<String, dynamic> orderData) {
    final shippingMethod = orderData['shippingMethod'] as String?;

    if (shippingMethod == 'delivery') {
      return 'Cash on Delivery';
    }

    if (shippingMethod == 'selfPickup') {
      return 'Cash on Pickup';
    }

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
      case 'condiments':
        return Icons.liquor;
      case 'basic':
        return Icons.kitchen;
      case 'fruits':
        return Icons.apple;
      case 'beverages':
        return Icons.local_cafe;
      case 'snacks':
        return Icons.cookie;
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
      case 'condiments':
        return Colors.brown;
      case 'basic':
        return Colors.grey;
      case 'fruits':
        return Colors.pink;
      case 'beverages':
        return Colors.cyan;
      case 'snacks':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

