import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../utils/app_theme.dart';
import '../../services/order_service.dart';

class BuyerProfilePage extends StatefulWidget {
  const BuyerProfilePage({Key? key}) : super(key: key);

  @override
  _BuyerProfilePageState createState() => _BuyerProfilePageState();
}

class _BuyerProfilePageState extends State<BuyerProfilePage> {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  final OrderService _orderService = OrderService(); 
  Map<String, int> _orderSummary = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadOrderSummary();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final auth.User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        final DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (doc.exists) {
          setState(() {
            _userData = doc.data() as Map<String, dynamic>;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadOrderSummary() async {
    try {
      final summary = await _orderService.getOrderStatusSummary();
      setState(() {
        _orderSummary = summary;
      });
    } catch (e) {
      print('Error loading order summary: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).pushNamed('/edit-profile').then((_) {
                // Refresh user data when returning from edit page
                _loadUserData();
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _userData == null
          ? Center(child: Text('No profile data found'))
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Updated Profile header with avatar
              Center(
                child: Column(
                  children: [
                    // Profile Image with fallback
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: AppTheme.lightPinkColor,
                          backgroundImage: _userData!['profileImageUrl'] != null
                              ? NetworkImage(_userData!['profileImageUrl']!)
                              : null,
                          child: _userData!['profileImageUrl'] == null
                              ? Icon(
                            Icons.person,
                            size: 80,
                            color: AppTheme.primaryColor,
                          )
                              : null,
                        ),
                        // Optional: Add edit icon overlay
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      _userData!['fullName'] ?? 'User',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _userData!['email'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24), // CHANGED: Reduced space

              // ADD THIS: Order Summary Card
              _buildOrderSummaryCard(),

              SizedBox(height: 24),

              // ADD THIS: Quick Actions Menu
              _buildQuickActionsMenu(),

              SizedBox(height: 24),

              // Profile details (existing code)
              Text(
                'Profile Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              SizedBox(height: 16),

              _buildProfileDetail(Icons.phone, 'Phone', _userData!['phone']),
              _buildProfileDetail(Icons.location_on, 'Address', _userData!['address']),
              _buildProfileDetail(Icons.person_outline, 'Account Type', _userData!['userType'] == 'buyer' ? 'Buyer' : 'Seller'),

              SizedBox(height: 40),

              // Sign out button
              Center(
                child: SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.logout),
                    label: Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.textColor,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () async {
                      // Show confirmation dialog
                      final shouldLogout = await _showLogoutConfirmation();
                      if (shouldLogout == true) {
                        await Provider.of<AuthViewModel>(context, listen: false).logout();
                        Navigator.of(context).pushReplacementNamed('/login');
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ADD THIS: Order Summary Card Widget
  Widget _buildOrderSummaryCard() {
    final totalOrders = _orderSummary.values.fold(0, (sum, count) => sum + count);
    final pendingOrders = _orderSummary['pending'] ?? 0;
    final deliveredOrders = _orderSummary['delivered'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Orders',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildOrderStat('Total', '$totalOrders', Icons.shopping_cart),
              _buildOrderStat('Delivered', '$deliveredOrders', Icons.check_circle),
              _buildOrderStat('Pending', '$pendingOrders', Icons.pending),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/order-tracking');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'View All Orders',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ADD THIS: Quick Actions Menu Widget
  Widget _buildQuickActionsMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        SizedBox(height: 16),
        
        // My Orders Menu Item
        _buildMenuTile(
          icon: Icons.shopping_bag_outlined,
          title: 'My Orders',
          subtitle: 'Track your orders and purchase history',
          onTap: () {
            Navigator.of(context).pushNamed('/order-tracking');
          },
        ),
        
        // Favorites Menu Item
        _buildMenuTile(
          icon: Icons.favorite_outline,
          title: 'My Favorites',
          subtitle: 'View your saved recipes',
          onTap: () {
            Navigator.of(context).pushNamed('/favorites');
          },
        ),
        
        // Shopping Cart Menu Item
        _buildMenuTile(
          icon: Icons.shopping_cart_outlined,
          title: 'Shopping Cart',
          subtitle: 'View items in your cart',
          onTap: () {
            Navigator.of(context).pushNamed('/shopping-cart');
          },
        ),
        
        // Settings Menu Item
        _buildMenuTile(
          icon: Icons.settings_outlined,
          title: 'Settings',
          subtitle: 'Manage your account preferences',
          onTap: () {
            // Navigate to settings page when available
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Settings page coming soon!')),
            );
          },
        ),
      ],
    );
  }

  // ADD THIS: Menu Tile Helper Widget
  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  // ADD THIS: Order Stats Helper Widget
  Widget _buildOrderStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Add logout confirmation dialog
  Future<bool?> _showLogoutConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sign Out'),
          content: Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileDetail(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 24,
            color: AppTheme.primaryColor,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value ?? 'Not provided',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}