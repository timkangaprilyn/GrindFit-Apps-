import 'dart:math' as math;

import 'meal_recommendation.dart';

/// One food with approximate values per 100 g of the ready-to-eat portion
/// (rice, monggo and meat are cooked weights). Nutrition values are rounded
/// from the DOST-FNRI Philippine Food Composition Tables and USDA FoodData
/// Central. Prices are rough Philippine market estimates per 100 g.
class Food {
  const Food(
    this.id,
    this.name,
    this.kcal,
    this.protein,
    this.carbs,
    this.fat,
    this.pesoPer100, {
    this.unit,
    this.unitGrams,
  });
  final String id, name;
  final double kcal, protein, carbs, fat, pesoPer100;

  /// Counted foods such as eggs or pandesal are rounded to whole pieces.
  final String? unit;
  final double? unitGrams;
}

enum FoodRole { protein, staple, side }

/// A food inside a recipe. Protein and staple portions are resized to the
/// member's targets between [min] and [max]; side portions stay fixed.
class FoodPart {
  const FoodPart(this.food, this.role, this.grams, {double? min, double? max})
    : min = min ?? grams,
      max = max ?? grams;
  final String food;
  final FoodRole role;
  final double grams, min, max;
}

class PlannedFood {
  PlannedFood(this.food, this.grams);
  final Food food;
  final int grams;
  double get kcal => food.kcal * grams / 100;
  double get protein => food.protein * grams / 100;
  double get carbs => food.carbs * grams / 100;
  double get fat => food.fat * grams / 100;
  double get cost => food.pesoPer100 * grams / 100;

  /// "2 eggs (100 g)" for counted foods, otherwise "150 g".
  String get amount {
    final unit = food.unit, size = food.unitGrams;
    if (unit == null || size == null) return '$grams g';
    final count = (grams / size).round();
    return '$count ${count == 1 ? unit : '${unit}s'} ($grams g)';
  }
}

class PlannedMeal {
  PlannedMeal(this.slot, this.recipe, this.foods);
  final MealSlot slot;
  final MealRecommendation recipe;
  final List<PlannedFood> foods;
  double _sum(double Function(PlannedFood f) of) =>
      foods.fold(0, (total, f) => total + of(f));
  double get kcal => _sum((f) => f.kcal);
  double get protein => _sum((f) => f.protein);
  double get carbs => _sum((f) => f.carbs);
  double get fat => _sum((f) => f.fat);
  double get cost => _sum((f) => f.cost);
  String get mainProtein => MealPlanner._partsOf(recipe.id)
      .firstWhere(
        (p) => p.role == FoodRole.protein,
        orElse: () => const FoodPart('', FoodRole.protein, 0),
      )
      .food;
}

class NutritionTarget {
  const NutritionTarget({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.goal,
    required this.summary,
  });
  final int kcal, protein, carbs, fat;
  final String goal, summary;
}

class DailyMealPlan {
  DailyMealPlan({
    required this.target,
    required this.meals,
    required this.budget,
    required this.cheapestCost,
  });
  final NutritionTarget target;
  final List<PlannedMeal> meals;
  final int budget;

  /// Lowest possible cost for a full day with the member's food filters.
  final double cheapestCost;
  double _sum(double Function(PlannedMeal m) of) =>
      meals.fold(0, (total, m) => total + of(m));
  double get kcal => _sum((m) => m.kcal);
  double get protein => _sum((m) => m.protein);
  double get carbs => _sum((m) => m.carbs);
  double get fat => _sum((m) => m.fat);
  double get cost => _sum((m) => m.cost);
  bool get overBudget => cost > budget + 0.5;
  bool get budgetTooLow => cheapestCost > budget + 0.5;
  bool get proteinShort => protein < target.protein * 0.85;
  PlannedMeal? mealFor(MealSlot slot) {
    for (final meal in meals) {
      if (meal.slot == slot) return meal;
    }
    return null;
  }
}

class MealPlanner {
  static const minBudget = 80, maxBudget = 2000, defaultBudget = 200;
  static const budgetPresets = [150, 200, 300, 500];

