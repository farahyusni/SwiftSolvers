import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/recipe_service.dart';
import '../../services/supabase_service.dart';

class EditRecipePage extends StatefulWidget {
  final Map<String, dynamic> recipe;

  const EditRecipePage({Key? key, required this.recipe}) : super(key: key);

  @override
  _EditRecipePageState createState() => _EditRecipePageState();
}

class _EditRecipePageState extends State<EditRecipePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RecipeService _recipeService = RecipeService();
  final SupabaseService _supabaseService = SupabaseService();
  final ImagePicker _imagePicker = ImagePicker();

  // Form controllers
  final _recipeNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Lists to hold ingredients and instructions
  List<Map<String, dynamic>> _ingredients = [];
  List<Map<String, dynamic>> _instructions = [];

  // Loading states
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  String? _currentImageUrl;

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
    _currentImageUrl = widget.recipe['imageUrl'];

    // Initialize ingredients
    final ingredients = widget.recipe['ingredients'] as List<dynamic>? ?? [];
    _ingredients =
        ingredients
            .map((ingredient) => Map<String, dynamic>.from(ingredient))
            .toList();

    // Initialize instructions
    final instructions = widget.recipe['instructions'] as List<dynamic>? ?? [];
    _instructions =
        instructions
            .map((instruction) => Map<String, dynamic>.from(instruction))
            .toList();

    // If this is a new recipe (empty), start with the Ingredients tab and add a sample ingredient
    final isNewRecipe =
        widget.recipe['isNewRecipe'] == true ||
        widget.recipe['id'] == null ||
        widget.recipe['id'].toString().isEmpty;

    if (isNewRecipe) {
      print('🆕 This is a new recipe, setting up defaults...');

      // Start with Photo tab (index 0) for new recipes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _tabController.animateTo(0);
        }
      });

      // Add default first ingredient if none exist
      if (_ingredients.isEmpty) {
        _ingredients.add({
          'name': '',
          'amount': '',
          'unit': '',
          'category': 'basic',
          'isOptional': false,
          'estimatedPrice': {'tesco': 0.0, 'mydin': 0.0, 'giant': 0.0},
        });
      }

      // Add default first instruction if none exist
      if (_instructions.isEmpty) {
        _instructions.add({'step': 1, 'instruction': ''});
      }
    }

    print(
      '✅ Initialized with ${_ingredients.length} ingredients and ${_instructions.length} instructions',
    );
  }

  void _showSupabaseImageGallery() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Recipe Image',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: FutureBuilder<List<Map<String, String>>>(
                    future: _supabaseService.getRecipeImages(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF5B9E),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      final images = snapshot.data ?? [];

                      if (images.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No recipe images found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          final image = images[index];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentImageUrl = image['url'];
                              });
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Image selected!'),
                                  backgroundColor: Color(0xFFFF5B9E),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      _currentImageUrl == image['url']
                                          ? const Color(0xFFFF5B9E)
                                          : Colors.grey.withOpacity(0.3),
                                  width:
                                      _currentImageUrl == image['url'] ? 3 : 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  image['url']!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Recipe Name Field
          TextFormField(
            controller: _recipeNameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
              hintText: 'Enter recipe name',
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),

          const SizedBox(height: 24),

          // Photo Display Area
          GestureDetector(
            onTap: _isUploadingImage ? null : _showImageSourceDialog,
            child: Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Stack(
                children: [
                  // Image or placeholder
                  if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        _currentImageUrl!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildImagePlaceholder();
                        },
                      ),
                    )
                  else
                    _buildImagePlaceholder(),

                  // Upload overlay when uploading
                  if (_isUploadingImage)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text(
                              'Uploading image...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Change Photo Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isUploadingImage ? null : _showImageSourceDialog,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                side: const BorderSide(color: Color(0xFFFF5B9E)),
              ),
              child: Text(
                _currentImageUrl != null && _currentImageUrl!.isNotEmpty
                    ? 'Change Display Photo'
                    : 'Add Display Photo',
                style: const TextStyle(
                  color: Color(0xFFFF5B9E),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Display Photo',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to add a photo',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.folder, color: Color(0xFFFF5B9E)),
                title: const Text('Recipe Gallery'),
                subtitle: const Text('Choose from uploaded recipe images'),
                onTap: () {
                  Navigator.pop(context);
                  _showSupabaseImageGallery();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFFFF5B9E),
                ),
                title: const Text('Device Gallery'),
                subtitle: const Text('Upload new image from device'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadRecipeImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFFFF5B9E)),
                title: const Text('Camera'),
                subtitle: const Text('Take a new photo'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadRecipeImage(ImageSource.camera);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadRecipeImage(ImageSource source) async {
    setState(() {
      _isUploadingImage = true;
    });

    try {
      // Pick image
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        final imageFile = File(image.path);

        // Upload to Supabase
        final imageUrl = await _supabaseService.uploadRecipeImage(imageFile);

        setState(() {
          _currentImageUrl = imageUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recipe image uploaded successfully!'),
            backgroundColor: Color(0xFFFF5B9E),
          ),
        );
      }
    } catch (e) {
      print('❌ Error uploading recipe image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Widget _buildIngredientsTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _ingredients.length + 1, // +1 for the header section
            itemBuilder: (context, index) {
              // First item is the recipe name and description
              if (index == 0) {
                return _buildRecipeHeaderSection();
              }
              // Rest are ingredients (adjust index by -1)
              return _buildIngredientItem(index - 1);
            },
          ),
        ),
        _buildAddIngredientButton(),
      ],
    );
  }

  Widget _buildRecipeHeaderSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          TextFormField(
            controller: _recipeNameController,
            decoration: const InputDecoration(
              labelText: 'Recipe Name *',
              border: OutlineInputBorder(),
              hintText: 'Enter recipe name',
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
              hintText: 'Enter recipe description',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5B9E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFFF5B9E).withOpacity(0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFFFF5B9E), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fill in the recipe name above, then add ingredients below',
                    style: TextStyle(fontSize: 14, color: Color(0xFFFF5B9E)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
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
              'estimatedPrice': {'tesco': 0.0, 'mydin': 0.0, 'giant': 0.0},
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
              child:
                  _isSaving
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
    print('🔍 Recipe data: ${widget.recipe}');

    // Validation
    if (_recipeNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a recipe name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one ingredient'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_instructions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one instruction'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Prepare recipe data
      Map<String, dynamic> recipeData = Map.from(widget.recipe);
      recipeData['name'] = _recipeNameController.text.trim();
      recipeData['description'] = _descriptionController.text.trim();
      recipeData['ingredients'] = _ingredients;
      recipeData['instructions'] = _instructions;
      recipeData['imageUrl'] = _currentImageUrl ?? '';

      bool success;
      String message;

      // Check if this is a new recipe
      final recipeId = widget.recipe['id']?.toString() ?? '';
      final isExplicitlyNew = widget.recipe['isNewRecipe'] == true;

      // It's new if explicitly marked as new OR if ID is empty/null
      final isNewRecipe = isExplicitlyNew || recipeId.isEmpty;

      print('🔍 Recipe ID: "$recipeId"');
      print('🔍 Is explicitly new: $isExplicitlyNew');
      print('🔍 Determined isNewRecipe: $isNewRecipe');

      if (isNewRecipe) {
        print('🆕 Creating new recipe...');

        // Clean up the data for new recipe
        recipeData.remove('isNewRecipe');
        recipeData.remove(
          'id',
        ); // Remove ID field to let Firestore generate one
        recipeData['createdAt'] = DateTime.now().toIso8601String();
        recipeData['updatedAt'] = DateTime.now().toIso8601String();

        // Create recipe and get the complete recipe data with ID
        final newRecipeData = await _recipeService.createRecipe(recipeData);
        success = newRecipeData != null;

        if (success) {
          recipeData = newRecipeData!;
          print('✅ New recipe created with ID: ${recipeData['id']}');
        }

        message =
            success
                ? 'Recipe created successfully!'
                : 'Failed to create recipe. Please try again.';
      } else {
        print('✏️ Updating existing recipe with ID: $recipeId');

        // Update existing recipe
        recipeData['id'] = recipeId; // Keep the original ID
        recipeData['updatedAt'] = DateTime.now().toIso8601String();
        recipeData.remove('isNewRecipe'); // Remove this flag

        // Update the existing recipe
        success = await _recipeService.updateRecipe(recipeId, recipeData);

        message =
            success
                ? 'Recipe updated successfully!'
                : 'Failed to update recipe. Please try again.';

        print('✏️ Update result: $success');
      }

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        if (success) {
          print('✅ Recipe operation completed successfully');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: const Color(0xFFFF5B9E),
            ),
          );

          Navigator.pop(context, recipeData); // Return updated recipe data
        } else {
          print('❌ Recipe operation failed');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
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
