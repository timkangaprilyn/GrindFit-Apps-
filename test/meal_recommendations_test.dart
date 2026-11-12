import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/models/meal_recommendation.dart';
import 'package:flutter_application_1/services/meal_preferences_store.dart';
import 'package:flutter_application_1/screens/meal_recommendations_screen.dart';
import 'package:flutter_application_1/theme/grindfit_theme.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('every meal slot has a matching default option', () {
    for (final slot in MealSlot.values) {
      final matches = MealCatalog.matching(const MealPreferences(), slot: slot);
      expect(matches, isNotEmpty);
      expect(
        matches.every((m) => m.slots.contains(slot) && m.pesos <= 75),
        true,
      );
    }
  });
  test('all alternatives honor diet, budget and exclusions', () {
    final preferences = MealPreferences(
      budget: 50,
      plantOnly: true,
      excluded: {'soy', 'peanut', 'wheat', 'egg', 'fish', 'milk'},
    );
    for (final slot in MealSlot.values) {
      final meals = MealCatalog.matching(preferences, slot: slot);
      expect(meals, isNotEmpty);
      expect(
        meals.every(
          (m) =>
              m.plantBased &&
              m.pesos <= 50 &&
              !m.exclusions.any(preferences.excluded.contains),
        ),
        true,
      );
    }
    expect(
      MealCatalog.matching(
        const MealPreferences(budget: 30),
        slot: MealSlot.dinner,
      ),
      isEmpty,
    );
  });
  test('ingredient exclusions include packaged bread uncertainty', () {
    for (final tag in MealPreferences.exclusionOptions) {
      final meals = MealCatalog.matching(
        MealPreferences(budget: 150, excluded: {tag}),
      );
      expect(meals.every((m) => !m.exclusions.contains(tag)), true);
    }
  });
  test(
    'local filters and favorites survive restart and are account scoped',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final store = MealPreferencesStore(
        ownerUid: null,
        preferences: prefs,
        currentUid: () => null,
      );
      await store.initialize();
      await store.update(
        MealPreferences(
          budget: 50,
          plantOnly: true,
          excluded: {'soy'},
          favorites: {'monggo-bowl'},
        ),
      );
      store.dispose();
      final restored = MealPreferencesStore(
        ownerUid: null,
        preferences: prefs,
        currentUid: () => null,
      );
      await restored.initialize();
      expect(restored.value.budget, 50);
      expect(restored.value.favorites, {'monggo-bowl'});
      expect(restored.pending, true);
      restored.dispose();
      final other = MealPreferencesStore(
        ownerUid: 'another-account',
        preferences: prefs,
        currentUid: () => null,
      );
      await other.initialize();
      expect(other.value.favorites, isEmpty);
      expect(other.value.budget, 75);
      other.dispose();
    },
  );
  test(
    'Supabase restores preferences and confirms authenticated saves',
    () async {
      final requests = <String>[];
      final store = MealPreferencesStore(
        ownerUid: 'member-a',
        currentUid: () => 'member-a',
        token: () async => 'firebase-token',
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer firebase-token');
          expect(request.url.path, '/functions/v1/meal-preferences');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          requests.add(body['action'] as String);
          return body['action'] == 'read'
              ? http.Response(
                  jsonEncode({
                    'preferences': const MealPreferences(budget: 90).toJson(),
                  }),
                  200,
                )
              : http.Response('{"updated_at":"2026-11-09T12:00:00Z"}', 200);
        }),
      );
      await store.initialize();
      expect(store.value.budget, 90);
      await store.update(store.value.copyWith(budget: 100));
      await store.sync();
      expect(store.pending, false);
      expect(requests, ['read', 'save']);
      store.dispose();
    },
  );
  test(
    'failed cloud save stays pending; account changes stop requests',
    () async {
      String? uid = 'member-a';
      var requests = 0;
      final store = MealPreferencesStore(
        ownerUid: uid,
        currentUid: () => uid,
        token: () async => 'token',
        client: MockClient((_) async {
          requests++;
          return http.Response('{}', 404);
        }),
      );
      await store.initialize();
      await store.update(store.value.copyWith(budget: 50));
      await store.sync();
      expect(store.pending, true);
      expect(store.status, contains('cloud sync unavailable'));
      uid = 'member-b';
      final before = requests;
      await store.sync();
      expect(requests, before);
      store.dispose();
    },
  );
  test(
    'newer edits are retained when an older cloud write completes',
    () async {
      final response = Completer<http.Response>();
      final store = MealPreferencesStore(
        ownerUid: 'a',
        currentUid: () => 'a',
        token: () async => 'token',
        client: MockClient((request) async {
          if (jsonDecode(request.body)['action'] == 'read') {
            return http.Response('{"preferences":null}', 200);
          }
          return response.future;
        }),
      );
      await store.initialize();
      await store.update(store.value.copyWith(budget: 40));
      final sync = store.sync();
      await Future<void>.delayed(Duration.zero);
      await store.update(store.value.copyWith(budget: 65));
      response.complete(
        http.Response('{"updated_at":"2026-11-09T12:00:00Z"}', 200),
      );
      await sync;
      expect(store.value.budget, 65);
      expect(store.pending, true);
      store.dispose();
    },
  );
  testWidgets(
    'meal screen supports swap, favorites and filters on a narrow screen',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = MealPreferencesStore(
        ownerUid: null,
        currentUid: () => null,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: GrindFitTheme.dark,
          home: MealRecommendationsScreen(store: store),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Meal Plan'), findsOneWidget);
      // The meal cards sit below the target and budget cards, so scroll
      // until the list has built the first one.
      for (
        var i = 0;
        i < 10 && find.byTooltip('Save favorite').evaluate().isEmpty;
        i++
      ) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -200));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.byTooltip('Save favorite').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Save favorite').first);
      await tester.pumpAndSettle();
      expect(store.value.favorites.length, 1);
      final originalMeal = MealCatalog.meals
          .firstWhere((m) => m.id == store.value.favorites.first)
          .name;
      await tester.ensureVisible(find.text('Swap meal').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Swap meal').first);
      await tester.pumpAndSettle();
      expect(find.text(originalMeal), findsNothing);
      await tester.drag(find.byType(ListView).first, const Offset(0, 1200));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Favorites (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Favorites (1)'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('SAVED MEAL'), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, 1200));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      // The sheet title matches the row label behind it.
      expect(find.text('Apply preferences'), findsOneWidget);
      await tester.tap(find.text('Plant-based only'));
      await tester.tap(find.text('Apply preferences'));
      await tester.pumpAndSettle();
      expect(store.value.plantOnly, true);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );
}
