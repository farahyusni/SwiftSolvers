// lib/viewmodels/cart_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../models/cart_model.dart';
import '../services/cart_service.dart';

class CartViewModel extends ChangeNotifier {
  final CartService _cartService = CartService();
  
  Cart _cart = Cart();
  bool _isLoading = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _availableStores = [];
  bool _isProcessingCheckout = false;

  // Getters
  Cart get cart => _cart;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get availableStores => _availableStores;
  bool get isProcessingCheckout => _isProcessingCheckout;
  
  // Convenience getters
  int get totalItems => _cart.totalItems;
  double get totalPrice => _cart.totalPrice;
  bool get isEmpty => _cart.isEmpty;
  bool get isNotEmpty => _cart.isNotEmpty;
  String get selectedStore => _cart.selectedStore;

  // Constructor
  CartViewModel() {
    loadCart();
    loadAvailableStores();
  }

  // Load cart from service
  Future<void> loadCart() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _cart = await _cartService.getCart();
      print('🛒 Cart loaded: ${_cart.items.length} items');
    } catch (e) {
      _errorMessage = 'Failed to load cart: $e';
      print('❌ Error loading cart: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load available stores
  Future<void> loadAvailableStores() async {
    try {
      _availableStores = await _cartService.getAvailableStores();
      print('🏪 Loaded ${_availableStores.length} stores');
    } catch (e) {
      print('❌ Error loading stores: $e');
      // Set default stores if loading fails
      _availableStores = [
        {'id': 'tesco', 'name': 'Tesco', 'deliveryFee': 5.0},
        {'id': 'mydin', 'name': 'Mydin', 'deliveryFee': 4.0},
        {'id': 'giant', 'name': 'Giant', 'deliveryFee': 6.0},
      ];
    }
    notifyListeners();
  }

  // Add ingredients to cart
  Future<bool> addIngredientsToCart({
    required Map<String, dynamic> recipe,
    required List<bool> checkedIngredients,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final success = await _cartService.addIngredientsToCart(
        recipe: recipe,
        checkedIngredients: checkedIngredients,
      );

      if (success) {
        // Reload cart to get updated data
        await loadCart();
        return true;
      } else {
        _errorMessage = 'Failed to add ingredients to cart';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error adding to cart: $e';
      print('❌ Error in addIngredientsToCart: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update item quantity
  Future<bool> updateItemQuantity(String itemId, int newQuantity) async {
    try {
      final success = await _cartService.updateItemQuantity(itemId, newQuantity);
      
      if (success) {
        // Update local cart immediately for better UX
        final itemIndex = _cart.items.indexWhere((item) => item.id == itemId);
        if (itemIndex >= 0) {
          final updatedItems = List<CartItem>.from(_cart.items);
          
          if (newQuantity <= 0) {
            updatedItems.removeAt(itemIndex);
          } else {
            updatedItems[itemIndex] = updatedItems[itemIndex].copyWith(
              quantity: newQuantity,
            );
          }
          
          _cart = _cart.copyWith(items: updatedItems);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update quantity: $e';
      notifyListeners();
      return false;
    }
  }

  // Remove item from cart
  Future<bool> removeItem(String itemId) async {
    try {
      final success = await _cartService.removeItem(itemId);
      
      if (success) {
        // Update local cart immediately
        final updatedItems = _cart.items.where((item) => item.id != itemId).toList();
        _cart = _cart.copyWith(items: updatedItems);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to remove item: $e';
      notifyListeners();
      return false;
    }
  }

  // Change selected store
  Future<bool> changeStore(String newStore) async {
    try {
      final success = await _cartService.changeStore(newStore);
      
      if (success) {
        // Update local cart immediately
        final updatedItems = _cart.items
            .map((item) => item.copyWith(selectedStore: newStore))
            .toList();
        _cart = Cart(items: updatedItems, selectedStore: newStore);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to change store: $e';
      notifyListeners();
      return false;
    }
  }

  // Clear cart
  Future<bool> clearCart() async {
    try {
      final success = await _cartService.clearCart();
      
      if (success) {
        _cart = Cart();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to clear cart: $e';
      notifyListeners();
      return false;
    }
  }

  // Process checkout
  Future<bool> processCheckout() async {
    if (_cart.isEmpty) {
      _errorMessage = 'Cart is empty';
      notifyListeners();
      return false;
    }

    _isProcessingCheckout = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final success = await _cartService.processCheckout();
      
      if (success) {
        _cart = Cart(); // Clear local cart
        return true;
      } else {
        _errorMessage = 'Checkout failed. Please try again.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Checkout error: $e';
      return false;
    } finally {
      _isProcessingCheckout = false;
      notifyListeners();
    }
  }

  // Get delivery fee for current store
  double getDeliveryFee() {
    final store = _availableStores.firstWhere(
      (store) => store['id'] == _cart.selectedStore,
      orElse: () => {'deliveryFee': 5.0},
    );
    return (store['deliveryFee'] as num?)?.toDouble() ?? 5.0;
  }

  // Get minimum order for current store
  double getMinimumOrder() {
    final store = _availableStores.firstWhere(
      (store) => store['id'] == _cart.selectedStore,
      orElse: () => {'minimumOrder': 50.0},
    );
    return (store['minimumOrder'] as num?)?.toDouble() ?? 50.0;
  }

  // Check if order meets minimum requirement
  bool meetsMinimumOrder() {
    return _cart.totalPrice >= getMinimumOrder();
  }

  // Get final total (including delivery fee)
  double getFinalTotal() {
    return _cart.totalPrice + getDeliveryFee();
  }

  // Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  // Increment item quantity
  Future<void> incrementQuantity(String itemId) async {
    final item = _cart.items.firstWhere((item) => item.id == itemId);
    await updateItemQuantity(itemId, item.quantity + 1);
  }

  // Decrement item quantity
  Future<void> decrementQuantity(String itemId) async {
    final item = _cart.items.firstWhere((item) => item.id == itemId);
    await updateItemQuantity(itemId, item.quantity - 1);
  }
}