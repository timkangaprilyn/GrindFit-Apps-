import 'package:flutter/material.dart';
import 'package:flutter_application_1/animations/motion.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/google_auth_service.dart';

import '../models/app_state.dart';
import 'login_screen.dart';
import 'initial_assessment_screen.dart';
import 'main_navigation_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color _bg = Color(0xFF0C0C0E);
  static const Color _card = Color(0xFF18181C);
  static const Color _border = Color(0xFF38383F);
  static const Color _gold = Color(0xFFF5B800);
  static const Color _goldLight = Color(0xFFFFD34D);
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9CA3AF);
  static const Color _hint = Color(0xFF6B7280);

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _agreedToPrivacy = false;
  bool _isEmailLoading = false;
  bool _isGoogleLoading = false;

  bool get _isLoading => _isEmailLoading || _isGoogleLoading;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Safe back handler para sa Register screen
  void _handleBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Future<void> _handleRegister() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (fullName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password and confirmation do not match.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!_agreedToPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You must agree to the Data Privacy Act of 2012 (RA 10173).',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isEmailLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(fullName);
        AppState.instance.loadProfile({
          'fullName': fullName,
          'email': email,
        }, fallbackName: fullName);

        // Firestore document creation
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': fullName,
          'email': email,
          'role': 'member',
          'setupCompleted': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!user.emailVerified) {
          await user.sendEmailVerification();
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your account has been created. Please verify your email.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const InitialAssessmentScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'An error occurred while creating your account.';
      if (e.code == 'weak-password') {
        message = 'The password is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for this email.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address format is invalid.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isEmailLoading = false);
    }
  }

  // Google Sign-In Logic for Register Screen
  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() => _isGoogleLoading = true);
    try {
      final user = await GoogleAuthService().signIn();
      if (user == null) {
        return;
      }

      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      var userDoc = await userRef.get();

      if (!userDoc.exists) {
        await userRef.set({
          'uid': user.uid,
          'fullName': user.displayName ?? 'Google User',
          'email': user.email ?? '',
          'role': 'member',
          'setupCompleted': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        userDoc = await userRef.get();
      }

      final docData = userDoc.data();
      AppState.instance.loadProfile(docData, fallbackName: user.displayName);
      final role = docData?['role'] as String? ?? 'member';
      if (role == 'admin' || role == 'trainer') {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Admin and trainer accounts must use the GrindFit Admin web portal, not the mobile app.',
            ),
            backgroundColor: Colors.amber,
          ),
        );
        return;
      }

      if (!mounted) return;

      final Widget destination = docData?['setupCompleted'] == true
          ? const MainNavigationScreen()
          : const InitialAssessmentScreen();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => destination),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(GoogleAuthService.errorMessage(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Widget _buildField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    Widget? suffix,
    ValueChanged<String>? onSubmitted,
  }) {
    OutlineInputBorder border(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _white,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          cursorColor: _gold,
          style: const TextStyle(
            fontSize: 15,
            color: _white,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _hint, fontSize: 15),
            filled: true,
            fillColor: _card,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 20,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Icon(icon, color: _gold, size: 22),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            suffixIcon: suffix,
            border: border(_border),
            enabledBorder: border(_border),
            focusedBorder: border(_gold, width: 1.5),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Create Account',
          style: TextStyle(
            color: _white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _handleBack,
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
      ),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_gold.withAlpha(50), _gold.withAlpha(0)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 10.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: staggered([
                  const Text(
                    'Join GrindFit and start achieving your fitness goals.',
                    style: TextStyle(
                      fontSize: 14,
                      color: _gray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),

                  _buildField(
                    label: 'Full Name',
                    hint: 'e.g. Juan Dela Cruz',
                    icon: Icons.person_outline,
                    controller: _fullNameController,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),

                  _buildField(
                    label: 'Email',
                    hint: 'you@example.com',
                    icon: Icons.mail_outline,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),

                  _buildField(
                    label: 'Password',
                    hint: 'Create a password',
                    icon: Icons.lock_outline,
                    controller: _passwordController,
                    obscureText: _isPasswordObscured,
                    textInputAction: TextInputAction.next,
                    suffix: IconButton(
                      icon: Icon(
                        _isPasswordObscured
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: _gray,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordObscured = !_isPasswordObscured;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildField(
                    label: 'Confirm Password',
                    hint: 'Re-enter your password',
                    icon: Icons.lock_reset_rounded,
                    controller: _confirmPasswordController,
                    obscureText: _isConfirmPasswordObscured,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (!_isLoading) _handleRegister();
                    },
                    suffix: IconButton(
                      icon: Icon(
                        _isConfirmPasswordObscured
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: _gray,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordObscured =
                              !_isConfirmPasswordObscured;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Checkbox(
                        value: _agreedToPrivacy,
                        activeColor: _gold,
                        checkColor: _bg,
                        side: const BorderSide(color: _gray),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _agreedToPrivacy = val ?? false;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'I agree to the Data Privacy Act of 2012 (RA 10173) terms and conditions.',
                          style: TextStyle(
                            color: _gray,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

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
                              color: _gold.withAlpha(90),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _isLoading ? null : _handleRegister,
                          child: Center(
                            child: _isEmailLoading
                                ? const SizedBox(
                                    width: 26,
                                    height: 26,
                                    child: CircularProgressIndicator(
                                      color: _bg,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Create Account',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: _bg,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: _bg,
                                        size: 22,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: const [
                      Expanded(child: Divider(color: _border)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or',
                          style: TextStyle(
                            color: _gray,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: _border)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'Google accounts do not need a GrindFit password. Continue with Google to create or access your account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _gray, fontSize: 12, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Continue with Google Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _border, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: _card,
                      ),
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      child: _isGoogleLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: _gold,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/google_logo.png',
                                  height: 24,
                                  width: 24,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: _white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(fontSize: 14, color: _gray),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            fontSize: 14,
                            color: _gold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
