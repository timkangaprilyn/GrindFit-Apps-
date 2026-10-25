import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'analytics_dashboard_screen.dart';
import 'home_dashboard_screen.dart';
import 'ai_recommendations_screen.dart';
import 'log_workout_screen.dart';
import 'profile_screen.dart';
import 'rest_day_screen.dart';
import 'ai_recommendation_update_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color _bg = Color(0xFF121212);
  static const Color _card = Color(0xFF1C1C1E);
  static const Color _border = Color(0xFF2E2E31);
  static const Color _gold = Color(0xFFF5B800);
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9CA3AF);
  static const Color _muted = Color(0xFF6B7280);

  final DateTime _today = DateTime.now();
  final List<Map<String, dynamic>> _notifications = [];
  int _currentIndex = 4;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _notifications.addAll([
      {
        'title': 'Workout Reminder',
        'subtitle': 'Time for your scheduled workout',
        'date': _today,
        'type': 'Reminders',
        'icon': Icons.fitness_center_rounded,
        'isRead': false,
        'route': 'log',
      },
      {
        'title': 'Rest Day Alert',
        'subtitle': 'It’s time to rest and recover',
        'date': _today.subtract(const Duration(days: 1)),
        'type': 'Reminders',
        'icon': Icons.self_improvement_rounded,
        'isRead': false,
        'route': 'rest',
      },
      {
        'title': 'New Recommendation',
        'subtitle': 'Your plan has been updated',
        'date': _today.subtract(const Duration(days: 2)),
        'type': 'Updates',
        'icon': Icons.auto_awesome_rounded,
        'isRead': true,
        'route': 'ai',
      },
      {
        'title': 'Goal Milestone',
        'subtitle': 'You completed 10 workouts!',
        'date': _today.subtract(const Duration(days: 4)),
        'type': 'Updates',
        'icon': Icons.emoji_events_rounded,
        'isRead': true,
        'route': 'analytics',
      },
      {
        'title': 'Workout Reminder',
        'subtitle': 'Don’t forget your workout',
        'date': _today.subtract(const Duration(days: 6)),
        'type': 'Reminders',
        'icon': Icons.fitness_center_rounded,
        'isRead': false,
        'route': 'log',
      },
    ]);
  }

  List<Map<String, dynamic>> get filteredNotifications {
    final items = _selectedFilter == 'All'
        ? _notifications
        : _notifications.where((n) => n['type'] == _selectedFilter).toList();
    final sorted = List<Map<String, dynamic>>.from(items);
    sorted.sort(
      (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
    );
    return sorted;
  }

  String _formatDate(DateTime date) {
    final difference = _today.difference(date).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return DateFormat('EEE, MMM d').format(date);
  }

  void _markAllAsRead() {
    setState(() {
      for (final item in _notifications) {
        item['isRead'] = true;
      }
    });
  }

  void _markAsRead(int index) {
    setState(() {
      final item = filteredNotifications[index];
      item['isRead'] = true;
    });
  }

  void _openNotification(Map<String, dynamic> item) {
    switch (item['route']) {
      case 'ai':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AiRecommendationUpdateScreen(),
          ),
        );
        break;
      case 'rest':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RestDayScreen()),
        );
        break;
      case 'analytics':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnalyticsDashboardScreen()),
        );
        break;
      case 'log':
      default:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LogWorkoutScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications
        .where((n) => !(n['isRead'] as bool))
        .length;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: _white,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all as read',
                style: TextStyle(color: _gold, fontWeight: FontWeight.w800),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: _border, height: 1.0),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: _card,
            child: Row(
              children: ['All', 'Reminders', 'Updates'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? _gold : const Color(0xFF2C2F36),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? _gold : _border),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? _bg : _white,
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
            child: filteredNotifications.isEmpty
                ? Center(
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.notifications_off_rounded,
                            color: _gold,
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No notifications',
                            style: TextStyle(
                              color: _white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'You are all caught up for now.',
                            style: TextStyle(color: _gray, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AnalyticsDashboardScreen(),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _gold,
                              foregroundColor: _bg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('View Analytics'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    itemCount: filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final item = filteredNotifications[index];
                      final isRead = item['isRead'] as bool;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: _card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isRead
                                ? _border
                                : _gold.withValues(alpha: 0.8),
                            width: isRead ? 1.2 : 1.4,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _gold.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(item['icon'], color: _gold, size: 20),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item['title'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: _white,
                                  ),
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: _gold,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(
                                item['subtitle'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _gray,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(item['date'] as DateTime),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: _muted,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.chevron_right, color: _gray),
                              if (!isRead)
                                TextButton(
                                  onPressed: () => _markAsRead(
                                    filteredNotifications.indexOf(item),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 0),
                                  ),
                                  child: const Text(
                                    'Mark as read',
                                    style: TextStyle(
                                      color: _gold,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onTap: () {
                            if (!isRead) {
                              _markAsRead(filteredNotifications.indexOf(item));
                            }
                            _openNotification(item);
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
        backgroundColor: _card,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const AiRecommendationsScreen(),
              ),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LogWorkoutScreen()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const AnalyticsDashboardScreen(),
              ),
            );
          } else if (index == 5) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _gold,
        unselectedItemColor: _gray,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Workouts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Log',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_rounded),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
