// lib/views/buyer/shopping_cart_page.dart (Fixed Enhanced UI)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/cart_viewmodel.dart';
import '../../models/cart_model.dart';
import 'checkout_page.dart';

class ShoppingCartPage extends StatelessWidget {
  const ShoppingCartPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ShoppingCartView();
  }
}

class ShoppingCartView extends StatefulWidget {
  const ShoppingCartView({Key? key}) : super(key: key);

  @override
  State<ShoppingCartView> createState() => _ShoppingCartViewState();
}

class _ShoppingCartViewState extends State<ShoppingCartView> {
  Set<String> _selectedItemIds = {};
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartViewModel = Provider.of<CartViewModel>(context, listen: false);
      cartViewModel.loadCart().then((_) {
        if (mounted) {
          setState(() {
            _selectedItemIds = cartViewModel.cart.items.map((item) => item.id).toSet();
            _selectAll = _selectedItemIds.isNotEmpty;
          });
        }
      });
    });
  }

  void _toggleSelectAll(CartViewModel cartViewModel) {
    setState(() {
      if (_selectAll) {
        _selectedItemIds.clear();
        _selectAll = false;
      } else {
        _selectedItemIds = cartViewModel.cart.items.map((item) => item.id).toSet();
        _selectAll = true;
      }
    });
  }

  void _toggleItemSelection(String itemId, CartViewModel cartViewModel) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        _selectedItemIds.add(itemId);
      }
      _selectAll = _selectedItemIds.length == cartViewModel.cart.items.length;
    });
  }

  List<CartItem> _getSelectedItems(CartViewModel cartViewModel) {
    return cartViewModel.cart.items.where((item) => _selectedItemIds.contains(item.id)).toList();
  }

  double _getSelectedItemsTotal() {
    final cartViewModel = Provider.of<CartViewModel>(context, listen: false);
    return _getSelectedItems(cartViewModel).fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  int _getSelectedItemsCount() {
    final cartViewModel = Provider.of<CartViewModel>(context, listen: false);
    return _getSelectedItems(cartViewModel).fold(0, (sum, item) => sum + item.quantity);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Consumer<CartViewModel>(
          builder: (context, cartViewModel, child) {
            if (cartViewModel.isLoading) {
              return _buildLoadingState();
            }

            if (cartViewModel.isEmpty) {
              return _buildEmptyCart(context);
            }

            return Column(
              children: [
                // Custom App Bar
                _buildCustomAppBar(context, cartViewModel),

                // Main Content
                Expanded(
                  child: Column(
                    children: [
                      // Store selector
                      _buildStoreSelector(context, cartViewModel),

                      // Select all section
                      _buildSelectAllSection(cartViewModel),

                      // Cart items
                      Expanded(
                        child: _buildCartItems(context, cartViewModel),
                      ),
                    ],
                  ),
                ),

                // Sticky bottom checkout section
                _buildStickyCheckoutSection(context, cartViewModel),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFFFF5B9E),
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Loading your cart...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context, CartViewModel cartViewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 16),

          // Title and summary
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Shopping Cart',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${cartViewModel.cart.items.length} types • ${cartViewModel.totalItems} items',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: IconButton(
                  icon: const Icon(Icons.favorite_outline, size: 20),
                  onPressed: () {
                    Navigator.of(context).pushNamed('/favorites');
                  },
                ),
              ),
              const SizedBox(width: 8),

              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  onPressed: () => _showClearCartDialog(context, cartViewModel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty cart illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5B9E).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 60,
                color: Color(0xFFFF5B9E),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              'Discover delicious recipes and add ingredients to your cart!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // CTA buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed('/buyer-home');
                },
                icon: const Icon(Icons.explore),
                label: const Text('Browse Recipes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5B9E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed('/favorites');
                },
                icon: const Icon(Icons.favorite_outline),
                label: const Text('View Favorites'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF5B9E),
                  side: const BorderSide(color: Color(0xFFFF5B9E)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreSelector(BuildContext context, CartViewModel cartViewModel) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5B9E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.store,
              color: Color(0xFFFF5B9E),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Store',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                DropdownButton<String>(
                  value: cartViewModel.selectedStore,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  items: cartViewModel.availableStores.map((store) {
                    return DropdownMenuItem<String>(
                      value: store['id'],
                      child: Text(store['name']),
                    );
                  }).toList(),
                  onChanged: (String? newStore) {
                    if (newStore != null) {
                      cartViewModel.changeStore(newStore);
                    }
                  },
                ),
              ],
            ),
          ),

          Icon(
            Icons.info_outline,
            size: 20,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectAllSection(CartViewModel cartViewModel) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Enhanced checkbox
          GestureDetector(
            onTap: () => _toggleSelectAll(cartViewModel),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _selectAll ? const Color(0xFFFF5B9E) : Colors.grey[300]!,
                  width: 2,
                ),
                color: _selectAll ? const Color(0xFFFF5B9E) : Colors.transparent,
              ),
              child: _selectAll
                  ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              )
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select All Items',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _selectAll ? const Color(0xFFFF5B9E) : Colors.black,
                  ),
                ),
                Text(
                  '${cartViewModel.cart.items.length} types available',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Selection counter
          if (_selectedItemIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5B9E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_selectedItemIds.length} selected',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFFF5B9E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCartItems(BuildContext context, CartViewModel cartViewModel) {
    final itemsByRecipe = cartViewModel.cart.itemsByRecipe;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: itemsByRecipe.length,
      itemBuilder: (context, index) {
        final recipeId = itemsByRecipe.keys.elementAt(index);
        final recipeItems = itemsByRecipe[recipeId]!;
        final recipeName = recipeItems.first.recipeName;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Recipe header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5B9E).withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5B9E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        color: Color(0xFFFF5B9E),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipeName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF5B9E),
                            ),
                          ),
                          Text(
                            '${recipeItems.length} ingredients',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Recipe ingredients
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: recipeItems.map((item) =>
                      _buildEnhancedCartItemTile(context, item, cartViewModel)).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnhancedCartItemTile(BuildContext context, CartItem item, CartViewModel cartViewModel) {
    final isSelected = _selectedItemIds.contains(item.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFF5B9E).withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFFFF5B9E).withOpacity(0.3) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Selection checkbox
          GestureDetector(
            onTap: () => _toggleItemSelection(item.id, cartViewModel),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? const Color(0xFFFF5B9E) : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelected ? const Color(0xFFFF5B9E) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 12,
              )
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Item info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.black : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.amount}${item.unit.isNotEmpty ? ' ${item.unit}' : ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),

          // Quantity controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => cartViewModel.decrementQuantity(item.id),
                  child: Container(
                    width: 28,
                    height: 28,
                    child: const Icon(
                      Icons.remove,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 40),
                  child: Text(
                    '${item.quantity}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => cartViewModel.incrementQuantity(item.id),
                  child: Container(
                    width: 28,
                    height: 28,
                    child: const Icon(
                      Icons.add,
                      size: 16,
                      color: Color(0xFFFF5B9E),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'RM${item.totalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? const Color(0xFFFF5B9E) : Colors.grey[400],
                ),
              ),
              if (item.quantity > 1)
                Text(
                  'RM${item.currentPrice.toStringAsFixed(2)}/each',
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStickyCheckoutSection(BuildContext context, CartViewModel cartViewModel) {
    final selectedItemsTotal = _getSelectedItemsTotal();
    final selectedItemsCount = _getSelectedItemsCount();
    final hasSelectedItems = _selectedItemIds.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasSelectedItems) ...[
                // Summary without delivery fee
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Selected Items ($selectedItemsCount)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'RM${selectedItemsTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const Divider(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subtotal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'RM${selectedItemsTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF5B9E),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Info about delivery fee
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5B9E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: const Color(0xFFFF5B9E),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Delivery fees will be calculated at checkout',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFFFF5B9E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],

              // Checkout button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: hasSelectedItems
                      ? () => _navigateToCheckout(context, cartViewModel)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5B9E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor: Colors.grey[300],
                    elevation: hasSelectedItems ? 2 : 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (hasSelectedItems) ...[
                        const Icon(Icons.shopping_bag_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Checkout ($selectedItemsCount items)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else ...[
                        const Icon(Icons.check_circle_outline, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Select items to continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, CartViewModel cartViewModel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Clear Cart'),
          content: const Text('Are you sure you want to remove all items from your cart?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                cartViewModel.clearCart();
                setState(() {
                  _selectedItemIds.clear();
                  _selectAll = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToCheckout(BuildContext context, CartViewModel cartViewModel) {
    final selectedItems = _getSelectedItems(cartViewModel);

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select items to checkout'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    // Pass selected items to checkout page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CheckoutPage(selectedItems: selectedItems),
      ),
    );
  }
}