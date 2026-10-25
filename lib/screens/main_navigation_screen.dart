import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_dashboard_screen.dart';
import 'ai_recommendations_screen.dart';
import 'log_workout_screen.dart';
import 'analytics_dashboard_screen.dart';
import 'profile_screen.dart';

/// Iisang "shell" na may iisang BottomNavigationBar para sa buong app.
/// Ginigarantiyahan ng IndexedStack na hindi mawawala ang state ng bawat tab.
///
/// Ang mga tab (Home, Workouts, Log, Analytics, Profile) ay HINDI dapat may
/// sarili pang bottomNavigationBar — dito lang dapat ang navbar.
class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  /// Para makalipat ng tab ang kahit anong screen sa loob ng shell:
  /// MainNavigationScreen.of(context)?.goToTab(1);
  static MainNavigationScreenState? of(BuildContext context) =>
      context.findAncestorStateOfType<MainNavigationScreenState>();

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex = widget.initialIndex;
  DateTime? _lastBackPress;

  // Black + Gold + White palette
  static const Color _bg = Color(0xFF121212); // Charcoal background
  static const Color _card = Color(0xFF1C1C1E); // Bottom Nav surface
  static const Color _border = Color(0xFF2E2E31);
  static const Color _gold = Color(0xFFF5B800); // Gold highlight
  static const Color _gray = Color(0xFF9CA3AF); // Secondary text

  static const List<Widget> _tabs = [
    HomeDashboardScreen(),
    AiRecommendationsScreen(),
    LogWorkoutScreen(),
    AnalyticsDashboardScreen(),
    ProfileScreen(),
  ];

  void goToTab(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  // Back button:
  //  - Kung nasa ibang tab → balik sa Home (nandoon pa rin ang navbar)
  //  - Kung nasa Home → pindutin ulit para lumabas ng app
  // Hindi na magpo-pop ang buong shell kaya hindi na mawawala ang navbar.
  void _handleBack() {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return;
    }

    final now = DateTime.now();
    final bool confirmed = _lastBackPress != null &&
        now.difference(_lastBackPress!) < const Duration(seconds: 2);

    if (confirmed) {
      SystemNavigator.pop();
      return;
    }

    _lastBackPress = now;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF2A2A2D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: _gold.withValues(alpha: 0.5)),
          ),
          content: const Text(
            'Press back again to exit',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: _card,
            border: Border(top: BorderSide(color: _border, width: 1)),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: goToTab,
            backgroundColor: Colors.transparent,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: _gold,
            unselectedItemColor: _gray,
            selectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            elevation: 0,
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
        ),
      ),
    );
  }
}