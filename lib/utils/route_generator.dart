import 'package:flutter/material.dart';
import '../views/auth/login_page.dart';
import '../views/auth/register_page.dart';
import '../views/auth/forgotpassword_page.dart';
import '../views/buyer/buyer_home_page.dart';
import '../views/buyer/buyer_profile_page.dart';
import '../views/buyer/edit_profile_page.dart';
import '../views/buyer/favorites_page.dart';  // Add this import
import '../views/seller/seller_home_page.dart';
import '../views/buyer/recipe_detail_page.dart';
import '../views/seller/seller_profile_page.dart';

// Import other pages here

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Getting arguments passed in while calling Navigator.pushNamed


    switch (settings.name) {
      case '/':
      case '/login':
        return MaterialPageRoute(builder: (_) => LoginPage());
      case '/register':
        return MaterialPageRoute(builder: (_) => RegisterPage());
      case '/forgot-password':
        return MaterialPageRoute(builder: (_) => ForgotPasswordPage());
      case '/buyer-home':
        return MaterialPageRoute(builder: (_) => BuyerHomePage());
      case '/seller-home':
        return MaterialPageRoute(builder: (_) => SellerHomePage());
      case '/buyer-profile':
        return MaterialPageRoute(builder: (_) => BuyerProfilePage());
      case '/seller-profile':
        return MaterialPageRoute(builder: (_) => SellerProfilePage());
      case '/edit-profile':
        return MaterialPageRoute(builder: (_) => EditProfilePage());
      case '/favorites':  // Add this new route for favorites
        return MaterialPageRoute(builder: (_) => const FavoritesPage());
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
          title: const Text('Error'),
        ),
        body: const Center(
          child: Text('PAGE NOT FOUND'),
        ),
      );
    });
  }
}