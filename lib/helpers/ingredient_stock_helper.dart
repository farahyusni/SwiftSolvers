// lib/helpers/ingredient_stock_helper.dart
import 'package:flutter/material.dart';
import '../services/stock_service.dart';

class IngredientStockHelper {
  static final StockService _stockService = StockService();

  /// Check which ingredients have available stock
  static Future<Map<String, dynamic>> checkIngredientsAvailability(
    List<dynamic> ingredients,
  ) async {
    Map<String, dynamic> availability = {
      'availableCount': 0,
      'totalCount': ingredients.length,
      'unavailableIngredients': <String>[],
      'availableIngredients': <Map<String, dynamic>>[],
      'ingredientDetails': <Map<String, dynamic>>[],
    };

    try {
      // Get all available stocks
      final stocks = await _stockService.getAllStocks();
      
      for (var ingredient in ingredients) {
        final ingredientMap = ingredient is Map<String, dynamic> ? ingredient : {};
        final linkedStockId = ingredientMap['linkedStockId'];
        
        if (linkedStockId != null && linkedStockId.toString().isNotEmpty) {
          // Find the corresponding stock
          final stock = stocks.firstWhere(
            (s) => s['id'] == linkedStockId,
            orElse: () => <String, dynamic>{},
          );
          
          if (stock.isNotEmpty) {
            final stockAmount = stock['stock'] ?? 0;
            final ingredientName = ingredientMap['name'] ?? 'Unknown';
            
            if (stockAmount > 0) {
              availability['availableCount']++;
              availability['availableIngredients'].add({
                'ingredient': ingredientMap,
                'stock': stock,
                'status': 'available',
              });
            } else {
              availability['unavailableIngredients'].add(ingredientName);
            }
            
            availability['ingredientDetails'].add({
              'ingredient': ingredientMap,
              'stock': stock,
              'isAvailable': stockAmount > 0,
              'stockAmount': stockAmount,
            });
          } else {
            // Stock item was deleted or doesn't exist
            availability['unavailableIngredients'].add(ingredientMap['name'] ?? 'Unknown');
          }
        } else {
          // Ingredient not linked to any stock
          availability['ingredientDetails'].add({
            'ingredient': ingredientMap,
            'stock': null,
            'isAvailable': false,
            'stockAmount': 0,
            'isNotLinked': true,
          });
        }
      }
      
      return availability;
    } catch (e) {
      print('❌ Error checking ingredients availability: $e');
      return availability;
    }
  }

  /// Get total estimated cost for available ingredients
  static double calculateAvailableIngredientsCost(
    Map<String, dynamic> availability,
  ) {
    double totalCost = 0.0;
    
    try {
      final availableIngredients = availability['availableIngredients'] as List<dynamic>? ?? [];
      
      for (var item in availableIngredients) {
        final stock = item['stock'] as Map<String, dynamic>? ?? {};
        final price = stock['price'] ?? 0.0;
        totalCost += price.toDouble();
      }
    } catch (e) {
      print('❌ Error calculating cost: $e');
    }
    
    return totalCost;
  }

  /// Generate shopping list for missing ingredients
  static List<Map<String, dynamic>> generateShoppingList(
    List<dynamic> ingredients,
  ) {
    List<Map<String, dynamic>> shoppingList = [];
    
    for (var ingredient in ingredients) {
      final ingredientMap = ingredient is Map<String, dynamic> ? ingredient : {};
      final linkedStockId = ingredientMap['linkedStockId'];
      
      if (linkedStockId != null && linkedStockId.toString().isNotEmpty) {
        shoppingList.add({
          'id': linkedStockId,
          'name': ingredientMap['linkedStockName'] ?? ingredientMap['name'],
          'price': ingredientMap['linkedStockPrice'] ?? 0.0,
          'unit': ingredientMap['linkedStockUnit'] ?? 'unit',
          'category': ingredientMap['linkedStockCategory'] ?? 'Others',
          'recipeAmount': '${ingredientMap['amount']} ${ingredientMap['unit']}',
          'ingredientName': ingredientMap['name'],
          'isOptional': ingredientMap['isOptional'] ?? false,
        });
      }
    }
    
    return shoppingList;
  }

