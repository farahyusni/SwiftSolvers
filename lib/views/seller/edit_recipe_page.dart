import 'package:flutter/material.dart';
import '../../services/recipe_service.dart';

class EditRecipePage extends StatefulWidget {
  final Map<String, dynamic> recipe;

  const EditRecipePage({Key? key, required this.recipe}) : super(key: key);

  @override
  _EditRecipePageState createState() => _EditRecipePageState();
}

class _EditRecipePageState extends State<EditRecipePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RecipeService _recipeService = RecipeService();
  
  // Form controllers
  final _recipeNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Lists to hold ingredients and instructions
  List<Map<String, dynamic>> _ingredients = [];
  List<Map<String, dynamic>> _instructions = [];
  
  // Loading states
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _recipeNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initializeData() {
    print('🔄 Initializing edit recipe data...');
    
    // Initialize basic recipe info
    _recipeNameController.text = widget.recipe['name'] ?? '';
    _descriptionController.text = widget.recipe['description'] ?? '';
    
    // Initialize ingredients
    final ingredients = widget.recipe['ingredients'] as List<dynamic>? ?? [];
    _ingredients = ingredients.map((ingredient) => Map<String, dynamic>.from(ingredient)).toList();
    
    // Initialize instructions
    final instructions = widget.recipe['instructions'] as List<dynamic>? ?? [];
    _instructions = instructions.map((instruction) => Map<String, dynamic>.from(instruction)).toList();
    
    print('✅ Initialized with ${_ingredients.length} ingredients and ${_instructions.length} instructions');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEECEE),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPhotoTab(),
                  _buildIngredientsTab(),
                  _buildInstructionsTab(),
                ],
              ),
            ),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: const Icon(Icons.chevron_left, color: Colors.black),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Edit Recipe',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
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
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: const Icon(Icons.person_outline, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: const Color(0xFFFF5B9E),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'Photo'),
          Tab(text: 'Ingredients'),
          Tab(text: 'Instructions'),
        ],
      ),
    );
  }

  Widget _buildPhotoTab() {
    return const Center(
      child: Text(
        'Photo editing will be implemented later with Supabase',
        style: TextStyle(
          fontSize: 16,
          color: Color(0xFF8B8B8B),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildIngredientsTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _ingredients.length,
            itemBuilder: (context, index) {
              return _buildIngredientItem(index);
            },
          ),
        ),
        _buildAddIngredientButton(),
      ],
    );
  }

  Widget _buildIngredientItem(int index) {
    final ingredient = _ingredients[index];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: ingredient['name'] ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Ingredient Name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _ingredients[index]['name'] = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: ingredient['amount'] ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _ingredients[index]['amount'] = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: ingredient['unit'] ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _ingredients[index]['unit'] = value;
                    });
                  },
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _ingredients.removeAt(index);
                  });
                },
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddIngredientButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _ingredients.add({
              'name': '',
              'amount': '',
              'unit': '',
              'category': 'basic',
              'isOptional': false,
              'estimatedPrice': {
                'tesco': 0.0,
                'mydin': 0.0,
                'giant': 0.0,
              }
            });
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Ingredient'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF5B9E),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionsTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _instructions.length,
            itemBuilder: (context, index) {
              return _buildInstructionItem(index);
            },
          ),
        ),
        _buildAddInstructionButton(),
      ],
    );
  }

  Widget _buildInstructionItem(int index) {
    final instruction = _instructions[index];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Color(0xFFFF5B9E),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              initialValue: instruction['instruction'] ?? '',
              decoration: const InputDecoration(
                labelText: 'Instruction',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 3,
              onChanged: (value) {
                setState(() {
                  _instructions[index]['instruction'] = value;
                  _instructions[index]['step'] = index + 1;
                });
              },
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _instructions.removeAt(index);
                // Reorder step numbers
                for (int i = 0; i < _instructions.length; i++) {
                  _instructions[i]['step'] = i + 1;
                }
              });
            },
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildAddInstructionButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _instructions.add({
              'step': _instructions.length + 1,
              'instruction': '',
            });
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Instruction'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF5B9E),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isSaving ? null : _cancelEdit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[400],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveRecipe,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5B9E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _cancelEdit() {
    Navigator.pop(context);
  }

  Future<void> _saveRecipe() async {
    print('💾 Starting to save recipe...');
    
    setState(() {
      _isSaving = true;
    });

    try {
      // Prepare updated recipe data
      Map<String, dynamic> updatedRecipe = Map.from(widget.recipe);
      updatedRecipe['name'] = _recipeNameController.text.trim();
      updatedRecipe['description'] = _descriptionController.text.trim();
      updatedRecipe['ingredients'] = _ingredients;
      updatedRecipe['instructions'] = _instructions;
      updatedRecipe['updatedAt'] = DateTime.now().toIso8601String();

      // Update in database
      final success = await _recipeService.updateRecipe(
        widget.recipe['id'],
        updatedRecipe,
      );

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        if (success) {
          print('✅ Recipe updated successfully');
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recipe updated successfully!'),
              backgroundColor: Color(0xFFFF5B9E),
            ),
          );
          
          Navigator.pop(context, updatedRecipe); // Return updated data
        } else {
          print('❌ Failed to update recipe');
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update recipe. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error saving recipe: $e');
      
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while saving. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}