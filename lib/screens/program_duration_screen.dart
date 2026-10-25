import 'package:flutter/material.dart';
import '../widgets/onboarding_step_indicator.dart';
import '../models/app_state.dart';
import 'workout_schedule_screen.dart';

class ProgramDurationScreen extends StatefulWidget {
  const ProgramDurationScreen({super.key});

  @override
  State<ProgramDurationScreen> createState() => _ProgramDurationScreenState();
}

class _ProgramDurationScreenState extends State<ProgramDurationScreen> {
  // Black + Gold + White + Gray palette
  static const Color _bg = Color(0xFF0F0F10);
  static const Color _card = Color(0xFF16181C);
  static const Color _border = Color(0xFF2C2F36);
  static const Color _gold = Color(0xFFF5B800);
  static const Color _goldBright = Color(0xFFFFCC1A);
  static const Color _goldLight = Color(0xFFFFD34D);
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9AA3AE);

  // Aspect ratios ng assets (hero: 412 x 640, bottom: 842 x 230)
  static const double _heroRatio = 640 / 412;
  static const double _bottomRatio = 230 / 842;

  final List<Map<String, dynamic>> _options = const [
    {
      'months': 3,
      'title': '3 Months',
      'subtitle': 'Build habit, see early results.',
      'icon': Icons.calendar_month_rounded,
    },
    {
      'months': 6,
      'title': '6 Months',
      'subtitle': 'Make steady progress and build consistency.',
      'icon': Icons.calendar_month_outlined,
    },
    {
      'months': 12,
      'title': '12 Months',
      'subtitle': 'Reach long-term goals and transform.',
      'icon': Icons.event_repeat_rounded,
    },
  ];

  late int _selectedMonths;

  @override
  void initState() {
    super.initState();
    // Kunin ang naka-save na value, tapos i-snap sa pinakamalapit na option (3, 6, 12)
    final saved = AppState.instance.programDurationMonths;
    _selectedMonths = _options
        .map<int>((o) => o['months'] as int)
        .reduce((a, b) => (a - saved).abs() <= (b - saved).abs() ? a : b);
  }

  void _handleNext() {
    AppState.instance.updateDuration(_selectedMonths);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WorkoutScheduleScreen()),
    );
  }

  Widget _icon(IconData icon, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? _gold.withValues(alpha: 0.12)
            : const Color(0xFF23262B),
        border: Border.all(
          color: isSelected ? _gold.withValues(alpha: 0.55) : _border,
          width: 1.4,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 32,
        color: isSelected ? _gold : const Color(0xFFC7CCD3),
      ),
    );
  }

  Widget _selector(bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? _gold : Colors.transparent,
        border: Border.all(
          color: isSelected ? _gold : const Color(0xFF5A606A),
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check_rounded, color: _bg, size: 19)
          : null,
    );
  }

  Widget _optionCard(Map<String, dynamic> option, int index) {
    final int months = option['months'];
    final bool isSelected = _selectedMonths == months;

    final card = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selectedMonths = months),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: 108,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    _gold.withValues(alpha: 0.12),
                    _card,
                  ],
                )
              : null,
          color: isSelected ? null : _card,
          border: Border.all(
            color: isSelected ? _gold : _border,
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.22),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : const [],
        ),
        child: Row(
          children: [
            _icon(option['icon'], isSelected),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option['title'],
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: _white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option['subtitle'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
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
    );

    // Sunod-sunod na fade + slide up pagpasok
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 450 + index * 130),
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
    final heroWidth = media.size.width * 0.49;
    final bottomDecoHeight = media.size.width * _bottomRatio;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Hero na babae sa taas-kanan (may gold glow)
          Positioned(
            top: 0,
            right: 0,
            width: heroWidth,
            height: heroWidth * _heroRatio,
            child: Image.asset(
              'assets/images/duration_hero.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),

          // 2. Wavy gold line + dumbbell sa ibaba
          Positioned(
            left: 0,
            right: 0,
            bottom: media.padding.bottom + 16 + 60 + 4,
            height: bottomDecoHeight,
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/duration_bottom.png',
                fit: BoxFit.fitWidth,
                alignment: Alignment.bottomCenter,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),

          // 3. Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D1F24),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: _white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  const FractionallySizedBox(
                    widthFactor: 0.62,
                    alignment: Alignment.centerLeft,
                    child: OnboardingStepIndicator(currentStep: 4, totalSteps: 5),
                  ),
                  const SizedBox(height: 40),

                  // Title
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: _white,
                        letterSpacing: -0.5,
                        height: 1.25,
                      ),
                      children: [
                        TextSpan(text: 'How many months for\nyour '),
                        TextSpan(
                          text: 'fitness program?',
                          style: TextStyle(color: _goldBright),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: media.size.width * 0.78,
                    ),
                    child: const Text(
                      'Set your target timeline for progress tracking and AI adaptation.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: _gray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Duration cards
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        for (var i = 0; i < _options.length; i++)
                          _optionCard(_options[i], i),
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