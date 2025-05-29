import 'package:flutter/material.dart';

void main() {
  runApp(NavigationTestApp());
}

class NavigationTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NavigationTestPage(),
    );
  }
}

class NavigationTestPage extends StatefulWidget {
  @override
  _NavigationTestPageState createState() => _NavigationTestPageState();
}

class _NavigationTestPageState extends State<NavigationTestPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEECEE),
      body: Center(
        child: Text(
          'Navigation Test - Look at the bottom!',
          style: TextStyle(fontSize: 24),
        ),
      ),
      bottomNavigationBar: Container(
        height: 80,
        color: Colors.red, // Bright red so you can definitely see it
        child: Center(
          child: Text(
            'NAVIGATION BAR HERE!',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      ),
    );
  }
}