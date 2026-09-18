import 'package:flutter/material.dart';
import 'home_dashboard_screen.dart';
import 'ai_recommendations_screen.dart';
import 'log_workout_screen.dart';
import 'analytics_dashboard_screen.dart';
import 'profile_screen.dart';

/// Iisang "shell" na may iisang BottomNavigationBar para sa buong app.
///
/// Dati, bawat tab screen (Home, Workouts, Log, Analytics) ay may sarili-
/// sariling Scaffold + BottomNavigationBar, at `Navigator.pushReplacement`
/// ang ginagamit kada tap — kaya bumubuo ng bagong screen mula zero
/// (may page-transition pa) kada tab switch, at kapag may nakalimutan
/// i-code sa isang screen, hindi gumagana ang tab doon.
///
/// Dito, IndexedStack ang gumagamit — lahat ng 5 tabs ay nakabuo na sa
/// memory, at ang pag-switch ay basta pagpalit lang ng index na ipinapakita.
/// Instant, walang animation lag, at hindi nawawala ang state ng bawat tab
/// (hal. scroll position, Weekly/Monthly toggle sa Analytics).
///
/// Gamitin ito bilang entry point papunta sa main app (hal. pagkatapos
/// mag-login o pagkatapos makumpleto ang onboarding/Plan Ready screen):
///
/// ```dart
/// Navigator.pushReplacement(
///   context,
///   MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
/// );
/// ```
///
/// Kung gusto mong direktang magbukas sa ibang tab (hal. mula sa
/// Workout History pabalik sa Analytics tab), gamitin ang `initialIndex`:
///
/// ```dart
/// MainNavigationScreen(initialIndex: 3)
/// ```
class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex = widget.initialIndex;

  static const List<Widget> _tabs = [
    HomeDashboardScreen(),
    AiRecommendationsScreen(),
    LogWorkoutScreen(),
    AnalyticsDashboardScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFFF5200),
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Workouts'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Log'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}