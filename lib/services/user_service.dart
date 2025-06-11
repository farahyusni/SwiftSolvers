// lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get user's default delivery address
  Future<DeliveryAddress?> getUserDefaultAddress() async {
    try {
      if (currentUserId == null) {
        print('❌ User not logged in');
        return null;
      }

      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final addressData = data['defaultAddress'] as Map<String, dynamic>?;

        if (addressData != null) {
          return DeliveryAddress.fromMap(addressData);
        }
      }

      print('ℹ️ No default address found for user');
      return null;

    } catch (e) {
      print('❌ Error getting user default address: $e');
      return null;
    }
  }

  // Save user's default delivery address
  Future<bool> saveUserDefaultAddress(DeliveryAddress address) async {
    try {
      if (currentUserId == null) {
        print('❌ User not logged in');
        return false;
      }

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .set({
        'defaultAddress': address.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Default address saved for user: $currentUserId');
      return true;

    } catch (e) {
      print('❌ Error saving user default address: $e');
      return false;
    }
  }

  // Get all user addresses
  Future<List<DeliveryAddress>> getUserAddresses() async {
    try {
      if (currentUserId == null) {
        return [];
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('addresses')
          .get();

      return snapshot.docs
          .map((doc) => DeliveryAddress.fromMap(doc.data()))
          .toList();

    } catch (e) {
      print('❌ Error getting user addresses: $e');
      return [];
    }
  }

  // Add new address to user's address book
  Future<bool> addUserAddress(DeliveryAddress address) async {
    try {
      if (currentUserId == null) {
        return false;
      }

      final addressId = 'addr_${DateTime.now().millisecondsSinceEpoch}';

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('addresses')
          .doc(addressId)
          .set({
        ...address.toMap(),
        'id': addressId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Address added to user address book: $addressId');
      return true;

    } catch (e) {
      print('❌ Error adding user address: $e');
      return false;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      if (currentUserId == null) {
        return false;
      }

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .set({
        ...profileData,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ User profile updated: $currentUserId');
      return true;

    } catch (e) {
      print('❌ Error updating user profile: $e');
      return false;
    }
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUserId == null) {
        return null;
      }

      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }

      return null;

    } catch (e) {
      print('❌ Error getting user profile: $e');
      return null;
    }
  }

  // Initialize user document (called after registration)
  Future<bool> initializeUserDocument({
    required String displayName,
    required String email,
  }) async {
    try {
      if (currentUserId == null) {
        return false;
      }

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .set({
        'uid': currentUserId,
        'displayName': displayName,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ User document initialized: $currentUserId');
      return true;

    } catch (e) {
      print('❌ Error initializing user document: $e');
      return false;
    }
  }

  // Delete user address
  Future<bool> deleteUserAddress(String addressId) async {
    try {
      if (currentUserId == null) {
        return false;
      }

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('addresses')
          .doc(addressId)
          .delete();

      print('✅ Address deleted: $addressId');
      return true;

    } catch (e) {
      print('❌ Error deleting address: $e');
      return false;
    }
  }

  // Update user address
  Future<bool> updateUserAddress(String addressId, DeliveryAddress address) async {
    try {
      if (currentUserId == null) {
        return false;
      }

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('addresses')
          .doc(addressId)
          .update({
        ...address.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Address updated: $addressId');
      return true;

    } catch (e) {
      print('❌ Error updating address: $e');
      return false;
    }
  }

  // Check if user exists
  Future<bool> userExists() async {
    try {
      if (currentUserId == null) {
        return false;
      }

      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      return doc.exists;

    } catch (e) {
      print('❌ Error checking if user exists: $e');
      return false;
    }
  }

  // Get user's favorite recipes
  Future<List<String>> getUserFavoriteRecipes() async {
    try {
      if (currentUserId == null) {
        return [];
      }

      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final favorites = data['favoriteRecipes'] as List<dynamic>?;
        return favorites?.cast<String>() ?? [];
      }

      return [];

    } catch (e) {
      print('❌ Error getting user favorite recipes: $e');
      return [];
    }
  }

  // Add recipe to favorites
  Future<bool> addToFavorites(String recipeId) async {
    try {
      if (currentUserId == null) {
        return false;
      }

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .update({
        'favoriteRecipes': FieldValue.arrayUnion([recipeId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Recipe added to favorites: $recipeId');
      return true;

    } catch (e) {
      print('❌ Error adding recipe to favorites: $e');
      return false;
    }
  }

  // Remove recipe from favorites
  Future<bool> removeFromFavorites(String recipeId) async {
    try {
      if (currentUserId == null) {
        return false;
      }

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .update({
        'favoriteRecipes': FieldValue.arrayRemove([recipeId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Recipe removed from favorites: $recipeId');
      return true;

    } catch (e) {
      print('❌ Error removing recipe from favorites: $e');
      return false;
    }
  }
}