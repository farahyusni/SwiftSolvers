import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/stock_service.dart';
import '../../services/supabase_service.dart';

class EditStockItemPage extends StatefulWidget {
  final Map<String, dynamic> item;

  const EditStockItemPage({Key? key, required this.item}) : super(key: key);

  @override
  _EditStockItemPageState createState() => _EditStockItemPageState();
}

class _EditStockItemPageState extends State<EditStockItemPage> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseService _supabaseService = SupabaseService();
  
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController priceController;
  late TextEditingController stockController;
  late TextEditingController categoryController;
  late TextEditingController unitController;

  File? _imageFile;
  String? _currentImageUrl; // Store current image URL
  bool _isLoading = false;
  bool _isUploadingImage = false; // Separate loading state for image upload
  String _selectedCategory = 'Grains';
  int _quantity = 1;
  double _price = 0.0;

  // Predefined categories
  final List<String> _categories = [
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
    nameController = TextEditingController(text: widget.item['name'] ?? '');
    descriptionController = TextEditingController(text: widget.item['description'] ?? '');
    priceController = TextEditingController(text: widget.item['price']?.toString() ?? '');
    stockController = TextEditingController(text: widget.item['stock']?.toString() ?? '');
    categoryController = TextEditingController(text: widget.item['category'] ?? '');
    unitController = TextEditingController(text: widget.item['unit'] ?? '');
    
    // Store current image URL if exists
    _currentImageUrl = widget.item['imageUrl']?.toString();
    
    // Initialize values with validation
    String itemCategory = widget.item['category']?.toString() ?? '';
    
    // Check if the item's category exists in our predefined list (case-insensitive)
    String matchedCategory = 'Grains'; // default
    for (String category in _categories) {
      if (category.toLowerCase() == itemCategory.toLowerCase()) {
        matchedCategory = category;
        break;
      }
    }
    
    _selectedCategory = matchedCategory;
    _quantity = widget.item['stock'] ?? 1;
    _price = widget.item['price']?.toDouble() ?? 0.0;
    
    // Update controllers
    stockController.text = _quantity.toString();
    categoryController.text = _selectedCategory;
    if (_price > 0) {
      priceController.text = _price.toString();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    stockController.dispose();
    categoryController.dispose();
    unitController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      // Show dialog to choose between gallery or Supabase
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Image Source'),
          content: const Text('Choose where to get your image from:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'supabase'),
              child: const Text('From Supabase'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'gallery'),
              child: const Text('From Gallery'),
            ),
          ],
        ),
      );

      if (choice == 'gallery') {
        await _pickFromGallery();
      } else if (choice == 'supabase') {
        await _pickFromSupabase();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        
        // Immediately upload to Supabase
        await _uploadImageToSupabase();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image from gallery: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickFromSupabase() async {
    try {
      setState(() {
        _isUploadingImage = true;
      });

      // Get all stock images from Supabase
      final stockImages = await _supabaseService.getStockImages();
      
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });

        if (stockImages.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No images found in Supabase storage'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        // Show image selection dialog
        final selectedImage = await showDialog<String>(
          context: context,
          builder: (context) => _buildImageSelectionDialog(stockImages),
        );

        if (selectedImage != null && selectedImage.isNotEmpty) {
          setState(() {
            _currentImageUrl = selectedImage;
            _imageFile = null; // Clear file since we're using URL
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image selected from Supabase!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load images from Supabase: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadImageToSupabase() async {
    if (_imageFile == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      print('📸 Starting stock image upload to Supabase...');
      
      // Use the dedicated stock image upload method
      final imageUrl = await _supabaseService.uploadStockImage(_imageFile!);
      
      if (mounted) {
        setState(() {
          _currentImageUrl = imageUrl;
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Stock image upload failed: $e');
      
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
          _imageFile = null; // Reset on failure
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image upload failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildImageSelectionDialog(List<Map<String, String>> images) {
    return Dialog(
      child: Container(
        width: double.maxFinite,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select from Supabase',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final image = images[index];
                  final imageUrl = image['url'] ?? '';
                  final imageName = image['name'] ?? 'Unknown';

                  return GestureDetector(
                    onTap: () => Navigator.pop(context, imageUrl),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: Image.network(
                                imageUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFFF5B9E),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.broken_image,
                                            color: Colors.grey,
                                            size: 40,
                                          ),
                                          Text(
                                            'Failed to load',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(12),
                              ),
                            ),
                            child: Text(
                              imageName.length > 15 
                                  ? '${imageName.substring(0, 15)}...' 
                                  : imageName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[400],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _incrementQuantity() {
    setState(() {
      _quantity++;
      stockController.text = _quantity.toString();
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
        stockController.text = _quantity.toString();
      });
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid price'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if image is still uploading
    if (_isUploadingImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for image upload to complete'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedItem = {
        'name': nameController.text.trim(),
        'description': descriptionController.text.trim(),
        'price': _price,
        'stock': _quantity,
        'unit': unitController.text.trim().isEmpty ? 'piece' : unitController.text.trim(),
        'category': _selectedCategory,
        'imageUrl': _currentImageUrl ?? '', // Include image URL
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final stockService = StockService();

      if (widget.item['id'] == null || widget.item['id'].toString().isEmpty) {
        updatedItem['createdAt'] = DateTime.now().toIso8601String();
        await stockService.addStock(updatedItem);
      } else {
        await stockService.updateStock(widget.item['id'], updatedItem);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.item['id'] == null || widget.item['id'].toString().isEmpty 
                ? 'Stock item added successfully!' 
                : 'Stock item updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save item: $e'), 
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _cancel() {
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEECEE),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                widget.item['id'] == null || widget.item['id'].toString().isEmpty 
                    ? 'Add Stock Item' 
                    : 'Edit Stock Item',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8B4B5C),
                ),
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Image Section
                      _buildImageSection(),

                      const SizedBox(height: 30),

                      // Item Name Field
                      _buildTextFormField(
                        controller: nameController,
                        hintText: 'Item Name',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter item name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Description Field
                      _buildTextFormField(
                        controller: descriptionController,
                        hintText: 'Add Description (optional)',
                        maxLines: 2,
                      ),

                      const SizedBox(height: 20),

                      // Price and Stock Row
                      Row(
                        children: [
                          // Price Field
                          Expanded(child: _buildPriceField()),

                          const SizedBox(width: 16),

                          // Stock Controls
                          Expanded(child: _buildStockControl()),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Unit Field
                      _buildTextFormField(
                        controller: unitController,
                        hintText: 'Unit (e.g., kg, piece, bottle)',
                      ),

                      const SizedBox(height: 20),

                      // Category Dropdown
                      _buildCategoryDropdown(),

                      const SizedBox(height: 40),

                      // Action Buttons
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          GestureDetector(
            onTap: _cancel,
            child: Container(
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

          // Profile icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: const Icon(
              Icons.person_outline,
              size: 24,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return GestureDetector(
      onTap: _isUploadingImage ? null : _pickImage,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!, width: 2),
        ),
        child: Stack(
          children: [
            // Image display
            Center(
              child: _isUploadingImage
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFFFF5B9E)),
                        SizedBox(height: 16),
                        Text(
                          'Uploading image...',
                          style: TextStyle(
                            color: Color(0xFF8B8B8B),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  : _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(
                            _imageFile!,
                            width: 180,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        )
                      : _currentImageUrl != null && _currentImageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(
                                _currentImageUrl!,
                                width: 180,
                                height: 180,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFFF5B9E),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 120,
                                    height: 160,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.grey[200],
                                    ),
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Failed to load',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            )
                          : Container(
                              width: 120,
                              height: 160,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[200],
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tap to add image',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
            ),

            // Edit button (only show if not uploading)
            if (!_isUploadingImage)
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5B9E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildPriceField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: priceController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ],
        decoration: const InputDecoration(
          hintText: 'Price',
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        onChanged: (value) {
          setState(() {
            _price = double.tryParse(value) ?? 0.0;
          });
        },
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Enter price';
          }
          final price = double.tryParse(value);
          if (price == null || price <= 0) {
            return 'Enter valid price';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildStockControl() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Decrease Button
          GestureDetector(
            onTap: _decrementQuantity,
            child: const Icon(Icons.remove, color: Colors.grey, size: 20),
          ),
          const SizedBox(width: 8),

          // Stock Input Field
          Expanded(
            child: TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                hintText: 'Stock',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              onChanged: (value) {
                final parsed = int.tryParse(value);
                if (parsed != null && parsed >= 0) {
                  setState(() {
                    _quantity = parsed;
                  });
                }
              },
            ),
          ),

          const SizedBox(width: 8),
          // Increase Button
          GestureDetector(
            onTap: _incrementQuantity,
            child: const Icon(Icons.add, color: Colors.grey, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedCategory,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        items: _categories.map((String category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Text(category),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedCategory = newValue;
              categoryController.text = _selectedCategory;
            });
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a category';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _cancel,
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveItem,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4B5C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
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
          _buildBottomNavItem(Icons.home_outlined, 'Home', false),
          _buildBottomNavItem(Icons.shopping_bag_outlined, 'Orders', false),
          _buildBottomNavItem(Icons.inventory_2, 'Stocks', true),
          _buildBottomNavItem(Icons.receipt_outlined, 'Recipe', false),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, bool isSelected) {
    return Column(
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
    );
  }
}