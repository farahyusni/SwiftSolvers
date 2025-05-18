import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Register Page',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: RegisterPage(),
    );
  }
}

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Focus Nodes - Add these
  final FocusNode _fullNameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // User type selection (buyer or seller)
  String _userType = 'buyer'; // Default selection

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();

    // Dispose focus nodes
    _fullNameFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();

    super.dispose();
  }

  // Add this helper method to handle field validation and focus transition
  void _fieldFocusChange(
      BuildContext context, FocusNode currentFocus, FocusNode nextFocus) {
    currentFocus.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }
  void _navigateToSellerRegistration() {
    // Demo function to navigate to seller registration
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigating to seller registration...'),
        backgroundColor: Color(0xFFD8789E),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Colors
    final primaryColor = Color(0xFFD8789E);
    final lightPinkColor = Color(0xFFFCE4EC);
    final textColor = Colors.black87;

    // Get screen size for responsive design
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          image: DecorationImage(
            image: NetworkImage(
              'https://images.unsplash.com/photo-1606787366850-de6330128bfc?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1160&q=80',
            ),
            fit: BoxFit.cover,
            opacity: 0.6,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              // Main Content
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: lightPinkColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      // Logo circle with asset image
                      Transform.translate(
                        offset: const Offset(0, 10),
                        child: Container(
                          width: 80, // Keep original circle size
                          height: 80, // Keep original circle size
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Transform.scale(
                              scale: 1.5, // Scale up the logo by 50%
                              child: Padding(
                                padding: const EdgeInsets.all(0), // No padding
                                child: Image.asset(
                                  'images/logo.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),


                      // Form
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Register as
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'REGISTER AS',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Radio<String>(
                                                  value: 'buyer',
                                                  groupValue: _userType,
                                                  activeColor: primaryColor,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _userType = value!;
                                                    });
                                                  },
                                                ),
                                                Text(
                                                  'Buyer',
                                                  style: TextStyle(
                                                    color: textColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Radio<String>(
                                                  value: 'seller',
                                                  groupValue: _userType,
                                                  activeColor: primaryColor,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _userType = value!;
                                                    });
                                                    _navigateToSellerRegistration();
                                                  },
                                                ),
                                                Text(
                                                  'Seller',
                                                  style: TextStyle(
                                                    color: textColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // Full Name
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'FULL NAME',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    TextFormField(
                                      controller: _fullNameController,
                                      decoration: InputDecoration(
                                        border: UnderlineInputBorder(),
                                        contentPadding: EdgeInsets.only(bottom: 4),
                                        hintText: 'John Doe',
                                        hintStyle: TextStyle(color: Colors.grey),
                                      ),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),

                                // Phone
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'NUMBER PHONE',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      decoration: InputDecoration(
                                        border: UnderlineInputBorder(),
                                        contentPadding: EdgeInsets.only(bottom: 4),
                                        hintText: '+60 12 345 6789',
                                        hintStyle: TextStyle(color: Colors.grey),
                                      ),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),

                                // Address
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ADDRESS',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    TextFormField(
                                      controller: _addressController,
                                      decoration: InputDecoration(
                                        border: UnderlineInputBorder(),
                                        contentPadding: EdgeInsets.only(bottom: 4),
                                        hintText: 'Lot #15, KG Sungai Baru',
                                        hintStyle: TextStyle(color: Colors.grey),
                                      ),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),

                                // Email
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'EMAIL',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    TextFormField(
                                      controller: _emailController,
                                      focusNode: _emailFocus,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: InputDecoration(
                                        border: UnderlineInputBorder(),
                                        contentPadding: EdgeInsets.only(bottom: 4),
                                        hintText: 'hello@example.com',
                                        hintStyle: TextStyle(color: Colors.grey),
                                      ),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: textColor,
                                      ),
                                      // Enable auto-validation
                                      autovalidateMode: AutovalidateMode.onUserInteraction,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!value.contains('@') || !value.contains('.')) {
                                          return 'Please enter a valid email address';
                                        }
                                        return null;
                                      },
                                      onEditingComplete: () {
                                        // Validate the field
                                        if (_emailController.text.isNotEmpty &&
                                            _emailController.text.contains('@') &&
                                            _emailController.text.contains('.')) {
                                          _fieldFocusChange(context, _emailFocus, _passwordFocus);
                                        }
                                        // Otherwise, keep focus on this field
                                      },
                                    ),
                                  ],
                                ),

                                // Password
                                // Password
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'PASSWORD',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    TextFormField(
                                      controller: _passwordController,
                                      focusNode: _passwordFocus,
                                      obscureText: _obscurePassword,
                                      decoration: InputDecoration(
                                        border: UnderlineInputBorder(),
                                        contentPadding: EdgeInsets.only(bottom: 4),
                                        hintText: '•••••••••',
                                        hintStyle: TextStyle(color: Colors.grey),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword = !_obscurePassword;
                                            });
                                          },
                                        ),
                                      ),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: textColor,
                                      ),
                                      // Enable auto-validation
                                      autovalidateMode: AutovalidateMode.onUserInteraction,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter a password';
                                        }
                                        // Check length
                                        if (value.length < 8) {
                                          return 'Password must be at least 8 characters';
                                        }
                                        // Check for uppercase
                                        if (!value.contains(RegExp(r'[A-Z]'))) {
                                          return 'Password must contain at least one uppercase letter';
                                        }
                                        // Check for lowercase
                                        if (!value.contains(RegExp(r'[a-z]'))) {
                                          return 'Password must contain at least one lowercase letter';
                                        }
                                        // Check for digits
                                        if (!value.contains(RegExp(r'[0-9]'))) {
                                          return 'Password must contain at least one number';
                                        }
                                        return null;
                                      },
                                      onEditingComplete: () {
                                        // Implement comprehensive password validation
                                        bool isValid = _passwordController.text.length >= 8 &&
                                            _passwordController.text.contains(RegExp(r'[A-Z]')) &&
                                            _passwordController.text.contains(RegExp(r'[a-z]')) &&
                                            _passwordController.text.contains(RegExp(r'[0-9]'));

                                        if (isValid) {
                                          _fieldFocusChange(context, _passwordFocus, _confirmPasswordFocus);
                                        }
                                        // Otherwise, keep focus on this field
                                      },
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CONFIRM PASSWORD',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    TextFormField(
                                      controller: _confirmPasswordController,
                                      obscureText: _obscureConfirmPassword,
                                      decoration: InputDecoration(
                                        border: UnderlineInputBorder(),
                                        contentPadding: EdgeInsets.only(bottom: 4),
                                        hintText: '•••••••••',
                                        hintStyle: TextStyle(color: Colors.grey),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscureConfirmPassword = !_obscureConfirmPassword;
                                            });
                                          },
                                        ),
                                      ),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: textColor,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please confirm your password';
                                        }
                                        if (value != _passwordController.text) {
                                          return 'Passwords do not match';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),

                                // Register Button
                                Center(
                                  child: Container(
                                    width: 200,
                                    child: ElevatedButton(onPressed: () async {
                                      if (_formKey.currentState!.validate()) {
                                        try {
                                          // Show loading
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (context) => Center(child: CircularProgressIndicator()),
                                          );

                                          // Create user with email/password
                                          final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                                            email: _emailController.text.trim(),
                                            password: _passwordController.text,
                                          );

                                          // Store additional user data
                                          await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
                                            'fullName': _fullNameController.text,
                                            'phone': _phoneController.text,
                                            'address': _addressController.text,
                                            'email': _emailController.text,
                                            'userType': _userType,
                                            'createdAt': FieldValue.serverTimestamp(),
                                          });

                                          // Close loading dialog
                                          Navigator.of(context).pop();

                                          // Show success
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Registration successful!'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );

                                          // Navigate to home or login page
                                          // Navigator.of(context).pushReplacementNamed('/home');

                                        } catch (e) {
                                          // Close loading dialog
                                          Navigator.of(context).pop();

                                          // Show error
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Error: ${e.toString()}'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: textColor,
                                        elevation: 0,
                                        padding: EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                      child: Text(
                                        'REGISTER',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Login Link
                                Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Already have an account? ",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textColor,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).pushReplacementNamed('/login');
                                        },
                                        child: Text(
                                          'LOGIN HERE',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
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
    );
  }
  @override
  void initState() {
    super.initState();
    // Set initial focus to first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_fullNameFocus);
    });
  }
}