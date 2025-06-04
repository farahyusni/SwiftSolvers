import 'package:flutter/material.dart';
import 'seller_shop_profile_page.dart'; // <-- Add this import
import 'seller_profile_page.dart';
import 'seller_recipe_detail_page.dart';
import 'edit_recipe_page.dart';
import '../../services/recipe_service.dart';

class SellerHomePage extends StatefulWidget {
  const SellerHomePage({Key? key}) : super(key: key);

  @override
  _SellerHomePageState createState() => _SellerHomePageState();
}

class _SellerHomePageState extends State<SellerHomePage> {
  int _selectedBottomNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final RecipeService _recipeService = RecipeService(); // Add this line

  List<Map<String, dynamic>> recipes = [];
  List<Map<String, dynamic>> filteredRecipes = [];
  bool _isLoading = true; // Add loading state

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterSearchResults);
    _debugDatabase();
    _loadRecipes(); // Load recipes from database
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Load recipes from Firebase using your existing service
  Future<void> _loadRecipes() async {
    print('🔄 Loading recipes from database...');
    setState(() {
      _isLoading = true;
    });

    try {
      final loadedRecipes = await _recipeService.getAllRecipes();

      // If no recipes found, initialize with sample data
      if (loadedRecipes.isEmpty) {
        print('⚠️ No recipes found, initializing database...');
        await _recipeService.initializeDatabase();
        final newRecipes = await _recipeService.getAllRecipes();

        if (mounted) {
          setState(() {
            recipes = newRecipes;
            filteredRecipes = newRecipes;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            recipes = loadedRecipes;
            filteredRecipes = loadedRecipes;
            _isLoading = false;
          });
        }
      }

      print('✅ Loaded ${recipes.length} recipes successfully');
    } catch (e) {
      print('❌ Error loading recipes: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Function to filter recipes based on search text
  void _filterSearchResults() {
    if (_searchController.text.isEmpty) {
      setState(() {
        filteredRecipes = recipes;
      });
    } else {
      setState(() {
        filteredRecipes =
            recipes
                .where(
                  (recipe) =>
                      recipe['name']?.toString().toLowerCase().contains(
                        _searchController.text.toLowerCase(),
                      ) ??
                      false,
                )
                .toList();
      });
    }
  }

  Future<void> _debugDatabase() async {
    print('🔍 Debugging database...');
    try {
      final recipes = await _recipeService.getAllRecipes();
      print('📊 Found ${recipes.length} recipes in database');

      if (recipes.isEmpty) {
        print(
          '⚠️ No recipes found. You might need to initialize the database.',
        );
        // Uncomment the line below if you need to add sample data
        // await _recipeService.initializeDatabase();
      } else {
        for (var recipe in recipes) {
          print('📖 Recipe: ${recipe['name']}');
        }
      }
    } catch (e) {
      print('❌ Database error: $e');
    }
  }

  // Function to get the main content based on selected tab
  Widget _getMainContent() {
    switch (_selectedBottomNavIndex) {
      case 0: // Home - Show Quick Stats
        return _buildQuickStats();
      case 1: // Orders
        return _buildOrdersContent();
      case 2: // Stocks
        return _buildStocksContent();
      case 3: // Recipe - Show search and food items
        return Expanded(
          // Add Expanded here!
          child: Column(children: [_buildSearchBar(), _buildFoodGrid()]),
        );
      default:
        return _buildQuickStats();
    }
  }

  Widget _buildQuickStats() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'Quick Stats',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8B8B8B),
              ),
            ),
            const SizedBox(height: 30),

            // Total Sales Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF5B9E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.attach_money,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '-',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Total Sales',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF8B8B8B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Number of Recipes Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF8C42),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '-',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Number of Recipes',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF8B8B8B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Pending Orders Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pending_actions,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '-',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pending Orders',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF8B8B8B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersContent() {
    return const Expanded(
      child: Center(
        child: Text(
          'Orders Content',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8B8B8B),
          ),
        ),
      ),
    );
  }

  Widget _buildStocksContent() {
    return const Expanded(
      child: Center(
        child: Text(
          'Stocks Content',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8B8B8B),
          ),
        ),
      ),
    );
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

            // Main content based on selected tab
            _getMainContent(),
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: _buildBottomNavigationBar(),

      // Floating Action Button above Recipe icon (only show when Recipe is selected)
      floatingActionButton:
          _selectedBottomNavIndex == 3 ? _buildFloatingActionButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: const Icon(
              Icons.chevron_left,
              size: 24,
              color: Colors.black,
            ),
          ),

          // YumCart logo
          Image.asset(
            'images/logo.png',
            width: 80,
            height: 80,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF5B9E),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.shopping_basket,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              );
            },
          ),

          // Icons: shop and profile
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.storefront_outlined,
                    size: 24,
                    color: Colors.black,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SellerShopProfilePage(),
                      ),
                    );
                  },
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.person_outline,
                    size: 24,
                    color: Colors.black,
                  ),
                  onPressed: () {
                    Navigator.of(context).pushNamed('/seller-profile');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            SizedBox(width: 20),
            Icon(Icons.menu, color: Colors.grey, size: 22),
            SizedBox(width: 15),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search your recipe',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ),
            Icon(Icons.search, color: Colors.grey, size: 22),
            SizedBox(width: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodGrid() {
    if (_isLoading) {
      return const Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFFFF5B9E)),
              SizedBox(height: 16),
              Text(
                'Loading recipes...',
                style: TextStyle(fontSize: 16, color: Color(0xFF8B8B8B)),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredRecipes.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _searchController.text.isEmpty
                    ? 'No recipes available'
                    : 'No recipes found',
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF8B8B8B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchController.text.isEmpty
                    ? 'Start by adding your first recipe!'
                    : 'Try a different search term',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: filteredRecipes.length,
          itemBuilder: (context, index) {
            final recipe = filteredRecipes[index];
            return GestureDetector(
              onTap: () {
                print('🍽️ Tapped on recipe: ${recipe['name']}');
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) => SellerRecipeDetailPage(recipe: recipe),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // Background image or color
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          image:
                              recipe['imageUrl'] != null &&
                                      recipe['imageUrl'].isNotEmpty
                                  ? DecorationImage(
                                    image: NetworkImage(recipe['imageUrl']),
                                    fit: BoxFit.cover,
                                  )
                                  : null,
                          color:
                              recipe['imageUrl'] == null ||
                                      recipe['imageUrl'].isEmpty
                                  ? Colors.grey[400]
                                  : null,
                        ),
                      ),

                      // Dark overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),

                      // Recipe name
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Text(
                          recipe['name'] ?? 'Unknown Recipe',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(Icons.home_outlined, 'Home', 0),
          _buildBottomNavItem(Icons.shopping_bag_outlined, 'Orders', 1),
          const SizedBox(width: 60), // Space for FAB
          _buildBottomNavItem(Icons.inventory_2_outlined, 'Stocks', 2),
          _buildBottomNavItem(Icons.receipt_outlined, 'Recipe', 3),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedBottomNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBottomNavIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFFFF5B9E) : Colors.grey,
            size: 26,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFFFF5B9E) : Colors.grey,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 3,
              width: 30,
              decoration: const BoxDecoration(
                color: Color(0xFFFF5B9E),
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          bottom: 10,
          left: MediaQuery.of(context).size.width / 2 - 35,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 35),
          ),
        ),
      ],
    );
  }
}
