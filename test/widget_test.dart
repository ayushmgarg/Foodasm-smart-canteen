import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:Foodasm/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Smart Canteen App Tests', () {
    testWidgets('App loads successfully', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const MyApp());

      // Verify app initializes
      expect(find.byType(MyApp), findsOneWidget);
    });

    testWidgets('Splash screen appears', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Wait for splash screen animations
      await tester.pump();

      // Verify splash screen shows
      expect(find.text('Smart Canteen'), findsOneWidget);
    });
  });
}