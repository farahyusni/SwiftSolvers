// lib/views/seller/seller_home_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'seller_shop_profile_page.dart';
import 'seller_profile_page.dart';
import 'seller_recipe_detail_page.dart';
import 'edit_recipe_page.dart';
import '../../services/recipe_service.dart';
import '../../services/stock_service.dart';
import 'edit_stock_item_page.dart';
import '../../helpers/auth_helper.dart'; // Add this import
import 'package:cloud_firestore/cloud_firestore.dart';

class SellerHomePage extends StatefulWidget {
  const SellerHomePage({Key? key}) : super(key: key);

  @override
  _SellerHomePageState createState() => _SellerHomePageState();
}

class _SellerHomePageState extends State<SellerHomePage> {
  int _selectedBottomNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final RecipeService _recipeService = RecipeService();
  final StockService _stockService = StockService();

  List<Map<String, dynamic>> recipes = [];
  List<Map<String, dynamic>> filteredRecipes = [];
  bool _isLoading = true;

  List<Map<String, dynamic>> stocks = [];
  List<Map<String, dynamic>> filteredStocks = [];
  final TextEditingController _stockSearchController = TextEditingController();
  bool _isStockLoading = true;

  // User session data
  String? _currentUserId;
  String? _currentUserEmail;
  bool _isNewUser = false;

  // Category filter variables
  String _selectedStockCategory = 'All';
  bool _showCategoryFilter = false;
  final List<String> _stockCategories = [
    'All',
    'Grains',
    'Vegetables',
    'Fruits',
    'Protein',
    'Dairy',
    'Condiments',
    'Spices',
    'Beverages',
    'Snacks',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterSearchResults);
    _stockSearchController.addListener(() {
      setState(() {
        // This will trigger rebuild and filter the stock list
      });
    });

