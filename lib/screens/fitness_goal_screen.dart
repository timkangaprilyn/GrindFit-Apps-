import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/onboarding_step_indicator.dart';
import '../models/app_state.dart';
import 'workout_environment_screen.dart';

class FitnessGoalScreen extends StatefulWidget {
  const FitnessGoalScreen({super.key});

  @override
  State<FitnessGoalScreen> createState() => _FitnessGoalScreenState();
}

class _FitnessGoalScreenState extends State<FitnessGoalScreen> {
  static const Color _bg = Color(0xFF050505);
  static const Color _card = Color(0xFF18181A);
  static const Color _border = Color(0xFF2A2A2D);
  static const Color _checkBorder = Color(0xFF3F3F44);
  static const Color _gold = Color(0xFFF5B800);
  static const Color _goldLight = Color(0xFFFFD34D);
  static const Color _iconColor = Color(0xFFFF9F0A);
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9CA3AF);

  late String _selectedGoal = AppState.instance.fitnessGoal;

  // 'kind': run -> Material icon, emoji -> 💪, heart -> custom heart-pulse,
  // dumbbell -> custom horizontal dumbbell
  // Getter ito (hindi field) para laging updated kahit hot reload.
  List<Map<String, String>> get _goals => const [
        {
          'title': 'Weight Loss',
          'subtitle': 'Get leaner and healthier.',
          'kind': 'run',
        },
        {
          'title': 'Muscle Gain / Strength',
          'subtitle': 'Build muscle and get stronger.',
          'kind': 'emoji',
        },
        {
          'title': 'Endurance / Cardio',
          'subtitle': 'Improve stamina and endurance.',
          'kind': 'heart',
        },
        {
          'title': 'General Fitness',
          'subtitle': 'Improve overall fitness and well-being.',
          'kind': 'dumbbell',
        },
      ];

  void _select(String title) {
    if (_selectedGoal == title) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedGoal = title);
  }

  void _handleNext() {
    AppState.instance.updateGoal(_selectedGoal);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WorkoutEnvironmentScreen()),
    );
  }

  Widget _iconGlyph(String? kind) {
    switch (kind) {
      case 'emoji':
        return const Text('💪', style: TextStyle(fontSize: 26));
      case 'heart':
        return const CustomPaint(
          size: Size(30, 28),
          painter: _HeartPulsePainter(color: _iconColor, pulseColor: _card),
        );
      case 'dumbbell':
        return const CustomPaint(
          size: Size(32, 22),
          painter: _DumbbellPainter(color: _iconColor),
        );
      default:
        return const Icon(Icons.directions_run_rounded,
            color: _iconColor, size: 30);
    }
  }

  Widget _goalIcon(Map<String, String> goal, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: isSelected ? _gold.withAlpha(40) : const Color(0xFF2A2A2D),
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? _gold.withAlpha(120) : Colors.transparent,
        ),
      ),
      alignment: Alignment.center,
      child: _iconGlyph(goal['kind']),
    );
  }

  Widget _goalCard(Map<String, String> goal, int index) {
    final isSelected = _selectedGoal == goal['title'];

    final card = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _select(goal['title'] ?? ''),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: isSelected
                  ? [_card, Color.alphaBlend(_gold.withAlpha(34), _card)]
                  : const [_card, _card],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? _gold : _border,
              width: isSelected ? 1.6 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _gold.withAlpha(45),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            children: [
              _goalIcon(goal, isSelected),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      goal['subtitle'] ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _gray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? _gold : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? _gold : _checkBorder,
                    width: 1.8,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: _bg, size: 15)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );

    // Fade + slide-up pagbukas ng screen (isa-isa ang cards)
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index * 90),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - v)),
          child: child,
        ),
      ),
      child: card,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Hero image — nakadikit sa kanang taas, may sariling gold glow at fade
          Positioned(
            top: 0,
            right: 0,
            width: size.width * 0.35,
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/goal_hero.png',
                fit: BoxFit.fitWidth,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF111113),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _border),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: _white,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const FractionallySizedBox(
                    widthFactor: 0.55,
                    alignment: Alignment.centerLeft,
                    child:
                        OnboardingStepIndicator(currentStep: 2, totalSteps: 5),
                  ),
                  const SizedBox(height: 26),

                  // Title na may gold na "goal?" at kurbadong underline
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "What's your ",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: _white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Text(
                            'goal?',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: _gold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Positioned(
                            left: 6,
                            right: 0,
                            bottom: -5,
                            child: CustomPaint(
                              size: const Size(double.infinity, 6),
                              painter: _UnderlinePainter(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Select your primary fitness goal.',
                    style: TextStyle(
                      fontSize: 14,
                      color: _gray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 22),

                  for (int i = 0; i < _goals.length; i++)
                    _goalCard(_goals[i], i),

                  const SizedBox(height: 14),

                  // Next button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Material(
                      color: Colors.transparent,
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [_goldLight, _gold],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _gold.withAlpha(70),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _handleNext,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Next',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: _bg,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_forward, color: _bg, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Heart + pulse icon (Endurance / Cardio) ----------
class _HeartPulsePainter extends CustomPainter {
  final Color color;
  final Color pulseColor;

  const _HeartPulsePainter({required this.color, required this.pulseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final heart = Path()
      ..moveTo(w * 0.5, h * 0.96)
      ..cubicTo(w * 0.05, h * 0.62, w * -0.02, h * 0.22, w * 0.25, h * 0.08)
      ..cubicTo(w * 0.38, h * 0.01, w * 0.48, h * 0.08, w * 0.5, h * 0.22)
      ..cubicTo(w * 0.52, h * 0.08, w * 0.62, h * 0.01, w * 0.75, h * 0.08)
      ..cubicTo(w * 1.02, h * 0.22, w * 0.95, h * 0.62, w * 0.5, h * 0.96)
      ..close();

    canvas.drawPath(heart, Paint()..color = color);

    // Pulse line (naka-clip sa loob ng puso)
    canvas.save();
    canvas.clipPath(heart);
    final pulse = Path()
      ..moveTo(w * 0.0, h * 0.50)
      ..lineTo(w * 0.34, h * 0.50)
      ..lineTo(w * 0.44, h * 0.30)
      ..lineTo(w * 0.57, h * 0.74)
      ..lineTo(w * 0.66, h * 0.50)
      ..lineTo(w * 1.0, h * 0.50);
    canvas.drawPath(
      pulse,
      Paint()
        ..color = pulseColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HeartPulsePainter old) =>
      old.color != color || old.pulseColor != pulseColor;
}

// ---------- Horizontal dumbbell icon (General Fitness) ----------
class _DumbbellPainter extends CustomPainter {
  final Color color;

  const _DumbbellPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = color;

    RRect box(double l, double t, double r, double b, double radius) =>
        RRect.fromLTRBR(l * w, t * h, r * w, b * h, Radius.circular(radius));

    // Bar sa gitna
    canvas.drawRRect(box(0.18, 0.40, 0.82, 0.60, 1.5), paint);

    // Inner plates
    canvas.drawRRect(box(0.14, 0.08, 0.27, 0.92, 2.5), paint);
    canvas.drawRRect(box(0.73, 0.08, 0.86, 0.92, 2.5), paint);

    // Outer plates
    canvas.drawRRect(box(0.02, 0.26, 0.11, 0.74, 2.0), paint);
    canvas.drawRRect(box(0.89, 0.26, 0.98, 0.74, 2.0), paint);
  }

  @override
  bool shouldRepaint(covariant _DumbbellPainter old) => old.color != color;
}

// ---------- Kurbadong underline sa "goal?" ----------
class _UnderlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF5B800)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 1.25,
        size.width,
        size.height * 0.1,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}