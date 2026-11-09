import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_state.dart';
import '../models/meal_recommendation.dart';
import '../services/meal_preferences_store.dart';

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
  final _chosen = <MealSlot, String>{};
  bool _favorites = false;
  @override
  void initState() {
    super.initState();
    _store =
        widget.store ??
        MealPreferencesStore(ownerUid: FirebaseAuth.instance.currentUser?.uid);
    WidgetsBinding.instance.addObserver(this);
    _store.initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _store.pending) _store.sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.store == null) _store.dispose();
    super.dispose();
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
                const SizedBox(height: 20),
                Text('Budget per meal · ₱${prefs.budget}'),
                const Text(
                  'Illustrative ingredient estimate for one serving',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                Slider(
                  value: prefs.budget.toDouble(),
                  min: 30,
                  max: 150,
                  divisions: 24,
                  label: '₱${prefs.budget}',
                  onChanged: (v) =>
                      update(() => prefs = prefs.copyWith(budget: v.round())),
                ),
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
      _chosen.clear();
      await _store.update(selected);
    }
  }

  void _favorite(MealRecommendation meal) {
    final saved = {..._store.value.favorites};
    saved.contains(meal.id) ? saved.remove(meal.id) : saved.add(meal.id);
    _store.update(_store.value.copyWith(favorites: saved));
  }

  Widget _meal(
    MealRecommendation meal, {
    MealSlot? slot,
    List<MealRecommendation> choices = const [],
  }) => Card(
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
                      slot?.label.toUpperCase() ?? 'SAVED MEAL',
                      style: const TextStyle(
                        color: gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meal.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: _store.value.favorites.contains(meal.id)
                    ? 'Remove favorite'
                    : 'Save favorite',
                onPressed: () => _favorite(meal),
                icon: Icon(
                  _store.value.favorites.contains(meal.id)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                '~₱${meal.pesos} / serving',
                style: const TextStyle(
                  color: gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (meal.plantBased)
                const Text(
                  '• Plant-based',
                  style: TextStyle(color: Colors.white60),
                ),
              if (meal.proteinSource)
                const Text(
                  '• Includes a protein source',
                  style: TextStyle(color: Colors.white60),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            meal.ingredients,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 12),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 12),
            title: const Text('How to prepare', style: TextStyle(fontSize: 14)),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  meal.steps,
                  style: const TextStyle(color: Colors.white70, height: 1.5),
                ),
              ),
            ],
          ),
          if (slot != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: choices.length < 2
                    ? null
                    : () => setState(
                        () => _chosen[slot] =
                            choices[(choices.indexOf(meal) + 1) %
                                    choices.length]
                                .id,
                      ),
                icon: const Icon(Icons.swap_horiz),
                label: Text(
                  choices.length < 2 ? 'Only matching option' : 'Swap meal',
                ),
              ),
            ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Meal Recommendations')),
    body: AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        if (_store.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        final prefs = _store.value;
        final goal = AppState.instance.fitnessGoal;
        final matches = MealCatalog.matching(prefs, goal: goal);
        final favorites = matches
            .where((m) => prefs.favorites.contains(m.id))
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
                    'Fuel your next session',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text('Goal: $goal', style: const TextStyle(color: gold)),
                  const SizedBox(height: 8),
                  Text(
                    goal.toLowerCase().contains('muscle') ||
                            goal.toLowerCase().contains('strength')
                        ? 'Protein-source options appear first. Add variety with vegetables, fruit and your preferred staple.'
                        : 'Explore meals with vegetables, fruit, a staple and a protein source. Adjust portions to your appetite.',
                    style: const TextStyle(color: Colors.white70, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _filters,
              icon: const Icon(Icons.tune),
              label: Text(
                '₱${prefs.budget}/meal · ${prefs.plantOnly ? 'Plant-based' : 'All diets'} · ${prefs.excluded.length} exclusions',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: [
                ChoiceChip(
                  label: const Text('Meal ideas'),
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
            ] else
              for (final slot in MealSlot.values) ...[
                Builder(
                  builder: (context) {
                    final choices = MealCatalog.matching(
                      prefs,
                      slot: slot,
                      goal: goal,
                    );
                    if (choices.isEmpty) {
                      return _empty(
                        'No ${slot.label.toLowerCase()} matches your preferences. Try another budget or review your food preferences.',
                      );
                    }
                    final selected = choices.where(
                      (m) => m.id == _chosen[slot],
                    );
                    final meal = selected.isNotEmpty
                        ? selected.first
                        : choices.first;
                    return _meal(meal, slot: slot, choices: choices);
                  },
                ),
              ],
            const Text(
              'Meal ideas, not a prescribed daily menu. Costs are illustrative ingredient estimates, not live store prices. Calories and macros are not calculated.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'General food-group reference: DOST-FNRI Pinggang Pinoy (adult guide). Recipes and budgets are GrindFit suggestions.',
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
