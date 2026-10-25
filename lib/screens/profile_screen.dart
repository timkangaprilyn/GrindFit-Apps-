import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_state.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';

// Walang sariling bottomNavigationBar dito: ang MainNavigationScreen (shell)
// ang may hawak ng iisang navbar.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
  static const Color _danger = Color(0xFFEF4444);

  static const List<String> _levels = ['Beginner', 'Intermediate', 'Advanced'];
  static const List<String> _environments = ['Gym', 'Home', 'Outdoor'];
  static const List<Map<String, dynamic>> _goals = [
    {
      'title': 'Weight Loss',
      'subtitle': 'Get leaner and healthier.',
      'icon': Icons.directions_run_rounded,
    },
    {
      'title': 'Muscle Gain / Strength',
      'subtitle': 'Build muscle and get stronger.',
      'icon': Icons.fitness_center_rounded,
    },
    {
      'title': 'Endurance / Cardio',
      'subtitle': 'Improve stamina and endurance.',
      'icon': Icons.monitor_heart_rounded,
    },
    {
      'title': 'General Fitness',
      'subtitle': 'Maintain a healthy lifestyle.',
      'icon': Icons.self_improvement_rounded,
    },
  ];

  // Mga preference na sine-save sa Firestore (users/{uid})
  String _environment = 'Gym';
  int _daysPerWeek = 3;
  bool _remindWorkout = true;
  bool _remindRest = true;
  bool _remindAchievements = true;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ───────────────────────── Data (Firestore ↔ AppState) ─────────────────────────

  Future<void> _loadProfile() async {
    try {
      final user = _user;
      if (user == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final d = doc.data();
      if (d == null || !mounted) return;

      final app = AppState.instance;
      setState(() {
        final String? name = d['fullName'] is String &&
                (d['fullName'] as String).trim().isNotEmpty
            ? (d['fullName'] as String).trim()
            : null;
        final int? age = d['age'] is num ? (d['age'] as num).toInt() : null;
        final double? height =
            d['height'] is num ? (d['height'] as num).toDouble() : null;
        final double? weight =
            d['weight'] is num ? (d['weight'] as num).toDouble() : null;
        final String? level =
            d['fitnessLevel'] is String && _levels.contains(d['fitnessLevel'])
                ? d['fitnessLevel'] as String
                : null;

        if (name != null ||
            age != null ||
            height != null ||
            weight != null ||
            level != null) {
          app.updateAssessment(
            fullName: name ?? app.fullName,
            age: age ?? app.age,
            heightCm: height ?? app.heightCm,
            weightKg: weight ?? app.weightKg,
            fitnessLevel: level ?? app.fitnessLevel,
          );
        }

        if (d['fitnessGoal'] is String &&
            (d['fitnessGoal'] as String).isNotEmpty) {
          app.updateGoal(d['fitnessGoal'] as String);
        }

        if (d['workoutEnvironment'] is String &&
            _environments.contains(d['workoutEnvironment'])) {
          _environment = d['workoutEnvironment'] as String;
        }
        if (d['daysPerWeek'] is num) {
          _daysPerWeek = (d['daysPerWeek'] as num).toInt().clamp(1, 7);
        }
        final n = d['notificationSettings'];
        if (n is Map) {
          _remindWorkout = n['workout'] is bool ? n['workout'] : _remindWorkout;
          _remindRest = n['rest'] is bool ? n['rest'] : _remindRest;
          _remindAchievements =
              n['achievements'] is bool ? n['achievements'] : _remindAchievements;
        }
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<bool> _saveToFirestore(Map<String, dynamic> data) async {
    try {
      final user = _user;
      if (user == null) return false;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(data, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('Error saving profile: $e');
      return false;
    }
  }

  // ───────────────────────── Helpers ─────────────────────────

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  double get _bmi {
    final h = AppState.instance.heightCm / 100;
    if (h <= 0) return 0;
    return AppState.instance.weightKg / (h * h);
  }

  // WHO classification
  String _bmiCategory(double bmi) {
    if (bmi <= 0) return '—';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _tile,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: (error ? _danger : _gold).withValues(alpha: 0.5),
            ),
          ),
          content: Row(
            children: [
              Icon(
                error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
                color: error ? _danger : _gold,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: _white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ───────────────────────── Build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    final user = _user;
    final String name = app.fullName.isNotEmpty ? app.fullName : 'GrindFit User';
    final String email = user?.email ?? 'Not signed in';
    final DateTime? created = user?.metadata.creationTime;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Gold glow sa taas na kanan
          Positioned(
            top: -150,
            right: -130,
            child: IgnorePointer(
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
          ),
          SafeArea(
            child: RefreshIndicator(
              color: _gold,
              backgroundColor: _card,
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile',
                      style: TextStyle(
                        color: _white,
                        fontWeight: FontWeight.w900,
                        fontSize: 30,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildHeaderCard(name, email, created),
                    const SizedBox(height: 16),
                    _buildStatsRow(),
                    const SizedBox(height: 16),
                    _buildBmiCard(),
                    const SizedBox(height: 24),
                    _sectionLabel('Account'),
                    _group([
                      _settingsTile(
                        icon: Icons.person_outline_rounded,
                        title: 'Personal Information',
                        subtitle:
                            '${app.age} yrs • ${app.heightCm.toStringAsFixed(0)} cm • ${app.weightKg.toStringAsFixed(0)} kg',
                        onTap: _editPersonalInfo,
                      ),
                      _settingsTile(
                        icon: Icons.lock_outline_rounded,
                        title: 'Change Password',
                        onTap: _changePassword,
                      ),
                    ]),
                    const SizedBox(height: 22),
                    _sectionLabel('Training'),
                    _group([
                      _settingsTile(
                        icon: Icons.flag_outlined,
                        title: 'Fitness Goal',
                        subtitle: app.fitnessGoal,
                        onTap: _pickGoal,
                      ),
                      _settingsTile(
                        icon: Icons.tune_rounded,
                        title: 'Workout Preferences',
                        subtitle: '$_environment • $_daysPerWeek days/week',
                        onTap: _editPreferences,
                      ),
                      _settingsTile(
                        icon: Icons.notifications_outlined,
                        title: 'Notification Settings',
                        subtitle: _notificationSummary,
                        onTap: _notificationSettings,
                      ),
                    ]),
                    const SizedBox(height: 22),
                    _buildLogoutTile(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _notificationSummary {
    final on = [_remindWorkout, _remindRest, _remindAchievements]
        .where((e) => e)
        .length;
    return on == 0 ? 'All off' : '$on of 3 on';
  }

  // ───────────────────────── Header / stats ─────────────────────────

  Widget _buildHeaderCard(String name, String email, DateTime? created) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(_gold.withValues(alpha: 0.14), _card),
            _card,
          ],
        ),
        border: Border.all(color: _gold.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_goldLight, _gold],
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _card,
              ),
              alignment: Alignment.center,
              child: Text(
                _initials(name),
                style: const TextStyle(
                  color: _goldBright,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _gray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _pill(Icons.bolt_rounded, AppState.instance.fitnessLevel),
                    if (created != null)
                      _pill(Icons.calendar_today_rounded,
                          'Since ${DateFormat('MMM yyyy').format(created)}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _gold.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _goldBright),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: _goldBright,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final app = AppState.instance;
    return Row(
      children: [
        Expanded(child: _statTile(Icons.cake_outlined, '${app.age}', 'Age')),
        const SizedBox(width: 12),
        Expanded(
          child: _statTile(Icons.straighten_rounded,
              app.heightCm.toStringAsFixed(0), 'Height (cm)'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statTile(Icons.monitor_weight_outlined,
              app.weightKg.toStringAsFixed(0), 'Weight (kg)'),
        ),
      ],
    );
  }

  Widget _statTile(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: Column(
        children: [
          Icon(icon, color: _gold, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: _muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── BMI ─────────────────────────

  Widget _buildBmiCard() {
    final double bmi = _bmi;
    final String category = _bmiCategory(bmi);
    // Scale: 15 → 40
    final double frac = ((bmi - 15) / 25).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Body Mass Index',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _white,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _gold.withValues(alpha: 0.35)),
                ),
                child: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _goldBright,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            bmi > 0 ? bmi.toStringAsFixed(1) : '—',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: _white,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              return SizedBox(
                height: 22,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 7,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          height: 8,
                          child: Row(
                            children: [
                              Expanded(
                                  flex: 35,
                                  child: Container(color: _gray.withValues(alpha: 0.45))),
                              const SizedBox(width: 2),
                              Expanded(flex: 65, child: Container(color: _gold)),
                              const SizedBox(width: 2),
                              Expanded(
                                  flex: 50,
                                  child: Container(color: _gold.withValues(alpha: 0.5))),
                              const SizedBox(width: 2),
                              Expanded(
                                  flex: 100,
                                  child: Container(color: _gray.withValues(alpha: 0.25))),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (bmi > 0)
                      Positioned(
                        left: (frac * w - 9).clamp(0.0, w - 18),
                        top: 2,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: _white,
                            shape: BoxShape.circle,
                            border: Border.all(color: _bg, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: _gold.withValues(alpha: 0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('15', style: _scaleStyle),
              Text('18.5', style: _scaleStyle),
              Text('25', style: _scaleStyle),
              Text('30', style: _scaleStyle),
              Text('40', style: _scaleStyle),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'A general guide only — not a medical diagnosis.',
            style: TextStyle(
              fontSize: 11,
              color: _muted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  static const TextStyle _scaleStyle = TextStyle(
    fontSize: 10.5,
    color: _muted,
    fontWeight: FontWeight.w700,
  );

  // ───────────────────────── Settings list ─────────────────────────

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 1.4,
          color: _muted,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _group(List<Widget> tiles) {
    return Material(
      color: _card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _border, width: 1.2),
      ),
      child: Column(
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            tiles[i],
            if (i != tiles.length - 1)
              const Divider(
                height: 1,
                indent: 68,
                endIndent: 16,
                color: _border,
              ),
          ],
        ],
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: _gold, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _white,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: _gray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _muted, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutTile() {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: _danger.withValues(alpha: 0.35), width: 1.2),
    );
    return Material(
      color: _danger.withValues(alpha: 0.08),
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: _confirmLogout,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _danger.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.logout_rounded,
                    color: _danger, size: 21),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Log Out',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _danger,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Sheet helpers ─────────────────────────

  Future<T?> _openSheet<T>(Widget Function(BuildContext) builder) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _card,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              24, 4, 24, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(child: builder(ctx)),
        ),
      ),
    );
  }

  Widget _sheetHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: _white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13.5,
            color: _gray,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: _white,
          ),
        ),
      );

  InputDecoration _fieldDecoration({
    String? hint,
    required IconData icon,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _muted, fontSize: 15),
      filled: true,
      fillColor: _bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 16, right: 12),
        child: Icon(icon, color: _gold, size: 22),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0),
      suffixIcon: suffix,
      border: border(_border),
      enabledBorder: border(_border),
      focusedBorder: border(_gold, width: 1.5),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      cursorColor: _gold,
      style: const TextStyle(
        fontSize: 15,
        color: _white,
        fontWeight: FontWeight.w500,
      ),
      decoration: _fieldDecoration(hint: hint, icon: icon, suffix: suffix),
    );
  }

  Widget _choiceChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [_goldLight, _gold])
              : null,
          color: selected ? null : _bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? _gold : _border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.black : _gray,
          ),
        ),
      ),
    );
  }

  Widget _errorBox(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _danger.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: _white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _goldButton(String label, VoidCallback? onTap, {bool loading = false}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_goldLight, _gold]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _gold.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: loading ? null : onTap,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 3),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Personal information ─────────────────────────

  void _editPersonalInfo() {
    final app = AppState.instance;
    final nameC = TextEditingController(text: app.fullName);
    final ageC = TextEditingController(text: app.age.toString());
    final heightC = TextEditingController(text: app.heightCm.toStringAsFixed(0));
    final weightC = TextEditingController(text: app.weightKg.toStringAsFixed(0));
    String level = _levels.contains(app.fitnessLevel)
        ? app.fitnessLevel
        : _levels.first;
    String? error;
    bool saving = false;

    _openSheet((ctx) => StatefulBuilder(
          builder: (ctx, setS) {
            Future<void> save() async {
              final name = nameC.text.trim();
              final age = int.tryParse(ageC.text.trim());
              final height = double.tryParse(heightC.text.trim());
              final weight = double.tryParse(weightC.text.trim());

              String? problem;
              if (name.isEmpty) {
                problem = 'Please enter your full name.';
              } else if (age == null || age < 10 || age > 100) {
                problem = 'Age must be between 10 and 100.';
              } else if (height == null || height < 100 || height > 250) {
                problem = 'Height must be between 100 and 250 cm.';
              } else if (weight == null || weight < 25 || weight > 300) {
                problem = 'Weight must be between 25 and 300 kg.';
              }
              if (problem != null) {
                setS(() => error = problem);
                return;
              }

              setS(() {
                error = null;
                saving = true;
              });

              app.updateAssessment(
                fullName: name,
                age: age!,
                heightCm: height!,
                weightKg: weight!,
                fitnessLevel: level,
              );
              final ok = await _saveToFirestore({
                'fullName': name,
                'age': age,
                'height': height,
                'weight': weight,
                'fitnessLevel': level,
              });

              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (mounted) setState(() {});
              _snack(ok
                  ? 'Profile updated'
                  : 'Saved on this device, but could not sync online.');
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHeader('Personal Information',
                    'Keep your details accurate for better recommendations.'),
                _fieldLabel('Full Name'),
                _textField(
                  controller: nameC,
                  icon: Icons.person_outline_rounded,
                  hint: 'e.g. Juan Dela Cruz',
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Age'),
                          _textField(
                            controller: ageC,
                            icon: Icons.cake_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Height (cm)'),
                          _textField(
                            controller: heightC,
                            icon: Icons.straighten_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _fieldLabel('Weight (kg)'),
                _textField(
                  controller: weightC,
                  icon: Icons.monitor_weight_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                _fieldLabel('Fitness Level'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final l in _levels)
                      _choiceChip(l, l == level, () => setS(() => level = l)),
                  ],
                ),
                if (error != null) _errorBox(error!),
                const SizedBox(height: 22),
                _goldButton('Save Changes', save, loading: saving),
              ],
            );
          },
        ));
  }

  // ───────────────────────── Fitness goal ─────────────────────────

  void _pickGoal() {
    final app = AppState.instance;

    _openSheet((ctx) => StatefulBuilder(
          builder: (ctx, setS) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHeader('Fitness Goal', 'Choose your primary goal.'),
                for (final g in _goals)
                  _goalOption(
                    title: g['title'] as String,
                    subtitle: g['subtitle'] as String,
                    icon: g['icon'] as IconData,
                    selected: app.fitnessGoal == g['title'],
                    onTap: () async {
                      final String title = g['title'] as String;
                      app.updateGoal(title);
                      final ok = await _saveToFirestore({'fitnessGoal': title});
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (mounted) setState(() {});
                      _snack(ok
                          ? 'Goal set to $title'
                          : 'Saved on this device, but could not sync online.');
                    },
                  ),
              ],
            );
          },
        ));
  }

  Widget _goalOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: selected ? _gold : _border,
        width: selected ? 1.5 : 1,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? _gold.withValues(alpha: 0.10) : _bg,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: selected ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: _gold, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: _gray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected ? _gold : _border,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Workout preferences ─────────────────────────

  void _editPreferences() {
    String env = _environment;
    int days = _daysPerWeek;
    bool saving = false;

    _openSheet((ctx) => StatefulBuilder(
          builder: (ctx, setS) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHeader('Workout Preferences',
                    'Tell us where and how often you train.'),
                _fieldLabel('Where do you work out?'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final e in _environments)
                      _choiceChip(e, e == env, () => setS(() => env = e)),
                  ],
                ),
                const SizedBox(height: 20),
                _fieldLabel('Days per week'),
                Row(
                  children: [
                    for (int d = 1; d <= 7; d++) ...[
                      if (d != 1) const SizedBox(width: 6),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setS(() => days = d),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            height: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: d == days
                                  ? const LinearGradient(
                                      colors: [_goldLight, _gold])
                                  : null,
                              color: d == days ? null : _bg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: d == days ? _gold : _border),
                            ),
                            child: Text(
                              '$d',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: d == days ? Colors.black : _gray,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 26),
                _goldButton('Save Preferences', () async {
                  setS(() => saving = true);
                  setState(() {
                    _environment = env;
                    _daysPerWeek = days;
                  });
                  final ok = await _saveToFirestore({
                    'workoutEnvironment': env,
                    'daysPerWeek': days,
                  });
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  _snack(ok
                      ? 'Preferences saved'
                      : 'Saved on this device, but could not sync online.');
                }, loading: saving),
              ],
            );
          },
        ));
  }

  // ───────────────────────── Notification settings ─────────────────────────

  Future<void> _saveNotificationSettings() {
    return _saveToFirestore({
      'notificationSettings': {
        'workout': _remindWorkout,
        'rest': _remindRest,
        'achievements': _remindAchievements,
      },
    });
  }

  void _notificationSettings() {
    _openSheet((ctx) => StatefulBuilder(
          builder: (ctx, setS) {
            Widget toggle(
                IconData icon, String title, String sub, bool value,
                ValueChanged<bool> onChanged) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _gold.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: _gold, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: _white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              sub,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _gray,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: value,
                        onChanged: onChanged,
                        thumbColor: WidgetStateProperty.resolveWith(
                          (s) => s.contains(WidgetState.selected)
                              ? Colors.black
                              : _gray,
                        ),
                        trackColor: WidgetStateProperty.resolveWith(
                          (s) => s.contains(WidgetState.selected)
                              ? _gold
                              : _tile,
                        ),
                        trackOutlineColor:
                            WidgetStateProperty.all(Colors.transparent),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHeader('Notification Settings',
                    'Choose which reminders you want to receive.'),
                toggle(
                  Icons.fitness_center_rounded,
                  'Workout reminders',
                  'Reminders for your planned sessions',
                  _remindWorkout,
                  (v) {
                    setS(() => _remindWorkout = v);
                    setState(() {});
                    _saveNotificationSettings();
                  },
                ),
                toggle(
                  Icons.bedtime_rounded,
                  'Rest day alerts',
                  'Recovery tips on your rest days',
                  _remindRest,
                  (v) {
                    setS(() => _remindRest = v);
                    setState(() {});
                    _saveNotificationSettings();
                  },
                ),
                toggle(
                  Icons.emoji_events_rounded,
                  'Achievements',
                  'Streaks, milestones and goal progress',
                  _remindAchievements,
                  (v) {
                    setS(() => _remindAchievements = v);
                    setState(() {});
                    _saveNotificationSettings();
                  },
                ),
                const SizedBox(height: 10),
                _goldButton('View Notifications', () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen()),
                  );
                }),
              ],
            );
          },
        ));
  }

  // ───────────────────────── Change password ─────────────────────────

  void _changePassword() {
    final user = _user;
    if (user == null || user.email == null) {
      _snack('You need to be signed in to change your password.', error: true);
      return;
    }
    final bool hasPassword =
        user.providerData.any((p) => p.providerId == 'password');
    if (!hasPassword) {
      _snack('This account signs in with a different provider, so there is no password to change.',
          error: true);
      return;
    }

    final currentC = TextEditingController();
    final newC = TextEditingController();
    final confirmC = TextEditingController();
    bool obscure = true;
    bool saving = false;
    String? error;

    _openSheet((ctx) => StatefulBuilder(
          builder: (ctx, setS) {
            Future<void> save() async {
              final current = currentC.text;
              final next = newC.text;
              final confirm = confirmC.text;

              String? problem;
              if (current.isEmpty) {
                problem = 'Enter your current password.';
              } else if (next.length < 6) {
                problem = 'New password must be at least 6 characters.';
              } else if (next == current) {
                problem = 'New password must be different from the current one.';
              } else if (next != confirm) {
                problem = 'New passwords do not match.';
              }
              if (problem != null) {
                setS(() => error = problem);
                return;
              }

              setS(() {
                error = null;
                saving = true;
              });

              try {
                final cred = EmailAuthProvider.credential(
                    email: user.email!, password: current);
                await user.reauthenticateWithCredential(cred);
                await user.updatePassword(next);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _snack('Password changed successfully');
              } on FirebaseAuthException catch (e) {
                String msg;
                switch (e.code) {
                  case 'wrong-password':
                  case 'invalid-credential':
                    msg = 'Current password is incorrect.';
                    break;
                  case 'weak-password':
                    msg = 'New password is too weak. Try a longer one.';
                    break;
                  case 'too-many-requests':
                    msg = 'Too many attempts. Please try again later.';
                    break;
                  case 'requires-recent-login':
                    msg = 'Please log out and log in again, then retry.';
                    break;
                  default:
                    msg = e.message ?? 'Could not change password.';
                }
                if (ctx.mounted) {
                  setS(() {
                    error = msg;
                    saving = false;
                  });
                }
              } catch (_) {
                if (ctx.mounted) {
                  setS(() {
                    error = 'Something went wrong. Please try again.';
                    saving = false;
                  });
                }
              }
            }

            final Widget eye = IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _gray,
              ),
              onPressed: () => setS(() => obscure = !obscure),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHeader('Change Password',
                    'Use at least 6 characters you haven\'t used before.'),
                _fieldLabel('Current Password'),
                _textField(
                  controller: currentC,
                  icon: Icons.lock_outline_rounded,
                  obscure: obscure,
                  suffix: eye,
                ),
                const SizedBox(height: 16),
                _fieldLabel('New Password'),
                _textField(
                  controller: newC,
                  icon: Icons.lock_reset_rounded,
                  obscure: obscure,
                ),
                const SizedBox(height: 16),
                _fieldLabel('Confirm New Password'),
                _textField(
                  controller: confirmC,
                  icon: Icons.verified_user_outlined,
                  obscure: obscure,
                ),
                if (error != null) _errorBox(error!),
                const SizedBox(height: 22),
                _goldButton('Update Password', save, loading: saving),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: saving
                        ? null
                        : () async {
                            try {
                              await FirebaseAuth.instance
                                  .sendPasswordResetEmail(email: user.email!);
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              _snack('Reset link sent to ${user.email}');
                            } catch (_) {
                              if (ctx.mounted) {
                                setS(() => error =
                                    'Could not send the reset email. Try again.');
                              }
                            }
                          },
                    child: const Text(
                      'Forgot password? Email me a reset link',
                      style: TextStyle(
                        color: _goldBright,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ));
  }

  // ───────────────────────── Log out ─────────────────────────

  Future<void> _confirmLogout() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: _border),
        ),
        title: const Text(
          'Log out?',
          style: TextStyle(color: _white, fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'You\'ll need to log in again to access your workouts.',
          style: TextStyle(color: _gray, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _gray, fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Log Out',
              style: TextStyle(color: _danger, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      _snack('Could not log out. Please try again.', error: true);
      return;
    }

    if (!mounted) return;
    // Alisin ang buong stack (kasama ang shell) at bumalik sa Login
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}