import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_model.dart';

class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'stocks';

  // Initialize the database with sample data (call this ONCE)
  Future<void> initializeDatabase() async {
    try {
      print('Starting database initialization...');

      // Check if data already exists
      final existingData =
          await _firestore.collection(_collection).limit(1).get();
      if (existingData.docs.isNotEmpty) {
        print('✅ Database already has data, skipping initialization');
        return;
      }

      // Create sample inventory items
      await _createSampleStocks();

      print('✅ Database initialization completed successfully!');
    } catch (e) {
      print('❌ Error initializing database: $e');
      rethrow;
    }
  }

  // Private method to create sample stocks
  Future<void> _createSampleStocks() async {
    final sampleItems = [
      InventoryModel(
        name: '1kg thick yellow noodles',
        price: 2.00,
        stock: 50,
        category: 'Grains',
        unit: 'pack',
        description: 'Fresh yellow noodles',
        isLowStock: false,
      ),
      InventoryModel(
        name: '2kg Minyak Masak Saji',
        price: 13.50,
        stock: 100,
        category: 'Condiments',
        unit: 'bottle',
        description: 'Cooking oil',
        isLowStock: false,
      ),
      InventoryModel(
        name: 'Carrot',
        price: 5.50,
        stock: 8,
        category: 'Vegetables',
        unit: 'kg',
        description: 'Fresh carrots',
        isLowStock: true,
      ),
      InventoryModel(
        name: 'Eggs',
        price: 0.50,
        stock: 100,
        category: 'Protein',
        unit: 'per piece',
        description: 'Fresh chicken eggs',
        isLowStock: false,
      ),
      InventoryModel(
        name: 'Chilli Sauce',
        price: 3.20,
        stock: 25,
        category: 'Condiments',
        unit: 'bottle',
        description: 'Spicy chilli sauce',
        isLowStock: false,
      ),
      InventoryModel(
        name: 'White Rice',
        price: 15.00,
        stock: 30,
        category: 'Grains',
        unit: '5kg bag',
        description: 'Premium white rice',
        isLowStock: false,
      ),
    ];

    // Add each item to Firestore
    for (final item in sampleItems) {
      await _firestore.collection(_collection).add(item.toFirestore());
      print('Added: ${item.name}');
    }
  }

  // Public method to force create sample data
  Future<void> createSampleData() async {
    try {
      print('🔄 Force creating sample inventory data...');
      await _createSampleStocks();
      print('✅ Sample inventory data created successfully!');
    } catch (e) {
      print('❌ Error creating sample inventory data: $e');
      rethrow;
    }
  }

  // Get all inventory items
  Stream<List<InventoryModel>> getInventoryItems() {
    return _firestore
        .collection(_collection)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => InventoryModel.fromFirestore(doc.data(), doc.id),
                  )
                  .toList(),
        );
  }

  // Get inventory items by category
  Stream<List<InventoryModel>> getInventoryByCategory(String category) {
    return _firestore
        .collection(_collection)
        .where('category', isEqualTo: category)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => InventoryModel.fromFirestore(doc.data(), doc.id),
                  )
                  .toList(),
        );
  }

  // Get low stock items
  Stream<List<InventoryModel>> getLowStockItems() {
    return _firestore
        .collection(_collection)
        .where('isLowStock', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => InventoryModel.fromFirestore(doc.data(), doc.id),
                  )
                  .toList(),
        );
  }

  // Add new inventory item
  Future<String?> addInventoryItem(InventoryModel item) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(item.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error adding inventory item: $e');
      return null;
    }
  }

  // Update existing inventory item
  Future<bool> updateInventoryItem(InventoryModel item) async {
    try {
      if (item.id == null) return false;

      await _firestore
          .collection(_collection)
          .doc(item.id)
          .update(item.toFirestore());
      return true;
    } catch (e) {
      print('Error updating inventory item: $e');
      return false;
    }
  }

  // Delete inventory item
  Future<bool> deleteInventoryItem(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting inventory item: $e');
      return false;
    }
  }

  // Update stock quantity
  Future<bool> updateStock(String id, int newStock) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'stock': newStock,
        'updatedAt': DateTime.now(),
        'isLowStock': newStock <= 10, // Auto-mark as low stock if <= 10
      });
      return true;
    } catch (e) {
      print('Error updating stock: $e');
      return false;
    }
  }

  // Search inventory items by name
  Stream<List<InventoryModel>> searchInventoryItems(String searchTerm) {
    return _firestore
        .collection(_collection)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => InventoryModel.fromFirestore(doc.data(), doc.id),
                  )
                  .where(
                    (item) => item.name.toLowerCase().contains(
                      searchTerm.toLowerCase(),
                    ),
                  )
                  .toList(),
        );
  }

  // Get unique categories
  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final categories =
          snapshot.docs
              .map((doc) => doc.data()['category'] as String)
              .toSet()
              .toList();
      categories.sort();
      return categories;
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }
}