  /// Check if recipe can be cooked with current stock
  static Future<Map<String, dynamic>> canCookRecipe(
    List<dynamic> ingredients,
  ) async {
    final availability = await checkIngredientsAvailability(ingredients);
    final availableCount = availability['availableCount'] as int;
    final totalCount = availability['totalCount'] as int;
    final unavailableIngredients = availability['unavailableIngredients'] as List<String>;
    
    // Check if all required (non-optional) ingredients are available
    int requiredIngredients = 0;
    int availableRequiredIngredients = 0;
    
    for (var detail in availability['ingredientDetails']) {
      final ingredient = detail['ingredient'] as Map<String, dynamic>;
      final isOptional = ingredient['isOptional'] ?? false;
      final isAvailable = detail['isAvailable'] ?? false;
      
      if (!isOptional) {
        requiredIngredients++;
        if (isAvailable) {
          availableRequiredIngredients++;
        }
      }
    }
    
    final canCook = availableRequiredIngredients == requiredIngredients;
    
    return {
      'canCook': canCook,
      'availableCount': availableCount,
      'totalCount': totalCount,
      'requiredIngredients': requiredIngredients,
      'availableRequiredIngredients': availableRequiredIngredients,
      'unavailableIngredients': unavailableIngredients,
      'availability': availability,
    };
  }
}

// Enhanced Ingredient Display Widget
class IngredientListWidget extends StatelessWidget {
  final List<dynamic> ingredients;
  final VoidCallback? onIngredientTap;

