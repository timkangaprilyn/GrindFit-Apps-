import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'welcome_screen.dart';
import 'home_dashboard_screen.dart';
import 'initial_assessment_screen.dart'; // Pinalitan ng InitialAssessmentScreen kung saan dumidiretso ang registration

/// GrindFit brand palette
class GrindColors {
  static const black = Color(0xFF050505);
  static const charcoal = Color(0xFF141414);
  static const gold = Color(0xFFFFC107);
  static const goldDeep = Color(0xFFE0A100);
  static const white = Color(0xFFFFFFFF);
  static const gray = Color(0xFF9CA3AF);
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();

    // 3.5 seconds loading duration
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
    );

    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        
        // Suriin ang login status at kung tapos na ang setup sa Firestore
        await _checkAuthAndNavigate();
      }
    });

    _controller.forward();
  }

  Future<void> _checkAuthAndNavigate() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Walang naka-login -> Welcome Screen
      _navigateTo(const WelcomeScreen());
      return;
    }

    try {
      // Kunin ang user data sa Firestore para makita kung tapos na ang setup
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (doc.exists && doc.data()?['setupCompleted'] == true) {
        // May account at tapos na ang setup -> Home Dashboard
        _navigateTo(const HomeDashboardScreen());
      } else {
        // Naka-login pero hindi pa tapos ang setup -> Initial Assessment / Complete Profile
        _navigateTo(const InitialAssessmentScreen());
      }
    } catch (e) {
      // Kung may error sa connection, mag-fallback sa Welcome screen
      if (!mounted) return;
      _navigateTo(const WelcomeScreen());
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GrindColors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image ng splash
          Image.asset(
            'assets/images/splash_bg.png',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) => const ColoredBox(
              color: GrindColors.black,
              child: Center(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'GRIND',
                        style: TextStyle(color: GrindColors.white),
                      ),
                      TextSpan(
                        text: 'FIT',
                        style: TextStyle(color: GrindColors.gold),
                      ),
                    ],
                  ),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ),

          // Inayos ang alignment pababang bahagi (0.65) para hindi matakpan 
          // ang "STRONGER YOU" o gitnang logo ng background image.
          Align(
            alignment: const Alignment(0, 0.65),
            child: FadeTransition(
              opacity: _fadeIn,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final percent = (_progress.value * 100).round().clamp(0, 100);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: _progress.value,
                              strokeWidth: 3.5,
                              strokeCap: StrokeCap.round,
                              backgroundColor: const Color(0x33FFC107),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                GrindColors.gold,
                              ),
                            ),
                            Center(
                              child: Text(
                                '$percent%',
                                style: const TextStyle(
                                  color: GrindColors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Initializing System...',
                        style: TextStyle(
                          color: GrindColors.gray,
                          fontSize: 11,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}