// lib/views/buyer/checkout_page.dart (Updated to handle selected items)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/checkout_viewmodel.dart';
import '../../viewmodels/cart_viewmodel.dart';
import '../../models/order_model.dart';
import '../../models/cart_model.dart';
import 'order_success_page.dart'; // Import the success page

class CheckoutPage extends StatelessWidget {
  final List<CartItem>? selectedItems; // Add selected items parameter

  const CheckoutPage({Key? key, this.selectedItems}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CheckoutView(selectedItems: selectedItems);
  }
}

class CheckoutView extends StatefulWidget {
  final List<CartItem>? selectedItems;

  const CheckoutView({Key? key, this.selectedItems}) : super(key: key);

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  late CheckoutViewModel _checkoutViewModel;

  @override
  void initState() {
    super.initState();
    _checkoutViewModel = CheckoutViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkoutViewModel.loadUserAddress();
    });
  }

  @override
  void dispose() {
    _checkoutViewModel.dispose();
    super.dispose();
  }

  // Get items to display (selected items or all cart items)
  List<CartItem> _getItemsToCheckout(CartViewModel cartViewModel) {
    return widget.selectedItems ?? cartViewModel.cart.items;
  }

  // Calculate total for selected items only
  double _getSelectedItemsTotal(CartViewModel cartViewModel) {
    final items = _getItemsToCheckout(cartViewModel);
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEECEE),
      appBar: _buildAppBar(),
      body: Consumer<CartViewModel>(
        builder: (context, cartViewModel, child) {
          return AnimatedBuilder(
            animation: _checkoutViewModel,
            builder: (context, child) {
              if (_checkoutViewModel.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF5B9E),
                  ),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Delivery Address Section
                          _buildDeliveryAddressSection(_checkoutViewModel),
                          const SizedBox(height: 20),

                          // Shipping Options Section
                          _buildShippingOptionsSection(_checkoutViewModel),
                          const SizedBox(height: 20),

                          // Order Summary Section (Updated)
                          _buildOrderSummarySection(cartViewModel),
                          const SizedBox(height: 20),

                          // Payment Details Section (Updated)
                          _buildPaymentDetailsSection(cartViewModel, _checkoutViewModel),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Bar (Updated)
                  _buildBottomActionBar(context, _checkoutViewModel, cartViewModel),
                ],
              );
            },
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFFEECEE),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Checkout',
        style: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildDeliveryAddressSection(CheckoutViewModel checkoutViewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: Color(0xFFFF5B9E),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Delivery Address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _showAddressDialog(checkoutViewModel),
                child: const Text(
                  'Change',
                  style: TextStyle(
                    color: Color(0xFFFF5B9E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (checkoutViewModel.deliveryAddress != null) ...[
            Text(
              checkoutViewModel.deliveryAddress!.recipientName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              checkoutViewModel.deliveryAddress!.phoneNumber,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              checkoutViewModel.deliveryAddress!.fullAddress,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    color: Colors.orange[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Please add a delivery address to continue',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShippingOptionsSection(CheckoutViewModel checkoutViewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.local_shipping,
                color: Color(0xFFFF5B9E),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Shipping Option',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Delivery Option
          _buildShippingOption(
            checkoutViewModel,
            ShippingMethod.delivery,
            'Cash On Delivery',
            'Delivered to your address',
            Icons.home,
          ),

          const SizedBox(height: 12),

          // Self Pickup Option
          _buildShippingOption(
            checkoutViewModel,
            ShippingMethod.selfPickup,
            'Self-Pickup',
            'Pick up from store location',
            Icons.store,
          ),

          // Pickup Location Selection
          if (checkoutViewModel.selectedShippingMethod == ShippingMethod.selfPickup) ...[
            const SizedBox(height: 16),
            const Text(
              'Pickup Location:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ...checkoutViewModel.pickupLocations.map((location) =>
                _buildPickupLocationOption(checkoutViewModel, location)),
          ],
        ],
      ),
    );
  }

  Widget _buildShippingOption(
      CheckoutViewModel checkoutViewModel,
      ShippingMethod method,
      String title,
      String subtitle,
      IconData icon,
      ) {
    final isSelected = checkoutViewModel.selectedShippingMethod == method;

    return GestureDetector(
      onTap: () => checkoutViewModel.setShippingMethod(method),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFFFF5B9E) : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? const Color(0xFFFF5B9E).withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFFF5B9E) : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? const Color(0xFFFF5B9E) : Colors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFFFF5B9E) : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickupLocationOption(CheckoutViewModel checkoutViewModel, String location) {
    final isSelected = checkoutViewModel.selectedPickupLocation == location;

    return GestureDetector(
      onTap: () => checkoutViewModel.setPickupLocation(location),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFFFF5B9E) : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? const Color(0xFFFF5B9E).withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                location,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? const Color(0xFFFF5B9E) : Colors.black,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFFFF5B9E) : Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummarySection(CartViewModel cartViewModel) {
    final itemsToShow = _getItemsToCheckout(cartViewModel);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt,
                color: Color(0xFFFF5B9E),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Show selection indicator
              if (widget.selectedItems != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5B9E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${itemsToShow.length} selected',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFF5B9E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Show selected items only
          ...itemsToShow.take(5).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${item.quantity}x ${item.name}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Text(
                  'RM${item.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )),

          // Show more items indicator
          if (itemsToShow.length > 5) ...[
            Text(
              '... and ${itemsToShow.length - 5} more items',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentDetailsSection(CartViewModel cartViewModel, CheckoutViewModel checkoutViewModel) {
    final subtotal = _getSelectedItemsTotal(cartViewModel); // Use selected items total
    final shippingFee = checkoutViewModel.getShippingFee();
    final total = subtotal + shippingFee; // Only subtotal + delivery fee

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.payment,
                color: Color(0xFFFF5B9E),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Payment Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Subtotal (selected items only)
          _buildPaymentRow('Merchandise Subtotal', 'RM${subtotal.toStringAsFixed(2)}'),

          // Delivery Fee (only show if delivery is selected)
          if (checkoutViewModel.selectedShippingMethod == ShippingMethod.delivery && shippingFee > 0)
            _buildPaymentRow('Delivery Fee', 'RM${shippingFee.toStringAsFixed(2)}'),

          const Divider(height: 24),

          // Total
          _buildPaymentRow(
            'Total Payment',
            'RM${total.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.grey[700],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? const Color(0xFFFF5B9E) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(
      BuildContext context,
      CheckoutViewModel checkoutViewModel,
      CartViewModel cartViewModel,
      ) {
    final canProceed = checkoutViewModel.canProceedToOrder();
    final total = _getSelectedItemsTotal(cartViewModel) +
        checkoutViewModel.getShippingFee(); // Only delivery fee, no COD fee

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Total amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'RM${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF5B9E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Proceed button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canProceed && !checkoutViewModel.isProcessing
                  ? () => _processOrder(context, checkoutViewModel, cartViewModel)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5B9E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: checkoutViewModel.isProcessing
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                'Place Order',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddressDialog(CheckoutViewModel checkoutViewModel) {
    showDialog(
      context: context,
      builder: (context) => AddressDialog(
        onAddressSelected: (address) {
          checkoutViewModel.setDeliveryAddress(address);
        },
        currentAddress: checkoutViewModel.deliveryAddress,
      ),
    );
  }

  void _processOrder(
      BuildContext context,
      CheckoutViewModel checkoutViewModel,
      CartViewModel cartViewModel,
      ) async {
    // Create a temporary cart with only selected items for checkout
    final selectedItems = _getItemsToCheckout(cartViewModel);
    final tempCart = Cart(
      items: selectedItems,
      selectedStore: cartViewModel.selectedStore,
    );

    final success = await checkoutViewModel.processOrder(tempCart);

    if (success) {
      // Remove only selected items from cart, not all items
      if (widget.selectedItems != null) {
        for (final item in widget.selectedItems!) {
          await cartViewModel.removeItem(item.id);
        }
      } else {
        // If no selection (all items), clear entire cart
        await cartViewModel.clearCart();
      }

      // Calculate order details for success page
      final totalAmount = _getSelectedItemsTotal(cartViewModel) +
          checkoutViewModel.getShippingFee();
      final isDelivery = checkoutViewModel.selectedShippingMethod == ShippingMethod.delivery;
      final estimatedTime = checkoutViewModel.getEstimatedTime();
      final orderId = 'YC${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

      // Navigate to success page instead of showing snackbar
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => OrderSuccessPage(
            orderId: orderId,
            totalAmount: totalAmount,
            estimatedDelivery: estimatedTime,
            isDelivery: isDelivery,
          ),
        ),
      );
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(checkoutViewModel.errorMessage.isNotEmpty
              ? checkoutViewModel.errorMessage
              : 'Order failed. Please try again.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

// Address Dialog Widget (unchanged)
class AddressDialog extends StatefulWidget {
  final Function(DeliveryAddress) onAddressSelected;
  final DeliveryAddress? currentAddress;

  const AddressDialog({
    Key? key,
    required this.onAddressSelected,
    this.currentAddress,
  }) : super(key: key);

  @override
  State<AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends State<AddressDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.currentAddress != null) {
      _nameController.text = widget.currentAddress!.recipientName;
      _phoneController.text = widget.currentAddress!.phoneNumber;
      _addressController.text = widget.currentAddress!.addressLine;
      _postcodeController.text = widget.currentAddress!.postcode;
      _cityController.text = widget.currentAddress!.city;
      _stateController.text = widget.currentAddress!.state;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delivery Address'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Recipient Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address Line',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _postcodeController,
                    decoration: const InputDecoration(
                      labelText: 'Postcode',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _stateController,
              decoration: const InputDecoration(
                labelText: 'State',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveAddress,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5B9E),
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveAddress() {
    if (_nameController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _addressController.text.isNotEmpty &&
        _postcodeController.text.isNotEmpty &&
        _cityController.text.isNotEmpty &&
        _stateController.text.isNotEmpty) {

      final address = DeliveryAddress(
        recipientName: _nameController.text,
        phoneNumber: _phoneController.text,
        addressLine: _addressController.text,
        postcode: _postcodeController.text,
        city: _cityController.text,
        state: _stateController.text,
      );

      widget.onAddressSelected(address);
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _postcodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }
}