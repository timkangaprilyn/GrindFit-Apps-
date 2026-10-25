import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/onboarding_step_indicator.dart';
import '../models/app_state.dart';
import 'fitness_goal_screen.dart';
import 'login_screen.dart';

class InitialAssessmentScreen extends StatefulWidget {
  const InitialAssessmentScreen({super.key});

  @override
  State<InitialAssessmentScreen> createState() =>
      _InitialAssessmentScreenState();
}

class _InitialAssessmentScreenState extends State<InitialAssessmentScreen> {
  // Black + Gold + White palette
  static const Color _bg = Color(0xFF121212); // charcoal background
  static const Color _card = Color(0xFF1C1C1E); // field / sheet surface
  static const Color _border = Color(0xFF2E2E31);
  static const Color _iconTile = Color(0xFF2A2A2D);
  static const Color _gold = Color(0xFFF5B800);
  static const Color _goldLight = Color(0xFFFFD34D);
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9CA3AF); // secondary text
  static const Color _hint = Color(0xFF6B7280);

  // Toggle field icons visibility
  static const bool _showFieldIcons = true;

  late final _nameController =
      TextEditingController(text: AppState.instance.fullName);
  late final _ageController =
      TextEditingController(text: AppState.instance.age.toString());
  late final _heightController =
      TextEditingController(text: AppState.instance.heightCm.toStringAsFixed(0));
  late final _weightController =
      TextEditingController(text: AppState.instance.weightKg.toStringAsFixed(0));
  final _injuryController = TextEditingController();

  String? _selectedGender; // Optional gender state
  bool _hasInjuryOrCondition = false;

  late String _fitnessLevel = AppState.instance.fitnessLevel;
  final List<String> _fitnessLevels = ['Beginner', 'Intermediate', 'Advanced'];
  final Map<String, String> _levelDescriptions = const {
    'Beginner': 'Just getting started with workouts',
    'Intermediate': 'Train regularly and know the basics',
    'Advanced': 'Experienced and highly consistent',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _injuryController.dispose();
    super.dispose();
  }

  // Safe back handler: sign out and return to LoginScreen securely
  Future<void> _handleBackToLogin() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _handleNext() {
    final fullName = _nameController.text.trim();
    final ageText = _ageController.text.trim();
    final heightText = _heightController.text.trim();
    final weightText = _weightController.text.trim();

    // Validation for empty fields and realistic values
    if (fullName.isEmpty || ageText.isEmpty || heightText.isEmpty || weightText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required profile fields.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final int? age = int.tryParse(ageText);
    final double? height = double.tryParse(heightText);
    final double? weight = double.tryParse(weightText);

    if (age == null || age <= 0 || age > 120) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid age between 1 and 120.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (height == null || height <= 0 || height > 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid height in centimeters.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (weight == null || weight <= 0 || weight > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid weight in kilograms.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    AppState.instance.updateAssessment(
      fullName: fullName,
      age: age,
      heightCm: height,
      weightKg: weight,
      fitnessLevel: _fitnessLevel,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FitnessGoalScreen()),
    );
  }

  // Bottom sheet picker for fitness level
  Future<void> _pickFitnessLevel() async {
    FocusScope.of(context).unfocus();

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _card,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Fitness Level',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _white,
                ),
              ),
              const SizedBox(height: 16),
              for (final level in _fitnessLevels) _levelTile(ctx, level),
            ],
          ),
        ),
      ),
    );

    if (selected != null) setState(() => _fitnessLevel = selected);
  }

  Widget _levelTile(BuildContext ctx, String level) {
    final isSelected = level == _fitnessLevel;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: isSelected ? _gold : _border,
        width: isSelected ? 1.5 : 1,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isSelected ? _gold.withAlpha(28) : _bg,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: () => Navigator.pop(ctx, level),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _levelDescriptions[level] ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _gray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? _gold : _border,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Label with small gold icon on the left
  Widget _label(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 17, color: _gold),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _white,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData fieldIcon) {
    OutlineInputBorder border(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _hint, fontSize: 15),
      filled: true,
      fillColor: _card,
      contentPadding: EdgeInsets.symmetric(
        horizontal: _showFieldIcons ? 8 : 18,
        vertical: 18,
      ),
      prefixIcon: _showFieldIcons
          ? Padding(
              padding: const EdgeInsets.only(left: 12, right: 10),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _iconTile,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(fieldIcon, color: _gold, size: 22),
              ),
            )
          : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      border: border(_border),
      enabledBorder: border(_border),
      focusedBorder: border(_gold, width: 1.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      fontSize: 15,
      color: _white,
      fontWeight: FontWeight.w500,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackToLogin();
      },
      child: Scaffold(
        backgroundColor: _bg,
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
                      _gold.withAlpha(55),
                      _gold.withAlpha(0),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _handleBackToLogin,
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
                    const SizedBox(height: 20),

                    const OnboardingStepIndicator(currentStep: 1, totalSteps: 5),
                    const SizedBox(height: 32),

                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: _white,
                          letterSpacing: -0.5,
                        ),
                        children: [
                          TextSpan(text: 'Complete Your '),
                          TextSpan(
                            text: 'Profile',
                            style: TextStyle(color: _gold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Help us personalize your experience.',
                      style: TextStyle(
                        fontSize: 15,
                        color: _gray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Full Name
                    _label(Icons.person, 'Full Name'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      style: textStyle,
                      cursorColor: _gold,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                          'Juan Dela Cruz', Icons.person_outline),
                    ),
                    const SizedBox(height: 22),

                    // Age + Gender (Optional) Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label(Icons.calendar_month_outlined, 'Age'),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _ageController,
                                style: textStyle,
                                cursorColor: _gold,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                decoration: _inputDecoration('20', Icons.calendar_month_outlined),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label(Icons.wc, 'Gender (Optional)'),
                              const SizedBox(height: 10),
                              Container(
                                height: 58,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: _card,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _border),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedGender,
                                    dropdownColor: _card,
                                    hint: const Text('Select', style: TextStyle(color: _hint, fontSize: 14)),
                                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _gold),
                                    items: ['Male', 'Female', 'Other'].map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value, style: textStyle),
                                      );
                                    }).toList(),
                                    onChanged: (newValue) {
                                      setState(() {
                                        _selectedGender = newValue;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Height + Weight
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label(Icons.straighten, 'Height (cm)'),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _heightController,
                                style: textStyle,
                                cursorColor: _gold,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                decoration:
                                    _inputDecoration('170', Icons.straighten),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label(
                                  Icons.monitor_weight_outlined, 'Weight (kg)'),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _weightController,
                                style: textStyle,
                                cursorColor: _gold,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration(
                                    '62', Icons.monitor_weight_outlined),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Fitness Level (tap -> bottom sheet)
                    _label(Icons.trending_up, 'Fitness Level'),
                    const SizedBox(height: 10),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _pickFitnessLevel,
                      child: InputDecorator(
                        decoration:
                            _inputDecoration('', Icons.signal_cellular_alt)
                                .copyWith(
                          suffixIcon: const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(Icons.keyboard_arrow_down, color: _gray),
                          ),
                          suffixIconConstraints:
                              const BoxConstraints(minWidth: 0, minHeight: 0),
                        ),
                        child: Text(_fitnessLevel, style: textStyle),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Injury or Health Condition Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Do you have any injuries or conditions?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _white,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _hasInjuryOrCondition,
                                activeThumbColor: _gold,
                                onChanged: (val) {
                                  setState(() {
                                    _hasInjuryOrCondition = val;
                                  });
                                },
                              ),
                            ],
                          ),
                          if (_hasInjuryOrCondition) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _injuryController,
                              cursorColor: _gold,
                              style: const TextStyle(fontSize: 14, color: _white),
                              decoration: InputDecoration(
                                hintText: 'Please specify (e.g., lower back pain, knee injury)',
                                hintStyle: const TextStyle(color: _hint, fontSize: 13),
                                filled: true,
                                fillColor: _bg,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _gold, width: 1.5)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.withAlpha(20),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.amber.withAlpha(80)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Injury Alert: We will adjust your workout recommendations accordingly for your safety.',
                                      style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 34),

                    // Next button
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
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _gold.withAlpha(70),
                                blurRadius: 22,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _handleNext,
                            child: const Row(
                              children: [
                                SizedBox(width: 24 + 4),
                                Expanded(
                                  child: Text(
                                    'Next',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: _bg,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(right: 16),
                                  child: Icon(
                                    Icons.chevron_right,
                                    color: _bg,
                                    size: 28,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}