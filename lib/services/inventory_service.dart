// lib/services/inventory_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user ID
  String? get _currentUserId {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  // Initialize inventory database for specific user
  Future<void> initializeDatabase() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await initializeDatabaseForUser(userId);
    } catch (e) {
      print('❌ Error initializing inventory database: $e');
      rethrow;
    }
  }

  // Initialize inventory database for specific user
  Future<void> initializeDatabaseForUser(String userId) async {
    try {
      print('📦 Starting inventory initialization for user: $userId');

      // Check if user already has inventory data
      final existingInventory = await _firestore
          .collection('inventory')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (existingInventory.docs.isNotEmpty) {
        print('✅ User already has inventory data, skipping creation');
        return;
      }

      // Create sample inventory items for the user
      await _createSampleInventoryForUser(userId);

      print('✅ Inventory initialization completed for user: $userId');
    } catch (e) {
      print('❌ Error initializing inventory for user: $e');
      rethrow;
    }
  }

  // Private method to create sample inventory for a specific user
  Future<void> _createSampleInventoryForUser(String userId) async {
    try {
      List<Map<String, dynamic>> sampleInventoryItems = [
        {
          'itemName': 'Rice',
          'category': 'Grains',
          'quantity': 5.0,
          'unit': 'kg',
          'expiryDate': DateTime.now().add(Duration(days: 365)),
          'purchaseDate': DateTime.now().subtract(Duration(days: 30)),
          'cost': 15.50,
          'supplier': 'Local Market',
          'location': 'Storage Room A',
          'minimumLevel': 2.0,
          'status': 'Available',
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'itemName': 'Cooking Oil',
          'category': 'Condiments',
          'quantity': 3.0,
          'unit': 'liters',
          'expiryDate': DateTime.now().add(Duration(days: 180)),
          'purchaseDate': DateTime.now().subtract(Duration(days: 15)),
          'cost': 25.90,
          'supplier': 'Wholesale Supplier',
          'location': 'Storage Room B',
          'minimumLevel': 1.0,
          'status': 'Available',
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'itemName': 'Fresh Vegetables Mix',
          'category': 'Vegetables',
          'quantity': 2.5,
          'unit': 'kg',
          'expiryDate': DateTime.now().add(Duration(days: 7)),
          'purchaseDate': DateTime.now().subtract(Duration(days: 2)),
          'cost': 12.00,
          'supplier': 'Local Farm',
          'location': 'Cold Storage',
          'minimumLevel': 1.0,
          'status': 'Available',
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'itemName': 'Chicken',
          'category': 'Protein',
          'quantity': 1.5,
          'unit': 'kg',
          'expiryDate': DateTime.now().add(Duration(days: 3)),
          'purchaseDate': DateTime.now().subtract(Duration(days: 1)),
          'cost': 18.90,
          'supplier': 'Fresh Meat Supplier',
          'location': 'Freezer',
          'minimumLevel': 0.5,
          'status': 'Available',
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'itemName': 'Soy Sauce',
          'category': 'Condiments',
          'quantity': 0.5,
          'unit': 'liters',
          'expiryDate': DateTime.now().add(Duration(days: 300)),
          'purchaseDate': DateTime.now().subtract(Duration(days: 60)),
          'cost': 6.80,
          'supplier': 'Asian Grocery',
          'location': 'Pantry',
          'minimumLevel': 1.0,
          'status': 'Low Stock',
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      // Add all sample inventory items to Firestore
      for (var item in sampleInventoryItems) {
        await _firestore.collection('inventory').add(item);
      }

      print('✅ Created ${sampleInventoryItems.length} sample inventory items for user: $userId');
    } catch (e) {
      print('❌ Error creating sample inventory: $e');
      rethrow;
    }
  }

  // Get all inventory items for current user
  Future<List<Map<String, dynamic>>> getAllInventoryItems() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      QuerySnapshot snapshot = await _firestore
          .collection('inventory')
          .where('userId', isEqualTo: userId)
          .get();

      List<Map<String, dynamic>> items = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> itemData = doc.data() as Map<String, dynamic>;
        itemData['id'] = doc.id;
        items.add(itemData);
      }

      print('✅ Loaded ${items.length} inventory items for user: $userId');
      return items;
    } catch (e) {
      print('❌ Error fetching inventory items: $e');
      return [];
    }
  }

  // Add new inventory item for current user
  Future<bool> addInventoryItem(Map<String, dynamic> itemData) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Ensure the item is linked to the current user
      itemData['userId'] = userId;
      itemData['createdAt'] = FieldValue.serverTimestamp();
      itemData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('inventory').add(itemData);
      print('✅ Inventory item added successfully for user: $userId');
      return true;
    } catch (e) {
      print('❌ Error adding inventory item: $e');
      return false;
    }
  }

  // Update inventory item (ensure it belongs to current user)
  Future<bool> updateInventoryItem(String itemId, Map<String, dynamic> updatedData) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // First verify the item belongs to the current user
      DocumentSnapshot doc = await _firestore.collection('inventory').doc(itemId).get();
      
      if (!doc.exists) {
        print('❌ Inventory item not found');
        return false;
      }

      Map<String, dynamic> itemData = doc.data() as Map<String, dynamic>;
      
      if (itemData['userId'] != userId) {
        print('❌ Access denied: Inventory item does not belong to current user');
        return false;
      }

      // Add updated timestamp
      updatedData['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('inventory').doc(itemId).update(updatedData);
      print('✅ Inventory item updated successfully for user: $userId');
      return true;
    } catch (e) {
      print('❌ Error updating inventory item: $e');
      return false;
    }
  }

  // Delete inventory item (ensure it belongs to current user)
  Future<bool> deleteInventoryItem(String itemId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // First verify the item belongs to the current user
      DocumentSnapshot doc = await _firestore.collection('inventory').doc(itemId).get();
      
      if (!doc.exists) {
        print('❌ Inventory item not found');
        return false;
      }

      Map<String, dynamic> itemData = doc.data() as Map<String, dynamic>;
      
      if (itemData['userId'] != userId) {
        print('❌ Access denied: Inventory item does not belong to current user');
        return false;
      }

      await _firestore.collection('inventory').doc(itemId).delete();
      print('✅ Inventory item deleted successfully for user: $userId');
      return true;
    } catch (e) {
      print('❌ Error deleting inventory item: $e');
      return false;
    }
  }

  // Get inventory items by category for current user
  Future<List<Map<String, dynamic>>> getInventoryByCategory(String category) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      QuerySnapshot snapshot = await _firestore
          .collection('inventory')
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category)
          .get();

      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print('❌ Error fetching inventory by category: $e');
      return [];
    }
  }

  // Get low stock items for current user
  Future<List<Map<String, dynamic>>> getLowStockItems() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      QuerySnapshot snapshot = await _firestore
          .collection('inventory')
          .where('userId', isEqualTo: userId)
          .get();

      List<Map<String, dynamic>> lowStockItems = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> item = doc.data() as Map<String, dynamic>;
        item['id'] = doc.id;

        double quantity = (item['quantity'] ?? 0).toDouble();
        double minimumLevel = (item['minimumLevel'] ?? 0).toDouble();

        if (quantity <= minimumLevel) {
          lowStockItems.add(item);
        }
      }

      print('📊 Found ${lowStockItems.length} low stock items for user: $userId');
      return lowStockItems;
    } catch (e) {
      print('❌ Error fetching low stock items: $e');
      return [];
    }
  }

  // Get items expiring soon for current user
  Future<List<Map<String, dynamic>>> getItemsExpiringSoon({int daysAhead = 7}) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      DateTime targetDate = DateTime.now().add(Duration(days: daysAhead));

      QuerySnapshot snapshot = await _firestore
          .collection('inventory')
          .where('userId', isEqualTo: userId)
          .where('expiryDate', isLessThanOrEqualTo: targetDate)
          .get();

      List<Map<String, dynamic>> expiringItems = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> item = doc.data() as Map<String, dynamic>;
        item['id'] = doc.id;
        expiringItems.add(item);
      }

      print('⏰ Found ${expiringItems.length} items expiring in next $daysAhead days for user: $userId');
      return expiringItems;
    } catch (e) {
      print('❌ Error fetching expiring items: $e');
      return [];
    }
  }

  // Search inventory items for current user
  Future<List<Map<String, dynamic>>> searchInventoryItems(String searchTerm) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get all items for current user first, then filter
      QuerySnapshot snapshot = await _firestore
          .collection('inventory')
          .where('userId', isEqualTo: userId)
          .get();

      List<Map<String, dynamic>> filteredItems = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> item = doc.data() as Map<String, dynamic>;
        item['id'] = doc.id;

        if (item['itemName'].toString().toLowerCase().contains(searchTerm.toLowerCase()) ||
            item['category'].toString().toLowerCase().contains(searchTerm.toLowerCase())) {
          filteredItems.add(item);
        }
      }

      return filteredItems;
    } catch (e) {
      print('❌ Error searching inventory items: $e');
      return [];
    }
  }

  // Get total inventory value for current user
  Future<double> getTotalInventoryValue() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      QuerySnapshot snapshot = await _firestore
          .collection('inventory')
          .where('userId', isEqualTo: userId)
          .get();

      double totalValue = 0.0;

      for (var doc in snapshot.docs) {
        Map<String, dynamic> item = doc.data() as Map<String, dynamic>;
        double cost = (item['cost'] ?? 0).toDouble();
        double quantity = (item['quantity'] ?? 0).toDouble();
        totalValue += (cost * quantity);
      }

      print('💰 Total inventory value for user $userId: RM${totalValue.toStringAsFixed(2)}');
      return totalValue;
    } catch (e) {
      print('❌ Error calculating total inventory value: $e');
      return 0.0;
    }
  }

  // Update item quantity (for consumption/usage)
  Future<bool> updateItemQuantity(String itemId, double newQuantity) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // First verify the item belongs to the current user
      DocumentSnapshot doc = await _firestore.collection('inventory').doc(itemId).get();
      
      if (!doc.exists) {
        print('❌ Inventory item not found');
        return false;
      }

      Map<String, dynamic> itemData = doc.data() as Map<String, dynamic>;
      
      if (itemData['userId'] != userId) {
        print('❌ Access denied: Inventory item does not belong to current user');
        return false;
      }

      // Update quantity and status if needed
      Map<String, dynamic> updateData = {
        'quantity': newQuantity,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update status based on quantity vs minimum level
      double minimumLevel = (itemData['minimumLevel'] ?? 0).toDouble();
      if (newQuantity <= minimumLevel) {
        updateData['status'] = 'Low Stock';
      } else if (newQuantity == 0) {
        updateData['status'] = 'Out of Stock';
      } else {
        updateData['status'] = 'Available';
      }

      await _firestore.collection('inventory').doc(itemId).update(updateData);
      print('✅ Item quantity updated successfully for user: $userId');
      return true;
    } catch (e) {
      print('❌ Error updating item quantity: $e');
      return false;
    }
  }
}