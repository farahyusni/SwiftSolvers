// lib/models/category_model.dart
class Category {
  final String id;
  final String name;
  final String description;
  final String color;

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
  });

  // Factory constructor to create Category from Firestore document
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      color: map['color'] ?? '#FF6B6B',
    );
  }

  // Convert Category to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
    };
  }

  @override
  String toString() {
    return 'Category{id: $id, name: $name, description: $description, color: $color}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}