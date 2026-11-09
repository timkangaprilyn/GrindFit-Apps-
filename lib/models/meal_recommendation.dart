enum MealSlot {
  breakfast('Breakfast'),
  lunch('Lunch'),
  dinner('Dinner'),
  snack('Snack');

  const MealSlot(this.label);
  final String label;
}

class MealRecommendation {
  const MealRecommendation(
    this.id,
    this.name,
    this.ingredients,
    this.steps,
    this.pesos,
    this.slots, {
    this.exclusions = const {},
    this.plantBased = false,
    this.proteinSource = false,
  });
  final String id, name, ingredients, steps;
  final int pesos;
  final Set<MealSlot> slots;
  final Set<String> exclusions;
  final bool plantBased, proteinSource;
}

class MealPreferences {
  const MealPreferences({
    this.budget = 75,
    this.plantOnly = false,
    this.excluded = const {},
    this.favorites = const {},
  });
  final int budget;
  final bool plantOnly;
  final Set<String> excluded, favorites;
  static const exclusionOptions = [
    'egg',
    'soy',
    'fish',
    'milk',
    'peanut',
    'wheat',
  ];
  MealPreferences copyWith({
    int? budget,
    bool? plantOnly,
    Set<String>? excluded,
    Set<String>? favorites,
  }) => MealPreferences(
    budget: budget ?? this.budget,
    plantOnly: plantOnly ?? this.plantOnly,
    excluded: Set.unmodifiable(excluded ?? this.excluded),
    favorites: Set.unmodifiable(favorites ?? this.favorites),
  );
  Map<String, dynamic> toJson() => {
    'budget': budget,
    'plant_only': plantOnly,
    'excluded': excluded.toList()..sort(),
    'favorites': favorites.toList()..sort(),
  };
  factory MealPreferences.fromJson(Map<String, dynamic> json) =>
      MealPreferences(
        budget: ((json['budget'] as num?)?.toInt() ?? 75).clamp(30, 150),
        plantOnly: json['plant_only'] == true,
        excluded: (json['excluded'] as List? ?? [])
            .whereType<String>()
            .where(exclusionOptions.contains)
            .toSet(),
        favorites: (json['favorites'] as List? ?? [])
            .whereType<String>()
            .where((id) => MealCatalog.meals.any((m) => m.id == id))
            .toSet(),
      );
}

