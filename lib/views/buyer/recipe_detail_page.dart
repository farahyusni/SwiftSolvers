import 'package:flutter/material.dart';
import '../../services/favourites_services.dart';

class RecipeDetailPage extends StatefulWidget {
  final Map<String, dynamic> recipe;

  const RecipeDetailPage({Key? key, required this.recipe}) : super(key: key);

  @override
  _RecipeDetailPageState createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  List<bool> _checkedIngredients = [];
  final FavoritesService _favoritesService = FavoritesService();
  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print('🚀 RecipeDetailPage initState started');

    // Initialize all ingredients as unchecked
    final ingredients = widget.recipe['ingredients'] as List<dynamic>? ?? [];
    _checkedIngredients = List.filled(ingredients.length, false);

    // Debug: Print the entire recipe data
    print('📦 Recipe data keys: ${widget.recipe.keys.toList()}');
    print('📦 Recipe name: ${widget.recipe['name']}');
    print('📦 Recipe id: ${widget.recipe['id']}');

    // Check if recipe is already in favorites
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    print('🔍 _checkFavoriteStatus called');

    final recipeId = widget.recipe['id']?.toString() ?? '';

    print('🔍 Recipe data received: ${widget.recipe.keys.toList()}');
    print('🔍 Recipe ID from data: $recipeId');
    print('🔍 Current user ID: ${_favoritesService.currentUserId}');

    if (recipeId.isNotEmpty) {
      print('🔍 Calling isFavorite with ID: $recipeId');
      final isFav = await _favoritesService.isFavorite(recipeId);
      print('🔍 isFavorite returned: $isFav');

      if (mounted) {
        setState(() {
          _isFavorite = isFav;
        });
        print('📝 Favorite status set to: $_isFavorite');
      }
    } else {
      print('❌ No recipe ID found in recipe data');
      print('❌ Full recipe data: $widget.recipe');
    }
  }

  Future<void> _toggleFavorite() async {
    print('🔄 _toggleFavorite called');

    setState(() {
      _isLoading = true;
    });

    // Store the current state before toggling
    final wasAlreadyFavorite = _isFavorite;
    print('🔄 Current favorite status: $wasAlreadyFavorite');

    final success = await _favoritesService.toggleFavorite(widget.recipe);
    print('🔄 toggleFavorite returned: $success');

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (success) {
          _isFavorite = !_isFavorite;
        }
      });

      // Show feedback to user based on the action that was performed
      if (success) {
        final message = wasAlreadyFavorite
            ? 'Recipe removed from favorites!'
            : 'Recipe saved to favorites!';

        print('✅ Showing message: $message');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFFFF5B9E),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        print('❌ Toggle failed, showing error message');
        // Show error message if the operation failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update favorites. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final ingredients = recipe['ingredients'] as List<dynamic>? ?? [];
    final instructions = recipe['instructions'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFFEECEE), // Light pink background
      body: SafeArea(
        child: Column(
          children: [
            // Header with recipe image and title
            _buildHeader(context, recipe),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ingredients section
                    _buildIngredientsSection(ingredients),

                    // Add to cart button
                    _buildAddToCartButton(context),

                    // Instructions section
                    _buildInstructionsSection(instructions),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic> recipe) {
    return Container(
      height: 300,
      child: Stack(
        children: [
          // Background image
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              image: recipe['imageUrl'] != null && recipe['imageUrl'].isNotEmpty
                  ? DecorationImage(
                image: NetworkImage(recipe['imageUrl']),
                fit: BoxFit.cover,
              )
                  : null,
              color: recipe['imageUrl'] == null || recipe['imageUrl'].isEmpty
                  ? Colors.grey[300]
                  : null,
            ),
            child: recipe['imageUrl'] == null || recipe['imageUrl'].isEmpty
                ? const Center(
              child: Icon(
                Icons.image_not_supported,
                size: 50,
                color: Colors.grey,
              ),
            )
                : null,
          ),

          // Dark overlay
          Container(
            height: 300,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),

          // Top row with back button and profile icon
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushNamed('/buyer-profile');
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Recipe title and save button
          Positioned(
            bottom: 40,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  recipe['name'] ?? 'Unknown Recipe',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _isLoading ? null : () {
                    print('💾 Save button tapped!');
                    print('💾 Current loading state: $_isLoading');
                    print('💾 Current favorite state: $_isFavorite');
                    _toggleFavorite();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isFavorite
                          ? const Color(0xFFFF5B9E).withOpacity(0.9)
                          : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isLoading)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _isFavorite ? Colors.white : const Color(0xFFFF5B9E),
                              ),
                            ),
                          )
                        else
                          Icon(
                            _isFavorite ? Icons.bookmark : Icons.bookmark_border,
                            size: 16,
                            color: _isFavorite ? Colors.white : Colors.black,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          _isFavorite ? 'Saved' : 'Save',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _isFavorite ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection(List<dynamic> ingredients) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ingredients',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...ingredients.asMap().entries.map((entry) {
            final index = entry.key;
            final ingredient = entry.value;
            final name = ingredient['name'] ?? '';
            final amount = ingredient['amount'] ?? '';
            final unit = ingredient['unit'] ?? '';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _checkedIngredients[index] = !_checkedIngredients[index];
                      });
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _checkedIngredients[index]
                              ? const Color(0xFFFF5B9E)
                              : Colors.grey,
                          width: 2,
                        ),
                        color: _checkedIngredients[index]
                            ? const Color(0xFFFF5B9E)
                            : Colors.transparent,
                      ),
                      child: _checkedIngredients[index]
                          ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$amount${unit.isNotEmpty ? ' $unit' : ''} $name',
                      style: TextStyle(
                        fontSize: 16,
                        decoration: _checkedIngredients[index]
                            ? TextDecoration.lineThrough
                            : null,
                        color: _checkedIngredients[index]
                            ? Colors.grey
                            : Colors.black,
                      ),
                    ),
                  ),
                  // Dropdown arrow (for future price comparison feature)
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAddToCartButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ingredients added to cart!'),
                backgroundColor: Color(0xFFFF5B9E),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5B9E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: const Text(
            'Add to cart',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionsSection(List<dynamic> instructions) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Instructions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...instructions.map((instruction) {
            final step = instruction['step'] ?? 0;
            final text = instruction['instruction'] ?? '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$step. ',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}