import 'package:flutter/material.dart';
import '../widgets/onboarding_step_indicator.dart';
import '../models/app_state.dart';
import 'plan_ready_screen.dart';

class WorkoutScheduleScreen extends StatefulWidget {
  const WorkoutScheduleScreen({super.key});

  @override
  State<WorkoutScheduleScreen> createState() => _WorkoutScheduleScreenState();
}

class _WorkoutScheduleScreenState extends State<WorkoutScheduleScreen> {
  // Black + Gold + White + Gray palette
  static const Color _bg = Color(0xFF0A0A0B);
  static const Color _card = Color(0xFF14161B);
  static const Color _border = Color(0xFF2C2F36);
  static const Color _gold = Color(0xFFF5B800);
  static const Color _goldBright = Color(0xFFFFCC1A);
  static const Color _goldLight = Color(0xFFFFD34D);
  static const Color _goldDeep = Color(0xFFE0A100);
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9AA3AE);

  // Aspect ratio ng assets/images/schedule_hero.png (591 x 640)
  static const double _heroWidthFactor = 591 / 841;
  static const double _heroRatio = 640 / 591;

  late final List<String> _selectedDays =
      List<String>.from(AppState.instance.workoutDays);
  final List<String> _weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  late String _selectedDuration = AppState.instance.sessionDuration.isNotEmpty
      ? AppState.instance.sessionDuration
      : '30 min';
  final List<String> _durations = ['15 min', '30 min', '45 min', '60 min', '90 min'];

  void _handleNext() {
    AppState.instance.updateSchedule(_selectedDays, _selectedDuration);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlanReadyScreen()),
    );
  }

  // Small check badge sa kanang-taas ng chip
  Widget _badge({required Color fill, required Color check}) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      child: Icon(Icons.check_rounded, size: 14, color: check),
    );
  }

  Widget _dayChip(String day, double width) {
    final isSelected = _selectedDays.contains(day);
    return GestureDetector(
      onTap: () => setState(() {
        if (isSelected) {
          _selectedDays.remove(day);
        } else {
          _selectedDays.add(day);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: width,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_goldLight, _goldDeep],
                )
              : null,
          color: isSelected ? null : _card,
          border: Border.all(
            color: isSelected ? _goldBright : _border,
            width: isSelected ? 1.4 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                day,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.black : _white,
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: 7,
                right: 8,
                child: _badge(fill: Colors.black, check: _goldBright),
              ),
          ],
        ),
      ),
    );
  }

  Widget _durationChip(String duration, double width) {
    final isSelected = _selectedDuration == duration;
    return GestureDetector(
      onTap: () => setState(() => _selectedDuration = duration),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: width,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? _gold.withValues(alpha: 0.10) : _card,
          border: Border.all(
            color: isSelected ? _goldBright : _border,
            width: isSelected ? 1.6 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                duration,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? _goldBright : _white,
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: 5,
                right: 7,
                child: _badge(fill: _goldBright, check: Colors.black),
              ),
          ],
        ),
      ),
    );
  }

  // Section header: gold ring icon + title + subtitle
  Widget _sectionHeader(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _gold.withValues(alpha: 0.06),
            border: Border.all(color: _gold.withValues(alpha: 0.8), width: 1.4),
          ),
          child: Icon(icon, color: _gold, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: _gray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenW = media.size.width;
    final heroW = screenW * _heroWidthFactor;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Gold diagonal accents sa gilid
          const Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _EdgeAccentPainter())),
          ),

          // 2. Hero: couple sa taas-kanan (walang logo)
          Positioned(
            top: 0,
            right: 0,
            width: heroW,
            height: heroW * _heroRatio,
            child: Image.asset(
              'assets/images/schedule_hero.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),

          // 3. Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button (gold ring)
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.5),
                        border: Border.all(color: _gold, width: 1.4),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: _goldBright,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const FractionallySizedBox(
                    widthFactor: 0.45,
                    alignment: Alignment.centerLeft,
                    child: OnboardingStepIndicator(currentStep: 5, totalSteps: 5),
                  ),
                  const SizedBox(height: 26),

                  // Scrollable na bahagi (title -> chips)
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const gap = 12.0;
                        final chipW = (constraints.maxWidth - gap * 2) / 3;

                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: _white,
                                    letterSpacing: -0.3,
                                    height: 1.2,
                                  ),
                                  children: [
                                    TextSpan(text: 'When can you\n'),
                                    TextSpan(
                                      text: 'work out?',
                                      style: TextStyle(color: _goldBright),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              ConstrainedBox(
                                constraints:
                                    BoxConstraints(maxWidth: screenW * 0.7),
                                child: const Text(
                                  'Choose your days and preferred duration per session.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.35,
                                    color: _gray,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 26),

                              // Days per week
                              _sectionHeader(
                                Icons.calendar_month_rounded,
                                'Days per week',
                                'Select the days you want to work out.',
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: gap,
                                runSpacing: gap,
                                children: [
                                  for (final d in _weekDays) _dayChip(d, chipW),
                                ],
                              ),
                              const SizedBox(height: 28),

                              // Preferred duration
                              _sectionHeader(
                                Icons.schedule_rounded,
                                'Preferred duration',
                                'Choose how long you want each session to be.',
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: gap,
                                runSpacing: gap,
                                children: [
                                  for (final d in _durations)
                                    _durationChip(d, chipW),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Next button (gold gradient)
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
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _gold.withValues(alpha: 0.28),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _handleNext,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Next',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 20,
                                color: Colors.black,
                              ),
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

/// Glowing gold diagonal accents sa kaliwa at kanang gilid
class _EdgeAccentPainter extends CustomPainter {
  const _EdgeAccentPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final line = Paint()
      ..color = const Color(0xFFF5B800)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final glow = Paint()
      ..color = const Color(0x55F5B800)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    void seg(Offset a, Offset b) {
      canvas.drawLine(a, b, glow);
      canvas.drawLine(a, b, line);
    }

    // Kanang gilid
    seg(Offset(w, h * 0.54), Offset(w * 0.90, h * 0.595));
    seg(Offset(w, h * 0.605), Offset(w * 0.94, h * 0.64));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}