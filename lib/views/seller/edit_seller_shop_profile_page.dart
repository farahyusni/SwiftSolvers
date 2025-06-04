import 'package:flutter/material.dart';

class EditSellerShopProfilePage extends StatefulWidget {
  const EditSellerShopProfilePage({super.key});

  @override
  State<EditSellerShopProfilePage> createState() => _EditSellerShopProfilePageState();
}

class _EditSellerShopProfilePageState extends State<EditSellerShopProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for editable fields
  final _shopNameController = TextEditingController(text: 'Segi Fresh Bagan Serai');
  final _phoneController = TextEditingController(text: '+60124388744');
  final _addressController = TextEditingController(
    text: 'No. 40-G, 42-G & 44-G, Jalan Syed Thaupy 2, Pusat Bandar Baru, 34300 Bagan Serai, Perak',
  );
  final _emailController = TextEditingController(text: 'segifreshbs@gmail.com');
  final _passwordController = TextEditingController(text: '12345678');

  @override
  void dispose() {
    _shopNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

                // Store Logo with edit icon
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    const CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.green,
                      child: Text('Segi\nfresh',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.yellow, fontSize: 22, fontWeight: FontWeight.bold)),
                    ),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 14,
                        child: Icon(Icons.edit, size: 18),
                      ),
                    ),
                  ],
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
