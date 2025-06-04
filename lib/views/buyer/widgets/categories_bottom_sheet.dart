// lib/views/buyer/widgets/categories_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:yum_cart/models/category_model.dart';
import 'package:yum_cart/services/recipe_service.dart';

class CategoriesBottomSheet extends StatefulWidget {
  final Function(String?) onCategorySelected;
  final String? selectedCategoryId;

  const CategoriesBottomSheet({
    Key? key,
    required this.onCategorySelected,
    this.selectedCategoryId,
  }) : super(key: key);

  @override
  _CategoriesBottomSheetState createState() => _CategoriesBottomSheetState();
}

class _CategoriesBottomSheetState extends State<CategoriesBottomSheet> {
  final RecipeService _recipeService = RecipeService();
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categoriesData = await _recipeService.getAllCategories();
      setState(() {
        _categories = categoriesData.map((data) => Category.fromMap(data)).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _parseColor(String colorString) {
    try {
      // Remove # if present and add opacity
      String cleanColor = colorString.replaceAll('#', '');
      return Color(int.parse('FF$cleanColor', radix: 16));
    } catch (e) {
      // Default color if parsing fails
      return const Color(0xFFFF6B6B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFFFEECEE), // Match your app's background color
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 20),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFFF5B9E).withOpacity(0.3), // Pink handle bar
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Choose Category',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF5B9E), // Pink title
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFFFF5B9E)), // Pink close button
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Categories list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // "All Categories" option
                      _buildCategoryTile(
                        title: 'All Recipes',
                        description: 'Show all available recipes',
                        color: const Color(0xFFFF5B9E), // Use app's pink color
                        isSelected: widget.selectedCategoryId == null,
                        onTap: () {
                          widget.onCategorySelected(null);
                          Navigator.pop(context);
                        },
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Category tiles
                      ..._categories.map((category) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildCategoryTile(
                          title: category.name,
                          description: category.description,
                          color: _parseColor(category.color),
                          isSelected: widget.selectedCategoryId == category.name,
                          onTap: () {
                            widget.onCategorySelected(category.name);
                            Navigator.pop(context);
                          },
                        ),
                      )).toList(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile({
    required String title,
    required String description,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.white.withOpacity(0.7), // Softer background
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFFF5B9E).withOpacity(0.3), // Pink border
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Color indicator
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    )
                  : null,
            ),
            
            const SizedBox(width: 16),
            
            // Category info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : const Color(0xFF4A5568), // Darker text
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF718096), // Consistent grey
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow icon
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isSelected ? color : const Color(0xFFFF5B9E).withOpacity(0.5), // Pink arrow
            ),
          ],
        ),
      ),
    );
  }
}