  /// Share of the day's food for each meal.
  static const slotShare = {
    MealSlot.breakfast: 0.25,
    MealSlot.lunch: 0.35,
    MealSlot.dinner: 0.30,
    MealSlot.snack: 0.10,
  };

  static const foods = <String, Food>{
    'rice': Food('rice', 'Rice (cooked)', 130, 2.7, 28, 0.3, 2.5),
    'oats': Food('oats', 'Rolled oats (dry)', 389, 16.9, 66, 6.9, 24),
    'pandesal': Food(
      'pandesal',
      'Pandesal',
      290,
      8,
      55,
      4,
      12,
      unit: 'pc',
      unitGrams: 25,
    ),
    'camote': Food('camote', 'Camote (boiled)', 86, 1.6, 20, 0.1, 7),
    'corn': Food('corn', 'Corn (boiled)', 96, 3.4, 21, 1.5, 10),
    'egg': Food(
      'egg',
      'Egg',
      143,
      12.6,
      0.7,
      9.5,
      18,
      unit: 'egg',
      unitGrams: 50,
    ),
    'chicken': Food(
      'chicken',
      'Chicken, skinless (cooked)',
      165,
      31,
      0,
      3.6,
      32,
    ),
    'tilapia': Food(
      'tilapia',
      'Tilapia (cooked, no bones)',
      128,
      26,
      0,
      2.7,
      30,
    ),
    'sardines': Food('sardines', 'Sardines in tomato sauce', 160, 18, 2, 9, 18),
    'tokwa': Food('tokwa', 'Tokwa (firm tofu)', 144, 15.8, 3, 8.7, 12),
    'monggo': Food('monggo', 'Monggo (cooked)', 105, 7, 19, 0.4, 5),
    'peanuts': Food('peanuts', 'Peanuts (roasted)', 585, 24, 21, 50, 20),
    'peanut_butter': Food(
      'peanut_butter',
      'Peanut butter',
      588,
      25,
      20,
      50,
      35,
    ),
    'yogurt': Food('yogurt', 'Plain yogurt', 61, 3.5, 4.7, 3.3, 25),
    'banana': Food('banana', 'Banana', 89, 1.1, 23, 0.3, 7),
    'papaya': Food('papaya', 'Papaya', 43, 0.5, 11, 0.3, 6),
    'pechay': Food('pechay', 'Pechay', 13, 1.5, 2.2, 0.2, 8),
    'malunggay': Food('malunggay', 'Malunggay leaves', 64, 9.4, 8, 1.4, 10),
    'cabbage': Food('cabbage', 'Cabbage', 25, 1.3, 6, 0.1, 7),
    'sayote': Food('sayote', 'Sayote', 19, 0.8, 4.5, 0.1, 6),
    'kalabasa': Food('kalabasa', 'Kalabasa', 26, 1, 6.5, 0.1, 6),
    'sitaw': Food('sitaw', 'Sitaw', 47, 2.8, 8, 0.4, 10),
    'carrots': Food('carrots', 'Carrots', 41, 0.9, 10, 0.2, 9),
    'tomato': Food('tomato', 'Tomato', 18, 0.9, 3.9, 0.2, 10),
    'oil': Food('oil', 'Cooking oil', 884, 0, 0, 100, 10),
  };

  static const _p = FoodRole.protein, _s = FoodRole.staple, _x = FoodRole.side;
  static const _rice = FoodPart('rice', _s, 150, min: 80, max: 380);

