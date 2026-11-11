import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/network_status.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_state.dart';
import 'initial_assessment_screen.dart';
import 'main_navigation_screen.dart';
import 'welcome_screen.dart';

class GrindColors {
  static const black = Color(0xFF050505);
  static const gold = Color(0xFFFFC107);
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
  Object? _startupError;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.3, curve: Curves.easeOut),
    );

    _startStartup();
  }

  Future<Widget> _resolveDestination() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const WelcomeScreen();

    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final online = await NetworkStatus.instance.checkNow().timeout(
      const Duration(seconds: 6),
      onTimeout: () => false,
    );
    DocumentSnapshot<Map<String, dynamic>> doc;
    if (online) {
      try {
        doc = await ref.get().timeout(const Duration(seconds: 8));
      } catch (_) {
        NetworkStatus.instance.setOnline(false);
        doc = await ref.get(const GetOptions(source: Source.cache));
      }
    } else {
      // Offline: use the profile saved on this phone from the last session.
      try {
        doc = await ref.get(const GetOptions(source: Source.cache));
      } catch (_) {
        throw StateError(
          'No internet. Connect once so GrindFit can download your profile for offline use.',
        );
      }
    }
    final data = doc.data();
    final role = data?['role'] as String? ?? 'member';
    AppState.instance.loadProfile(data, fallbackName: user.displayName);

    if (role == 'admin' || role == 'trainer') {
      await FirebaseAuth.instance.signOut();
      return const WelcomeScreen(
        notice: 'Admin and trainer accounts must use the GrindFit Admin web portal, not the mobile app.',
      );
    }

    if (data?['setupCompleted'] == true) {
      return const MainNavigationScreen();
    }

    return const InitialAssessmentScreen();
  }

  Future<void> _startStartup() async {
    Object? startupError;
    Widget? destination;
    final resolution = _resolveDestination()
        .timeout(const Duration(seconds: 15))
        .then<void>(
          (screen) => destination = screen,
          onError: (Object error, StackTrace stackTrace) {
            startupError = error;
          },
        );
    final minimumDuration = Future<void>.delayed(
      const Duration(milliseconds: 1100),
    );

    await Future.wait<void>([
      _controller.forward(),
      minimumDuration,
      resolution,
    ]);

    if (!mounted) return;
    if (startupError != null) {
      debugPrint('Unable to verify the GrindFit account: $startupError');
      setState(() => _startupError = startupError);
      return;
    }

    _navigateTo(destination!);
  }

  void _retryStartup() {
    setState(() => _startupError = null);
    _controller.reset();
    _startStartup();
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
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
          Image.asset(
            'assets/images/splash_bg.png',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) => const ColoredBox(
              color: GrindColors.black,
              child: Center(
                child: Text(
                  'GRINDFIT',
                  style: TextStyle(
                    color: GrindColors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    stops: [0.72, 1],
                    colors: [Colors.transparent, Color(0xE6050505)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 28,
            right: 28,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: FadeTransition(
                opacity: _fadeIn,
                child: _startupError == null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Getting your GrindFit ready',
                            style: TextStyle(
                              color: GrindColors.gray,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: AnimatedBuilder(
                              animation: _progress,
                              builder: (context, child) =>
                                  LinearProgressIndicator(
                                    value: _progress.value,
                                    minHeight: 3,
                                    backgroundColor: GrindColors.gold
                                        .withValues(alpha: 0.25),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          GrindColors.gold,
                                        ),
                                  ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.wifi_off_rounded,
                            color: GrindColors.gold,
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Unable to verify your profile.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: GrindColors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Check your internet connection and try again.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: GrindColors.gray,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _retryStartup,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Try again'),
                            style: TextButton.styleFrom(
                              foregroundColor: GrindColors.gold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
