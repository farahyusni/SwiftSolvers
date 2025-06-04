// lib/services/cart_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_model.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Add ingredients to cart (only unticked ones)
  Future<bool> addIngredientsToCart({
    required Map<String, dynamic> recipe,
    required List<bool> checkedIngredients,
  }) async {
    try {
      if (currentUserId == null) {
        print('❌ User not logged in');
        return false;
      }

      print('🛒 Adding ingredients to cart...');
      
      final ingredients = recipe['ingredients'] as List<dynamic>? ?? [];
      final recipeId = recipe['id']?.toString() ?? '';
      final recipeName = recipe['name']?.toString() ?? 'Unknown Recipe';

      print('🛒 Recipe: $recipeName');
      print('🛒 Total ingredients: ${ingredients.length}');
      print('🛒 Checked ingredients: $checkedIngredients');

      List<CartItem> newItems = [];

      // Only add unticked (unchecked) ingredients
      for (int i = 0; i < ingredients.length; i++) {
        if (i < checkedIngredients.length && !checkedIngredients[i]) {
          // This ingredient is NOT checked, so user doesn't have it
          final ingredient = ingredients[i];
          final cartItem = CartItem.fromIngredient(
            ingredient: ingredient,
            recipeId: recipeId,
            recipeName: recipeName,
          );
          newItems.add(cartItem);
          print('🛒 Adding: ${cartItem.name}');
        }
      }

      if (newItems.isEmpty) {
        print('🛒 No unchecked ingredients to add');
        return true; // Success but nothing to add
      }

      // Get existing cart
      final existingCart = await getCart();
      final updatedItems = List<CartItem>.from(existingCart.items);

      // Add new items or update quantities if item already exists
      for (var newItem in newItems) {
        final existingIndex = updatedItems.indexWhere(
          (item) => item.name == newItem.name && item.recipeId == newItem.recipeId,
        );

        if (existingIndex >= 0) {
          // Item exists, increase quantity
          updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
            quantity: updatedItems[existingIndex].quantity + 1,
          );
          print('🛒 Updated quantity for: ${newItem.name}');
        } else {
          // New item, add to cart
          updatedItems.add(newItem);
          print('🛒 Added new item: ${newItem.name}');
        }
      }

      // Save updated cart
      await _saveCart(Cart(
        items: updatedItems,
        selectedStore: existingCart.selectedStore,
      ));

      print('✅ Successfully added ${newItems.length} ingredients to cart');
      return true;

    } catch (e) {
      print('❌ Error adding ingredients to cart: $e');
      return false;
    }
  }

  // Get user's cart
  Future<Cart> getCart() async {
    try {
      if (currentUserId == null) {
        return Cart();
      }

      final doc = await _firestore
          .collection('carts')
          .doc(currentUserId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final itemsList = data['items'] as List<dynamic>? ?? [];
        final items = itemsList
            .map((item) => CartItem.fromMap(item as Map<String, dynamic>))
            .toList();

        return Cart(
          items: items,
          selectedStore: data['selectedStore'] ?? 'tesco',
        );
      }

      return Cart();
    } catch (e) {
      print('❌ Error getting cart: $e');
      return Cart();
    }
  }

  // Save cart to Firestore
  Future<void> _saveCart(Cart cart) async {
    if (currentUserId == null) return;

    try {
      await _firestore.collection('carts').doc(currentUserId).set({
        'items': cart.items.map((item) => item.toMap()).toList(),
        'selectedStore': cart.selectedStore,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error saving cart: $e');
      rethrow;
    }
  }

  // Update item quantity
  Future<bool> updateItemQuantity(String itemId, int newQuantity) async {
    try {
      final cart = await getCart();
      final itemIndex = cart.items.indexWhere((item) => item.id == itemId);

      if (itemIndex >= 0) {
        final updatedItems = List<CartItem>.from(cart.items);
        
        if (newQuantity <= 0) {
          // Remove item if quantity is 0 or negative
          updatedItems.removeAt(itemIndex);
        } else {
          // Update quantity
          updatedItems[itemIndex] = updatedItems[itemIndex].copyWith(
            quantity: newQuantity,
          );
        }

        await _saveCart(Cart(
          items: updatedItems,
          selectedStore: cart.selectedStore,
        ));
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error updating item quantity: $e');
      return false;
    }
  }

  // Remove item from cart
  Future<bool> removeItem(String itemId) async {
    try {
      final cart = await getCart();
      final updatedItems = cart.items.where((item) => item.id != itemId).toList();

      await _saveCart(Cart(
        items: updatedItems,
        selectedStore: cart.selectedStore,
      ));
      return true;
    } catch (e) {
      print('❌ Error removing item: $e');
      return false;
    }
  }

  // Change selected store for all items
  Future<bool> changeStore(String newStore) async {
    try {
      final cart = await getCart();
      final updatedItems = cart.items
          .map((item) => item.copyWith(selectedStore: newStore))
          .toList();

      await _saveCart(Cart(
        items: updatedItems,
        selectedStore: newStore,
      ));
      return true;
    } catch (e) {
      print('❌ Error changing store: $e');
      return false;
    }
  }

  // Clear cart
  Future<bool> clearCart() async {
    try {
      if (currentUserId == null) return false;

      await _firestore.collection('carts').doc(currentUserId).delete();
      return true;
    } catch (e) {
      print('❌ Error clearing cart: $e');
      return false;
    }
  }

  // Get available stores
  Future<List<Map<String, dynamic>>> getAvailableStores() async {
    try {
      final snapshot = await _firestore.collection('stores').get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>
      }).toList();
    } catch (e) {
      print('❌ Error getting stores: $e');
      return [
        {'id': 'tesco', 'name': 'Tesco', 'deliveryFee': 5.0},
        {'id': 'mydin', 'name': 'Mydin', 'deliveryFee': 4.0},
        {'id': 'giant', 'name': 'Giant', 'deliveryFee': 6.0},
      ];
    }
  }

  // Process checkout (placeholder for future implementation)
  Future<bool> processCheckout() async {
    try {
      // This is where you would integrate with payment gateway
      // For now, we'll just clear the cart after successful "payment"
      
      print('🛒 Processing checkout...');
      
      // Simulate processing time
      await Future.delayed(Duration(seconds: 2));
      
      // Clear cart after successful checkout
      await clearCart();
      
      print('✅ Checkout completed successfully');
      return true;
    } catch (e) {
      print('❌ Error processing checkout: $e');
      return false;
    }
  }
}