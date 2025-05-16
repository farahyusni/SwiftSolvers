import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isLoginView = true; // Toggle between login and register views

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoginView => _isLoginView;

  // Constructor - check if user is already logged in
  AuthViewModel() {
    _currentUser = _authService.getCurrentUser();
  }

  // Toggle between login and register views
  void toggleAuthView() {
    _isLoginView = !_isLoginView;
    _errorMessage = ''; // Clear any error messages when toggling
    notifyListeners();
  }

  // Login user
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      _currentUser = await _authService.login(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Register user
  // Future<bool> register(String email, String password, String? displayName) async {
  //   _isLoading = true;
  //   _errorMessage = '';
  //   notifyListeners();
  //
  //   try {
  //     _currentUser = await _authService.register(email, password, displayName);
  //     _isLoading = false;
  //     notifyListeners();
  //     return true;
  //   } catch (e) {
  //     _isLoading = false;
  //     _errorMessage = e.toString();
  //     notifyListeners();
  //     return false;
  //   }
  // }
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String address,
    required String userType,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _currentUser = await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        address: address,
        userType: userType,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}