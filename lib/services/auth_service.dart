import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? getCurrentUser() {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;
    
    return User(
      id: firebaseUser.uid,
      email: firebaseUser.email!,
      displayName: firebaseUser.displayName,
    );
  }
  
  // Login with email and password
  Future<User> login(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return User(
        id: userCredential.user!.uid,
        email: userCredential.user!.email!,
        displayName: userCredential.user!.displayName,
      );
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }
  
  // Register a new user
  // Future<User> register(String email, String password, String? displayName) async {
  //   try {
  //     final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
  //       email: email,
  //       password: password,
  //     );
  //
  //     // Update display name if provided
  //     if (displayName != null && displayName.isNotEmpty) {
  //       await userCredential.user!.updateDisplayName(displayName);
  //     }
  //
  //     return User(
  //       id: userCredential.user!.uid,
  //       email: userCredential.user!.email!,
  //       displayName: displayName,
  //     );
  //   } catch (e) {
  //     throw Exception('Failed to register: $e');
  //   }
  // }

  Future<User> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String address,
    required String userType,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name in Firebase Auth profile
      await userCredential.user!.updateDisplayName(fullName);

      // Save extra info in Firestore under "users" collection
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'fullName': fullName,
        'phone': phone,
        'address': address,
        'email': email,
        'userType': userType,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return User(
        id: userCredential.user!.uid,
        email: email,
        displayName: fullName,
        phone: phone,
        address: address,
        userType: userType,
      );
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

Future<String?> getUserRole(String uid) async {
  try {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data()?['userType'];
    }
    return null;
  } catch (e) {
    throw Exception('Failed to get user role: $e');
  }
}


  // Logout user
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }
  
  // Password reset
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw e;
    }
  }
}