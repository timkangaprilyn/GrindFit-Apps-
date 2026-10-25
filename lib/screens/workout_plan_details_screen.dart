import 'package:flutter/material.dart';

// Standalone models para hindi makadamay sa ibang files
class DetailsPlanExercise {
  final String name;
  final String detail;
  final String repsLabel;
  final String muscles;
  final String equipment;
  final String? imageUrl;

  const DetailsPlanExercise({
    required this.name,
    required this.detail,
    required this.repsLabel,
    required this.muscles,
    required this.equipment,
    this.imageUrl,
  });
}

class WorkoutDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> workoutData;

  const WorkoutDetailsScreen({
    super.key,
    required this.workoutData,
  });

  // Black + Gold + White + Gray palette
  static const Color _bg = Color(0xFF121212);
  static const Color _card = Color(0xFF1C1C1E);
  static const Color _tile = Color(0xFF2A2A2D);
  static const Color _border = Color(0xFF2E2E31);
  static const Color _gold = Color(0xFFF5B800);
  static const Color _goldBright = Color(0xFFFFCC1A);
  static const Color _goldLight = Color(0xFFFFD34D);
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9CA3AF);
  static const Color _muted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final String title = workoutData['title'] ?? workoutData['workoutName'] ?? 'Workout Session';
    final String date = workoutData['date'] ?? 'Recent Date';
    final String category = workoutData['category'] ?? 'Gym';
    final String duration = workoutData['duration'] ?? '45 min';
    final String intensity = workoutData['intensity'] ?? 'Moderate';
    final String notes = workoutData['notes'] ?? '';

    // Listahan ng exercises na nagpapakita ng Sets, Reps, at Weight
    final List<Map<String, dynamic>> exercises = (workoutData['exercises'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [
          {
            'name': 'Push Up',
            'sets': 3,
            'reps': 10,
            'weight': 'Bodyweight',
          },
          {
            'name': 'Dumbbell Row',
            'sets': 3,
            'reps': 10,
            'weight': '12 kg',
          },
          {
            'name': 'Shoulder Press',
            'sets': 3,
            'reps': 10,
            'weight': '10 kg',
          },
        ];

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        leadingWidth: 68,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _white,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          'Workout Details',
          style: TextStyle(
            color: _white,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
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
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  _buildHeaderCard(title, date, category),
                  const SizedBox(height: 16),

                  // Overview Stats
                  Row(
                    children: [
                      _buildOverviewTile(Icons.timer_outlined, 'Duration', duration),
                      const SizedBox(width: 10),
                      _buildOverviewTile(Icons.bolt_rounded, 'Intensity', intensity),
                      const SizedBox(width: 10),
                      _buildOverviewTile(Icons.fitness_center_rounded, 'Exercises', '${exercises.length}'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Exercises Completed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Listahan ng mga Exercises (Sets, Reps, Weight)
                  for (int i = 0; i < exercises.length; i++) ...[
                    _buildExerciseTile(i + 1, exercises[i]),
                    if (i != exercises.length - 1) const SizedBox(height: 12),
                  ],

                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Session Notes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                      ),
                      child: Text(
                        notes,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _gray,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(String title, String date, String category) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _gold.withValues(alpha: 0.35), width: 1.2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(_gold.withValues(alpha: 0.14), _card),
            _card,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_goldLight, _gold],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.check_circle_rounded, color: Colors.black, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: _goldBright,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: _muted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: _gray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTile(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            Icon(icon, color: _gold, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: _white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: _gray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseTile(int index, Map<String, dynamic> exercise) {
    final String name = exercise['name'] ?? 'Exercise';
    final int sets = exercise['sets'] ?? 3;
    final int reps = exercise['reps'] ?? 10;
    final String weight = (exercise['weight'] != null && exercise['weight'].toString().isNotEmpty)
        ? exercise['weight'].toString()
        : 'Bodyweight';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: _goldBright,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: _white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$sets sets • $reps reps',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: _gray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _tile,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: Text(
              weight,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _goldBright,
              ),
            ),
          ),
        ],
      ),
    );
  }
}