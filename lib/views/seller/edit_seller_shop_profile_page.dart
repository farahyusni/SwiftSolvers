import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditSellerShopProfilePage extends StatefulWidget {
  final Map<String, String>? initialData;
  
  const EditSellerShopProfilePage({super.key, this.initialData});

  @override
  State<EditSellerShopProfilePage> createState() => _EditSellerShopProfilePageState();
}

class _EditSellerShopProfilePageState extends State<EditSellerShopProfilePage> {
  final _formKey = GlobalKey<FormState>();
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  // Controllers for editable fields
  late final TextEditingController _shopNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController(text: '12345678');

  @override
  void initState() {
    super.initState();
    // Initialize controllers with data from previous page or defaults
    _shopNameController = TextEditingController(
      text: widget.initialData?['shopName'] ?? 'Jaya Grocer'
    );
    _phoneController = TextEditingController(
      text: widget.initialData?['phone'] ?? '0175412365'
    );
    _addressController = TextEditingController(
      text: widget.initialData?['address'] ?? '2 Jalan Maju 3'
    );
    _emailController = TextEditingController(
      text: widget.initialData?['email'] ?? 'jgrocer@gmail.com'
    );
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Profile Picture',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _imageSourceButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () => _getImage(ImageSource.camera),
                  ),
                  _imageSourceButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () => _getImage(ImageSource.gallery),
                  ),
                  if (_profileImage != null)
                    _imageSourceButton(
                      icon: Icons.delete,
                      label: 'Remove',
                      onTap: _removeImage,
                      color: Colors.red,
                    ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _imageSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.blue,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    Navigator.pop(context);
    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  void _removeImage() {
    Navigator.pop(context);
    setState(() {
      _profileImage = null;
    });
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      // You can send these values to backend/database here
      final updatedData = {
        'shopName': _shopNameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
      };

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );

      // Go back after short delay
      Future.delayed(const Duration(milliseconds: 800), () {
        Navigator.of(context).pop(updatedData); // you may pass the data back if needed
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEECEE),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Top Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _circleIcon(Icons.chevron_left, () => Navigator.pop(context)),
                    Image.asset(
                      'images/logo.png',
                      height: 60,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.store),
                    ),
                    _circleIcon(Icons.person_outline, () {}),
                  ],
                ),

                const SizedBox(height: 20),

                // Store Logo with edit icon - Updated for Jaya Grocer with image picker
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.pink.shade100,
                        backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                        child: _profileImage == null
                            ? Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.pink.shade200,
                                ),
                                child: const Icon(
                                  Icons.store,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.pink.shade400,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 20),

                _buildTextField('Shop Name', _shopNameController),
                _buildTextField('Number Phone', _phoneController),
                _buildTextField('Address', _addressController),
                _buildTextField('Email', _emailController, keyboardType: TextInputType.emailAddress),
                _buildTextField('Password', _passwordController, obscureText: true),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFEAEA),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _saveProfile,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool obscureText = false, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.black),
        onPressed: onPressed,
      ),
    );
  }
}