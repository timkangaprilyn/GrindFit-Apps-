import 'package:flutter/material.dart';
import 'home_dashboard_screen.dart';
import 'ai_recommendations_screen.dart';
import 'log_workout_screen.dart';
import 'rest_day_screen.dart';
import 'ai_recommendation_update_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _currentIndex = 3;
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Workout Reminder',
      'subtitle': 'Time for your scheduled workout',
      'time': 'Today, 8:00 AM',
      'type': 'Reminders',
      'icon': Icons.fitness_center_rounded,
    },
    {
      'title': 'Rest Day Alert',
      'subtitle': 'It’s time to rest and recover',
      'time': 'Thu, Apr 24',
      'type': 'Reminders',
      'icon': Icons.self_improvement_rounded,
      'isRestDay': true,
    },
    {
      'title': 'New Recommendation',
      'subtitle': 'Your plan has been updated',
      'time': 'Apr 20, 2026',
      'type': 'Updates',
      'icon': Icons.auto_awesome_rounded,
      'isAiUpdate': true,
    },
    {
      'title': 'Goal Milestone',
      'subtitle': 'You completed 10 workouts!',
      'time': 'Apr 18, 2026',
      'type': 'Updates',
      'icon': Icons.emoji_events_rounded,
    },
    {
      'title': 'Workout Reminder',
      'subtitle': 'Don’t forget your workout',
      'time': 'Apr 17, 2026',
      'type': 'Reminders',
      'icon': Icons.fitness_center_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredNotifications = _selectedFilter == 'All'
        ? _notifications
        : _notifications.where((n) => n['type'] == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.white,
            child: Row(
              children: ['All', 'Reminders', 'Updates'].map((filter) {
                bool isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFF5200) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: filteredNotifications.length,
              itemBuilder: (context, index) {
                final item = filteredNotifications[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5200).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item['icon'], color: const Color(0xFFFF5200), size: 20),
                    ),
                    title: Text(
                      item['title'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          item['subtitle'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['time'],
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                    onTap: () {
                      // Direktang sinusuri kung ito ba ang AI Update o Rest Day
                      if (item['title'] == 'New Recommendation' || item['isAiUpdate'] == true) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AiRecommendationUpdateScreen()),
                        );
                      } else if (item['isRestDay'] == true) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RestDayScreen()),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
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
              MaterialPageRoute(builder: (_) => const AiRecommendationsScreen()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LogWorkoutScreen()),
            );
          } else if (index == 3) {
            // Nasa Notifications na
          }
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
          BottomNavigationBarItem(icon: Icon(Icons.notifications_rounded), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}