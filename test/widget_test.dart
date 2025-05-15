import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yum_cart/main.dart';
import 'package:yum_cart/viewmodels/auth_viewmodel.dart';

void main() {
  testWidgets('Login page smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ],
        child: MyApp(),
      ),
    );

    // Verify that we have a login page
    expect(find.text('YumCart'), findsOneWidget);
    expect(find.text('Login to Your Account'), findsOneWidget);
    
    // Test can be expanded with more specific checks for your login page
  });
}