// lib/services/recipe_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './inventory_service.dart';

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final InventoryService _inventoryService = InventoryService();

  String? get _currentUserId {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  Future<void> initializeDatabase() async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      print('Starting database initialization for user: $userId');

      await _createCategories();
      await _createStores();
      await _createSampleRecipesForUser(userId);
      await _inventoryService.initializeDatabaseForUser(userId);

      print('✅ Database initialization completed successfully for user: $userId');
    } catch (e) {
      print('❌ Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _createCategories() async {
    try {
      final existingCategories = await _firestore.collection('categories').limit(1).get();
      if (existingCategories.docs.isNotEmpty) return;

      await _firestore.collection('categories').doc('quick_meals').set({
        'id': 'quick_meals',
        'name': 'Quick Meals',
        'description': 'Recipes that can be prepared in 30 minutes or less',
        'color': '#FF6B6B',
      });
      await _firestore.collection('categories').doc('budget_friendly').set({
        'id': 'budget_friendly',
        'name': 'Budget-Friendly',
        'description': 'Affordable recipes under RM20',
        'color': '#4ECDC4',
      });
      await _firestore.collection('categories').doc('healthy').set({
        'id': 'healthy',
        'name': 'Healthy & Diet-Based',
        'description': 'Nutritious and diet-conscious recipes',
        'color': '#45B7D1',
      });
      await _firestore.collection('categories').doc('trending').set({
        'id': 'trending',
        'name': 'Trending',
        'description': 'Popular recipes right now',
        'color': '#96CEB4',
      });
    } catch (e) {
      print('❌ Error creating categories: $e');
      rethrow;
    }
  }

  Future<void> _createStores() async {
    try {
      final existingStores = await _firestore.collection('stores').limit(1).get();
      if (existingStores.docs.isNotEmpty) return;

      await _firestore.collection('stores').doc('tesco').set({
        'id': 'tesco',
        'name': 'Tesco',
        'deliveryFee': 5.00,
        'minimumOrder': 50.00,
        'deliveryTime': '1-2 hours',
      });
      await _firestore.collection('stores').doc('mydin').set({
        'id': 'mydin',
        'name': 'Mydin',
        'deliveryFee': 4.00,
        'minimumOrder': 40.00,
        'deliveryTime': '2-3 hours',
      });
      await _firestore.collection('stores').doc('giant').set({
        'id': 'giant',
        'name': 'Giant',
        'deliveryFee': 6.00,
        'minimumOrder': 60.00,
        'deliveryTime': '1-3 hours',
      });
    } catch (e) {
      print('❌ Error creating stores: $e');
      rethrow;
    }
  }

  Future<void> _createSampleRecipesForUser(String userId) async {
    // ... (Same content, unchanged)
  }

  Future<List<Map<String, dynamic>>> getAllRecipes() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('recipes').get();
      List<Map<String, dynamic>> recipes = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> recipeData = doc.data() as Map<String, dynamic>;
        recipeData['id'] = doc.id;
        recipes.add(recipeData);
      }

      print('✅ Loaded ${recipes.length} recipes');
      return recipes;
    } catch (e) {
      print('❌ Error fetching recipes: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRecipesByCategory(String category) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('recipes')
          .where('category', isEqualTo: category)
          .get();

      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print('Error fetching recipes by category: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getRecipeById(String recipeId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('recipes').doc(recipeId).get();
      if (doc.exists) {
        Map<String, dynamic> recipeData = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...recipeData};
      }
      return null;
    } catch (e) {
      print('Error fetching recipe: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> searchRecipes(String searchTerm) async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('recipes').get();
      List<Map<String, dynamic>> filteredRecipes = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> recipe = {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };

        if (recipe['name'].toString().toLowerCase().contains(searchTerm.toLowerCase())) {
          filteredRecipes.add(recipe);
        }
      }

      return filteredRecipes;
    } catch (e) {
      print('Error searching recipes: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('categories').get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllStores() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('stores').get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error fetching stores: $e');
      return [];
    }
  }

  Future<bool> updateRecipe(String recipeId, Map<String, dynamic> updatedData) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      DocumentSnapshot doc = await _firestore.collection('recipes').doc(recipeId).get();
      if (!doc.exists) return false;

      Map<String, dynamic> recipeData = doc.data() as Map<String, dynamic>;
      if (recipeData['createdBy'] != userId) return false;

      Map<String, dynamic> cleanData = Map.from(updatedData);
      cleanData.remove('id');
      cleanData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('recipes').doc(recipeId).update(cleanData);
      return true;
    } catch (e) {
      print('❌ Error updating recipe: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> createRecipe(Map<String, dynamic> recipeData) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      recipeData['createdBy'] = userId;
      recipeData['createdAt'] = FieldValue.serverTimestamp();
      recipeData['updatedAt'] = FieldValue.serverTimestamp();

      DocumentReference docRef = await _firestore.collection('recipes').add(recipeData);
      String newRecipeId = docRef.id;
      recipeData['id'] = newRecipeId;

      return recipeData;
    } catch (e) {
      print('❌ Error creating recipe: $e');
      return null;
    }
  }

  Future<bool> deleteRecipe(String recipeId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      if (recipeId.isEmpty) return false;

      DocumentSnapshot doc = await _firestore.collection('recipes').doc(recipeId).get();
      if (!doc.exists) return false;

      Map<String, dynamic> recipeData = doc.data() as Map<String, dynamic>;
      if (recipeData['createdBy'] != userId) return false;

      await _firestore.collection('recipes').doc(recipeId).delete();
      return true;
    } catch (e) {
      print('❌ Error deleting recipe: $e');
      return false;
    }
  }
}
