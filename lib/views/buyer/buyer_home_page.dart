import 'package:flutter/material.dart';
import 'package:yum_cart/services/recipe_service.dart';

class BuyerHomePage extends StatefulWidget {
  const BuyerHomePage({Key? key}) : super(key: key);

  @override
  _BuyerHomePageState createState() => _BuyerHomePageState();
}

class _BuyerHomePageState extends State<BuyerHomePage> {
  final RecipeService _recipeService = RecipeService();
  List<Map<String, dynamic>> _recipes = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    try {
      final recipes = await _recipeService.getAllRecipes();
      setState(() {
        _recipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading recipes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredRecipes {
    if (_searchQuery.isEmpty) {
      return _recipes;
    }
    return _recipes.where((recipe) {
      return recipe['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEECEE), // Light pink background
      body: SafeArea(
        child: Column(
          children: [
            // App bar with back button, logo, and profile icons
            _buildAppBar(context),

            // Search bar
            _buildSearchBar(context),

            // Recipe grid
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildRecipeGrid(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: const Icon(
                Icons.chevron_left,
                size: 24,
              ),
            ),
          ),

          // YumCart logo
          Row(
            children: [
              Image.asset(
                'images/logo.png', // Make sure to add this asset
                width: 100,
                height: 100,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF5B9E),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.shopping_basket,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
          ),

          // Favorite and profile buttons
          Row(
            children: [
              // Updated favorites button - now functional!
              IconButton(
                icon: const Icon(
                  Icons.bookmark_border, // Changed to bookmark icon for consistency
                  color: Color(0xFFFF5B9E), // Added your app's primary color
                ),
                onPressed: () {
                  // Navigate to favorites page
                  Navigator.of(context).pushNamed('/favorites');
                },
                tooltip: 'My Favorites', // Added tooltip for better UX
              ),
              IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () {
                  Navigator.of(context).pushNamed('/buyer-profile');
                },
                tooltip: 'Profile', // Added tooltip for consistency
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.menu, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Search your craving',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.search, color: Colors.grey),
                onPressed: () {
                  // Implement search functionality if needed
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeGrid(BuildContext context) {
    final recipes = _filteredRecipes;

    if (recipes.isEmpty) {
      return const Center(
        child: Text(
          'No recipes found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.0,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return _buildRecipeCard(
            context,
            recipe['name'] ?? 'Unknown Recipe',
            recipe['imageUrl'] ?? '',
            recipe['id'] ?? '',
            recipe, // Pass the entire recipe object
          );
        },
      ),
    );
  }

  Widget _buildRecipeCard(
      BuildContext context,
      String recipeName,
      String imageUrl,
      String recipeId,
      Map<String, dynamic> recipe,
      ) {
    return GestureDetector(
      onTap: () {
        // Navigate to recipe detail page
        Navigator.of(context).pushNamed(
          '/recipe-detail',
          arguments: recipe, // Pass the entire recipe object
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Recipe image
            imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
                );
              },
            )
                : Container(
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),

            // Transparent overlay
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
              ),
            ),

            // Recipe name text
            Center(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  recipeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}