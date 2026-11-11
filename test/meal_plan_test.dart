import 'package:flutter_application_1/models/meal_plan.dart';
import 'package:flutter_application_1/models/meal_recommendation.dart';
import 'package:flutter_test/flutter_test.dart';

NutritionTarget _target(String goal) => MealPlanner.target(
  goal: goal,
  weightKg: 70,
  heightCm: 170,
  age: 25,
  gender: 'Male',
  daysPerWeek: 3,
);

const _goals = [
  'Weight Loss',
  'Muscle Gain / Strength',
  'Endurance / Cardio',
  'General Fitness',
];

void main() {
  final date = DateTime(2026, 11, 11);

  test('each goal gets its own calorie and protein target', () {
    final loss = _target('Weight Loss');
    final gain = _target('Muscle Gain / Strength');
    final general = _target('General Fitness');
    final endurance = _target('Endurance / Cardio');
    expect(loss.kcal, lessThan(general.kcal));
    expect(gain.kcal, greaterThan(general.kcal));
    expect(endurance.carbs, greaterThan(general.carbs));
    expect(loss.protein, 126);
    expect(general.protein, 84);
    expect(loss.kcal, greaterThanOrEqualTo(1200));
  });

  test('a normal budget gives a full day close to the target', () {
    for (final goal in _goals) {
      final target = _target(goal);
      final plan = MealPlanner.plan(target: target, budget: 300, date: date);
      expect(plan.meals.map((m) => m.slot), MealSlot.values, reason: goal);
      expect(plan.cost, lessThanOrEqualTo(300), reason: goal);
      expect(plan.kcal / target.kcal, inInclusiveRange(0.8, 1.2), reason: goal);
      expect(
        plan.meals.expand((m) => m.foods).every((f) => f.grams > 0),
        isTrue,
      );
      // ignore: avoid_print
      print(
        '$goal ${target.kcal}kcal/${target.protein}g -> '
        '${plan.kcal.round()}kcal ${plan.protein.round()}g P ₱${plan.cost.round()}\n'
        '${plan.meals.map((m) => '  ${m.slot.label}: ${m.recipe.name} — ${m.foods.map((f) => '${f.food.name} ${f.amount}').join(', ')}').join('\n')}',
      );
    }
  });

  test('a smaller budget still fits by choosing cheaper food', () {
    final target = _target('Muscle Gain / Strength');
    final plan = MealPlanner.plan(target: target, budget: 150, date: date);
    expect(plan.cost, lessThanOrEqualTo(150));
    expect(plan.budgetTooLow, isFalse);
  });

  test('a budget below the cheapest day is flagged but still planned', () {
    final plan = MealPlanner.plan(
      target: _target('Weight Loss'),
      budget: MealPlanner.minBudget,
      date: date,
    );
    expect(plan.meals, hasLength(4));
    expect(plan.budgetTooLow, isTrue);
    expect(plan.cost, closeTo(plan.cheapestCost, 0.01));
  });

  test('exclusions and plant-based filters are respected', () {
    final noEggFish = MealPlanner.plan(
      target: _target('General Fitness'),
      budget: 400,
      prefs: const MealPreferences(excluded: {'egg', 'fish'}),
      date: date,
    );
    final ids = noEggFish.meals.expand((m) => m.foods).map((f) => f.food.id);
    expect(ids, isNot(contains('egg')));
    expect(ids, isNot(contains('tilapia')));
    expect(ids, isNot(contains('sardines')));

    final plant = MealPlanner.plan(
      target: _target('General Fitness'),
      budget: 400,
      prefs: const MealPreferences(plantOnly: true),
      date: date,
    );
    expect(plant.meals.every((m) => m.recipe.plantBased), isTrue);
  });

  test('the same day gives the same plan and swaps are kept', () {
    final target = _target('Endurance / Cardio');
    final a = MealPlanner.plan(target: target, budget: 250, date: date);
    final b = MealPlanner.plan(target: target, budget: 250, date: date);
    expect(a.meals.map((m) => m.recipe.id), b.meals.map((m) => m.recipe.id));
    final lunch = MealPlanner.swapOptions(
      const MealPreferences(),
      MealSlot.lunch,
      a,
    ).firstWhere((r) => r.id != a.mealFor(MealSlot.lunch)!.recipe.id);
    final swapped = MealPlanner.plan(
      target: target,
      budget: 250,
      date: date,
      chosen: {MealSlot.lunch: lunch.id},
    );
    expect(swapped.mealFor(MealSlot.lunch)!.recipe.id, lunch.id);
  });

  test('meals change from day to day for variety', () {
    final target = _target('General Fitness');
    final week = [
      for (var d = 0; d < 7; d++)
        MealPlanner.plan(
          target: target,
          budget: 300,
          date: date.add(Duration(days: d)),
        ),
    ];
    final lunches = week.map((p) => p.mealFor(MealSlot.lunch)!.recipe.id);
    final breakfasts = week.map(
      (p) => p.mealFor(MealSlot.breakfast)!.recipe.id,
    );
    expect(lunches.toSet().length, greaterThanOrEqualTo(3));
    expect(breakfasts.toSet().length, greaterThanOrEqualTo(2));
  });

  test('snacks stay near their calorie share', () {
    final target = _target('Weight Loss');
    final plan = MealPlanner.plan(target: target, budget: 300, date: date);
    final snack = plan.mealFor(MealSlot.snack)!;
    expect(snack.kcal, lessThan(target.kcal * 0.1 * 1.35));
  });

  test('counted foods are shown as whole pieces with grams', () {
    final eggs = PlannedFood(MealPlanner.foods['egg']!, 100);
    expect(eggs.amount, '2 eggs (100 g)');
    expect(PlannedFood(MealPlanner.foods['rice']!, 180).amount, '180 g');
    for (final recipe in MealCatalog.meals) {
      expect(MealPlanner.recipeParts, contains(recipe.id));
    }
  });
}
