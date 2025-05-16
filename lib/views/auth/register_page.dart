import 'package:flutter/material.dart';

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
  final _formKey = GlobalKey<FormState>();

  // User type selection (buyer or seller)
  String _userType = 'buyer'; // Default selection

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
              // Status Bar / Top area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '17:03',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.signal_cellular_4_bar, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Icon(Icons.wifi, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Icon(Icons.battery_full, color: Colors.white, size: 16),
                      ],
                    ),
                  ],
                ),
              ),

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
                      // Logo
                      Container(
                        margin: EdgeInsets.only(top: 20),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart,
                                size: 24,
                                color: primaryColor,
                              ),
                              Text(
                                'YumCart',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cursive',
                                  color: primaryColor,
                                ),
                              ),
                            ],
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
                                    ),
                                  ],
                                ),

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
                                      obscureText: true,
                                      decoration: InputDecoration(
                                        border: UnderlineInputBorder(),
                                        contentPadding: EdgeInsets.only(bottom: 4),
                                        hintText: '•••••••••',
                                        hintStyle: TextStyle(color: Colors.grey),
                                      ),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),

                                // Register Button
                                Center(
                                  child: Container(
                                    width: 200,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (_formKey.currentState!.validate()) {
                                          // Show a snackbar
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Registration submitted!'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
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
}