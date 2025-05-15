// lib/test_app.dart
import 'package:flutter/material.dart';

void main() {
  runApp(TestApp());
}

class TestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Image Test')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'images/yumcart_logo.jpg',
                width: 200,
                height: 200,
              ),
              SizedBox(height: 20),
              Text('If you can see the image above, it worked!'),
            ],
          ),
        ),
      ),
    );
  }
}