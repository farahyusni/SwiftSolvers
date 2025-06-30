// lib/viewmodels/checkout_viewmodel.dart (Enhanced Error Handling)
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/cart_model.dart';
import '../services/order_service.dart';
import '../services/user_service.dart';

class CheckoutViewModel extends ChangeNotifier {
  final OrderService _orderService = OrderService();
  final UserService _userService = UserService();

  // State variables
  bool _isLoading = false;
  bool _isProcessing = false;
  String _errorMessage = '';
  String _lastOrderId = ''; // Track the last created order ID

  // Delivery and shipping
  DeliveryAddress? _deliveryAddress;
  ShippingMethod _selectedShippingMethod = ShippingMethod.delivery;
  String _selectedPickupLocation = 'Merbok';

  // Available pickup locations
  final List<String> _pickupLocations = [
    'Merbok',
    'Skudai',
    'Pasir Puteh',
    'Kangar'
  ];

  // Getters
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String get errorMessage => _errorMessage;
  String get lastOrderId => _lastOrderId;
  DeliveryAddress? get deliveryAddress => _deliveryAddress;
  ShippingMethod get selectedShippingMethod => _selectedShippingMethod;
  String get selectedPickupLocation => _selectedPickupLocation;
  List<String> get pickupLocations => _pickupLocations;

  // Constructor
  CheckoutViewModel() {
    loadUserAddress();
  }

  // Load user's default address with better error handling
  Future<void> loadUserAddress() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      print('🏠 Loading user default address...');
      _deliveryAddress = await _userService.getUserDefaultAddress();

