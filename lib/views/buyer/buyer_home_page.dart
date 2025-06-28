// lib/views/buyer/buyer_home_page.dart - Simplified with notifications
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yum_cart/services/recipe_service.dart';
import 'package:yum_cart/views/buyer/widgets/categories_bottom_sheet.dart';
import '../../viewmodels/cart_viewmodel.dart';
import '../../services/notification_service.dart';
import '../../models/notification_models.dart';
import '../../services/order_notification_bridge.dart';


class BuyerHomePage extends StatefulWidget {
  const BuyerHomePage({Key? key}) : super(key: key);

  @override
  _BuyerHomePageState createState() => _BuyerHomePageState();
}

class _BuyerHomePageState extends State<BuyerHomePage>
    with TickerProviderStateMixin {
  final RecipeService _recipeService = RecipeService();
  List<Map<String, dynamic>> _recipes = [];
  List<Map<String, dynamic>> _allRecipes = []; // Store all recipes
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedCategory; // Track selected category

  // Notification system components
  late AnimationController _bellController;
  late Animation<double> _bellAnimation;

  final OrderNotificationBridge _notificationBridge = OrderNotificationBridge();

  @override
  void initState() {
    super.initState();
    _loadRecipes();
    _initializeNotifications();

    // Load cart when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartViewModel>().loadCart();
    });
  }

  Future<void> _initializeNotifications() async {
    try {
      print('🔔 Initializing buyer notifications...');

      // Initialize bell animation
      _bellController = AnimationController(
        duration: const Duration(milliseconds: 1000),
        vsync: this,
      );

      _bellAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _bellController,
        curve: Curves.elasticOut,
      ));

      // Initialize notification service
      final notificationService = context.read<NotificationService>();
      await notificationService.initialize();
      await notificationService.requestPermission();

      // 🔔 START LISTENING FOR ORDER STATUS UPDATES
      _notificationBridge.startListening(isSeller: false);

      print('✅ Buyer notifications initialized successfully');

      // Add sample notifications for demo (keep your existing code)
     // _addSampleNotifications();

    } catch (e) {
      print('❌ Error initializing notifications: $e');
    }
  }

  // void _addSampleNotifications() {
  //   final notificationService = context.read<NotificationService>();
  //
  //   // Add sample notifications for demo purposes
  //   Future.delayed(const Duration(seconds: 2), () {
  //     if (mounted) {
  //       notificationService.createPromotionalNotification(
  //         title: 'Welcome to YumCart! 🎉',
  //         message: 'Discover delicious recipes and get groceries delivered!',
  //       );
  //     }
  //   });
  //
  //   Future.delayed(const Duration(seconds: 5), () {
  //     if (mounted) {
  //       notificationService.createPromotionalNotification(
  //         title: 'Fresh Vegetables Sale',
  //         message: '20% off on all fresh vegetables this weekend!',
  //       );
  //     }
  //   });
  // }

  @override
  void dispose() {
    _bellController.dispose();
    _notificationBridge.stopListening();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    try {
      final recipes = await _recipeService.getAllRecipes();
      setState(() {
        _allRecipes = recipes;
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

  // Filter recipes by category
  Future<void> _filterByCategory(String? category) async {
    setState(() {
      _isLoading = true;
      _selectedCategory = category;
    });

    try {
      List<Map<String, dynamic>> filteredRecipes;

      if (category == null) {
        // Show all recipes
        filteredRecipes = _allRecipes;
      } else {
        // Filter by category
        filteredRecipes = await _recipeService.getRecipesByCategory(category);
      }

      setState(() {
        _recipes = filteredRecipes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error filtering recipes: $e');
      setState(() {
        _recipes = _allRecipes; // Fallback to all recipes
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

  void _showCategoriesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoriesBottomSheet(
        selectedCategoryId: _selectedCategory,
        onCategorySelected: (category) {
          _filterByCategory(category);
        },
      ),
    );
  }

  void _showNotificationPanel() {
    final notificationService = context.read<NotificationService>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationPanel(
        notifications: notificationService.notifications,
        onNotificationTap: (notificationId) {
          notificationService.markAsRead(notificationId);
        },
        onMarkAllAsRead: () {
          notificationService.markAllAsRead();
        },
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

            // Search bar with category indicator
            _buildSearchBar(context),

            // Category indicator (if selected)
            if (_selectedCategory != null) _buildCategoryIndicator(),

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
          // Empty space to maintain spacing (where back button was)
          const SizedBox(width: 24),

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

          // Action buttons (notifications, cart, favorites, profile)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Notification bell with badge
              _buildNotificationButton(),

              // Shopping Cart button with badge
              _buildCartButton(context),

              // Favorites button
              IconButton(
                icon: const Icon(
                  Icons.bookmark_border,
                  color: Color(0xFFFF5B9E),
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed('/favorites');
                },
                tooltip: 'My Favorites',
              ),

              // Profile button
              IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () {
                  Navigator.of(context).pushNamed('/buyer-profile');
                },
                tooltip: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Consumer<NotificationService>(
      builder: (context, notificationService, child) {
        return GestureDetector(
          onTap: _showNotificationPanel,
          child: Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(right: 4),
            child: Stack(
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFFFF5B9E),
                  size: 24,
                ),
                // Notification badge
                if (notificationService.unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        notificationService.unreadCount > 99
                            ? '99+'
                            : notificationService.unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartButton(BuildContext context) {
    return Consumer<CartViewModel>(
      builder: (context, cartViewModel, child) {
        final itemCount = cartViewModel.totalItems;

        return Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.shopping_cart_outlined,
                color: Color(0xFFFF5B9E),
              ),
              onPressed: () {
                Navigator.of(context).pushNamed('/shopping-cart');
              },
              tooltip: 'Shopping Cart',
            ),

            // Badge showing item count
            if (itemCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    itemCount > 99 ? '99+' : '$itemCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
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
            // Updated menu icon - now functional!
            GestureDetector(
              onTap: _showCategoriesBottomSheet,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _selectedCategory != null
                      ? const Color(0xFFFF5B9E).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.menu,
                  color: _selectedCategory != null
                      ? const Color(0xFFFF5B9E)
                      : Colors.grey,
                ),
              ),
            ),
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

  Widget _buildCategoryIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5B9E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFF5B9E),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.filter_list,
                  size: 16,
                  color: Color(0xFFFF5B9E),
                ),
                const SizedBox(width: 6),
                Text(
                  _selectedCategory!,
                  style: const TextStyle(
                    color: Color(0xFFFF5B9E),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _filterByCategory(null),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Color(0xFFFF5B9E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_filteredRecipes.length} recipes found',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeGrid(BuildContext context) {
    final recipes = _filteredRecipes;

    if (recipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _selectedCategory != null
                  ? 'No recipes found in $_selectedCategory'
                  : 'No recipes found',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            if (_selectedCategory != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _filterByCategory(null),
                child: const Text(
                  'Show all recipes',
                  style: TextStyle(color: Color(0xFFFF5B9E)),
                ),
              ),
            ],
          ],
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

// ====================================================================
// NOTIFICATION PANEL WIDGET
// ====================================================================

class NotificationPanel extends StatelessWidget {
  final List<NotificationModel> notifications;
  final Function(String) onNotificationTap;
  final VoidCallback onMarkAllAsRead;

  const NotificationPanel({
    Key? key,
    required this.notifications,
    required this.onNotificationTap,
    required this.onMarkAllAsRead,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (unreadCount > 0)
                      Text(
                        '$unreadCount unread',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
                if (unreadCount > 0)
                  TextButton(
                    onPressed: () {
                      onMarkAllAsRead();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Mark all as read',
                      style: TextStyle(
                        color: Color(0xFFFF5B9E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(),

          // Notifications list
          Expanded(
            child: notifications.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationTile(context, notification);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, NotificationModel notification) {
    return GestureDetector(
      onTap: () {
        onNotificationTap(notification.id);
        Navigator.pop(context);

        // Navigate to order details if it's an order notification
        if (notification.orderId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening order #${notification.orderId}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : const Color(0xFFFF5B9E).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead
                ? Colors.grey.withOpacity(0.2)
                : const Color(0xFFFF5B9E).withOpacity(0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: notification.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                notification.icon,
                color: notification.color,
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF5B9E),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTimestamp(notification.timestamp),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}