  /// Gram portions for every recipe in [MealCatalog.meals].
  static const recipeParts = <String, List<FoodPart>>{
    'egg-rice-banana': [
      FoodPart('egg', _p, 100, min: 50, max: 150),
      _rice,
      FoodPart('tomato', _x, 50),
      FoodPart('banana', _x, 100),
      FoodPart('oil', _x, 5),
    ],
    'oats-banana': [
      FoodPart('oats', _s, 40, min: 30, max: 90),
      FoodPart('banana', _x, 100),
    ],
    'tofu-pechay': [
      FoodPart('tokwa', _p, 150, min: 100, max: 300),
      FoodPart('pechay', _x, 100),
      _rice,
      FoodPart('oil', _x, 5),
    ],
    'chicken-tinola': [
      FoodPart('chicken', _p, 120, min: 80, max: 250),
      FoodPart('sayote', _x, 100),
      FoodPart('malunggay', _x, 20),
      _rice,
    ],
    'monggo-bowl': [
      FoodPart('monggo', _p, 200, min: 150, max: 350),
      FoodPart('malunggay', _x, 20),
      FoodPart('tomato', _x, 30),
      _rice,
      FoodPart('oil', _x, 5),
    ],
    'sardines-cabbage': [
      FoodPart('sardines', _p, 155, min: 75, max: 310),
      FoodPart('cabbage', _x, 100),
      _rice,
    ],
    'camote-fruit': [
      FoodPart('camote', _s, 150, min: 100, max: 300),
      FoodPart('papaya', _x, 100),
    ],
    'tofu-breakfast': [
      FoodPart('tokwa', _p, 100, min: 70, max: 250),
      FoodPart('tomato', _x, 50),
      _rice,
      FoodPart('oil', _x, 5),
    ],
    'chicken-vegetables': [
      FoodPart('chicken', _p, 120, min: 80, max: 250),
      FoodPart('carrots', _x, 50),
      FoodPart('cabbage', _x, 80),
      _rice,
      FoodPart('oil', _x, 5),
    ],
    'tilapia-greens': [
      FoodPart('tilapia', _p, 150, min: 100, max: 300),
      FoodPart('pechay', _x, 100),
      _rice,
    ],
    'egg-tomato': [
      FoodPart('egg', _p, 100, min: 50, max: 150),
      FoodPart('tomato', _x, 80),
      _rice,
      FoodPart('oil', _x, 5),
    ],
    'squash-beans': [
      FoodPart('monggo', _p, 120, min: 100, max: 300),
      FoodPart('kalabasa', _x, 100),
      FoodPart('sitaw', _x, 60),
      _rice,
    ],
    'banana-peanuts': [
      FoodPart('peanuts', _p, 30, min: 20, max: 50),
      FoodPart('banana', _x, 100),
    ],
    'yogurt-fruit': [
      FoodPart('yogurt', _p, 150, min: 100, max: 250),
      FoodPart('banana', _x, 60),
      FoodPart('papaya', _x, 100),
    ],
    'corn-fruit': [
      FoodPart('corn', _s, 100, min: 80, max: 200),
      FoodPart('papaya', _x, 100),
    ],
    'peanut-pandesal': [
      FoodPart('peanut_butter', _p, 16, min: 16, max: 32),
      FoodPart('pandesal', _s, 50, min: 25, max: 100),
      FoodPart('banana', _x, 100),
    ],
  };

  static List<FoodPart> _partsOf(String id) => recipeParts[id] ?? const [];

  static String goalKey(String goal) {
    final g = goal.toLowerCase();
    if (g.contains('loss') || g.contains('lose')) return 'loss';
    if (g.contains('endurance') || g.contains('cardio')) return 'endurance';
    if (g.contains('muscle') || g.contains('strength') || g.contains('gain')) {
      return 'gain';
    }
    return 'general';
  }

