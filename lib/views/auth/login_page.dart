import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../utils/app_theme.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Apply theme locally for this page
    final theme = AppTheme.getTheme();

    // Get screen size for responsive design
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    return Theme(
      data: theme,
      child: Scaffold(
        body: Consumer<AuthViewModel>(
          builder: (context, authViewModel, _) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screenSize.height),
                child: Container(
                  color: AppTheme.lightPinkColor,
                  child: Column(
                    children: [
                      // Top image section
                      Container(
                        width: double.infinity,
                        height:
                        screenSize.height * (isSmallScreen ? 0.35 : 0.4),
                        child: Stack(
                          children: [
                            // Vegetable image
                            Positioned.fill(
                              child: Image.network(
                                'https://images.unsplash.com/photo-1573246123716-6b1782bfc499?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1160&q=80',
                                fit: BoxFit.cover,
                              ),
                            ),
                            // Pink bottom curve
                            Positioned(
                              bottom: -1,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppTheme.lightPinkColor,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(40),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Logo circle with asset image
                      Transform.translate(
                        offset: const Offset(0, -40),
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

                      // Login form
                      Padding(
                        padding: EdgeInsets.fromLTRB(24, 0, 24, 20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Email field
                              Text(
                                'EMAIL',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textColor,
                                ),
                              ),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: 'hello@graduate.utm.my',
                                  errorText:
                                  _emailController.text.isEmpty &&
                                      authViewModel
                                          .errorMessage
                                          .isNotEmpty
                                      ? 'Please enter your email'
                                      : null,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: isSmallScreen ? 15 : 25),

                              // Password field
                              Text(
                                'PASSWORD',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textColor,
                                ),

                              ),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  hintText: '•••••••••',
                                  errorText:
                                  _passwordController.text.isEmpty &&
                                      authViewModel
                                          .errorMessage
                                          .isNotEmpty
                                      ? 'Please enter your password'
                                      : null,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                              ),

                              // Forgot password link
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    // Navigate to forgot password page instead of showing dialog
                                    Navigator.of(context).pushNamed('/forgot-password');
                                  },

                                  child: Text(
                                    'Forgot password',
                                    style: TextStyle(
                                      color: AppTheme.accentColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              // Error message
                              if (authViewModel.errorMessage.isNotEmpty &&
                                  _emailController.text.isNotEmpty &&
                                  _passwordController.text.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    authViewModel.errorMessage.replaceAll(
                                      'Exception: ',
                                      '',
                                    ),
                                    style: TextStyle(color: Colors.red),
                                    textAlign: TextAlign.center,
                                  ),
                                ),

                              SizedBox(height: isSmallScreen ? 15 : 25),

                              // Login button
                              Center(
                                child: SizedBox(
                                  width: 180,
                                  height: 45,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (_formKey.currentState!.validate()) {
                                        try {
                                          // Show loading spinner
                                          setState(() {
                                            _isLoading = true;
                                          });

                                          // Attempt to sign in with Firebase
                                          UserCredential userCredential =
                                          await FirebaseAuth.instance
                                              .signInWithEmailAndPassword(
                                            email:
                                            _emailController.text
                                                .trim(),
                                            password:
                                            _passwordController
                                                .text,
                                          );

                                          // Hide loading spinner
                                          setState(() {
                                            _isLoading = false;
                                          });

                                          // Check user role and navigate accordingly
                                          DocumentSnapshot userDoc =
                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(userCredential.user!.uid)
                                              .get();

                                          if (userDoc.exists) {
                                            Map<String, dynamic> userData =
                                            userDoc.data()
                                            as Map<String, dynamic>;
                                            String userRole =
                                                userData['role'] ?? 'buyer';

                                            // Navigate based on role
                                            if (userRole == 'buyer') {
                                              Navigator.pushReplacementNamed(
                                                context,
                                                '/buyer-home',
                                              );
                                            } else if (userRole == 'seller') {
                                              Navigator.pushReplacementNamed(
                                                context,
                                                '/seller-home',
                                              );
                                            }
                                          } else {
                                            // If no role is found, default to buyer
                                            Navigator.pushReplacementNamed(
                                              context,
                                              '/buyer-home',
                                            );
                                          }
                                        } on FirebaseAuthException catch (e) {
                                          // Hide loading spinner
                                          setState(() {
                                            _isLoading = false;
                                          });

                                          // Handle specific login errors
                                          String errorMessage;
                                          switch (e.code) {
                                            case 'user-not-found':
                                              errorMessage =
                                              'No user found with this email.';
                                              break;
                                            case 'wrong-password':
                                              errorMessage =
                                              'Incorrect password.';
                                              break;
                                            case 'invalid-email':
                                              errorMessage =
                                              'Invalid email address.';
                                              break;
                                            case 'user-disabled':
                                              errorMessage =
                                              'This account has been disabled.';
                                              break;
                                            default:
                                              errorMessage =
                                                  e.message ??
                                                      'An error occurred.';
                                          }

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(errorMessage),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppTheme.textColor,
                                    ),
                                    child:
                                    authViewModel.isLoading
                                        ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                        AlwaysStoppedAnimation<
                                            Color
                                        >(AppTheme.primaryColor),
                                      ),
                                    )
                                        : Text(
                                      'LOGIN',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: isSmallScreen ? 15 : 20),

                              // Register link
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account? ",
                                      style: TextStyle(
                                        color: AppTheme.textColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        // Navigate to register page
                                        Navigator.of(
                                          context,
                                        ).pushReplacementNamed('/register');
                                      },
                                      child: Text(
                                        'REGISTER HERE',
                                        style: TextStyle(
                                          color: AppTheme.accentColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showForgotPasswordDialog(
      BuildContext context,
      AuthViewModel authViewModel,
      ) {
    final TextEditingController resetEmailController = TextEditingController();
    final resetFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Reset Password'),
          content: Form(
            key: resetFormKey,
            child: TextFormField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (resetFormKey.currentState!.validate()) {
                  Navigator.pop(context);

                  // Show loading dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (context) => Center(child: CircularProgressIndicator()),
                  );

                  try {
                    await authViewModel.resetPassword(
                      resetEmailController.text.trim(),
                    );

                    // Close loading dialog
                    Navigator.pop(context);

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Password reset email sent. Check your inbox.',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    // Close loading dialog
                    Navigator.pop(context);

                    // Show error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to send reset email: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text('Send Reset Link'),
            ),
          ],
        );
      },
    );
  }
}