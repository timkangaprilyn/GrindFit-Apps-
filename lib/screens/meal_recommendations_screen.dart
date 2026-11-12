import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_state.dart';
import '../models/meal_plan.dart';
import '../models/meal_recommendation.dart';
import '../services/meal_preferences_store.dart';
import '../services/offline_store.dart';

/// App palette (same black + gold + white used across GrindFit).
class _C {
  static const Color bg = Color(0xFF121212);
  static const Color card = Color(0xFF1C1C1E);
  static const Color border = Color(0xFF2E2E31);
  static const Color gold = Color(0xFFF5B800);
  static const Color white = Colors.white;
  static const Color body = Colors.white70;
  static const Color faint = Colors.white60;
  static const Color warn = Colors.orangeAccent;
}

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
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: _C.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _BudgetSheet(current: current),
  );
}

/// Owns its text controller so it is disposed only after the sheet has
/// finished closing. Disposing it when the route pops crashed the app,
/// because the field is still rebuilt during the closing animation.
class _BudgetSheet extends StatefulWidget {
  const _BudgetSheet({required this.current});
  final int current;

  @override
  State<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<_BudgetSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: '${widget.current}',
  );
  String? _error;
  bool _closing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_closing) return;
    final value = int.tryParse(_controller.text.trim());
    if (value == null ||
        value < MealPlanner.minBudget ||
        value > MealPlanner.maxBudget) {
      setState(
        () => _error =
            'Enter ₱${MealPlanner.minBudget} to ₱${MealPlanner.maxBudget}',
      );
      return;
    }
    _closing = true; // ignore a double tap while the sheet closes
    FocusScope.of(context).unfocus();
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Daily food budget', style: _T.sheetTitle),
              const SizedBox(height: 6),
              const Text(
                'How much can you spend on food for the whole day '
                '(breakfast, lunch, dinner and a snack)?',
                style: TextStyle(color: _C.faint, height: 1.4),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                cursorColor: _C.gold,
                style: const TextStyle(
                  color: _C.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
                onChanged: (_) => setState(() => _error = null),
                decoration: _inputDecoration(
                  prefixText: '₱ ',
                  suffixText: 'per day',
                  errorText: _error,
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final preset in MealPlanner.budgetPresets)
                    _presetChip(
                      label: '₱$preset',
                      active: _controller.text.trim() == '$preset',
                      onPressed: () => setState(() {
                        _controller.text = '$preset';
                        _error = null;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: _submit,
                style: _primaryStyle,
                child: const Text('Save budget'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Shared styles ─────────────────────────

class _T {
  static const overline = TextStyle(
    color: _C.gold,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.4,
  );
  static const sectionLabel = TextStyle(
    color: _C.faint,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.4,
  );
  static const cardTitle = TextStyle(
    color: _C.white,
    fontSize: 16,
    fontWeight: FontWeight.w800,
  );
  static const sheetTitle = TextStyle(
    color: _C.white,
    fontSize: 20,
    fontWeight: FontWeight.w800,
  );
  static const fine = TextStyle(color: _C.faint, fontSize: 12, height: 1.5);
}

final ButtonStyle _primaryStyle = FilledButton.styleFrom(
  backgroundColor: _C.gold,
  foregroundColor: Colors.black,
  minimumSize: const Size.fromHeight(52),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
);

InputDecoration _inputDecoration({
  String? prefixText,
  String? suffixText,
  String? errorText,
}) {
  OutlineInputBorder outline(Color c, [double w = 1.2]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: c, width: w),
  );
  return InputDecoration(
    prefixText: prefixText,
    prefixStyle: const TextStyle(
      color: _C.gold,
      fontSize: 18,
      fontWeight: FontWeight.w800,
    ),
    suffixText: suffixText,
    suffixStyle: const TextStyle(color: _C.faint, fontSize: 13),
    errorText: errorText,
    errorStyle: const TextStyle(color: _C.warn),
    filled: true,
    fillColor: _C.bg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    enabledBorder: outline(_C.border),
    focusedBorder: outline(_C.gold, 1.6),
    errorBorder: outline(_C.warn),
    focusedErrorBorder: outline(_C.warn, 1.6),
  );
}

Widget _presetChip({
  required String label,
  required bool active,
  required VoidCallback onPressed,
}) => ActionChip(
  label: Text(label),
  onPressed: onPressed,
  backgroundColor: active ? _C.gold.withValues(alpha: .16) : _C.bg,
  side: BorderSide(color: active ? _C.gold : _C.border),
  shape: const StadiumBorder(),
  labelStyle: TextStyle(
    color: active ? _C.gold : _C.white,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  ),
);

BoxDecoration _surface({Color? border}) => BoxDecoration(
  color: _C.card,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: border ?? _C.border, width: 1.2),
);

// ───────────────────────── Screen ─────────────────────────

class MealRecommendationsScreen extends StatefulWidget {
  const MealRecommendationsScreen({super.key, this.store});
  final MealPreferencesStore? store;
  @override
  State<MealRecommendationsScreen> createState() =>
      _MealRecommendationsScreenState();
}

class _MealRecommendationsScreenState extends State<MealRecommendationsScreen>
    with WidgetsBindingObserver {
  static const gold = _C.gold;
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
      showDragHandle: true,
      backgroundColor: _C.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * .85,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Meal preferences', style: _T.sheetTitle),
                  const SizedBox(height: 16),
                  Material(
                    color: _C.bg,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: _C.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: Colors.black,
                        activeTrackColor: gold,
                        secondary: const Icon(Icons.eco_outlined, color: gold),
                        title: const Text(
                          'Plant-based only',
                          style: TextStyle(
                            color: _C.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        value: prefs.plantOnly,
                        onChanged: (v) =>
                            update(() => prefs = prefs.copyWith(plantOnly: v)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    prefs.excluded.isEmpty
                        ? 'INGREDIENTS TO EXCLUDE'
                        : 'INGREDIENTS TO EXCLUDE · ${prefs.excluded.length}',
                    style: _T.sectionLabel,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: MealPreferences.exclusionOptions.map((tag) {
                      final on = prefs.excluded.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: on,
                        showCheckmark: true,
                        checkmarkColor: gold,
                        backgroundColor: _C.bg,
                        selectedColor: gold.withValues(alpha: .16),
                        side: BorderSide(color: on ? gold : _C.border),
                        shape: const StadiumBorder(),
                        labelStyle: TextStyle(
                          color: on ? gold : _C.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (on) => update(() {
                          final tags = {...prefs.excluded};
                          on ? tags.add(tag) : tags.remove(tag);
                          prefs = prefs.copyWith(excluded: tags);
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: _C.faint,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Filters apply to the listed recipes. Check packaged ingredients and preparation for allergens and cross-contact.',
                          style: _T.fine,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, prefs),
                    style: _primaryStyle,
                    child: const Text('Apply preferences'),
                  ),
                ],
              ),
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

  // ───────────────────────── Meal card ─────────────────────────

  Widget _meal(PlannedMeal meal, {DailyMealPlan? plan}) {
    final saved = _store.value.favorites.contains(meal.recipe.id);
    final swaps = plan == null
        ? 0
        : MealPlanner.swapOptions(_store.value, meal.slot, plan).length;
    // A Material (not a coloured Container) so the "How to prepare"
    // ExpansionTile has a surface to paint on; otherwise it throws.
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: _C.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _C.border, width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 8, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(13),
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
                          style: _T.overline,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          meal.recipe.name,
                          style: const TextStyle(
                            color: _C.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: saved ? 'Remove favorite' : 'Save favorite',
                    onPressed: () => _favorite(meal.recipe),
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        saved ? Icons.favorite : Icons.favorite_border,
                        key: ValueKey(saved),
                        color: gold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _macroChip(
                      Icons.local_fire_department_outlined,
                      '${_num(meal.kcal)} kcal',
                    ),
                    _macroChip(
                      Icons.egg_alt_outlined,
                      '${_num(meal.protein)} g protein',
                    ),
                    _macroChip(Icons.payments_outlined, '~₱${_num(meal.cost)}'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Ingredient list as a quiet table: name left, amount right.
              Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _C.bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    for (final (i, food) in meal.foods.indexed) ...[
                      if (i != 0)
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: _C.border,
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                food.food.name,
                                style: const TextStyle(
                                  color: _C.body,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              food.amount,
                              style: const TextStyle(
                                color: _C.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Theme(
                // Remove the default ExpansionTile divider lines.
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.only(right: 10),
                  childrenPadding: const EdgeInsets.only(right: 10, bottom: 12),
                  iconColor: gold,
                  collapsedIconColor: _C.faint,
                  leading: const Icon(
                    Icons.menu_book_outlined,
                    color: gold,
                    size: 20,
                  ),
                  title: const Text(
                    'How to prepare',
                    style: TextStyle(
                      color: _C.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        meal.recipe.steps,
                        style: const TextStyle(color: _C.body, height: 1.55),
                      ),
                    ),
                  ],
                ),
              ),
              if (plan != null) ...[
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Divider(height: 1, thickness: 1, color: _C.border),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: swaps < 2 ? null : () => _swap(plan, meal),
                    style: TextButton.styleFrom(
                      foregroundColor: gold,
                      disabledForegroundColor: _C.faint.withValues(alpha: .5),
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      textStyle: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    icon: const Icon(Icons.swap_horiz, size: 20),
                    label: Text(
                      swaps < 2 ? 'Only matching option' : 'Swap meal',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _macroChip(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: gold.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: gold),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            color: gold,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  // ───────────────────────── Budget ─────────────────────────

  Widget _budgetCard(DailyMealPlan plan) {
    final ratio = plan.budget == 0 ? 0.0 : plan.cost / plan.budget;
    final warnings = <String>[
      if (plan.budgetTooLow)
        'Your budget is below the lowest-cost day we can plan (about ₱${_num(plan.cheapestCost)}). The plan below uses the cheapest options.'
      else if (plan.overBudget)
        'Your swapped meals go over budget by about ₱${_num(plan.cost - plan.budget)}.',
      if (plan.proteinShort) 'Protein is below your target. Eggs, monggo, tokwa and sardines are the most budget-friendly protein.',
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text('DAILY BUDGET', style: _T.sectionLabel),
              ),
              Tooltip(
                message: 'Edit budget',
                child: OutlinedButton.icon(
                  onPressed: _editBudget,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: gold,
                    side: BorderSide(color: gold.withValues(alpha: .5)),
                    shape: const StadiumBorder(),
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Semantics(
            label:
                "Today's plan costs about ${_num(plan.cost)} pesos of a ${plan.budget} peso daily budget",
            excludeSemantics: true,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '₱${_num(plan.cost)}',
                    style: TextStyle(
                      color: plan.overBudget ? _C.warn : _C.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: '  of ₱${plan.budget}',
                    style: const TextStyle(
                      color: _C.faint,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          const Text("Today's plan, estimated", style: _T.fine),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio.clamp(0.0, 1.0).toDouble()),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                color: plan.overBudget ? _C.warn : gold,
                backgroundColor: Colors.white12,
              ),
            ),
          ),
          for (final warning in warnings) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _C.warn.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.warn.withValues(alpha: .3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: _C.warn, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warning,
                      style: const TextStyle(
                        color: _C.body,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ───────────────────────── Totals ─────────────────────────

  Widget _totals(DailyMealPlan plan) {
    final t = plan.target;
    Widget row(String label, double value, int target, String unit) {
      final ratio = target == 0 ? 0.0 : (value / target).clamp(0.0, 1.0);
      return Semantics(
        label: '$label ${_num(value)} of $target $unit',
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(color: _C.body, fontSize: 13.5),
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: _num(value),
                          style: const TextStyle(
                            color: _C.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: ' / $target $unit',
                          style: const TextStyle(
                            color: _C.faint,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    style: const TextStyle(fontSize: 13.5),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio.toDouble(),
                  minHeight: 5,
                  color: gold,
                  backgroundColor: Colors.white12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
      decoration: _surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Day total vs your target', style: _T.cardTitle),
          const SizedBox(height: 16),
          row('Calories', plan.kcal, t.kcal, 'kcal'),
          row('Protein', plan.protein, t.protein, 'g'),
          row('Carbs', plan.carbs, t.carbs, 'g'),
          row('Fat', plan.fat, t.fat, 'g'),
        ],
      ),
    );
  }

  // ───────────────────────── View switch ─────────────────────────

  Widget _viewTabs(int favoriteCount) {
    Widget tab(String label, bool selected, VoidCallback onTap) => Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? gold : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.black : _C.faint,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          tab(
            "Today's plan",
            !_favorites,
            () => setState(() => _favorites = false),
          ),
          tab(
            'Favorites ($favoriteCount)',
            _favorites,
            () => setState(() => _favorites = true),
          ),
        ],
      ),
    );
  }

  Widget _preferencesRow(MealPreferences prefs) => Material(
    color: _C.card,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: _C.border),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _filters,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.tune, color: gold, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Meal preferences',
                    style: TextStyle(
                      color: _C.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${prefs.plantOnly ? 'Plant-based' : 'All diets'} · ${prefs.excluded.length} exclusions',
                    style: const TextStyle(color: _C.faint, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _C.faint),
          ],
        ),
      ),
    ),
  );

  // ───────────────────────── Build ─────────────────────────

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _C.bg,
    appBar: AppBar(
      backgroundColor: _C.card,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      iconTheme: const IconThemeData(color: _C.white),
      title: const Text(
        'Meal Plan',
        style: TextStyle(
          color: _C.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _C.border),
      ),
    ),
    body: AnimatedBuilder(
      animation: Listenable.merge([_store, AppState.instance]),
      builder: (context, _) {
        if (_store.loading) {
          return const Center(child: CircularProgressIndicator(color: gold));
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            // Daily target (flat surface with a gold edge, no gradient).
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _surface(border: gold.withValues(alpha: .35)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GOAL • ${target.goal.toString().toUpperCase()}',
                    style: _T.overline,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Today's meal plan",
                    style: TextStyle(
                      color: _C.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _targetStat('${target.kcal}', 'kcal / day'),
                        ),
                        const VerticalDivider(
                          width: 24,
                          thickness: 1,
                          color: _C.border,
                        ),
                        Expanded(
                          child: _targetStat(
                            '${target.protein} g',
                            'protein / day',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    target.summary,
                    style: const TextStyle(color: _C.body, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _budgetCard(plan),
            const SizedBox(height: 14),
            _preferencesRow(prefs),
            const SizedBox(height: 24),
            _viewTabs(prefs.favorites.length),
            const SizedBox(height: 16),
            if (_favorites) ...[
              if (favorites.isEmpty)
                _empty(
                  prefs.favorites.isEmpty
                      ? 'No favorites yet. Tap the heart on a meal to save it.'
                      : 'Your favorites do not match the current filters. Adjust preferences to see more.',
                  icon: Icons.favorite_border,
                ),
              ...favorites.map((m) => _meal(m)),
            ] else ...[
              if (plan.meals.isEmpty)
                _empty(
                  'No meals match your preferences. Try removing an exclusion.',
                  icon: Icons.no_meals_outlined,
                  action: TextButton(
                    onPressed: _filters,
                    style: TextButton.styleFrom(foregroundColor: gold),
                    child: const Text('Edit preferences'),
                  ),
                ),
              for (final meal in plan.meals) _meal(meal, plan: plan),
              if (plan.meals.isNotEmpty) _totals(plan),
            ],
            const SizedBox(height: 8),
            // Sources and disclaimers grouped in one quiet note.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _C.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: _C.faint,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'ABOUT THESE NUMBERS',
                        style: TextStyle(
                          color: _C.faint,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Grams are for ready-to-eat food (rice and monggo are cooked weight). '
                    'Calories and prices are estimates: market prices vary by place '
                    'and season. This is a general guide, not medical advice. Ask a '
                    'doctor or dietitian if you have a health condition.',
                    style: _T.fine,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Nutrition values are rounded from the DOST-FNRI Philippine Food '
                    'Composition Tables and USDA FoodData Central. Daily targets use '
                    'the Mifflin-St Jeor estimate with your age, height, weight and '
                    'training days.',
                    style: _T.fine,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.only(left: 14, right: 6),
              decoration: BoxDecoration(
                color: _C.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _C.border),
              ),
              child: Row(
                children: [
                  _store.syncing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: gold,
                          ),
                        )
                      : const Icon(Icons.cloud_outlined, color: gold, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _store.status,
                      style: const TextStyle(color: _C.faint, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: _store.syncing ? null : _store.sync,
                    style: TextButton.styleFrom(
                      foregroundColor: gold,
                      minimumSize: const Size(0, 44),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    child: const Text('Sync'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _targetStat(String value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(
          color: _C.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: _C.faint, fontSize: 12)),
    ],
  );

  Widget _empty(String text, {IconData? icon, Widget? action}) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
    decoration: _surface(),
    child: Column(
      children: [
        if (icon != null) ...[
          Icon(icon, color: gold, size: 30),
          const SizedBox(height: 10),
        ],
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _C.body, height: 1.5),
        ),
        if (action != null) ...[const SizedBox(height: 6), action],
      ],
    ),
  );
}