  /// Daily energy and protein estimate (Mifflin-St Jeor, activity from the
  /// number of training days, then adjusted for the goal).
  static NutritionTarget target({
    required String goal,
    required double weightKg,
    required double heightCm,
    required int age,
    String? gender,
    int daysPerWeek = 3,
  }) {
    final weight = weightKg.clamp(30, 250).toDouble();
    final height = heightCm.clamp(120, 230).toDouble();
    final years = age.clamp(13, 90);
    final g = (gender ?? '').toLowerCase();
    final sexOffset = g.startsWith('m')
        ? 5
        : g.startsWith('f')
        ? -161
        : -78;
    final bmr = 10 * weight + 6.25 * height - 5 * years + sexOffset;
    final activity = daysPerWeek <= 2
        ? 1.375
        : daysPerWeek <= 5
        ? 1.55
        : 1.725;
    final maintenance = bmr * activity;
    final key = goalKey(goal);
    final (factor, proteinPerKg, fatShare, summary) = switch (key) {
      'loss' => (
        0.8,
        1.8,
        0.25,
        'About 20% below your daily energy needs, with high protein to keep '
            'muscle while losing fat.',
      ),
      'gain' => (
        1.1,
        1.8,
        0.25,
        'About 10% above your daily energy needs, with high protein to help '
            'build muscle.',
      ),
      'endurance' => (
        1.05,
        1.4,
        0.25,
        'Enough energy for cardio with more rice, camote and fruit (carbs) '
            'to fuel longer sessions.',
      ),
      _ => (
        1.0,
        1.2,
        0.30,
        'Balanced to maintain your weight with a mix of staple, protein, '
            'vegetables and fruit.',
      ),
    };
    final floor = math.max(1200.0, bmr);
    final kcal = (math.max(maintenance * factor, floor) / 10).round() * 10;
    final protein = (weight * proteinPerKg).round();
    final fat = (kcal * fatShare / 9).round();
    final carbs = math.max(0, ((kcal - protein * 4 - fat * 9) / 4).round());
    return NutritionTarget(
      kcal: kcal,
      protein: protein,
      carbs: carbs,
      fat: fat,
      goal: switch (key) {
        'loss' => 'Weight Loss',
        'gain' => 'Muscle Gain',
        'endurance' => 'Endurance',
        _ => 'General Fitness',
      },
      summary: summary,
    );
  }

  static double _round(FoodPart part, double grams) {
    final size = foods[part.food]?.unitGrams;
    final step = size ?? 5;
    final clamped = grams.clamp(part.min, part.max).toDouble();
    return math.max(step, (clamped / step).round() * step);
  }

  /// Sizes one recipe for its share of the day's calories and protein.
  static PlannedMeal build(
    MealRecommendation recipe,
    MealSlot slot,
    NutritionTarget target,
  ) {
    final share = slotShare[slot] ?? 0.25;
    final mealKcal = target.kcal * share, mealProtein = target.protein * share;
    final parts = _partsOf(recipe.id);
    final grams = <FoodPart, double>{for (final p in parts) p: p.grams};
    FoodPart? proteinPart, staplePart;
    for (final p in parts) {
      if (p.role == FoodRole.protein) proteinPart ??= p;
      if (p.role == FoodRole.staple) staplePart ??= p;
    }
    double total(double Function(Food f) of, {FoodPart? skip}) {
      var sum = 0.0;
      grams.forEach((part, g) {
        if (part == skip) return;
        final food = foods[part.food];
        if (food != null) sum += of(food) * g / 100;
      });
      return sum;
    }

    // Size the protein first, then fill the remaining energy with the staple.
    for (var pass = 0; pass < 2; pass++) {
      final protein = proteinPart;
      if (protein != null) {
        final food = foods[protein.food]!;
        final need = mealProtein - total((f) => f.protein, skip: protein);
        // Leave room for the sides and the smallest staple portion so a
        // calorie-dense protein (peanuts) does not overshoot the meal.
        final staple = staplePart;
        var others = total((f) => f.kcal, skip: protein);
        if (staple != null) {
          final kcal = foods[staple.food]!.kcal;
          others += (staple.min - grams[staple]!) * kcal / 100;
        }
        final room = (mealKcal * 1.1 - others) / food.kcal * 100;
        grams[protein] = _round(
          protein,
          math.min(need / food.protein * 100, math.max(room, protein.min)),
        );
      }
      final staple = staplePart;
      if (staple != null) {
        final food = foods[staple.food]!;
        final left = mealKcal - total((f) => f.kcal, skip: staple);
        grams[staple] = _round(staple, left / food.kcal * 100);
      }
    }
    return PlannedMeal(slot, recipe, [
      for (final p in parts)
        if (foods[p.food] != null)
          PlannedFood(foods[p.food]!, grams[p]!.round()),
    ]);
  }

