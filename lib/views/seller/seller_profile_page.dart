import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../utils/app_theme.dart';

class SellerProfilePage extends StatefulWidget {
  const SellerProfilePage({Key? key}) : super(key: key);

  @override
  _SellerProfilePageState createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends State<SellerProfilePage> {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final auth.User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Fetch user data from Firestore
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seller Profile'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          // Edit profile button
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
                        // Profile header with avatar
                        Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: AppTheme.lightPinkColor,
                               child: Icon(
  Icons.person,
  size: 80,
  color: AppTheme.primaryColor,
),

                              ),
                              SizedBox(height: 16),
                              Text(
                                _userData!['fullName'] ?? 'Seller',
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

                        Divider(height: 40),

                        // Profile details
                        _buildProfileDetail(Icons.phone, 'Phone', _userData!['phone']),
                        _buildProfileDetail(Icons.location_on, 'Address', _userData!['address']),
                        _buildProfileDetail(Icons.store_mall_directory, 'Store Name', _userData!['storeName']),
                        _buildProfileDetail(Icons.person_outline, 'Account Type', _userData!['userType'] == 'seller' ? 'Seller' : 'Buyer'),

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
                                // Sign out
                                await Provider.of<AuthViewModel>(context, listen: false).logout();
                                Navigator.of(context).pushReplacementNamed('/login');
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