    // Initialize user session and load data
    _initializeUserSession();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _stockSearchController.dispose();
    super.dispose();
  }

  // Initialize user session and check for new users
  Future<void> _initializeUserSession() async {
    try {
      // Validate user session
      final isValidSession = await AuthHelper.validateUserSession();
      if (!isValidSession) {
        // Redirect to login if session is invalid
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      // Get current user info
      _currentUserId = AuthHelper.getCurrentUserId();
      _currentUserEmail = AuthHelper.getCurrentUserEmail();

      print('👤 Current user: $_currentUserEmail (ID: $_currentUserId)');

      // Load existing data (no automatic sample data creation)
      await _loadUserData();
    } catch (e) {
      print('❌ Error initializing user session: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Initialize data for new users
  Future<void> _initializeNewUserData() async {
    try {
      print('🆕 New user detected: $_currentUserId');

      // Mark user as initialized without creating sample data
      await AuthHelper.markUserAsInitialized();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Welcome! You can start creating your own recipes and managing inventory.',
            ),
            backgroundColor: Color(0xFFFF5B9E),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error initializing new user: $e');
      rethrow;
    }
  }

  // Load user-specific data
  Future<void> _loadUserData() async {
    try {
      await Future.wait([_loadRecipes(), _loadStocks()]);
    } catch (e) {
      print('❌ Error loading user data: $e');
    }
  }

  // Load recipes for current user
  Future<void> _loadRecipes() async {
    print('🔄 Loading recipes for user: $_currentUserId');

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final loadedRecipes = await _recipeService.getAllRecipes();

      print('📊 Loaded ${loadedRecipes.length} recipes for current user');

      // Debug: Print all recipe names and IDs
      for (var recipe in loadedRecipes) {
        print(
          '📖 Recipe: "${recipe['name']}" - ID: "${recipe['id']}" - Created by: "${recipe['createdBy']}"',
        );
      }

      if (mounted) {
        setState(() {
          recipes = loadedRecipes;
          filteredRecipes = loadedRecipes;
          _isLoading = false;
        });
      }

      print('✅ Loaded ${recipes.length} recipes successfully for current user');

      // Filter current search if there's text in search controller
      if (_searchController.text.isNotEmpty) {
        _filterSearchResults();
      }
    } catch (e) {
      print('❌ Error loading recipes: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading recipes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Load stocks for current user
  Future<void> _loadStocks() async {
    print('📦 Loading stocks for user: $_currentUserId');

    if (mounted) {
      setState(() => _isStockLoading = true);
    }

    try {
      final fetchedStocks = await _stockService.getAllStocks();

      if (mounted) {
        setState(() {
          stocks = fetchedStocks;
          filteredStocks = fetchedStocks;
          _isStockLoading = false;
        });
      }

      print('✅ Loaded ${stocks.length} stock items for current user');
    } catch (e) {
      print('❌ Error loading stocks: $e');

      if (mounted) {
        setState(() => _isStockLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading stocks: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Navigate to create new recipe
  Future<void> _navigateToCreateRecipe() async {
    print('🆕 Navigating to create new recipe page');

    try {
      // Validate user session before creating
      if (!AuthHelper.isUserAuthenticated()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to create recipes'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create an empty recipe template
      final emptyRecipe = {
        'id': '', // Will be set after creation
        'name': '',
        'description': '',
        'category': 'Quick Meals',
        'difficulty': 'Easy',
        'prepTime': 0,
        'cookTime': 0,
        'servings': 1,
        'isPopular': false,
        'imageUrl': '',
        'ingredients': [],
        'instructions': [],
        'tags': [],
        'nutritionInfo': {
          'calories': 0,
          'protein': '0g',
          'carbs': '0g',
          'fat': '0g',
        },
        'totalEstimatedCost': {'tesco': 0.0, 'mydin': 0.0, 'giant': 0.0},
        'createdBy': _currentUserId, // Link to current user
        'isNewRecipe': true, // Flag to indicate this is a new recipe
      };

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EditRecipePage(recipe: emptyRecipe),
        ),
      );

      // If a new recipe was created, refresh the recipe list
      if (result != null && result is Map<String, dynamic>) {
        print('✅ New recipe was created, refreshing recipe list');

        // Reload recipes from database
        await _loadRecipes();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New recipe created successfully!'),
              backgroundColor: Color(0xFFFF5B9E),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error navigating to create recipe page: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to open create recipe page. Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Filter recipes based on search text
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

  // Get the main content based on selected tab
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
          child: Column(children: [_buildSearchBar(), _buildFoodGrid()]),
        );
      default:
        return _buildQuickStats();
    }
  }

  // Calculate total sales for current user
  Future<double> _getTotalSales() async {
    try {
      double total = 0.0;
      final snapshot =
          await FirebaseFirestore.instance
              .collection('orders')
              .where(
                'sellerId',
                isEqualTo: _currentUserId,
              ) // Filter by current user
              .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'paid') {
          total += (data['totalAmount'] ?? 0).toDouble();
        }
      }
      return total;
    } catch (e) {
      print('❌ Error calculating total sales: $e');
      return 0.0;
    }
  }

  // Build quick stats widget
  Widget _buildQuickStats() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Quick Stats',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8B8B8B),
              ),
            ),
            const SizedBox(height: 20),

            // Welcome message for current user
            if (_currentUserEmail != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5B9E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF5B9E).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.person,
                      color: Color(0xFFFF5B9E),
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Welcome, ${AuthHelper.getUserDisplayName()}!',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF5B9E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentUserEmail ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8B8B8B),
                      ),
                    ),
                  ],
                ),
              ),

            // Total Sales Card
            FutureBuilder<double>(
              future: _getTotalSales(),
              builder: (context, snapshot) {
                final totalText =
                    snapshot.connectionState == ConnectionState.waiting
                        ? '...'
                        : snapshot.hasData
                        ? 'RM ${snapshot.data!.toStringAsFixed(2)}'
                        : 'RM 0.00';

                return Container(
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
                      Text(
                        totalText,
                        style: const TextStyle(
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
                );
              },
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
                  Text(
                    '${recipes.length}',
                    style: const TextStyle(
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

            // Number of Stock Items Card
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
                      Icons.inventory_2,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${stocks.length}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Stock Items',
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

  // Build stocks content with user-specific data
  Widget _buildStocksContent() {
    if (_isStockLoading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF5B9E)),
        ),
      );
    }

    // Filter stocks based on selected category and search text
    List<Map<String, dynamic>> displayedStocks =
        stocks.where((stock) {
          final name = stock['name']?.toString().toLowerCase() ?? '';
          final category = stock['category']?.toString() ?? '';

          // Check search text
          bool matchesSearch =
              name.isEmpty ||
              name.contains(_stockSearchController.text.toLowerCase());

          // Check category filter
          bool matchesCategory =
              _selectedStockCategory == 'All' ||
              category == _selectedStockCategory;

          return matchesSearch && matchesCategory;
        }).toList();

    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(
                  'Inventory Management',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B8B8B),
                  ),
                ),
                const SizedBox(height: 20),

                // Search bar with filter dropdown
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 20),
                      // Filter menu icon
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showCategoryFilter = !_showCategoryFilter;
                          });
                        },
                        child: Icon(
                          _showCategoryFilter
                              ? Icons.filter_list_off
                              : Icons.menu,
                          color:
                              _selectedStockCategory != 'All'
                                  ? const Color(0xFFFF5B9E)
                                  : Colors.grey,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextField(
                          controller: _stockSearchController,
                          decoration: const InputDecoration(
                            hintText: 'Search Stock',
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              // This will trigger rebuild and filter the list
                            });
                          },
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final newItem = {
                            'id': '',
                            'name': '',
                            'price': 0.0,
                            'stock': 0,
                            'unit': '',
                            'category': '',
                            'imageUrl': '',
                          };

                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => EditStockItemPage(item: newItem),
                            ),
                          );

                          if (result == true) {
                            await _loadStocks();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'New stock item added successfully!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.only(right: 5),
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Category filter dropdown
                if (_showCategoryFilter)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Filter by Category',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              _stockCategories.map((category) {
                                final isSelected =
                                    _selectedStockCategory == category;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedStockCategory = category;
                                      _showCategoryFilter = false;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? const Color(0xFFFF5B9E)
                                              : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? const Color(0xFFFF5B9E)
                                                : Colors.grey[300]!,
                                      ),
                                    ),
                                    child: Text(
                                      category,
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Colors.black,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Show current filter if not 'All'
          if (_selectedStockCategory != 'All')
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5B9E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFF5B9E)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Category: $_selectedStockCategory',
                          style: const TextStyle(
                            color: Color(0xFFFF5B9E),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedStockCategory = 'All';
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            color: Color(0xFFFF5B9E),
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${displayedStocks.length} items',
                    style: const TextStyle(
                      color: Color(0xFF8B8B8B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          // Stock list
          Expanded(
            child:
                displayedStocks.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedStockCategory == 'All' &&
                                    _stockSearchController.text.isEmpty
                                ? 'No stock items available'
                                : 'No items found',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFF8B8B8B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedStockCategory == 'All' &&
                                    _stockSearchController.text.isEmpty
                                ? 'Start by adding your first stock item!'
                                : 'Try adjusting your search or filter',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      itemCount: displayedStocks.length,
                      itemBuilder: (context, index) {
                        final item = displayedStocks[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Image container
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[300],
                                  border: Border.all(
                                    color: Colors.grey[400]!,
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child:
                                      (item['imageUrl'] != null &&
                                              item['imageUrl']
                                                  .toString()
                                                  .isNotEmpty)
                                          ? Image.network(
                                            item['imageUrl'],
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (
                                              context,
                                              child,
                                              loadingProgress,
                                            ) {
                                              if (loadingProgress == null)
                                                return child;
                                              return const Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Color(
                                                          0xFFFF5B9E,
                                                        ),
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                              );
                                            },
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return Container(
                                                width: 80,
                                                height: 80,
                                                color: Colors.grey[200],
                                                child: const Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.broken_image,
                                                      size: 30,
                                                      color: Colors.grey,
                                                    ),
                                                    Text(
                                                      'Failed',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          )
                                          : Container(
                                            width: 80,
                                            height: 80,
                                            color: Colors.grey[200],
                                            child: const Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.inventory_2,
                                                  size: 30,
                                                  color: Colors.grey,
                                                ),
                                                Text(
                                                  'No Image',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'] ?? '-',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'RM${(item['price'] ?? 0).toStringAsFixed(2)} / ${item['unit'] ?? 'piece'}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF8B8B8B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Available: ${item['stock']}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF8B8B8B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Category: ${item['category'] ?? '-'}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF8B8B8B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () async {
                                          final updated = await Navigator.of(
                                            context,
                                          ).push(
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      EditStockItemPage(
                                                        item: item,
                                                      ),
                                            ),
                                          );
                                          if (updated == true) {
                                            await _loadStocks();
                                          }
                                        },
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.edit,
                                            size: 20,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () async {
                                          final confirmed = await showDialog<
                                            bool
                                          >(
                                            context: context,
                                            builder:
                                                (context) => AlertDialog(
                                                  title: const Text(
                                                    'Delete Stock Item',
                                                  ),
                                                  content: Text(
                                                    'Are you sure you want to delete "${item['name']}"?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            context,
                                                            false,
                                                          ),
                                                      child: const Text(
                                                        'Cancel',
                                                      ),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            context,
                                                            true,
                                                          ),
                                                      child: const Text(
                                                        'Delete',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                          );

                                          if (confirmed == true) {
                                            try {
                                              final success =
                                                  await _stockService
                                                      .deleteStock(item['id']);
                                              if (success) {
                                                await _loadStocks();
                                                if (mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Stock deleted successfully',
                                                      ),
                                                      backgroundColor:
                                                          Colors.green,
                                                    ),
                                                  );
                                                }
                                              } else {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Failed to delete stock',
                                                      ),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                }
                                              }
                                            } catch (e) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Failed to delete stock: $e',
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          }
                                        },
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.delete_outline,
                                            size: 20,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if ((item['stock'] ?? 0) < 50)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'LOW',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersContent() {
    return const Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Color(0xFF8B8B8B),
            ),
            SizedBox(height: 16),
            Text(
              'Orders Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8B8B8B),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Coming Soon',
              style: TextStyle(fontSize: 16, color: Color(0xFF8B8B8B)),
            ),
          ],
        ),
      ),
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
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  const Icon(Icons.menu, color: Colors.grey, size: 22),
                  const SizedBox(width: 15),
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
                  const Icon(Icons.search, color: Colors.grey, size: 22),
                  const SizedBox(width: 15),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Add Stocks Icon Button
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.inventory_2_outlined, color: Colors.black),
              onPressed: () {
                print('📦 Navigating to Stocks tab...');
                setState(() {
                  _selectedBottomNavIndex = 2; // Go to Stocks
                });
              },
            ),
          ),
        ],
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
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.9,
          ),
          itemCount: filteredRecipes.length,
          itemBuilder: (context, index) {
            final recipe = filteredRecipes[index];
            return GestureDetector(
              onTap: () async {
                print('🍽️ Tapped on recipe: ${recipe['name']}');
                print('🔍 Recipe ID: ${recipe['id']}');

                // Make sure the recipe has a valid ID before navigation
                if (recipe['id'] == null || recipe['id'].toString().isEmpty) {
                  print('❌ Recipe has no valid ID, cannot open details');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cannot open recipe: Invalid recipe ID'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  // Navigate to detail page and wait for result
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => SellerRecipeDetailPage(recipe: recipe),
                    ),
                  );

                  print('🔄 Received result from detail page: $result');

                  // Handle the result
                  if (result != null && result is Map<String, dynamic>) {
                    if (result['deleted'] == true) {
                      print('🗑️ Recipe was deleted, refreshing list...');

                      // Show a brief loading indicator
                      setState(() {
                        _isLoading = true;
                      });

                      // Reload the recipe list
                      await _loadRecipes();

                      // Show success message
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Recipe deleted and list refreshed!'),
                            backgroundColor: Color(0xFFFF5B9E),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } else if (result['updated'] == true) {
                      // Recipe was updated, refresh the list
                      print('✏️ Recipe was updated, refreshing list...');

                      setState(() {
                        _isLoading = true;
                      });

                      await _loadRecipes();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Recipe updated and list refreshed!'),
                            backgroundColor: Color(0xFFFF5B9E),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  }
                } catch (e) {
                  print('❌ Error navigating to recipe details: $e');

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error opening recipe details: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
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
          child: GestureDetector(
            onTap: () {
              print('➕ Create new recipe button tapped');
              _navigateToCreateRecipe();
            },
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
        ),
      ],
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
}