  /// Recipes allowed by the member's diet and exclusions for one meal.
  static List<MealRecommendation> allowed(
    MealPreferences prefs,
    MealSlot slot,
  ) => MealCatalog.meals
      .where(
        (m) =>
            m.slots.contains(slot) &&
            (!prefs.plantOnly || m.plantBased) &&
            !m.exclusions.any(prefs.excluded.contains) &&
            recipeParts.containsKey(m.id),
      )
      .toList();

  static int _hash(String text) {
    var h = 2166136261;
    for (final unit in text.codeUnits) {
      h = ((h ^ unit) * 16777619) & 0x7fffffff;
    }
    return h;
  }

  /// Picks breakfast, lunch, dinner and a snack that fit the daily [budget]
  /// while getting as close as possible to the targets. The same date always
  /// gives the same plan; a new day rotates the choices for variety.
  /// [chosen] keeps a meal the member swapped in for that slot.
  static DailyMealPlan plan({
    required NutritionTarget target,
    required int budget,
    MealPreferences prefs = const MealPreferences(),
    DateTime? date,
    Map<MealSlot, String> chosen = const {},
  }) {
    final day = date ?? DateTime.now();
    final dayKey = '${day.year}-${day.month}-${day.day}';
    final options = <MealSlot, List<PlannedMeal>>{};
    for (final slot in MealSlot.values) {
      var recipes = allowed(prefs, slot);
      final pick = chosen[slot];
      if (pick != null && recipes.any((r) => r.id == pick)) {
        recipes = recipes.where((r) => r.id == pick).toList();
      }
      if (recipes.isNotEmpty) {
        options[slot] = [for (final r in recipes) build(r, slot, target)];
      }
    }
    final slots = options.keys.toList();
    List<PlannedMeal>? best, cheapest;
    var bestScore = double.negativeInfinity;
    var cheapestCost = double.infinity;
    void visit(int index, List<PlannedMeal> picked, double cost) {
      if (index == slots.length) {
        if (cost < cheapestCost) {
          cheapestCost = cost;
          cheapest = List.of(picked);
        }
        if (cost > budget + 0.5) return;
        final kcal = picked.fold<double>(0, (t, m) => t + m.kcal);
        final protein = picked.fold<double>(0, (t, m) => t + m.protein);
        final proteinScore = math.min(protein / target.protein, 1.05);
        final kcalScore = 1 - (kcal / target.kcal - 1).abs();
        final mains = picked
            .map((m) => m.mainProtein)
            .where((p) => p.isNotEmpty)
            .toList();
        final repeats = mains.length - mains.toSet().length;
        final variety =
            _hash('$dayKey|${picked.map((m) => m.recipe.id).join(',')}') %
            1000 /
            1000;
        final score =
            proteinScore * 60 + kcalScore * 30 + variety * 20 - repeats * 15;
        if (score > bestScore) {
          bestScore = score;
          best = List.of(picked);
        }
        return;
      }
      for (final meal in options[slots[index]]!) {
        if (picked.any((m) => m.recipe.id == meal.recipe.id)) continue;
        picked.add(meal);
        visit(index + 1, picked, cost + meal.cost);
        picked.removeLast();
      }
    }

    visit(0, [], 0);
    final meals = best ?? cheapest ?? const <PlannedMeal>[];
    return DailyMealPlan(
      target: target,
      meals: List.unmodifiable(meals),
      budget: budget,
      cheapestCost: cheapestCost.isFinite ? cheapestCost : 0,
    );
  }

  /// Other recipes the member can swap in for [slot], in catalog order.
  static List<MealRecommendation> swapOptions(
    MealPreferences prefs,
    MealSlot slot,
    DailyMealPlan plan,
  ) {
    final used = plan.meals
        .where((m) => m.slot != slot)
        .map((m) => m.recipe.id)
        .toSet();
    return allowed(prefs, slot).where((r) => !used.contains(r.id)).toList();
  }
}
