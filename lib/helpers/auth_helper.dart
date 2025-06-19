// lib/helpers/auth_helper.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthHelper {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user ID
  static String? getCurrentUserId() {
    final user = _auth.currentUser;
    return user?.uid;
  }

  // Get current user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Check if user is authenticated
  static bool isUserAuthenticated() {
    return _auth.currentUser != null;
  }

  // Get current user's email
  static String? getCurrentUserEmail() {
    return _auth.currentUser?.email;
  }

  // Get current user data from Firestore
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return null;

      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('❌ Error getting current user data: $e');
      return null;
    }
  }

  // Check if current user is a seller
  static Future<bool> isCurrentUserSeller() async {
    try {
      final userData = await getCurrentUserData();
      return userData?['userType'] == 'seller';
    } catch (e) {
      print('❌ Error checking user type: $e');
      return false;
    }
  }

  // Check if current user is a buyer
  static Future<bool> isCurrentUserBuyer() async {
    try {
      final userData = await getCurrentUserData();
      return userData?['userType'] == 'buyer';
    } catch (e) {
      print('❌ Error checking user type: $e');
      return false;
    }
  }

  // Update user data in Firestore
  static Future<bool> updateUserData(Map<String, dynamic> data) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return false;

      await _firestore.collection('users').doc(userId).update(data);
      return true;
    } catch (e) {
      print('❌ Error updating user data: $e');
      return false;
    }
  }

  // Sign out user and clear any cached data
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('✅ User signed out successfully');
    } catch (e) {
      print('❌ Error signing out: $e');
      rethrow;
    }
  }

  // Listen to authentication state changes
  static Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }

  // Get user display name or email as fallback
  static String getUserDisplayName() {
    final user = getCurrentUser();
    if (user == null) return 'Guest';
    
    return user.displayName ?? user.email?.split('@').first ?? 'User';
  }

  // Check if this is a new user (first time login)
  static Future<bool> isNewUser() async {
    try {
      final userData = await getCurrentUserData();
      if (userData == null) return true;
      
      // Check if user has been initialized with data
      final hasInitialized = userData['dataInitialized'] ?? false;
      return !hasInitialized;
    } catch (e) {
      print('❌ Error checking if new user: $e');
      return true; // Assume new user on error
    }
  }

  // Mark user as initialized
  static Future<void> markUserAsInitialized() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return;

      await _firestore.collection('users').doc(userId).update({
        'dataInitialized': true,
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ User marked as initialized');
    } catch (e) {
      print('❌ Error marking user as initialized: $e');
    }
  }

  // Validate user session and ensure they have access
  static Future<bool> validateUserSession() async {
    try {
      if (!isUserAuthenticated()) {
        print('❌ No authenticated user');
        return false;
      }

      final userData = await getCurrentUserData();
      if (userData == null) {
        print('❌ No user data found in Firestore');
        return false;
      }

      print('✅ User session valid for: ${userData['email']}');
      return true;
    } catch (e) {
      print('❌ Error validating user session: $e');
      return false;
    }
  }

  // Get user's business/store name (for sellers)
  static Future<String?> getUserStoreName() async {
    try {
      final userData = await getCurrentUserData();
      return userData?['storeName'];
    } catch (e) {
      print('❌ Error getting store name: $e');
      return null;
    }
  }

  // Get user's full profile information
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final userData = await getCurrentUserData();
      if (userData == null) return null;

      // Combine Firebase Auth data with Firestore data
      final user = getCurrentUser();
      if (user == null) return userData;

      return {
        ...userData,
        'uid': user.uid,
        'email': user.email,
        'emailVerified': user.emailVerified,
        'creationTime': user.metadata.creationTime,
        'lastSignInTime': user.metadata.lastSignInTime,
      };
    } catch (e) {
      print('❌ Error getting user profile: $e');
      return null;
    }
  }
}