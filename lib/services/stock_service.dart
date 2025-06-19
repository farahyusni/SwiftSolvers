// lib/services/stock_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StockService {
  final CollectionReference stockRef = FirebaseFirestore.instance.collection('stocks');

  // Get current user ID
  String? get _currentUserId {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  // Initialize database with sample stock data for specific user
  Future<void> initializeDatabaseForUser(String userId) async {
    try {
      print('🏪 Initializing stock data for user: $userId');

      // Check if user already has stock items
      final existingStocks = await stockRef
          .where('createdBy', isEqualTo: userId)
          .limit(1)
          .get();

      if (existingStocks.docs.isNotEmpty) {
        print('✅ User already has stock items, skipping creation');
        return;
      }

      // Create sample stock items for the user
      await _createSampleStocksForUser(userId);

      print('✅ Stock initialization completed for user: $userId');
    } catch (e) {
      print('❌ Error initializing stock data: $e');
      rethrow;
    }
  }

  // Private method to create sample stocks for a specific user
  Future<void> _createSampleStocksForUser(String userId) async {
    try {
      List<Map<String, dynamic>> sampleStocks = [
        {
          'name': '5 kg Cooking Oil',
          'price': 25.90,
          'stock': 70,
          'unit': 'bottle',
          'category': 'Condiments',
          'imageUrl': 'https://via.placeholder.com/150/FFB6C1/000000?text=Oil',
          'createdBy': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Fresh Carrot',
          'price': 4.50,
          'stock': 68,
          'unit': 'kg',
          'category': 'Vegetables',
          'imageUrl': 'https://via.placeholder.com/150/FFA500/000000?text=Carrot',
          'createdBy': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Fresh Eggs',
          'price': 9.30,
          'stock': 37,
          'unit': 'dozen',
          'category': 'Protein',
          'imageUrl': 'https://via.placeholder.com/150/FFFFE0/000000?text=Eggs',
          'createdBy': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Fresh Milk',
          'price': 7.50,
          'stock': 43,
          'unit': 'carton',
          'category': 'Dairy',
          'imageUrl': 'https://via.placeholder.com/150/FFFFFF/000000?text=Milk',
          'createdBy': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'White Rice',
          'price': 15.20,
          'stock': 125,
          'unit': 'kg',
          'category': 'Grains',
          'imageUrl': 'https://via.placeholder.com/150/F5F5DC/000000?text=Rice',
          'createdBy': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Fresh Chicken',
          'price': 18.90,
          'stock': 22,
          'unit': 'kg',
          'category': 'Protein',
          'imageUrl': 'https://via.placeholder.com/150/FFE4E1/000000?text=Chicken',
          'createdBy': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Soy Sauce',
          'price': 6.80,
          'stock': 89,
          'unit': 'bottle',
          'category': 'Condiments',
          'imageUrl': 'https://via.placeholder.com/150/8B4513/FFFFFF?text=Soy+Sauce',
          'createdBy': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Fresh Tomatoes',
          'price': 5.20,
          'stock': 45,
          'unit': 'kg',
          'category': 'Vegetables',
          'imageUrl': 'https://via.placeholder.com/150/FF6347/000000?text=Tomato',
          'createdBy': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Fresh Onions',
          'price': 3.80,
          'stock': 62,
          'unit': 'kg',
          'category': 'Vegetables',
          'imageUrl': 'https://via.placeholder.com/150/DDA0DD/000000?text=Onion',
          'createdBy': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Coconut Milk',
          'price': 4.20,
          'stock': 78,
          'unit': 'can',
          'category': 'Dairy',
          'imageUrl': 'https://via.placeholder.com/150/F0F8FF/000000?text=Coconut+Milk',
          'createdBy': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      // Add all sample stocks to Firestore
      for (var stockData in sampleStocks) {
        await stockRef.add(stockData);
      }

      print('✅ Created ${sampleStocks.length} sample stock items for user: $userId');
    } catch (e) {
      print('❌ Error creating sample stocks: $e');
      rethrow;
    }
  }

  // Get all stock items for current user only
  Future<List<Map<String, dynamic>>> getAllStocks() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await stockRef
          .where('createdBy', isEqualTo: userId)
          .get();

      List<Map<String, dynamic>> stocks = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        stocks.add(data);
      }

      print('✅ Loaded ${stocks.length} stock items for user: $userId');
      return stocks;
    } catch (e) {
      print('❌ Error fetching stocks: $e');
      return [];
    }
  }

  // Add new stock item for current user
  Future<bool> addStock(Map<String, dynamic> data) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Ensure the stock item is linked to the current user
      data['createdBy'] = userId;
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await stockRef.add(data);
      print('✅ Stock item added successfully for user: $userId');
      return true;
    } catch (e) {
      print('❌ Error adding stock: $e');
      return false;
    }
  }

  // Update existing stock item (ensure it belongs to current user)
  Future<bool> updateStock(String id, Map<String, dynamic> data) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // First verify the stock item belongs to the current user
      DocumentSnapshot doc = await stockRef.doc(id).get();
      
      if (!doc.exists) {
        print('❌ Stock item not found');
        return false;
      }

      Map<String, dynamic> stockData = doc.data() as Map<String, dynamic>;
      
      if (stockData['createdBy'] != userId) {
        print('❌ Access denied: Stock item does not belong to current user');
        return false;
      }

      // Add updated timestamp
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      await stockRef.doc(id).update(data);
      print('✅ Stock item updated successfully for user: $userId');
      return true;
    } catch (e) {
      print('❌ Error updating stock: $e');
      return false;
    }
  }

  // Delete stock item (ensure it belongs to current user)
  Future<bool> deleteStock(String id) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // First verify the stock item belongs to the current user
      DocumentSnapshot doc = await stockRef.doc(id).get();
      
      if (!doc.exists) {
        print('❌ Stock item not found');
        return false;
      }

      Map<String, dynamic> stockData = doc.data() as Map<String, dynamic>;
      
      if (stockData['createdBy'] != userId) {
        print('❌ Access denied: Stock item does not belong to current user');
        return false;
      }

      await stockRef.doc(id).delete();
      print('✅ Stock item deleted successfully for user: $userId');
      return true;
    } catch (e) {
      print('❌ Error deleting stock: $e');
      return false;
    }
  }

  // Get stock item by ID (ensure it belongs to current user)
  Future<Map<String, dynamic>?> getStockById(String id) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      DocumentSnapshot doc = await stockRef.doc(id).get();
      
      if (!doc.exists) {
        return null;
      }

      Map<String, dynamic> stockData = doc.data() as Map<String, dynamic>;
      
      // Verify the stock item belongs to the current user
      if (stockData['createdBy'] != userId) {
        print('❌ Access denied: Stock item does not belong to current user');
        return null;
      }

      stockData['id'] = doc.id;
      return stockData;
    } catch (e) {
      print('❌ Error getting stock by ID: $e');
      return null;
    }
  }

  // Search stocks for current user
  Future<List<Map<String, dynamic>>> searchStocks(String searchTerm) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get all stocks for current user first, then filter
      final snapshot = await stockRef
          .where('createdBy', isEqualTo: userId)
          .get();

      List<Map<String, dynamic>> filteredStocks = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> stock = doc.data() as Map<String, dynamic>;
        stock['id'] = doc.id;

        if (stock['name'].toString().toLowerCase().contains(searchTerm.toLowerCase())) {
          filteredStocks.add(stock);
        }
      }

      return filteredStocks;
    } catch (e) {
      print('❌ Error searching stocks: $e');
      return [];
    }
  }

  // Get stocks by category for current user
  Future<List<Map<String, dynamic>>> getStocksByCategory(String category) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await stockRef
          .where('createdBy', isEqualTo: userId)
          .where('category', isEqualTo: category)
          .get();

      List<Map<String, dynamic>> stocks = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        stocks.add(data);
      }

      return stocks;
    } catch (e) {
      print('❌ Error fetching stocks by category: $e');
      return [];
    }
  }

  // Get low stock items (stock < 50) for current user
  Future<List<Map<String, dynamic>>> getLowStockItems() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await stockRef
          .where('createdBy', isEqualTo: userId)
          .where('stock', isLessThan: 50)
          .get();

      List<Map<String, dynamic>> lowStocks = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        lowStocks.add(data);
      }

      print('📊 Found ${lowStocks.length} low stock items for user: $userId');
      return lowStocks;
    } catch (e) {
      print('❌ Error fetching low stock items: $e');
      return [];
    }
  }

  // Get total stock value for current user
  Future<double> getTotalStockValue() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await stockRef
          .where('createdBy', isEqualTo: userId)
          .get();

      double totalValue = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final price = (data['price'] ?? 0).toDouble();
        final stock = (data['stock'] ?? 0).toInt();
        totalValue += (price * stock);
      }

      print('💰 Total stock value for user $userId: RM${totalValue.toStringAsFixed(2)}');
      return totalValue;
    } catch (e) {
      print('❌ Error calculating total stock value: $e');
      return 0.0;
    }
  }
}