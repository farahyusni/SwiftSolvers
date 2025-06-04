import 'package:flutter/material.dart';
import '../../services/recipe_service.dart';
import 'edit_recipe_page.dart';

class SellerRecipeDetailPage extends StatefulWidget {
  final Map<String, dynamic> recipe;

  const SellerRecipeDetailPage({Key? key, required this.recipe})
    : super(key: key);

  @override
  _SellerRecipeDetailPageState createState() => _SellerRecipeDetailPageState();
}

class _SellerRecipeDetailPageState extends State<SellerRecipeDetailPage> {
  @override
  void initState() {
    super.initState();
    print('🚀 SellerRecipeDetailPage initState started');
    print('📦 Recipe data: ${widget.recipe}');
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
              image:
                  recipe['imageUrl'] != null && recipe['imageUrl'].isNotEmpty
                      ? DecorationImage(
                        image: NetworkImage(recipe['imageUrl']),
                        fit: BoxFit.cover,
                      )
                      : null,
              color:
                  recipe['imageUrl'] == null || recipe['imageUrl'].isEmpty
                      ? Colors.grey[300]
                      : null,
            ),
            child:
                recipe['imageUrl'] == null || recipe['imageUrl'].isEmpty
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
                    Navigator.of(context).pushNamed('/seller-profile');
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

          // Recipe title and edit button
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
                  onTap: () {
                    print('✏️ Edit button tapped!');
                    _showEditOptions(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, size: 16, color: Colors.black),
                        SizedBox(width: 8),
                        Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
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
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...ingredients.asMap().entries.map((entry) {
            final ingredient = entry.value;
            final name = ingredient['name'] ?? '';
            final amount = ingredient['amount'] ?? '';
            final unit = ingredient['unit'] ?? '';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF5B9E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$amount${unit.isNotEmpty ? ' $unit' : ''} $name',
                      style: const TextStyle(fontSize: 16, color: Colors.black),
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

  Widget _buildInstructionsSection(List<dynamic> instructions) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Instructions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF5B9E),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$step',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(text, style: const TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _showEditOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Edit Recipe',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFFFF5B9E)),
                title: const Text('Edit Recipe Details'),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  _navigateToEditPage(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Recipe'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Add this new method to handle navigation to edit page
  Future<void> _navigateToEditPage(BuildContext context) async {
    print('📝 Navigating to edit page for recipe: ${widget.recipe['name']}');

    try {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EditRecipePage(recipe: widget.recipe),
        ),
      );

      // If the edit page returns updated data, refresh this page
      if (result != null && result is Map<String, dynamic>) {
        print('✅ Recipe was updated, refreshing detail page');

        setState(() {
          // Update the recipe data with the returned updated data
          widget.recipe.clear();
          widget.recipe.addAll(result);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recipe details refreshed!'),
            backgroundColor: Color(0xFFFF5B9E),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error navigating to edit page: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to open edit page. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Recipe'),
          content: const Text(
            'Are you sure you want to delete this recipe? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Implement delete functionality
                print('Delete recipe: ${widget.recipe['name']}');
                Navigator.pop(context); // Go back to previous page
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
