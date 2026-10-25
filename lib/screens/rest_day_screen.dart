import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'home_dashboard_screen.dart';
import 'ai_recommendations_screen.dart';
import 'log_workout_screen.dart';
import 'analytics_dashboard_screen.dart';

class RestDayScreen extends StatefulWidget {
  const RestDayScreen({super.key});

  @override
  State<RestDayScreen> createState() => _RestDayScreenState();
}

class _RestDayScreenState extends State<RestDayScreen>
    with SingleTickerProviderStateMixin {
  // Black + Gold + White + Gray palette (kapareho ng ibang screens)
  static const Color _bg = Color(0xFF121212);
  static const Color _card = Color(0xFF1C1C1E);
  static const Color _tile = Color(0xFF2A2A2D);
  static const Color _border = Color(0xFF2E2E31);
  static const Color _gold = Color(0xFFF5B800);
  static const Color _goldBright = Color(0xFFFFCC1A);
  static const Color _goldLight = Color(0xFFFFD34D);
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9CA3AF);

  int _currentIndex = 1; // Naka-align sa Workouts tab

  // FIX: "late final" na may initializer (lazy) imbes na sa initState.
  // Dati, kapag nag-hot reload ka, hindi na tumatakbo ulit ang initState kaya
  // "LateInitializationError: _pulse has not been initialized" ang lumalabas.
  // Ngayon, automatic na magagawa ito sa unang gamit kahit hot reload.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  // Mga naka-check na tips (pwedeng i-tap)
  final Set<int> _done = <int>{};

  final List<Map<String, dynamic>> _tips = const [
    {
      'icon': Icons.bedtime_rounded,
      'text': 'Take a rest day',
      'sub': 'Skip intense training today.',
    },
    {
      'icon': Icons.water_drop_rounded,
      'text': 'Stay hydrated',
      'sub': 'Sip water throughout the day.',
    },
    {
      'icon': Icons.self_improvement_rounded,
      'text': 'Do light stretching',
      'sub': '5–10 minutes of gentle mobility.',
    },
  ];

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  // Sunod-sunod na fade + slide up pagpasok
  Widget _reveal(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 450 + index * 90),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 22 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String today = DateFormat('EEE, MMM d').format(DateTime.now());

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Gold glow sa taas
          Positioned(
            top: -160,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 440,
                height: 440,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _gold.withValues(alpha: 0.20),
                      _gold.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.maybePop(context),
                      child: Container(
                        width: 44,
                        height: 44,
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
                  const SizedBox(height: 10),

                  // Recovery hero icon (may pulsing gold rings)
                  _reveal(0, _buildHeroIcon()),
                  const SizedBox(height: 22),

                  // Title and subtitle
                  _reveal(
                    1,
                    Column(
                      children: [
                        const Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Rest Day ',
                                style: TextStyle(color: _goldBright),
                              ),
                              TextSpan(text: 'Reminder'),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: _white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Your body needs time to recover\nand get stronger.',
                          style: TextStyle(
                            fontSize: 15,
                            color: _gray,
                            fontWeight: FontWeight.w500,
                            height: 1.45,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),

                  // Rest Day badge card
                  _reveal(2, _buildBadgeCard(today)),
                  const SizedBox(height: 28),

                  // For better results
                  _reveal(3, _buildTipsSection()),
                  const SizedBox(height: 20),

                  // Modify your workout
                  _reveal(4, _buildModifyCard()),
                  const SizedBox(height: 28),

                  // Get It button
                  _reveal(5, _buildGetItButton()),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ───────────────────────── Hero icon ─────────────────────────

  Widget _buildHeroIcon() {
    return SizedBox(
      width: 200,
      height: 200,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_pulse.value);
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Outer ring
              Transform.scale(
                scale: 1.0 + 0.06 * t,
                child: Container(
                  width: 196,
                  height: 196,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _gold.withValues(alpha: 0.10 + 0.10 * t),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              // Middle glow ring
              Transform.scale(
                scale: 1.0 + 0.04 * t,
                child: Container(
                  width: 154,
                  height: 154,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _gold.withValues(alpha: 0.24 + 0.10 * t),
                        _gold.withValues(alpha: 0.04),
                      ],
                    ),
                    border: Border.all(
                      color: _gold.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              // Inner icon
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _card,
                  border: Border.all(color: _gold, width: 1.6),
                  boxShadow: [
                    BoxShadow(
                      color: _gold.withValues(alpha: 0.35),
                      blurRadius: 28,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.self_improvement_rounded,
                  size: 58,
                  color: _goldBright,
                ),
              ),
              // Maliliit na kumikislap na sparkle
              Positioned(
                top: 16,
                right: 22,
                child: Opacity(
                  opacity: 0.55 + 0.45 * t,
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: _goldLight, size: 20),
                ),
              ),
              Positioned(
                bottom: 30,
                left: 18,
                child: Opacity(
                  opacity: 1.0 - 0.45 * t,
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: _gold, size: 13),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ───────────────────────── Badge card ─────────────────────────

  Widget _buildBadgeCard(String today) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color.alphaBlend(_gold.withValues(alpha: 0.18), _card),
            _card,
          ],
        ),
        border: Border.all(color: _gold.withValues(alpha: 0.45), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_goldLight, _gold],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.event_available_rounded,
                color: Colors.black, size: 25),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rest Day',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _white,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: _goldBright, size: 12),
                    const SizedBox(width: 6),
                    Text(
                      today,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _goldBright,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _gold.withValues(alpha: 0.35)),
            ),
            child: const Text(
              'RECOVERY',
              style: TextStyle(
                fontSize: 10.5,
                letterSpacing: 1.4,
                color: _goldBright,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Tips ─────────────────────────

  Widget _buildTipsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'For better results:',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: _white,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: _done.isEmpty ? 0.08 : 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_done.length}/${_tips.length} done',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _goldBright,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Material para makita ang ripple ng InkWell sa loob ng card
        Material(
          color: _card,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _border, width: 1.2),
          ),
          child: Column(
            children: [
              for (var i = 0; i < _tips.length; i++) ...[
                _buildTipRow(i),
                if (i != _tips.length - 1)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: _border.withValues(alpha: 0.8),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipRow(int index) {
    final tip = _tips[index];
    final bool done = _done.contains(index);

    return InkWell(
      onTap: () => setState(() {
        if (!_done.add(index)) _done.remove(index);
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: done ? _gold.withValues(alpha: 0.18) : _tile,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(tip['icon'] as IconData, color: _gold, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tip['text'] as String,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tip['sub'] as String,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: _gray,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: done ? _gold : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: done ? _gold : const Color(0xFF3F3F44),
                  width: 1.8,
                ),
              ),
              child: done
                  ? const Icon(Icons.check_rounded,
                      color: Colors.black, size: 17)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Modify card ─────────────────────────

  Widget _buildModifyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: _gold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _gold.withValues(alpha: 0.12),
                border: Border.all(color: _gold.withValues(alpha: 0.35)),
              ),
              child: const Icon(Icons.fitness_center_rounded,
                  color: _gold, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Modify your workout',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Reduce intensity or focus on mobility and care.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: _gray,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '(not a medical diagnosis)',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF6B7280),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Get It button ─────────────────────────

  Widget _buildGetItButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
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
                color: _gold.withValues(alpha: 0.30),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.pop(context),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded,
                    color: Colors.black, size: 22),
                SizedBox(width: 10),
                Text(
                  'Get It',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Bottom navigation ─────────────────────────

  Widget _buildBottomNav() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _card,
        border: Border(top: BorderSide(color: _border, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const AiRecommendationsScreen()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LogWorkoutScreen()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const AnalyticsDashboardScreen()),
            );
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: _goldBright,
        unselectedItemColor: const Color(0xFF6B7280),
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center), label: 'Workouts'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded), label: 'Log'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded), label: 'Analytics'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}