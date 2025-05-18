import 'package:flutter/material.dart';

class BuyerHomePage extends StatelessWidget {
  const BuyerHomePage({Key? key}) : super(key: key);

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
              child: _buildRecipeGrid(context),
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
          Container(
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
              // const Text(
              //   'YumCart',
              //   style: TextStyle(
              //     fontSize: 16,
              //     fontWeight: FontWeight.bold,
              //     color: Color(0xFFFF5B9E),
              //   ),
              // ),
            ],
          ),

          // Favorite and profile buttons
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () {
                  Navigator.of(context).pushNamed('/buyer-profile');
                },
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
            const Expanded(
              child: TextField(
                decoration: InputDecoration(
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
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeGrid(BuildContext context) {
    // List of recipes exactly as shown in the Figma
    final List<Map<String, String>> recipes = [
      {'name': 'Chicken Rendang', 'image': 'images/chicken_rendang.jpg'},
      {'name': 'Patin tempoyak', 'image': 'images/patin_tempoyak.jpg'},
      {'name': 'Daging masak hitam', 'image': 'images/daging_masak_hitam.jpg'},
      {'name': 'Smoked Duck Spaghetti', 'image': 'images/smoked_duck.jpg'},
      {'name': 'Laksa Johor', 'image': 'images/laksa_johor.jpg'},
      {'name': 'Spaghetti Bolognese', 'image': 'images/spaghetti_bolognese.jpg'},
      {'name': 'Laksa Sarawak', 'image': 'images/laksa_sarawak.jpg'},
      {'name': 'Hokkien Mee', 'image': 'images/hokkien_mee.jpg'},
      {'name': 'Tom Yam Soup', 'image': 'images/tom_yam.jpg'},
      {'name': 'Pan Mee', 'image': 'images/pan_mee.jpg'},
      {'name': 'Mee curry', 'image': 'images/mee_curry.jpg'},
      {'name': 'Ayam masak Merah', 'image': 'images/ayam_masak_merah.jpg'},
    ];

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
          return _buildRecipeCard(
            context, // Pass context to _buildRecipeCard
            recipes[index]['name']!,
            recipes[index]['image']!,
          );
        },
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, String recipeName, String imagePath) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Recipe image
          Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              );
            },
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
    );
  }
}