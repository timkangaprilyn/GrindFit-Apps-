import 'package:flutter/material.dart';
import '../screens/home_dashboard_screen.dart';
import '../screens/ai_recommendations_screen.dart';
import '../screens/active_workout_session_screen.dart';
// Import din ang iba pang main screens kung kinakailangan

class GrindFitBottomNav extends StatelessWidget {
  final int currentIndex;

  const GrindFitBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == currentIndex) return; // Kung kasalukuyang nasa screen na ito, huwag nang mag-navigate

        Widget targetScreen;
        switch (index) {
          case 0:
            targetScreen = const HomeDashboardScreen();
            break;
          case 1:
            targetScreen = const AiRecommendationsScreen(); // Workouts / Recommendations
            break;
          case 2:
            targetScreen = const ActiveWorkoutSessionScreen(); // Log / Active session
            break;
          case 3:
            targetScreen = const HomeDashboardScreen(); // Analytics / Progress (pwede mong palitan ng Analytics screen)
            break;
          case 4:
            targetScreen = const HomeDashboardScreen(); // Profile (pwede mong palitan ng Profile screen)
            break;
          default:
            targetScreen = const HomeDashboardScreen();
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => targetScreen),
        );
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFFFF5200),
      unselectedItemColor: const Color(0xFF94A3B8),
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Workouts'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Log'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Progress'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
      ],
    );
  }
}