import 'package:flutter/material.dart';
import 'seller_shop_profile_page.dart'; // <-- Add this import
import 'seller_profile_page.dart'; 

class SellerHomePage extends StatefulWidget {
  const SellerHomePage({Key? key}) : super(key: key);

  @override
  _SellerHomePageState createState() => _SellerHomePageState();
}

class _SellerHomePageState extends State<SellerHomePage> {
  int _selectedBottomNavIndex = 0; // Start with Home tab selected
  final TextEditingController _searchController = TextEditingController(); // Controller for search input
  List<String> foodItems = [
    'Malaysian Fried Rice',
    'Hokkien Mee',
    'Malaysian Chicken Curry',
  ];
  List<String> filteredFoodItems = []; // To hold the filtered items

  @override
  void initState() {
    super.initState();
    filteredFoodItems = foodItems; // Initially, show all items
    _searchController.addListener(_filterSearchResults); // Listen for text changes in the search field
  }

  // Function to filter food items based on search text
  void _filterSearchResults() {
    setState(() {
      filteredFoodItems = foodItems
          .where((item) => item.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    });
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
        return Column(
          children: [
            _buildSearchBar(),
            _buildFoodGrid(),
          ],
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
      floatingActionButton: _selectedBottomNavIndex == 3 ? _buildFloatingActionButton() : null,
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
                      MaterialPageRoute(builder: (context) => const SellerShopProfilePage()),
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
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            children: filteredFoodItems.map((item) => Expanded(
              child: Container(
                height: 120,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
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
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 35,
            ),
          ),
        ),
      ],
    );
  }
}