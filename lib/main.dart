import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/cart_viewmodel.dart';
import 'services/notification_service.dart'; // Add this import
import 'utils/route_generator.dart';
import 'services/navigation_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://qyelneymcdjuocataqtj.supabase.co', // Replace with your actual Supabase URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF5ZWxuZXltY2RqdW9jYXRhcXRqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgyMzM4MDAsImV4cCI6MjA2MzgwOTgwMH0.X13Bj9OpluBV_BUE-noyLVYx7g1GA4tyrFm37jRNDMU', // Replace with your actual Supabase anon key
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => CartViewModel()),
        // Add the notification service provider
        ChangeNotifierProvider(create: (_) => NotificationService()),

        // Add other providers here
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'YumCart',
        navigatorKey: NavigationService.navigatorKey,
        onGenerateRoute: RouteGenerator.generateRoute,
        initialRoute: '/login',
        theme: ThemeData(
          primarySwatch: Colors.pink,
          primaryColor: const Color(0xFFFF5B9E),
          // Add consistent theming for notifications
          snackBarTheme: const SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
      ),
    );
  }
}