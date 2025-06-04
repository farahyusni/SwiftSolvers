// lib/models/cart_model.dart
class CartItem {
  final String id;
  final String name;
  final String amount;
  final String unit;
  final String category;
  final String recipeId;
  final String recipeName;
  final Map<String, double> estimatedPrice;
  int quantity;
  String selectedStore;

  CartItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.unit,
    required this.category,
    required this.recipeId,
    required this.recipeName,
    required this.estimatedPrice,
    this.quantity = 1,
    this.selectedStore = 'tesco', // Default to tesco
  });

  // Factory constructor to create CartItem from recipe ingredient
  factory CartItem.fromIngredient({
    required Map<String, dynamic> ingredient,
    required String recipeId,
    required String recipeName,
  }) {
    return CartItem(
      id: '${recipeId}_${ingredient['name']}_${DateTime.now().millisecondsSinceEpoch}',
      name: ingredient['name'] ?? '',
      amount: ingredient['amount'] ?? '',
      unit: ingredient['unit'] ?? '',
      category: ingredient['category'] ?? '',
      recipeId: recipeId,
      recipeName: recipeName,
      estimatedPrice: Map<String, double>.from(ingredient['estimatedPrice'] ?? {}),
    );
  }

  // Convert CartItem to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'unit': unit,
      'category': category,
      'recipeId': recipeId,
      'recipeName': recipeName,
      'estimatedPrice': estimatedPrice,
      'quantity': quantity,
      'selectedStore': selectedStore,
    };
  }

  // Create CartItem from Map
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      amount: map['amount'] ?? '',
      unit: map['unit'] ?? '',
      category: map['category'] ?? '',
      recipeId: map['recipeId'] ?? '',
      recipeName: map['recipeName'] ?? '',
      estimatedPrice: Map<String, double>.from(map['estimatedPrice'] ?? {}),
      quantity: map['quantity'] ?? 1,
      selectedStore: map['selectedStore'] ?? 'tesco',
    );
  }

  // Get price for selected store
  double get currentPrice {
    return estimatedPrice[selectedStore] ?? 0.0;
  }

  // Get total price (price * quantity)
  double get totalPrice {
    return currentPrice * quantity;
  }

  // Copy with method for updates
  CartItem copyWith({
    String? id,
    String? name,
    String? amount,
    String? unit,
    String? category,
    String? recipeId,
    String? recipeName,
    Map<String, double>? estimatedPrice,
    int? quantity,
    String? selectedStore,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      recipeId: recipeId ?? this.recipeId,
      recipeName: recipeName ?? this.recipeName,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      quantity: quantity ?? this.quantity,
      selectedStore: selectedStore ?? this.selectedStore,
    );
  }

  @override
  String toString() {
    return 'CartItem{id: $id, name: $name, amount: $amount $unit, quantity: $quantity, store: $selectedStore, price: $currentPrice}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem && 
           (other.id == id || 
            (other.name == name && other.recipeId == recipeId));
  }

  @override
  int get hashCode => id.hashCode;
}

class Cart {
  final List<CartItem> items;
  String selectedStore;

  Cart({
    this.items = const [],
    this.selectedStore = 'tesco',
  });

  // Get total number of items
  int get totalItems {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Get total price for selected store
  double get totalPrice {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // Get items grouped by recipe
  Map<String, List<CartItem>> get itemsByRecipe {
    Map<String, List<CartItem>> grouped = {};
    for (var item in items) {
      if (!grouped.containsKey(item.recipeId)) {
        grouped[item.recipeId] = [];
      }
      grouped[item.recipeId]!.add(item);
    }
    return grouped;
  }

  // Check if cart is empty
  bool get isEmpty => items.isEmpty;

  // Check if cart is not empty
  bool get isNotEmpty => items.isNotEmpty;

  // Copy with method
  Cart copyWith({
    List<CartItem>? items,
    String? selectedStore,
  }) {
    return Cart(
      items: items ?? this.items,
      selectedStore: selectedStore ?? this.selectedStore,
    );
  }

  @override
  String toString() {
    return 'Cart{items: ${items.length}, totalPrice: $totalPrice, store: $selectedStore}';
  }
}