  const IngredientListWidget({
    Key? key,
    required this.ingredients,
    this.onIngredientTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ingredients',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        ...ingredients.map((ingredient) => _buildIngredientItem(context, ingredient)).toList(),
      ],
    );
  }

  Widget _buildIngredientItem(BuildContext context, dynamic ingredient) {
    final Map<String, dynamic> ingredientMap = ingredient is Map<String, dynamic> 
        ? ingredient 
        : {};

    final String name = ingredientMap['name'] ?? 'Unknown ingredient';
    final String amount = ingredientMap['amount'] ?? '';
    final String unit = ingredientMap['unit'] ?? '';
    final bool isOptional = ingredientMap['isOptional'] ?? false;
    final bool hasStockLink = ingredientMap['linkedStockId'] != null && 
                             ingredientMap['linkedStockId'].toString().isNotEmpty;

    return GestureDetector(
      onTap: hasStockLink ? () => _showStockDetails(context, ingredientMap) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasStockLink 
              ? const Color(0xFFFF5B9E).withOpacity(0.05)
              : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasStockLink 
                ? const Color(0xFFFF5B9E).withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            // Ingredient bullet point
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: hasStockLink 
                    ? const Color(0xFFFF5B9E) 
                    : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            
            // Ingredient details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$amount $unit $name',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: hasStockLink 
                                ? const Color(0xFFFF5B9E) 
                                : Colors.black,
                          ),
                        ),
                      ),
                      if (isOptional)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Optional',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  // Show stock info if linked
                  if (hasStockLink) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.inventory_2,
                          size: 14,
                          color: Color(0xFFFF5B9E),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Available in stock: ${ingredientMap['linkedStockName']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFFF5B9E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'RM${(ingredientMap['linkedStockPrice'] ?? 0).toStringAsFixed(2)} / ${ingredientMap['linkedStockUnit'] ?? 'unit'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Link indicator
            if (hasStockLink)
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Color(0xFFFF5B9E),
              ),
          ],
        ),
      ),
    );
  }

  void _showStockDetails(BuildContext context, Map<String, dynamic> ingredient) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.inventory_2,
                color: Color(0xFFFF5B9E),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Stock Details',
                  style: const TextStyle(
                    color: Color(0xFFFF5B9E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stock name
              Text(
                ingredient['linkedStockName'] ?? 'Unknown Stock',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Price
              Text(
                'Price: RM${(ingredient['linkedStockPrice'] ?? 0).toStringAsFixed(2)} / ${ingredient['linkedStockUnit'] ?? 'unit'}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFFFF5B9E),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              
              // Availability
              Text(
                'Available: ${ingredient['linkedStockAvailable'] ?? 0} ${ingredient['linkedStockUnit'] ?? 'units'}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              
              // Category
              Text(
                'Category: ${ingredient['linkedStockCategory'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              
              // Recipe requirement
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recipe Requirement:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      '${ingredient['amount']} ${ingredient['unit']} ${ingredient['name']}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Here you can add logic to add this item to cart
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${ingredient['linkedStockName']} would be added to cart',
                    ),
                    backgroundColor: const Color(0xFFFF5B9E),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5B9E),
              ),
              child: const Text(
                'Add to Cart',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Recipe Availability Widget
class RecipeAvailabilityWidget extends StatefulWidget {
  final List<dynamic> ingredients;
  final VoidCallback? onShopNow;

  const RecipeAvailabilityWidget({
    Key? key,
    required this.ingredients,
    this.onShopNow,
  }) : super(key: key);

  @override
  _RecipeAvailabilityWidgetState createState() => _RecipeAvailabilityWidgetState();
}

class _RecipeAvailabilityWidgetState extends State<RecipeAvailabilityWidget> {
  Map<String, dynamic>? _cookingStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkCookingStatus();
  }

  Future<void> _checkCookingStatus() async {
    setState(() => _isLoading = true);
    
    try {
      final status = await IngredientStockHelper.canCookRecipe(widget.ingredients);
      setState(() {
        _cookingStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Error checking cooking status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF5B9E)),
      );
    }

    if (_cookingStatus == null) {
      return const SizedBox.shrink();
    }

    final canCook = _cookingStatus!['canCook'] as bool;
    final availableCount = _cookingStatus!['availableCount'] as int;
    final totalCount = _cookingStatus!['totalCount'] as int;
    final unavailableIngredients = _cookingStatus!['unavailableIngredients'] as List<String>;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: canCook 
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canCook ? Colors.green : Colors.orange,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                canCook ? Icons.check_circle : Icons.warning,
                color: canCook ? Colors.green : Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  canCook 
                      ? 'Ready to Cook!' 
                      : 'Missing Ingredients',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: canCook ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Availability summary
          Text(
            'Available: $availableCount / $totalCount ingredients',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          if (!canCook && unavailableIngredients.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Missing: ${unavailableIngredients.join(', ')}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Action buttons
          Row(
            children: [
              if (!canCook)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showShoppingList(),
                    icon: const Icon(Icons.shopping_cart, size: 16),
                    label: const Text('Shop Missing Items'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5B9E),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              
              if (canCook)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Starting cooking mode...'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.restaurant, size: 16),
                    label: const Text('Start Cooking'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showShoppingList() {
    final shoppingList = IngredientStockHelper.generateShoppingList(widget.ingredients);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Shopping List'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: shoppingList.length,
              itemBuilder: (context, index) {
                final item = shoppingList[index];
                return ListTile(
                  leading: const Icon(
                    Icons.add_shopping_cart,
                    color: Color(0xFFFF5B9E),
                  ),
                  title: Text(item['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RM${item['price'].toStringAsFixed(2)} / ${item['unit']}'),
                      Text(
                        'Recipe needs: ${item['recipeAmount']}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  trailing: item['isOptional'] 
                      ? const Chip(
                          label: Text('Optional', style: TextStyle(fontSize: 10)),
                          backgroundColor: Colors.orange,
                          labelStyle: TextStyle(color: Colors.white),
                        )
                      : null,
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (widget.onShopNow != null) {
                  widget.onShopNow!();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5B9E),
              ),
              child: const Text(
                'Add All to Cart',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}