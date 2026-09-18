// Basic Flutter widget test for GrindFit.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

const MethodChannel _firebaseCoreChannel =
    MethodChannel('plugins.flutter.io/firebase_core');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_firebaseCoreChannel, (MethodCall call) async {
      switch (call.method) {
        case 'Firebase#initializeCore':
          return [
            {
              'name': '[DEFAULT]',
              'options': {
                'apiKey': 'fake-api-key',
                'appId': '1:1234567890:android:abcdef',
                'messagingSenderId': '1234567890',
                'projectId': 'grindfit-test',
              },
              'pluginConstants': {},
            },
          ];
        case 'Firebase#initializeApp':
          return {
            'name': (call.arguments as Map)['appName'],
            'options': (call.arguments as Map)['options'],
            'pluginConstants': {},
          };
        default:
          return null;
      }
    });

    await Firebase.initializeApp();
  });

  testWidgets('GrindFit app builds and renders splash screen logo',
      (WidgetTester tester) async {
    // Render the GrindFit main app
    await tester.pumpWidget(const GrindFitApp());
    await tester.pump();

    // Verifies that the GrindFit logo image is present on the splash screen
    expect(find.byType(Image), findsOneWidget);
  });
}