class MealCatalog {
  static const meals = [
    MealRecommendation(
      'egg-rice-banana',
      'Egg, rice & banana',
      'Eggs, cooked rice, banana, tomato, a little oil',
      'Cook the eggs through and serve with rice, sliced tomato and banana.',
      45,
      {MealSlot.breakfast},
      exclusions: {'egg'},
      proteinSource: true,
    ),
    MealRecommendation(
      'oats-banana',
      'Banana oatmeal',
      'Plain oats, banana, water, cinnamon',
      'Cook oats in water and top with sliced banana and cinnamon.',
      30,
      {MealSlot.breakfast, MealSlot.snack},
      plantBased: true,
    ),
    MealRecommendation(
      'tofu-pechay',
      'Tokwa & pechay bowl',
      'Plain tokwa, pechay, rice, garlic, a little oil, salt',
      'Sauté garlic and tokwa, add pechay, and serve with cooked rice.',
      50,
      {MealSlot.lunch, MealSlot.dinner},
      exclusions: {'soy'},
      plantBased: true,
      proteinSource: true,
    ),
    MealRecommendation(
      'chicken-tinola',
      'Chicken tinola',
      'Chicken, sayote, malunggay, ginger, rice, water, salt',
      'Simmer chicken with ginger until thoroughly cooked, add vegetables, and serve with rice. This version uses no fish sauce.',
      75,
      {MealSlot.lunch, MealSlot.dinner},
      proteinSource: true,
    ),
    MealRecommendation(
      'monggo-bowl',
      'Ginisang monggo bowl',
      'Monggo, malunggay, tomato, garlic, rice, salt',
      'Cook monggo until soft. Sauté garlic and tomato, add monggo and malunggay, and serve with rice. No fish sauce or shrimp paste.',
      40,
      {MealSlot.lunch, MealSlot.dinner},
      plantBased: true,
      proteinSource: true,
    ),
    MealRecommendation(
      'sardines-cabbage',
      'Sardines & cabbage',
      'Canned sardines in tomato sauce, cabbage, rice, garlic',
      'Check the can label, heat sardines with garlic and cabbage, and serve with rice.',
      55,
      {MealSlot.lunch, MealSlot.dinner},
      exclusions: {'fish'},
      proteinSource: true,
    ),
    MealRecommendation(
      'camote-fruit',
      'Camote & papaya',
      'Camote, papaya, water',
      'Boil camote until tender and serve with sliced papaya.',
      35,
      {MealSlot.breakfast, MealSlot.snack},
      plantBased: true,
    ),
    MealRecommendation(
      'tofu-breakfast',
      'Tokwa breakfast rice',
      'Plain tokwa, tomato, garlic, rice, a little oil, salt',
      'Brown tokwa with garlic and serve with tomato and rice. No soy sauce is needed.',
      45,
      {MealSlot.breakfast},
      exclusions: {'soy'},
      plantBased: true,
      proteinSource: true,
    ),
    MealRecommendation(
      'chicken-vegetables',
      'Chicken & vegetable rice',
      'Chicken, carrots, cabbage, rice, garlic, oil, salt',
      'Cook chicken thoroughly with garlic, add vegetables, and serve with rice.',
      85,
      {MealSlot.lunch, MealSlot.dinner},
      proteinSource: true,
    ),
    MealRecommendation(
      'tilapia-greens',
      'Tilapia & greens',
      'Tilapia, pechay, rice, calamansi, salt',
      'Cook fish through, steam the greens, and serve with rice and calamansi.',
      80,
      {MealSlot.lunch, MealSlot.dinner},
      exclusions: {'fish'},
      proteinSource: true,
    ),
    MealRecommendation(
      'egg-tomato',
      'Tomato egg rice',
      'Eggs, tomato, rice, garlic, a little oil',
      'Sauté tomato and garlic, add eggs and cook through, then serve with rice.',
      45,
      {MealSlot.breakfast, MealSlot.lunch},
      exclusions: {'egg'},
      proteinSource: true,
    ),
    MealRecommendation(
      'squash-beans',
      'Kalabasa & sitaw rice',
      'Kalabasa, sitaw, cooked monggo, garlic, rice, water, salt',
      'Simmer squash and sitaw until tender, stir in cooked monggo, and serve with rice.',
      55,
      {MealSlot.lunch, MealSlot.dinner},
      plantBased: true,
      proteinSource: true,
    ),
    MealRecommendation(
      'banana-peanuts',
      'Banana & peanuts',
      'Banana, plain roasted peanuts',
      'Serve banana with a small bowl of plain roasted peanuts; check the package label.',
      30,
      {MealSlot.snack},
      exclusions: {'peanut'},
      plantBased: true,
      proteinSource: true,
    ),
    MealRecommendation(
      'yogurt-fruit',
      'Plain yogurt & fruit',
      'Plain yogurt, banana, papaya',
      'Top plain yogurt with sliced fruit. Check the yogurt label for added ingredients.',
      65,
      {MealSlot.breakfast, MealSlot.snack},
      exclusions: {'milk'},
      proteinSource: true,
    ),
    MealRecommendation(
      'corn-fruit',
      'Boiled corn & fruit',
      'Corn, papaya, water',
      'Boil corn until tender and serve with fresh papaya; no butter is added.',
      35,
      {MealSlot.snack},
      plantBased: true,
    ),
    MealRecommendation(
      'peanut-pandesal',
      'Peanut butter pandesal',
      'Pandesal, peanut butter, banana',
      'Spread peanut butter on pandesal and serve with banana. Check bread and spread labels.',
      40,
      {MealSlot.breakfast, MealSlot.snack},
      exclusions: {'wheat', 'peanut', 'milk', 'egg', 'soy'},
      proteinSource: true,
    ),
  ];

  static List<MealRecommendation> matching(
    MealPreferences prefs, {
    MealSlot? slot,
    String goal = '',
  }) {
    final result = meals
        .where(
          (m) =>
              m.pesos <= prefs.budget &&
              (!prefs.plantOnly || m.plantBased) &&
              !m.exclusions.any(prefs.excluded.contains) &&
              (slot == null || m.slots.contains(slot)),
        )
        .toList();
    if (goal.toLowerCase().contains('strength') ||
        goal.toLowerCase().contains('muscle')) {
      result.sort(
        (a, b) => (b.proteinSource ? 1 : 0).compareTo(a.proteinSource ? 1 : 0),
      );
    }
    return result;
  }
}
