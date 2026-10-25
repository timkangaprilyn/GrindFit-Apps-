import 'package:flutter/material.dart';
import '../widgets/onboarding_step_indicator.dart';
import '../models/app_state.dart';
import 'program_duration_screen.dart';

class WorkoutEnvironmentScreen extends StatefulWidget {
  const WorkoutEnvironmentScreen({super.key});

  @override
  State<WorkoutEnvironmentScreen> createState() =>
      _WorkoutEnvironmentScreenState();
}

class _WorkoutEnvironmentScreenState extends State<WorkoutEnvironmentScreen> {
  // Black + Gold + White + Gray palette
  static const Color _bg = Color(0xFF050505);
  static const Color _card = Color(0xFF1C1C1E);
  static const Color _border = Color(0xFF3A3A3E);
  static const Color _gold = Color(0xFFF5B800);
  static const Color _goldLight = Color(0xFFFFD34D);
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFFB4B8BF);

  // Aspect ratio ng assets/images/env_hero.png (842 x 760)
  static const double _heroRatio = 760 / 842;

  late String _selectedEnvironment;

  // Updated environments to include Gym, Home (no equipment), and Outdoor[cite: 3]
  final List<Map<String, dynamic>> _environments = const [
    {
      'title': 'Gym',
      'subtitle': 'Full access to professional machines and heavy weights.',
      'icon': Icons.fitness_center_rounded,
      'image': 'assets/images/env_indoor.png',
    },
    {
      'title': 'Home (no equipment)',
      'subtitle': 'Bodyweight workouts optimized for your living space.',
      'icon': Icons.home_rounded,
      'image': 'assets/images/env_indoor.png',
    },
    {
      'title': 'Outdoor',
      'subtitle': 'Enjoy fresh air, parks, and open spaces.',
      'icon': Icons.park_rounded,
      'image': 'assets/images/env_outdoor.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedEnvironment = AppState.instance.workoutEnvironment.isNotEmpty
        ? AppState.instance.workoutEnvironment
        : 'Gym';
  }

  void _handleNext() {
    AppState.instance.updateEnvironment(_selectedEnvironment);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProgramDurationScreen()),
    );
  }

  // Icon sa loob ng gold ring
  Widget _envIcon(IconData icon, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        shape: BoxShape.circle,
        border: Border.all(
          color: _gold.withValues(alpha: isSelected ? 0.9 : 0.5),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: _gold, size: 30),
    );
  }

  // Check / radio sa kanan
  Widget _selector(bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isSelected ? _gold : Colors.black.withValues(alpha: 0.35),
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? _gold : const Color(0xFF5A5A60),
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check_rounded, color: _bg, size: 19)
          : null,
    );
  }

  Widget _envCard(Map<String, dynamic> env, int index) {
    final String title = env['title'];
    final isSelected = _selectedEnvironment == title;
    const radius = 22.0;

    final card = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selectedEnvironment = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: 140,
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: isSelected ? _gold : _border,
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : const [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 1),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo background
              Image.asset(
                env['image'],
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1C1C1E), Color(0xFF2A2A2D)],
                    ),
                  ),
                ),
              ),

              // Dark overlay (kaliwa -> kanan) para mabasa ang text
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xE6000000), Color(0x40000000)],
                  ),
                ),
              ),

              // Dagdag dim kapag hindi napili
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isSelected ? 0 : 1,
                child: const ColoredBox(color: Color(0x4D000000)),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    _envIcon(env['icon'], isSelected),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            env['subtitle'],
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.3,
                              color: _gray,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _selector(isSelected),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Fade + slide up pagpasok, sunod-sunod
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 450 + index * 150),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        ),
        child: card,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final heroHeight = media.size.width * _heroRatio;
    final topGap =
        (media.size.height * 0.24 - media.padding.top - 42).clamp(12.0, 220.0);

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Hero photo sa taas
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight,
            child: Image.asset(
              'assets/images/env_hero.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),

          // 2. Fade papuntang black sa ibaba ng hero
          Positioned(
            top: heroHeight - 160,
            left: 0,
            right: 0,
            height: 160,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00050505), Color(0xFF050505)],
                ),
              ),
            ),
          ),

          // 3. Subtle gold diagonal sa ibaba
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _BottomAccentPainter()),
            ),
          ),

          // 4. Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
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

                  SizedBox(height: topGap),

                  const FractionallySizedBox(
                    widthFactor: 0.62,
                    alignment: Alignment.centerLeft,
                    child: OnboardingStepIndicator(currentStep: 3, totalSteps: 5),
                  ),
                  const SizedBox(height: 22),

                  // Title
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: _white,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                      children: [
                        TextSpan(text: 'Where do you prefer\nto '),
                        TextSpan(
                          text: 'work out?',
                          style: TextStyle(color: _gold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Choose your workout environment.',
                    style: TextStyle(
                      fontSize: 15,
                      color: _gray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Environment cards
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        for (var i = 0; i < _environments.length; i++)
                          _envCard(_environments[i], i),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Next button (gold pill)
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: Material(
                      color: Colors.transparent,
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [_goldLight, _gold],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: _gold.withValues(alpha: 0.3),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: _handleNext,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Next',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: _bg,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_forward_rounded,
                                  color: _bg, size: 22),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Faint gold diagonal accents sa ilalim ng screen
class _BottomAccentPainter extends CustomPainter {
  const _BottomAccentPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()..color = const Color(0x14FFC107);

    final p1 = Path()
      ..moveTo(w * 0.55, h)
      ..lineTo(w, h * 0.78)
      ..lineTo(w, h * 0.85)
      ..lineTo(w * 0.72, h)
      ..close();
    canvas.drawPath(p1, paint);

    final p2 = Path()
      ..moveTo(w * 0.78, h)
      ..lineTo(w, h * 0.90)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(p2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}