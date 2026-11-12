import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/meal_recommendations_screen.dart';
import 'package:flutter_application_1/services/meal_preferences_store.dart';
import 'package:flutter_application_1/theme/grindfit_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<int?> openAndSave(WidgetTester tester, {String? type}) async {
    int? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  result = await showMealBudgetSheet(context, 250);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    if (type != null) await tester.enterText(find.byType(TextField), type);
    await tester.tap(find.text('Save budget'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('saving the budget closes the sheet without errors', (
    tester,
  ) async {
    final value = await openAndSave(tester, type: '300');
    expect(tester.takeException(), isNull);
    expect(value, 300);
    expect(find.text('Save budget'), findsNothing);
  });

  testWidgets('editing the budget on the Meal Plan screen does not crash', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = MealPreferencesStore(ownerUid: null, currentUid: () => null);
    await tester.pumpWidget(
      MaterialApp(
        theme: GrindFitTheme.dark,
        home: MealRecommendationsScreen(store: store),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '300');
    await tester.tap(find.text('Save budget'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Save budget'), findsNothing);
    expect(find.textContaining('of ₱300'), findsOneWidget);
    store.dispose();
  });

  testWidgets('a preset chip can be saved', (tester) async {
    int? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  result = await showMealBudgetSheet(context, 250),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ActionChip).last);
    await tester.pump();
    await tester.tap(find.text('Save budget'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(result, isNotNull);
  });
}
