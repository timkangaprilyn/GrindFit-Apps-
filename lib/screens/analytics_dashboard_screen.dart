import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'workout_history_screen.dart';
import 'log_workout_screen.dart'; // Siguraduhing ito ang import sa iyong Log/Goal screen

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  static const Color _bg = Color(0xFF121212);
  static const Color _card = Color(0xFF1C1C1E);
  static const Color _tile = Color(0xFF2A2A2D);
  static const Color _border = Color(0xFF2E2E31);
  static const Color _grid = Color(0xFF2A2A2D);
  static const Color _gold = Color(0xFFF5B800);
  static const Color _goldBright = Color(0xFFFFCC1A);
  static const Color _goldLight = Color(0xFFFFD34D);
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9CA3AF);
  static const Color _muted = Color(0xFF6B7280);

  bool _isWeekly = true;
  int? _selectedBar;

  void _setPeriod(bool weekly) {
    if (_isWeekly == weekly) return;
    setState(() {
      _isWeekly = weekly;
      _selectedBar = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String totalSessions = _isWeekly ? '4' : '16';
    final String avgDuration = _isWeekly ? '45 min' : '42 min';
    final String periodLabel = _isWeekly ? 'this week' : 'this month';

    final List<double> durationTrend = _isWeekly
        ? [35, 40, 42, 45, 40, 48, 45]
        : [38, 40, 42, 41, 44, 42, 45, 43, 46, 44, 45, 42];
    final List<double> intensityTrend = _isWeekly
        ? [2, 2, 3, 2, 3, 3, 2]
        : [2, 2, 3, 2, 3, 2, 3, 3, 2, 3, 3, 2];

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Positioned(
            top: -150,
            right: -130,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _gold.withValues(alpha: 0.18),
                    _gold.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildPeriodToggle(),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.fitness_center_rounded,
                          label: 'Total Sessions',
                          value: totalSessions,
                          caption: periodLabel,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.timer_outlined,
                          label: 'Avg. Duration',
                          value: avgDuration,
                          caption: 'per session',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildFrequencyCard(),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildDurationTrendCard(durationTrend)),
                      const SizedBox(width: 14),
                      Expanded(
                          child: _buildIntensityTrendCard(intensityTrend)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LogWorkoutScreen()),
                      );
                    },
                    child: _buildProgressToGoalCard(),
                  ),
                  const SizedBox(height: 18),
                  _buildAchievementsCard(),
                  const SizedBox(height: 18),
                  _buildHistoryButton(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics',
                style: TextStyle(
                  color: _white,
                  fontWeight: FontWeight.w900,
                  fontSize: 30,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Track your training progress',
                style: TextStyle(
                  color: _gray,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: const Icon(Icons.insights_rounded, color: _gold, size: 24),
        ),
      ],
    );
  }

  Widget _buildPeriodToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleTab('Weekly', _isWeekly, () => _setPeriod(true)),
          ),
          Expanded(
            child:
                _buildToggleTab('Monthly', !_isWeekly, () => _setPeriod(false)),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTab(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [_goldLight, _gold])
              : null,
          borderRadius: BorderRadius.circular(11),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.black : _gray,
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 20}) => BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _border, width: 1.2),
      );

  Widget _iconTile(IconData icon, {double size = 36, double iconSize = 18}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: _gold, size: iconSize),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String caption,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconTile(icon),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  softWrap: true,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _gray,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.25),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: Text(
              value,
              key: ValueKey(value),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: _white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: const TextStyle(
              fontSize: 11.5,
              color: _muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyCard() {
    final List<String> labels = _isWeekly
        ? const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
        : const ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4'];
    final List<int> values =
        _isWeekly ? const [1, 0, 1, 0, 1, 1, 0] : const [4, 4, 4, 4];

    final int defaultIndex = _isWeekly ? DateTime.now().weekday - 1 : 3;
    final int selected =
        (_selectedBar ?? defaultIndex).clamp(0, values.length - 1);

    final int maxVal = values.reduce(math.max);
    final int maxY = math.max(4, (((maxVal + 1) / 2).ceil()) * 2);
    final int step = maxY ~/ 2;
    const double plotH = 130;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Workout Frequency',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _isWeekly ? 'Sessions per day' : 'Sessions per week',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _gold.withValues(alpha: 0.35)),
                ),
                child: Text(
                  '${labels[selected]} · ${values[selected]}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _goldBright,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TweenAnimationBuilder<double>(
            key: ValueKey('bars_$_isWeekly'),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 26,
                    height: plotH,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (int k = 0; k <= 2; k++)
                          Positioned(
                            left: 0,
                            right: 6,
                            bottom: plotH * k / 2 - 7,
                            child: Text(
                              '${step * k}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: _muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(
                          height: plotH,
                          child: Stack(
                            children: [
                              for (int k = 0; k <= 2; k++)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: plotH * k / 2,
                                  child: Container(
                                    height: 1,
                                    color: k == 0
                                        ? const Color(0xFF3A3A3F)
                                        : _grid,
                                  ),
                                ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  for (int i = 0; i < values.length; i++)
                                    Expanded(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () =>
                                            setState(() => _selectedBar = i),
                                        child: Align(
                                          alignment: Alignment.bottomCenter,
                                          child: _buildBar(
                                            height: values[i] / maxY * plotH * t,
                                            width: _isWeekly ? 18 : 38,
                                            selected: i == selected,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (int i = 0; i < labels.length; i++)
                              Expanded(
                                child: Text(
                                  labels[i],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: i == selected ? _goldBright : _muted,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBar({
    required double height,
    required double width,
    required bool selected,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      height: math.max(height, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: selected
              ? const [_goldLight, _gold]
              : [_gold.withValues(alpha: 0.55), _gold.withValues(alpha: 0.22)],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(8),
          bottom: Radius.circular(3),
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: _gold.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildDurationTrendCard(List<double> data) {
    final double diff = data.last - data.first;
    final bool up = diff >= 0;
    return _buildTrendCard(
      title: 'Duration Trend',
      valueText: '${data.last.toInt()} min',
      deltaText: '${up ? '+' : ''}${diff.toInt()} min',
      up: up,
      data: data,
      chartKey: 'duration_$_isWeekly',
    );
  }

  Widget _buildIntensityTrendCard(List<double> data) {
    final double avg = data.reduce((a, b) => a + b) / data.length;
    final String level = avg < 1.7
        ? 'Low'
        : avg < 2.5
            ? 'Moderate'
            : 'High';
    final double diff = data.last - data.first;
    return _buildTrendCard(
      title: 'Intensity Trend',
      valueText: level,
      deltaText: 'Avg ${avg.toStringAsFixed(1)}/3',
      up: diff >= 0,
      data: data,
      chartKey: 'intensity_$_isWeekly',
    );
  }

  Widget _buildTrendCard({
    required String title,
    required String valueText,
    required String deltaText,
    required bool up,
    required List<double> data,
    required String chartKey,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _gray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            valueText,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                size: 15,
                color: _goldBright,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  deltaText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: _goldBright,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 64,
            width: double.infinity,
            child: TweenAnimationBuilder<double>(
              key: ValueKey(chartKey),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) => CustomPaint(
                painter: _SmoothLinePainter(
                  data: data,
                  color: _gold,
                  gridColor: _grid,
                  progress: t,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressToGoalCard() {
    const double progress = 0.75;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(76, 76),
                    painter: _RingPainter(
                      progress: value,
                      track: _tile,
                      start: _gold,
                      end: _goldLight,
                    ),
                  ),
                  Text(
                    '${(value * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: _white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progress to Goal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '9 / 12 weeks',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _goldBright,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '3 weeks to go — keep it up!',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: _gray,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: _muted, size: 26),
        ],
      ),
    );
  }

  Widget _buildAchievementsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Achievements',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: _white,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildAchievementItem(
                    Icons.local_fire_department_rounded, '7 Day', 'Streak'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAchievementItem(
                    Icons.bolt_rounded, '16', 'Workouts'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAchievementItem(
                    Icons.emoji_events_rounded, 'Goal', 'Progress'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: _tile,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(color: _gold.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: _gold, size: 21),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: _white,
            ),
          ),
          const SizedBox(height: 1),
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
    );
  }

  Widget _buildHistoryButton() {
    return Material(
      color: _gold.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: _gold.withValues(alpha: 0.55), width: 1.2),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WorkoutHistoryScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _iconTile(Icons.history_rounded, size: 40, iconSize: 22),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'View Full Workout History',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: _goldBright,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: _goldBright, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmoothLinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final Color gridColor;
  final double progress;

  _SmoothLinePainter({
    required this.data,
    required this.color,
    required this.gridColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (int k = 0; k < 3; k++) {
      final y = size.height * k / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final double maxVal = data.reduce(math.max);
    final double minVal = data.reduce(math.min);
    final double range = (maxVal - minVal) == 0 ? 1 : (maxVal - minVal);

    const double xPad = 5;
    final double topPad = size.height * 0.14;
    final double usableHeight = size.height - topPad * 2;
    final double stepX = (size.width - xPad * 2) / (data.length - 1);

    final List<Offset> pts = [
      for (int i = 0; i < data.length; i++)
        Offset(
          xPad + stepX * i,
          size.height - topPad - ((data[i] - minVal) / range) * usableHeight,
        ),
    ];

    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final a = pts[i];
      final b = pts[i + 1];
      final cx = (a.dx + b.dx) / 2;
      line.cubicTo(cx, a.dy, cx, b.dy, b.dx, b.dy);
    }

    final fill = Path.from(line)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, -8, size.width * progress, size.height + 16));

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..strokeWidth = 2.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();

    if (progress > 0.98) {
      final end = pts.last;
      canvas.drawCircle(
          end, 7, Paint()..color = color.withValues(alpha: 0.25));
      canvas.drawCircle(end, 4, Paint()..color = color);
      canvas.drawCircle(end, 1.6, Paint()..color = const Color(0xFF1C1C1E));
    }
  }

  @override
  bool shouldRepaint(covariant _SmoothLinePainter old) =>
      old.data != data || old.color != color || old.progress != progress;
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color track;
  final Color start;
  final Color end;

  _RingPainter({
    required this.progress,
    required this.track,
    required this.start,
    required this.end,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 9;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);

    canvas.drawArc(
      arcRect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..shader = SweepGradient(
          colors: [start, end],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.start != start || old.end != end;
}