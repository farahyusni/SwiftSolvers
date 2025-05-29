// lib/services/favourites_services.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Add recipe to favorites
  Future<bool> addToFavorites(Map<String, dynamic> recipe) async {
    try {
      if (currentUserId == null) {
        print('❌ No user logged in');
        return false;
      }

      final recipeId = recipe['id']?.toString();
      if (recipeId == null || recipeId.isEmpty) {
        print('❌ Recipe ID is null or empty');
        print('Recipe data: $recipe');
        return false;
      }

      print('➕ Adding recipe to favorites: $recipeId for user: $currentUserId');

      // Save the complete recipe data to favorites subcollection
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorites')
          .doc(recipeId)
          .set({
        'id': recipeId,
        'name': recipe['name'],
        'description': recipe['description'],
        'category': recipe['category'],
        'difficulty': recipe['difficulty'],
        'prepTime': recipe['prepTime'],
        'cookTime': recipe['cookTime'],
        'servings': recipe['servings'],
        'isPopular': recipe['isPopular'],
        'imageUrl': recipe['imageUrl'],
        'ingredients': recipe['ingredients'],
        'instructions': recipe['instructions'],
        'tags': recipe['tags'],
        'nutritionInfo': recipe['nutritionInfo'],
        'totalEstimatedCost': recipe['totalEstimatedCost'],
        'createdBy': recipe['createdBy'],
        'addedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Successfully added to favorites');
      return true;
    } catch (e) {
      print('❌ Error adding to favorites: $e');
      return false;
    }
  }

  // Remove recipe from favorites
  Future<bool> removeFromFavorites(String recipeId) async {
    try {
      if (currentUserId == null) {
        print('❌ No user logged in');
        return false;
      }

      print('➖ Removing recipe from favorites: $recipeId for user: $currentUserId');

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorites')
          .doc(recipeId)
          .delete();

      print('✅ Successfully removed from favorites');
      return true;
    } catch (e) {
      print('❌ Error removing from favorites: $e');
      return false;
    }
  }

  // Check if recipe is in favorites
  Future<bool> isFavorite(String recipeId) async {
    try {
      if (currentUserId == null) {
        print('❌ No user logged in for favorite check');
        return false;
      }

      print('🔍 Checking if recipe is favorite: $recipeId for user: $currentUserId');

      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorites')
          .doc(recipeId)
          .get();

      final isFav = doc.exists;
      print('📝 Recipe $recipeId is favorite: $isFav');
      return isFav;
    } catch (e) {
      print('❌ Error checking favorite status: $e');
      return false;
    }
  }

  // Get all favorite recipes
  Stream<List<Map<String, dynamic>>> getFavorites() {
    if (currentUserId == null) {
      print('❌ No user logged in for getting favorites');
      return Stream.value([]);
    }

    print('📂 Getting favorites for user: $currentUserId');

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('favorites')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      print('📋 Found ${snapshot.docs.length} favorites');
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Ensure the id field is present for compatibility
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(Map<String, dynamic> recipe) async {
    final recipeId = recipe['id']?.toString();

    if (recipeId == null || recipeId.isEmpty) {
      print('❌ Cannot toggle favorite: Recipe ID is null or empty');
      print('Available recipe keys: ${recipe.keys.toList()}');
      return false;
    }

    print('🔄 Toggling favorite for recipe: $recipeId');

    final isFav = await isFavorite(recipeId);

    if (isFav) {
      print('➖ Recipe is currently favorite, removing...');
      return await removeFromFavorites(recipeId);
    } else {
      print('➕ Recipe is not favorite, adding...');
      return await addToFavorites(recipe);
    }
  }
}