      if (_deliveryAddress != null) {
        print('✅ Loaded user address: ${_deliveryAddress!.recipientName}');
      } else {
        print('ℹ️ No default address found');
      }
    } catch (e) {
      _errorMessage = 'Failed to load address: $e';
      print('❌ Error loading address: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set delivery address
  void setDeliveryAddress(DeliveryAddress address) {
    _deliveryAddress = address;
    _errorMessage = ''; // Clear any previous errors
    notifyListeners();

    // Save as default address
    _userService.saveUserDefaultAddress(address).catchError((error) {
      print('❌ Error saving default address: $error');
      // Don't show this error to user as it's not critical for checkout
    });
  }

  // Set shipping method
  void setShippingMethod(ShippingMethod method) {
    _selectedShippingMethod = method;
    _errorMessage = ''; // Clear any previous errors

    // Set default pickup location if switching to self-pickup
    if (method == ShippingMethod.selfPickup && _selectedPickupLocation.isEmpty) {
      _selectedPickupLocation = _pickupLocations.first;
    }

    notifyListeners();
  }

  // Set pickup location
  void setPickupLocation(String location) {
    _selectedPickupLocation = location;
    _errorMessage = ''; // Clear any previous errors
    notifyListeners();
  }

  // Get COD fee (removed since we have delivery fee)
  double getCODFee() {
    return 0.0; // No COD fee
  }

  // Get shipping fee (only for Cash on Delivery)
  double getShippingFee() {
    switch (_selectedShippingMethod) {
      case ShippingMethod.delivery:
        return 5.0; // RM5 delivery fee for Cash on Delivery
      case ShippingMethod.selfPickup:
        return 0.0; // No shipping fee for pickup
    }
  }

  // Calculate total amount
  double calculateTotal(double subtotal) {
    return subtotal + getCODFee() + getShippingFee();
  }

  // Enhanced validation
  bool canProceedToOrder() {
    if (_selectedShippingMethod == ShippingMethod.delivery) {
      return _deliveryAddress != null && isAddressValid(_deliveryAddress);
    } else {
      return _selectedPickupLocation.isNotEmpty;
    }
  }

  // Enhanced process order with better error handling
  Future<bool> processOrder(Cart cart) async {
    print('🛒 Starting order processing...');

    // Reset state
    _errorMessage = '';
    _lastOrderId = '';

    // Validation checks
    if (!canProceedToOrder()) {
      if (_selectedShippingMethod == ShippingMethod.delivery) {
        if (_deliveryAddress == null) {
          _errorMessage = 'Please add a delivery address';
        } else if (!isAddressValid(_deliveryAddress)) {
          _errorMessage = 'Please complete all address fields';
        }
      } else {
        _errorMessage = 'Please select a pickup location';
      }
      notifyListeners();
      return false;
    }

    if (cart.isEmpty) {
      _errorMessage = 'Your cart is empty';
      notifyListeners();
      return false;
    }

    _isProcessing = true;
    notifyListeners();

    try {
      print('🛒 Processing order...');
      print('🛒 Cart items: ${cart.items.length}');
      print('🛒 Shipping method: $_selectedShippingMethod');
      print('🛒 Delivery address: ${_deliveryAddress?.recipientName ?? 'N/A'}');
      print('🛒 Pickup location: $_selectedPickupLocation');

      // Create order using the service
      final success = await _orderService.createOrderFromCheckout(
        cart: cart,
        deliveryAddress: _selectedShippingMethod == ShippingMethod.delivery
            ? _deliveryAddress
            : null,
        shippingMethod: _selectedShippingMethod,
        pickupLocation: _selectedShippingMethod == ShippingMethod.selfPickup
            ? _selectedPickupLocation
            : null,
        codFee: getCODFee(),
        shippingFee: getShippingFee(),
      );

      if (success) {
        print('✅ Order processed successfully');

        // Generate order ID for UI (simplified version)
        _lastOrderId = _orderService.lastCreatedOrderId ?? DateTime.now().millisecondsSinceEpoch.toString();
        // Send confirmation notifications (if implemented)
        _sendOrderConfirmation(cart);

        return true;
      } else {
        _errorMessage = 'Failed to create order. Please try again.';
        print('❌ Failed to create order');
        return false;
      }

    } catch (e) {
      // Handle different types of errors
      final errorString = e.toString();

      if (errorString.contains('not authenticated') || errorString.contains('User not logged in')) {
        _errorMessage = 'Please log in again to place your order';
      } else if (errorString.contains('permission-denied')) {
        _errorMessage = 'Permission denied. Please check your account';
      } else if (errorString.contains('unavailable') || errorString.contains('network')) {
        _errorMessage = 'Network error. Please check your connection and try again';
      } else if (errorString.contains('timeout') || errorString.contains('deadline-exceeded')) {
        _errorMessage = 'Request timeout. Please try again';
      } else if (errorString.contains('address') || errorString.contains('Delivery address')) {
        _errorMessage = 'Please complete your delivery address';
      } else if (errorString.contains('pickup') || errorString.contains('Pickup location')) {
        _errorMessage = 'Please select a pickup location';
      } else if (errorString.contains('Cart is empty')) {
        _errorMessage = 'Your cart is empty';
      } else {
        // Generic error message for unknown errors
        _errorMessage = 'Order failed. Please try again or contact support';
      }

      print('❌ Error processing order: $e');
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // Send order confirmation (placeholder for future implementation)
  void _sendOrderConfirmation(Cart cart) {
    // This is where you would:
    // 1. Send push notification to user
    // 2. Send email confirmation
    // 3. Notify the store/vendor
    // 4. Update any analytics

    print('📧 Sending order confirmation...');
    print('📧 Order details:');
    print('   - Order ID: $_lastOrderId');
    print('   - Total: RM${calculateTotal(cart.totalPrice).toStringAsFixed(2)}');
    print('   - Items: ${cart.totalItems}');
    print('   - Shipping: ${_selectedShippingMethod.name}');

    if (_deliveryAddress != null) {
      print('   - Delivery to: ${_deliveryAddress!.recipientName}');
    }

    if (_selectedPickupLocation.isNotEmpty) {
      print('   - Pickup at: $_selectedPickupLocation');
    }
  }

  // Get estimated delivery/pickup time
  String getEstimatedTime() {
    final now = DateTime.now();
    DateTime estimatedTime;

    switch (_selectedShippingMethod) {
      case ShippingMethod.delivery:
        estimatedTime = now.add(const Duration(hours: 2));
        break;
      case ShippingMethod.selfPickup:
        estimatedTime = now.add(const Duration(minutes: 30));
        break;
    }

    final hour = estimatedTime.hour;
    final minute = estimatedTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$displayHour:$minute $period';
  }

  // Get order summary for confirmation
  Map<String, dynamic> getOrderSummary(Cart cart) {
    return {
      'orderId': _lastOrderId,
      'itemCount': cart.totalItems,
      'subtotal': cart.totalPrice,
      'shippingFee': getShippingFee(),
      'codFee': getCODFee(),
      'total': calculateTotal(cart.totalPrice),
      'shippingMethod': _selectedShippingMethod,
      'deliveryAddress': _deliveryAddress,
      'pickupLocation': _selectedPickupLocation,
      'estimatedTime': getEstimatedTime(),
    };
  }

  // Enhanced address validation
  bool isAddressValid(DeliveryAddress? address) {
    if (address == null) return false;

    return address.recipientName.trim().isNotEmpty &&
        address.phoneNumber.trim().isNotEmpty &&
        address.addressLine.trim().isNotEmpty &&
        address.postcode.trim().isNotEmpty &&
        address.city.trim().isNotEmpty &&
        address.state.trim().isNotEmpty;
  }

  // Get shipping method description
  String getShippingDescription() {
    switch (_selectedShippingMethod) {
      case ShippingMethod.delivery:
        return 'Your order will be delivered to your address';
      case ShippingMethod.selfPickup:
        return 'You can pick up your order from the selected location';
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  // Reset checkout state
  void reset() {
    _selectedShippingMethod = ShippingMethod.delivery;
    _selectedPickupLocation = _pickupLocations.first;
    _errorMessage = '';
    _lastOrderId = '';
    _isProcessing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}