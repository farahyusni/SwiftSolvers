import 'package:flutter/material.dart';
import '../views/auth/login_page.dart';
import '../views/auth/register_page.dart';
import '../views/auth/forgotpassword_page.dart';
import '../views/buyer/buyer_home_page.dart';
import '../views/buyer/buyer_profile_page.dart';  // Add this import
import '../views/buyer/edit_profile_page.dart';
import '../views/seller/seller_home_page.dart';
import '../views/buyer/recipe_detail_page.dart';
import '../views/seller/seller_profile_page.dart';  // Add this import

// Import other pages here

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Getting arguments passed in while calling Navigator.pushNamed
    final args = settings.arguments;

    switch (settings.name) {
      case '/':
      case '/login':
        return MaterialPageRoute(builder: (_) => LoginPage());
      case '/register':
        return MaterialPageRoute(builder: (_) => RegisterPage());
      case '/forgot-password': // Add this new route
        return MaterialPageRoute(builder: (_) => ForgotPasswordPage());
      case '/buyer-home':
        return MaterialPageRoute(builder: (_) => BuyerHomePage());
        case '/seller-home':
      return MaterialPageRoute(builder: (_) => SellerHomePage());
      case '/buyer-profile':  // Add this
        return MaterialPageRoute(builder: (_) => BuyerProfilePage());
         case '/seller-profile':  // Add this
        return MaterialPageRoute(builder: (_) => SellerProfilePage());
      case '/edit-profile':   // Add this
        return MaterialPageRoute(builder: (_) => EditProfilePage());
      case '/recipe-detail':
        final recipe = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => RecipeDetailPage(recipe: recipe),
        );
      // Add your other routes here
      // case '/home':
      //   return MaterialPageRoute(builder: (_) => HomePage());
      
      default:
        // If there is no such named route in the switch statement
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Error'),
        ),
        body: Center(
          child: Text('PAGE NOT FOUND'),
        ),
      );
    });
  }
}