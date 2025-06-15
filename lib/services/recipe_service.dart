// lib/services/recipe_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import './inventory_service.dart'; // Import the inventory service

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final InventoryService _inventoryService = InventoryService(); // Add inventory service

  // Initialize the database with sample data (call this ONCE)
  Future<void> initializeDatabase() async {
    try {
      print('Starting database initialization...');

      // Create categories first
      await _createCategories();

      // Create stores
      await _createStores();

      // Create sample recipes
      await _createSampleRecipes();

      // Initialize inventory/stocks data
      await _inventoryService.initializeDatabase();

      print('✅ Database initialization completed successfully!');
    } catch (e) {
      print('❌ Error initializing database: $e');
      rethrow;
    }
  }

  // Private method to create categories
  Future<void> _createCategories() async {
    try {
      // Check if categories already exist
      final existingCategories = await _firestore.collection('categories').limit(1).get();
      if (existingCategories.docs.isNotEmpty) {
        print('✅ Categories already exist, skipping creation');
        return;
      }

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

      print('✅ Categories created');
    } catch (e) {
      print('❌ Error creating categories: $e');
      rethrow;
    }
  }

  // Private method to create stores
  Future<void> _createStores() async {
    try {
      // Check if stores already exist
      final existingStores = await _firestore.collection('stores').limit(1).get();
      if (existingStores.docs.isNotEmpty) {
        print('✅ Stores already exist, skipping creation');
        return;
      }

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

      print('✅ Stores created');
    } catch (e) {
      print('❌ Error creating stores: $e');
      rethrow;
    }
  }

  // Private method to create sample recipes
  Future<void> _createSampleRecipes() async {
    try {
      // Check if recipes already exist
      final existingRecipes = await _firestore.collection('recipes').limit(1).get();
      if (existingRecipes.docs.isNotEmpty) {
        print('✅ Recipes already exist, skipping creation');
        return;
      }

      // Recipe 1: Hokkien Mee
      await _firestore.collection('recipes').add({
        'name': 'Hokkien Mee',
        'description': 'A delicious Malaysian stir-fried noodle dish',
        'category': 'Quick Meals',
        'difficulty': 'Medium',
        'prepTime': 15,
        'cookTime': 20,
        'servings': 4,
        'isPopular': true,
        'imageUrl':
            'https://via.placeholder.com/400x300/FF6B6B/FFFFFF?text=Hokkien+Mee',

        'ingredients': [
          {
            'name': 'thick yellow noodles',
            'amount': '1kg',
            'unit': 'kg',
            'category': 'noodles',
            'isOptional': false,
            'estimatedPrice': {'tesco': 3.50, 'mydin': 3.20, 'giant': 3.80},
          },
          {
            'name': 'dark soy sauce',
            'amount': '1/2',
            'unit': 'cup',
            'category': 'sauces',
            'isOptional': false,
            'estimatedPrice': {'tesco': 4.20, 'mydin': 3.90, 'giant': 4.50},
          },
          {
            'name': 'light soy sauce',
            'amount': '1/2',
            'unit': 'cup',
            'category': 'sauces',
            'isOptional': false,
            'estimatedPrice': {'tesco': 3.80, 'mydin': 3.50, 'giant': 4.00},
          },
          {
            'name': 'water',
            'amount': '6',
            'unit': 'cup',
            'category': 'basic',
            'isOptional': false,
            'estimatedPrice': {'tesco': 0.00, 'mydin': 0.00, 'giant': 0.00},
          },
          {
            'name': 'cooking oil',
            'amount': '1/2',
            'unit': 'cup',
            'category': 'basic',
            'isOptional': false,
            'estimatedPrice': {'tesco': 2.50, 'mydin': 2.30, 'giant': 2.70},
          },
          {
            'name': 'garlic, chopped finely',
            'amount': '1',
            'unit': 'tsp',
            'category': 'vegetables',
            'isOptional': false,
            'estimatedPrice': {'tesco': 1.20, 'mydin': 1.00, 'giant': 1.30},
          },
          {
            'name': 'medium size prawn',
            'amount': '150g',
            'unit': 'g',
            'category': 'seafood',
            'isOptional': false,
            'estimatedPrice': {'tesco': 12.00, 'mydin': 11.50, 'giant': 12.50},
          },
          {
            'name': 'cabbage',
            'amount': '300g',
            'unit': 'g',
            'category': 'vegetables',
            'isOptional': false,
            'estimatedPrice': {'tesco': 2.50, 'mydin': 2.20, 'giant': 2.80},
          },
        ],

        'instructions': [
          {
            'step': 1,
            'instruction':
                'Scald the noodles for 2 minutes to remove alkaline content, drain water, and set aside.',
          },
          {
            'step': 2,
            'instruction': 'Heat oil in wok and fry garlic until fragrant.',
          },
          {'step': 3, 'instruction': 'Add all sauces, salt, sugar and water.'},
          {'step': 4, 'instruction': 'Bring noodles to a boil until soft.'},
          {'step': 5, 'instruction': 'Add in the prawns and vegetables.'},
          {
            'step': 6,
            'instruction': 'Stir-fry everything together and serve hot.',
          },
        ],

        'tags': ['malaysian', 'noodles', 'stir-fry', 'seafood'],
        'nutritionInfo': {
          'calories': 450,
          'protein': '25g',
          'carbs': '55g',
          'fat': '15g',
        },
        'totalEstimatedCost': {'tesco': 29.70, 'mydin': 27.60, 'giant': 31.30},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': 'admin',
      });

      // Recipe 2: Malaysian Fried Rice
      await _firestore.collection('recipes').add({
        'name': 'Malaysian Fried Rice',
        'description': 'Quick and easy fried rice with local flavors',
        'category': 'Budget-Friendly',
        'difficulty': 'Easy',
        'prepTime': 10,
        'cookTime': 15,
        'servings': 3,
        'isPopular': true,
        'imageUrl':
            'https://via.placeholder.com/400x300/4ECDC4/FFFFFF?text=Fried+Rice',

        'ingredients': [
          {
            'name': 'cooked rice',
            'amount': '3',
            'unit': 'cups',
            'category': 'grains',
            'isOptional': false,
            'estimatedPrice': {'tesco': 2.00, 'mydin': 1.80, 'giant': 2.20},
          },
          {
            'name': 'eggs',
            'amount': '2',
            'unit': 'pieces',
            'category': 'protein',
            'isOptional': false,
            'estimatedPrice': {'tesco': 1.50, 'mydin': 1.30, 'giant': 1.60},
          },
          {
            'name': 'soy sauce',
            'amount': '2',
            'unit': 'tbsp',
            'category': 'sauces',
            'isOptional': false,
            'estimatedPrice': {'tesco': 3.00, 'mydin': 2.80, 'giant': 3.20},
          },
          {
            'name': 'cooking oil',
            'amount': '2',
            'unit': 'tbsp',
            'category': 'basic',
            'isOptional': false,
            'estimatedPrice': {'tesco': 1.00, 'mydin': 0.90, 'giant': 1.10},
          },
        ],

        'instructions': [
          {
            'step': 1,
            'instruction':
                'Heat oil in a large pan or wok over medium-high heat.',
          },
          {'step': 2, 'instruction': 'Scramble the eggs and set aside.'},
          {
            'step': 3,
            'instruction': 'Add rice to the pan and stir-fry for 3-4 minutes.',
          },
          {
            'step': 4,
            'instruction': 'Add soy sauce and scrambled eggs back to the pan.',
          },
          {'step': 5, 'instruction': 'Stir everything together and serve hot.'},
        ],

        'tags': ['malaysian', 'rice', 'quick', 'budget'],
        'nutritionInfo': {
          'calories': 320,
          'protein': '12g',
          'carbs': '45g',
          'fat': '10g',
        },
        'totalEstimatedCost': {'tesco': 7.50, 'mydin': 6.80, 'giant': 8.10},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': 'admin',
      });

      // Recipe 3: Chicken Curry
      await _firestore.collection('recipes').add({
        'name': 'Malaysian Chicken Curry',
        'description': 'Rich and aromatic chicken curry with coconut milk',
        'category': 'Healthy',
        'difficulty': 'Medium',
        'prepTime': 20,
        'cookTime': 45,
        'servings': 6,
        'isPopular': true,
        'imageUrl':
            'https://via.placeholder.com/400x300/45B7D1/FFFFFF?text=Chicken+Curry',

        'ingredients': [
          {
            'name': 'chicken thigh',
            'amount': '1kg',
            'unit': 'kg',
            'category': 'protein',
            'isOptional': false,
            'estimatedPrice': {'tesco': 15.00, 'mydin': 14.50, 'giant': 15.50},
          },
          {
            'name': 'coconut milk',
            'amount': '400ml',
            'unit': 'ml',
            'category': 'dairy',
            'isOptional': false,
            'estimatedPrice': {'tesco': 3.50, 'mydin': 3.20, 'giant': 3.80},
          },
          {
            'name': 'curry powder',
            'amount': '3',
            'unit': 'tbsp',
            'category': 'spices',
            'isOptional': false,
            'estimatedPrice': {'tesco': 2.50, 'mydin': 2.20, 'giant': 2.80},
          },
          {
            'name': 'onions',
            'amount': '2',
            'unit': 'pieces',
            'category': 'vegetables',
            'isOptional': false,
            'estimatedPrice': {'tesco': 2.00, 'mydin': 1.80, 'giant': 2.20},
          },
        ],

        'instructions': [
          {
            'step': 1,
            'instruction':
                'Cut chicken into bite-sized pieces and marinate with curry powder.',
          },
          {
            'step': 2,
            'instruction': 'Heat oil and sauté onions until golden brown.',
          },
          {
            'step': 3,
            'instruction': 'Add marinated chicken and cook until browned.',
          },
          {
            'step': 4,
            'instruction': 'Pour in coconut milk and simmer for 30 minutes.',
          },
          {'step': 5, 'instruction': 'Season with salt and serve with rice.'},
        ],

        'tags': ['malaysian', 'curry', 'chicken', 'spicy'],
        'nutritionInfo': {
          'calories': 380,
          'protein': '35g',
          'carbs': '8g',
          'fat': '22g',
        },
        'totalEstimatedCost': {'tesco': 23.00, 'mydin': 21.70, 'giant': 24.30},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': 'admin',
      });

      print('✅ Sample recipes created');
    } catch (e) {
      print('❌ Error creating recipes: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllRecipes() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('recipes').get();

      List<Map<String, dynamic>> recipes = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> recipeData = doc.data() as Map<String, dynamic>;

        // IMPORTANT: Always set the ID from the document ID
        recipeData['id'] = doc.id;

        // Debug logging
        print('📖 Recipe: "${recipeData['name']}" - Document ID: "${doc.id}"');
        print('📖 Recipe ID field: "${recipeData['id']}"');

        recipes.add(recipeData);
      }

      print('✅ Loaded ${recipes.length} recipes with proper IDs');
      return recipes;
    } catch (e) {
      print('❌ Error fetching recipes: $e');
      return [];
    }
  }

  // Method to get recipes by category
  Future<List<Map<String, dynamic>>> getRecipesByCategory(
    String category,
  ) async {
    try {
      QuerySnapshot snapshot =
          await _firestore
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

  // Method to get a single recipe by ID
  Future<Map<String, dynamic>?> getRecipeById(String recipeId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('recipes').doc(recipeId).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }
      return null;
    } catch (e) {
      print('Error fetching recipe: $e');
      return null;
    }
  }

  // Method to search recipes
  Future<List<Map<String, dynamic>>> searchRecipes(String searchTerm) async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('recipes').get();

      // Filter recipes that contain the search term in their name
      List<Map<String, dynamic>> filteredRecipes = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> recipe = {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };

        if (recipe['name'].toString().toLowerCase().contains(
          searchTerm.toLowerCase(),
        )) {
          filteredRecipes.add(recipe);
        }
      }

      return filteredRecipes;
    } catch (e) {
      print('Error searching recipes: $e');
      return [];
    }
  }

  // Method to get all categories
  Future<List<Map<String, dynamic>>> getAllCategories() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('categories').get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  // Method to get all stores
  Future<List<Map<String, dynamic>>> getAllStores() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('stores').get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error fetching stores: $e');
      return [];
    }
  }

  Future<bool> updateRecipe(
    String recipeId,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      print('🔄 Updating recipe with ID: $recipeId');
      print('🔄 Update data keys: ${updatedData.keys.toList()}');

      // Remove the 'id' field from update data since Firestore doesn't allow updating document ID
      Map<String, dynamic> cleanData = Map.from(updatedData);
      cleanData.remove('id');

      print('🔄 Clean data keys: ${cleanData.keys.toList()}');

      await _firestore.collection('recipes').doc(recipeId).update(cleanData);

      print('✅ Recipe updated successfully in Firestore');
      return true;
    } catch (e) {
      print('❌ Error updating recipe: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> createRecipe(
    Map<String, dynamic> recipeData,
  ) async {
    try {
      print('🆕 Creating new recipe: ${recipeData['name']}');

      // Add the recipe to Firestore and get the document reference
      DocumentReference docRef = await _firestore
          .collection('recipes')
          .add(recipeData);

      // Get the generated document ID
      String newRecipeId = docRef.id;

      // Add the ID to the recipe data
      recipeData['id'] = newRecipeId;

      print('✅ New recipe created successfully with ID: $newRecipeId');
      return recipeData; // Return the complete recipe data with ID
    } catch (e) {
      print('❌ Error creating recipe: $e');
      return null;
    }
  }

  Future<bool> deleteRecipe(String recipeId) async {
    try {
      if (recipeId.isEmpty) {
        return false;
      }

      await _firestore.collection('recipes').doc(recipeId).delete();
      return true;
    } catch (e) {
      print('❌ Error deleting recipe: $e');
      return false;
    }
  }
}