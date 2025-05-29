import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../utils/app_theme.dart';

class BuyerProfilePage extends StatefulWidget {
  const BuyerProfilePage({Key? key}) : super(key: key);

  @override
  _BuyerProfilePageState createState() => _BuyerProfilePageState();
}

class _BuyerProfilePageState extends State<BuyerProfilePage> {
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

              Divider(height: 40),

              // Profile details
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