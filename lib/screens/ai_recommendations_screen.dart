import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_state.dart';
import '../models/workout_plan.dart';
import 'rest_day_screen.dart';
import 'manual_log_workout_screen.dart';
import '../widgets/workout_image.dart';
import '../widgets/exercise_actions.dart';
import '../services/offline_store.dart';
import '../services/ai_workout_service.dart';

class AiRecommendationsScreen extends StatefulWidget {
  const AiRecommendationsScreen({super.key});

  @override
  State<AiRecommendationsScreen> createState() =>
      _AiRecommendationsScreenState();
}

class _AiRecommendationsScreenState extends State<AiRecommendationsScreen> {
  final TextEditingController _requestController = TextEditingController();
  bool _saving = false;
  static const _focuses = [
    'Full Body',
    'Upper Body',
    'Lower Body',
    'Chest at Triceps',
    'Back at Biceps',
    'Shoulders',
    'Legs at Glutes',
    'Core',
    'Cardio',
    'No Equipment',
    'Limited Mobility',
  ];
  // Black + Gold + White palette
  static const Color _bg = Color(0xFF121212); // Charcoal background
  static const Color _card = Color(0xFF1C1C1E); // Card surface
  static const Color _border = Color(0xFF2E2E31);
  static const Color _gold = Color(0xFFF5B800); // Gold highlight
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9CA3AF); // Secondary text

  int _selectedTab = 0; // 0: Today, 1: This Week, 2: Next Week

  @override
  void initState() {
    super.initState();
    _requestController.text = AppState.instance.workoutRequest;
    AppState.instance.addListener(_refreshForAppStateChanges);
  }

  @override
  void dispose() {
    _requestController.dispose();
    AppState.instance.removeListener(_refreshForAppStateChanges);
    super.dispose();
  }

  void _refreshForAppStateChanges() {
    if (mounted) setState(() {});
  }

  Future<void> _savePreferences(Map<String, dynamic> values) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await OfflineStore.instance.saveProfile(values);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save preferences on this device.'),
          ),
        );
      }
    }
  }

  Future<void> _saveBuilder(
    String focus, {
    bool generate = false,
    bool offline = false,
  }) async {
    if (_saving) return;
    final request = _requestController.text.trim();
    if (request.length > 500) return;
    setState(() => _saving = true);
    AppState.instance.updateWorkoutRequest(request, focus);
    await _savePreferences({'workoutRequest': request, 'workoutFocus': focus});
    if (offline) await _useOfflineWorkout();
    if (generate) {
      try {
        final generated = await AiWorkoutService().generate().timeout(
          const Duration(seconds: 8),
        );
        final state = AppState.instance;
        state.setGeneratedPlan(generated.plan, 'AI-generated plan');
        await _savePreferences({
          'generatedPlan': generated.plan.map((e) => e.toMap()).toList(),
          'generatedContext': state.generatedContext,
          'planSource': state.planSource,
          'exerciseSwaps': <String, String>{},
        });
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(generated.reason)));
        }
      } catch (_) {
        await _useOfflineWorkout(automatic: true);
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _useOfflineWorkout({bool automatic = false}) async {
    final state = AppState.instance;
    state.useOfflineWorkout();
    await _savePreferences({
      'generatedPlan': <Map<String, dynamic>>[],
      'generatedContext': '',
      'planSource': state.planSource,
      'exerciseSwaps': <String, String>{},
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          automatic
              ? 'Online AI is unavailable. Your personalized offline workout is ready.'
              : 'Your personalized offline workout is ready. No internet needed.',
        ),
      ),
    );
  }

  Future<void> _showCheckIn() async {
    var sleep = AppState.instance.sleepHours;
    var energy = AppState.instance.energyLevel;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _card,
          title: const Text('Daily check-in', style: TextStyle(color: _white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sleep: $sleep hours',
                style: const TextStyle(color: _white),
              ),
              Slider(
                value: sleep.toDouble(),
                min: 0,
                max: 12,
                divisions: 12,
                onChanged: (v) => setDialogState(() => sleep = v.round()),
              ),
              Text(
                'Energy: $energy / 5',
                style: const TextStyle(color: _white),
              ),
              Slider(
                value: energy.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                onChanged: (v) => setDialogState(() => energy = v.round()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    AppState.instance.updateCheckIn(sleep, energy);
    await _savePreferences({
      'sleepHours': sleep,
      'energyLevel': energy,
      'checkInDate': AppState.instance.checkInDate,
    });
  }

  Future<void> _showSwap(PlanExercise exercise) async {
    final choices = WorkoutPlan.alternativesFor(
      exercise,
      environment: AppState.instance.workoutEnvironment,
    );
    if (choices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No matching alternative in this workout setting.'),
        ),
      );
      return;
    }
    final choice = await showModalBottomSheet<PlanExercise>(
      context: context,
      backgroundColor: _card,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text('Replace exercise', style: TextStyle(color: _gold)),
            ),
            for (final option in choices)
              ListTile(
                title: Text(option.name, style: const TextStyle(color: _white)),
                subtitle: Text(
                  '${option.muscles} • ${option.equipment}',
                  style: const TextStyle(color: _gray),
                ),
                onTap: () => Navigator.pop(context, option),
              ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    AppState.instance.swapExercise(exercise.name, choice.name);
    await _savePreferences({'exerciseSwaps': AppState.instance.exerciseSwaps});
  }

  void _showFormGuide(PlanExercise exercise) =>
      showExerciseForm(context, exercise);

  @override
  Widget build(BuildContext context) {
    final int currentDay = AppState.instance.currentDayIndex;

    // Consistent default goal across screens
    final String goal = AppState.instance.fitnessGoal.isNotEmpty
        ? AppState.instance.fitnessGoal
        : "Muscle Gain / Strength";
    final exercises = AppState.instance.recommendedPlan;

    // Alamin kung pwede pang mag-pop (kung binuksan ito mula sa ibang screen gaya ng notification)
    final bool canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        elevation: 0,
        // Mag-aadjust ang leading depende kung galing sa push navigation o tab
        automaticallyImplyLeading: canPop,
        leading: canPop
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _white,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'AI Workout Recommendations',
          style: TextStyle(
            color: _white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: _border, height: 1.0),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -140,
            right: -120,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _gold.withValues(alpha: 0.15),
                    _gold.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPersonalization(),
                  const SizedBox(height: 20),
                  _buildMealSuggestions(goal),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _gold.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _gold.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Goal: $goal',
                                style: const TextStyle(
                                  color: _gold,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${WorkoutPlan.titleForGoal(goal)} is tailored to your goal and workout setting.',
                          style: const TextStyle(
                            color: _gray,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Program Progress: Day $currentDay Active',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: _white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RestDayScreen(),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border, width: 1.2),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.self_improvement_rounded,
                                color: _gold,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'View Rest Day / Recovery Mode',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _white,
                                ),
                              ),
                            ],
                          ),
                          Icon(Icons.chevron_right, color: _gold),
                        ],
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _selectedTab == 0 ? _gold : _card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedTab == 0 ? _gold : _border,
                              ),
                            ),
                            child: Text(
                              'Today',
                              style: TextStyle(
                                color: _selectedTab == 0 ? _bg : _white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _selectedTab == 1 ? _gold : _card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedTab == 1 ? _gold : _border,
                              ),
                            ),
                            child: Text(
                              'This Week',
                              style: TextStyle(
                                color: _selectedTab == 1 ? _bg : _white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _selectedTab == 2 ? _gold : _card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedTab == 2 ? _gold : _border,
                              ),
                            ),
                            child: Text(
                              'Next Week',
                              style: TextStyle(
                                color: _selectedTab == 2 ? _bg : _white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Day $currentDay - Your Workout',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: _white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final exercise in exercises) ...[
                    _buildExerciseCard(exercise),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(PlanExercise exercise) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 64,
              height: 64,
              child: WorkoutImage(
                imageUrl: exercise.imageUrl ?? '',
                backgroundColor: _bg,
                iconColor: _gold,
                iconSize: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  exercise.detail,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _gold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${exercise.muscles} • ${exercise.equipment}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _gray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: _gold),
                tooltip: 'Log this exercise',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManualLogWorkoutScreen(exercise: exercise),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.swap_horiz, color: _gold),
                tooltip: 'Replace exercise',
                onPressed: () => _showSwap(exercise),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, color: _gray),
                tooltip: 'Form guide',
                onPressed: () => _showFormGuide(exercise),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalization() {
    final state = AppState.instance;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Build your workout',
            style: TextStyle(
              color: _white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Uses your ${state.workoutEnvironment} setting, ${state.workoutDays.length} days/week and ${state.sessionDuration} sessions.',
            style: const TextStyle(color: _gray),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _requestController,
            maxLength: 500,
            maxLines: 3,
            style: const TextStyle(color: _white),
            decoration: const InputDecoration(
              hintText: 'Describe your goal or limits in your own words',
            ),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 2,
            children: [
              for (final focus in _focuses)
                ChoiceChip(
                  label: Text(focus),
                  selected: state.workoutFocus == focus,
                  onSelected: (_) => _saveBuilder(focus),
                ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _saving
                ? null
                : () => _saveBuilder(state.workoutFocus, generate: true),
            child: Text(_saving ? 'Building…' : 'Generate workout'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _saving
                ? null
                : () => _saveBuilder(state.workoutFocus, offline: true),
            icon: const Icon(Icons.offline_bolt_outlined),
            label: const Text('Use offline workout'),
          ),
          const Text(
            'Offline recommendations use your goal, equipment, focus and daily check-in. Online AI falls back automatically when unavailable.',
            style: TextStyle(color: _gray, fontSize: 12),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _showCheckIn,
            icon: const Icon(Icons.bedtime_outlined),
            label: Text(
              state.checkInDate ==
                      DateTime.now().toLocal().toIso8601String().substring(
                        0,
                        10,
                      )
                  ? 'Sleep ${state.sleepHours}h • Energy ${state.energyLevel}/5'
                  : 'Daily sleep and energy check-in',
            ),
          ),
          if (state.needsRecovery)
            const Text(
              'Low sleep or energy today: a gentle mobility session is recommended.',
              style: TextStyle(color: _gold),
            ),
          if (state.adaptationReason.isNotEmpty)
            Text(state.adaptationReason, style: const TextStyle(color: _gold)),
          const SizedBox(height: 6),
          Text(
            state.generatedContext == state.planContext
                ? state.planSource
                : 'On-device plan • Available offline',
            style: const TextStyle(color: _gray, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSuggestions(String goal) {
    final weightLoss = goal.toLowerCase().contains('loss');
    final strength =
        goal.toLowerCase().contains('muscle') ||
        goal.toLowerCase().contains('strength');
    final meals = weightLoss
        ? const [
            'Breakfast: boiled egg, banana, and water',
            'Lunch: grilled chicken, vegetables, and rice',
            'Dinner: tofu and vegetable stir-fry',
          ]
        : strength
        ? const [
            'Breakfast: eggs, rice, and banana',
            'Lunch: chicken adobo, rice, and vegetables',
            'Dinner: tofu, munggo, and rice',
          ]
        : const [
            'Breakfast: egg, pandesal, and banana',
            'Lunch: monggo with malunggay and rice',
            'Dinner: chicken, vegetables, and rice',
          ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Budget-friendly Pinoy meals',
            style: TextStyle(
              color: _white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text('Simple ideas for $goal', style: const TextStyle(color: _gray)),
          const SizedBox(height: 8),
          for (final meal in meals)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text('• $meal', style: const TextStyle(color: _white)),
            ),
          const Text(
            'Adjust portions to your needs, allergies, and budget.',
            style: TextStyle(color: _gray, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
