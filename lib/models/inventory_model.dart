class InventoryModel {
  final String? id;
  final String name;
  final double price;
  final int stock;
  final String category;
  final String imageUrl;
  final bool isLowStock;
  final String unit;
  final String description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  InventoryModel({
    this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.category,
    this.imageUrl = '',
    this.isLowStock = false,
    required this.unit,
    this.description = '',
    this.createdAt,
    this.updatedAt,
  });

  // Convert from Firestore document to InventoryModel
  factory InventoryModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return InventoryModel(
      id: documentId,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      stock: data['stock'] ?? 0,
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      isLowStock: data['isLowStock'] ?? false,
      unit: data['unit'] ?? '',
      description: data['description'] ?? '',
      createdAt: data['createdAt']?.toDate(),
      updatedAt: data['updatedAt']?.toDate(),
    );
  }

  // Convert InventoryModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'stock': stock,
      'category': category,
      'imageUrl': imageUrl,
      'isLowStock': isLowStock,
      'unit': unit,
      'description': description,
      'createdAt': createdAt ?? DateTime.now(),
      'updatedAt': DateTime.now(),
    };
  }

  // Create a copy with updated fields
  InventoryModel copyWith({
    String? id,
    String? name,
    double? price,
    int? stock,
    String? category,
    String? imageUrl,
    bool? isLowStock,
    String? unit,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      isLowStock: isLowStock ?? this.isLowStock,
      unit: unit ?? this.unit,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'InventoryModel(id: $id, name: $name, price: $price, stock: $stock, category: $category, isLowStock: $isLowStock)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}