import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_state.dart';
import '../models/meal_plan.dart';
import '../models/meal_recommendation.dart';
import '../services/meal_preferences_store.dart';
import '../services/offline_store.dart';

/// Saves the daily food budget on the member's profile.
Future<void> saveMealBudget(int pesos) async {
  AppState.instance.updateMealBudget(pesos);
  try {
    if (FirebaseAuth.instance.currentUser == null) return;
    await OfflineStore.instance.saveProfile({
      'mealBudget': AppState.instance.mealBudget,
    });
  } catch (_) {
    // Kept in memory; it is saved again the next time the budget changes.
  }
}

/// Bottom sheet for entering the daily food budget. Returns the new value.
Future<int?> showMealBudgetSheet(BuildContext context, int current) {
  final controller = TextEditingController(text: '$current');
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      String? error;
      return StatefulBuilder(
        builder: (ctx, update) {
          void submit() {
            final value = int.tryParse(controller.text.trim());
            if (value == null ||
                value < MealPlanner.minBudget ||
                value > MealPlanner.maxBudget) {
              update(
                () => error =
                    'Enter ₱${MealPlanner.minBudget} to ₱${MealPlanner.maxBudget}',
              );
              return;
            }
            Navigator.pop(ctx, value);
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily food budget',
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'How much can you spend on food for the whole day '
                      '(breakfast, lunch, dinner and a snack)?',
                      style: TextStyle(color: Colors.white60, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        prefixText: '₱ ',
                        suffixText: 'per day',
                        errorText: error,
                      ),
                      onSubmitted: (_) => submit(),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final preset in MealPlanner.budgetPresets)
                          ActionChip(
                            label: Text('₱$preset'),
                            onPressed: () => update(() {
                              controller.text = '$preset';
                              error = null;
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: submit,
                        child: const Text('Save budget'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  ).whenComplete(controller.dispose);
}

class MealRecommendationsScreen extends StatefulWidget {
  const MealRecommendationsScreen({super.key, this.store});
  final MealPreferencesStore? store;
  @override
  State<MealRecommendationsScreen> createState() =>
      _MealRecommendationsScreenState();
}

class _MealRecommendationsScreenState extends State<MealRecommendationsScreen>
    with WidgetsBindingObserver {
  static const gold = Color(0xFFF5B800);
  late final MealPreferencesStore _store;
  bool _favorites = false;
  @override
  void initState() {
    super.initState();
    _store =
        widget.store ??
        MealPreferencesStore(ownerUid: FirebaseAuth.instance.currentUser?.uid);
    WidgetsBinding.instance.addObserver(this);
    _store.addListener(_sharePreferences);
    _store.initialize();
  }

  void _sharePreferences() {
    if (!_store.loading) AppState.instance.setMealPreferences(_store.value);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _store.pending) _store.sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _store.removeListener(_sharePreferences);
    if (widget.store == null) _store.dispose();
    super.dispose();
  }

  Future<void> _editBudget() async {
    final value = await showMealBudgetSheet(
      context,
      AppState.instance.mealBudget,
    );
    if (value == null || !mounted) return;
    AppState.instance.clearMealChoices();
    await saveMealBudget(value);
  }

  Future<void> _filters() async {
    var prefs = _store.value;
    final selected = await showModalBottomSheet<MealPreferences>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meal preferences',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Plant-based only'),
                  value: prefs.plantOnly,
                  onChanged: (v) =>
                      update(() => prefs = prefs.copyWith(plantOnly: v)),
                ),
                const Text('Ingredients to exclude'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: MealPreferences.exclusionOptions
                      .map(
                        (tag) => FilterChip(
                          label: Text(tag),
                          selected: prefs.excluded.contains(tag),
                          onSelected: (on) => update(() {
                            final tags = {...prefs.excluded};
                            on ? tags.add(tag) : tags.remove(tag);
                            prefs = prefs.copyWith(excluded: tags);
                          }),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Filters apply to the listed recipes. Check packaged ingredients and preparation for allergens and cross-contact.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, prefs),
                    child: const Text('Apply preferences'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected != null && mounted) {
      AppState.instance.clearMealChoices();
      await _store.update(selected);
    }
  }

  void _favorite(MealRecommendation meal) {
    final saved = {..._store.value.favorites};
    saved.contains(meal.id) ? saved.remove(meal.id) : saved.add(meal.id);
    _store.update(_store.value.copyWith(favorites: saved));
  }

  void _swap(DailyMealPlan plan, PlannedMeal meal) {
    final options = MealPlanner.swapOptions(_store.value, meal.slot, plan);
    if (options.length < 2) return;
    final index = options.indexWhere((r) => r.id == meal.recipe.id);
    final next = options[(index + 1) % options.length];
    AppState.instance.chooseMeals({
      for (final m in plan.meals) m.slot: m.recipe.id,
      meal.slot: next.id,
    });
  }

  static String _num(double value) => value.round().toString();

  Widget _meal(PlannedMeal meal, {DailyMealPlan? plan}) {
    final saved = _store.value.favorites.contains(meal.recipe.id);
    final swaps = plan == null
        ? 0
        : MealPlanner.swapOptions(_store.value, meal.slot, plan).length;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.restaurant_outlined, color: gold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan == null
                            ? 'SAVED MEAL'
                            : meal.slot.label.toUpperCase(),
                        style: const TextStyle(
                          color: gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meal.recipe.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: saved ? 'Remove favorite' : 'Save favorite',
                  onPressed: () => _favorite(meal.recipe),
                  icon: Icon(
                    saved ? Icons.favorite : Icons.favorite_border,
                    color: gold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${_num(meal.kcal)} kcal • ${_num(meal.protein)} g protein • ~₱${_num(meal.cost)}',
              style: const TextStyle(color: gold, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            for (final food in meal.foods)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        food.food.name,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      food.amount,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 12),
              title: const Text(
                'How to prepare',
                style: TextStyle(fontSize: 14),
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    meal.recipe.steps,
                    style: const TextStyle(color: Colors.white70, height: 1.5),
                  ),
                ),
              ],
            ),
            if (plan != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: swaps < 2 ? null : () => _swap(plan, meal),
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(swaps < 2 ? 'Only matching option' : 'Swap meal'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _budgetCard(DailyMealPlan plan) {
    final ratio = plan.budget == 0 ? 0.0 : plan.cost / plan.budget;
    final warnings = <String>[
      if (plan.budgetTooLow)
        'Your budget is below the lowest-cost day we can plan (about ₱${_num(plan.cheapestCost)}). The plan below uses the cheapest options.'
      else if (plan.overBudget)
        'Your swapped meals go over budget by about ₱${_num(plan.cost - plan.budget)}.',
      if (plan.proteinShort) 'Protein is below your target. Eggs, monggo, tokwa and sardines are the most budget-friendly protein.',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payments_outlined, color: gold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Daily budget ₱${plan.budget}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _editBudget,
                  child: const Text('Edit budget'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "Today's plan costs about ₱${_num(plan.cost)}",
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 8,
                color: plan.overBudget ? Colors.orangeAccent : gold,
                backgroundColor: Colors.white12,
              ),
            ),
            for (final warning in warnings) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.orangeAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warning,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _totals(DailyMealPlan plan) {
    final t = plan.target;
    Widget row(String label, double value, int target, String unit) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Text(
            '${_num(value)} / $target $unit',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Day total vs your target',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            row('Calories', plan.kcal, t.kcal, 'kcal'),
            row('Protein', plan.protein, t.protein, 'g'),
            row('Carbs', plan.carbs, t.carbs, 'g'),
            row('Fat', plan.fat, t.fat, 'g'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Meal Plan')),
    body: AnimatedBuilder(
      animation: Listenable.merge([_store, AppState.instance]),
      builder: (context, _) {
        if (_store.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        final prefs = _store.value;
        final state = AppState.instance;
        final plan = MealPlanner.plan(
          target: state.nutritionTarget,
          budget: state.mealBudget,
          prefs: prefs,
          chosen: state.todayMealChoices,
        );
        final target = plan.target;
        final favorites = MealCatalog.meals
            .where(
              (m) =>
                  prefs.favorites.contains(m.id) &&
                  MealPlanner.allowed(prefs, m.slots.first).contains(m),
            )
            .map((m) => MealPlanner.build(m, m.slots.first, target))
            .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: gold.withValues(alpha: .3)),
                gradient: LinearGradient(
                  colors: [
                    gold.withValues(alpha: .14),
                    const Color(0xFF1C1C1E),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Today's meal plan",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Goal: ${target.goal}',
                    style: const TextStyle(color: gold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${target.kcal} kcal • ${target.protein} g protein per day',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    target.summary,
                    style: const TextStyle(color: Colors.white70, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _budgetCard(plan),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _filters,
              icon: const Icon(Icons.tune),
              label: Text(
                '${prefs.plantOnly ? 'Plant-based' : 'All diets'} · ${prefs.excluded.length} exclusions',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: [
                ChoiceChip(
                  label: const Text("Today's plan"),
                  selected: !_favorites,
                  onSelected: (_) => setState(() => _favorites = false),
                ),
                ChoiceChip(
                  label: Text('Favorites (${prefs.favorites.length})'),
                  selected: _favorites,
                  onSelected: (_) => setState(() => _favorites = true),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_favorites) ...[
              if (favorites.isEmpty)
                _empty(
                  prefs.favorites.isEmpty
                      ? 'No favorites yet. Tap the heart on a meal to save it.'
                      : 'Your favorites do not match the current filters. Adjust preferences to see more.',
                ),
              ...favorites.map((m) => _meal(m)),
            ] else ...[
              if (plan.meals.isEmpty)
                _empty(
                  'No meals match your preferences. Try removing an exclusion.',
                ),
              for (final meal in plan.meals) _meal(meal, plan: plan),
              if (plan.meals.isNotEmpty) _totals(plan),
            ],
            const Text(
              'Grams are for ready-to-eat food (rice and monggo are cooked weight). '
              'Calories and prices are estimates: market prices vary by place '
              'and season. This is a general guide, not medical advice. Ask a '
              'doctor or dietitian if you have a health condition.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Nutrition values are rounded from the DOST-FNRI Philippine Food '
              'Composition Tables and USDA FoodData Central. Daily targets use '
              'the Mifflin-St Jeor estimate with your age, height, weight and '
              'training days.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.cloud_outlined, color: gold, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _store.status,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: _store.syncing ? null : _store.sync,
                  child: const Text('Sync'),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
  Widget _empty(String text) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, height: 1.5),
      ),
    ),
  );
}
