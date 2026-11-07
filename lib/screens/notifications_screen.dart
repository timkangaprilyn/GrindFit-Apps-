import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'analytics_dashboard_screen.dart';
import 'log_workout_screen.dart';
import 'rest_day_screen.dart';
import 'ai_recommendation_update_screen.dart';
import 'workout_history_screen.dart';

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
  String _selectedFilter = 'All';
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _notifications.clear();
      });
      return;
    }

    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final profileDoc = await userRef.get();
      final profile = profileDoc.data() ?? const <String, dynamic>{};
      final rawSettings = profile['notificationSettings'];
      final settings = rawSettings is Map
          ? rawSettings
          : const <String, dynamic>{};
      final workoutEnabled = settings['workout'] is bool
          ? settings['workout'] as bool
          : true;
      final restEnabled = settings['rest'] is bool
          ? settings['rest'] as bool
          : true;
      final achievementsEnabled = settings['achievements'] is bool
          ? settings['achievements'] as bool
          : true;
      final result = await userRef
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      final notifications = result.docs
          .map((doc) {
            final data = doc.data();
            final rawDate = data['timestamp'];
            final DateTime? date = switch (rawDate) {
              Timestamp value => value.toDate(),
              DateTime value => value,
              String value => DateTime.tryParse(value),
              _ => DateTime.tryParse(data['date']?.toString() ?? ''),
            };
            return {
              ...data,
              'id': doc.id,
              'title': data['title']?.toString() ?? 'Notification',
              'subtitle': data['subtitle']?.toString() ?? '',
              'date': date,
              'type': data['type']?.toString() ?? 'Updates',
              'icon': _iconForType(data['type']?.toString()),
              'isRead': data['isRead'] == true,
              'route': data['route']?.toString() ?? 'analytics',
            };
          })
          .where((item) {
            return switch (item['type']) {
              'Reminders' => workoutEnabled,
              'Recovery' => restEnabled,
              'Achievements' => achievementsEnabled,
              _ => true,
            };
          })
          .toList();
      if (workoutEnabled) {
        final workoutReminder = await _ensureWorkoutReminder(user, profile);
        if (workoutReminder != null) notifications.insert(0, workoutReminder);
      }
      final recoveryNotification = restEnabled
          ? await _ensureRecoveryNotification(user)
          : null;
      if (recoveryNotification != null &&
          !notifications.any(
            (item) => item['id'] == recoveryNotification['id'],
          )) {
        notifications.insert(0, recoveryNotification);
      }
      if (!mounted) return;
      setState(() {
        _notifications
          ..clear()
          ..addAll(notifications);
        _isLoading = false;
        _loadError = null;
      });
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError =
            error.message ?? 'Could not load notifications. Please try again.';
      });
    }
  }

  Future<Map<String, dynamic>?> _ensureWorkoutReminder(
    User user,
    Map<String, dynamic> profile,
  ) async {
    final today = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(today);
    final weekdays = profile['workoutDays'];
    if (weekdays is! List ||
        !weekdays.whereType<String>().contains(DateFormat('E').format(today))) {
      return null;
    }

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final startOfDay = DateTime(today.year, today.month, today.day);
    final workoutsToday = await userRef
        .collection('workouts')
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .get();
    final completedToday = workoutsToday.docs.any((doc) {
      final timestamp = doc.data()['timestamp'];
      return timestamp is Timestamp &&
          timestamp.toDate().isBefore(startOfDay.add(const Duration(days: 1)));
    });
    if (completedToday) return null;

    final notificationId = 'workout-reminder-$todayKey';
    final notificationRef = userRef
        .collection('notifications')
        .doc(notificationId);
    final existingNotification = await notificationRef.get();
    if (existingNotification.exists) return null;

    const title = 'Workout Reminder';
    final subtitle =
        'It is a planned workout day. Open GrindFit to start your session.';
    await notificationRef.set({
      'title': title,
      'subtitle': subtitle,
      'type': 'Reminders',
      'route': 'log',
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
    return {
      'id': notificationId,
      'title': title,
      'subtitle': subtitle,
      'type': 'Reminders',
      'icon': _iconForType('Reminders'),
      'isRead': false,
      'route': 'log',
      'date': today,
    };
  }

  Future<Map<String, dynamic>?> _ensureRecoveryNotification(User user) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final workouts = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('workouts')
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(
            today.subtract(const Duration(days: 6)),
          ),
        )
        .get();

    final workoutDays = workouts.docs
        .map((doc) => doc.data()['timestamp'])
        .whereType<Timestamp>()
        .map((timestamp) {
          final date = timestamp.toDate();
          return DateTime(date.year, date.month, date.day);
        })
        .toSet();

    var streakStart = today;
    if (!workoutDays.contains(streakStart)) {
      streakStart = today.subtract(const Duration(days: 1));
    }

    var streak = 0;
    for (
      var day = streakStart;
      workoutDays.contains(day);
      day = day.subtract(const Duration(days: 1))
    ) {
      streak++;
    }
    if (streak < 5) return null;

    final notificationId = 'recovery-${DateFormat('yyyy-MM-dd').format(today)}';
    final notificationRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .doc(notificationId);
    final existingNotification = await notificationRef.get();
    if (existingNotification.exists) return null;

    final subtitle =
        "You've trained $streak days in a row. Take a rest day to recover.";
    await notificationRef.set({
      'title': 'Rest Day Alert',
      'subtitle': subtitle,
      'type': 'Recovery',
      'route': 'rest',
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });

    return {
      'id': notificationId,
      'title': 'Rest Day Alert',
      'subtitle': subtitle,
      'type': 'Recovery',
      'icon': _iconForType('Recovery'),
      'isRead': false,
      'route': 'rest',
      'date': now,
    };
  }

  IconData _iconForType(String? type) {
    return switch (type) {
      'Reminders' => Icons.fitness_center_rounded,
      'Recovery' => Icons.self_improvement_rounded,
      'Achievements' => Icons.emoji_events_rounded,
      _ => Icons.auto_awesome_rounded,
    };
  }

  List<Map<String, dynamic>> get filteredNotifications {
    final items = _selectedFilter == 'All'
        ? _notifications
        : _notifications.where((n) => n['type'] == _selectedFilter).toList();
    final sorted = List<Map<String, dynamic>>.from(items);
    sorted.sort((a, b) {
      final aDate = a['date'] as DateTime?;
      final bDate = b['date'] as DateTime?;
      if (aDate == null) return bDate == null ? 0 : 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    return sorted;
  }

  String _formatDate(DateTime date) {
    final difference = _today.difference(date).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return DateFormat('EEE, MMM d').format(date);
  }

  Future<void> _markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final batch = FirebaseFirestore.instance.batch();
      final notifications = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications');
      for (final item in _notifications) {
        if (item['isRead'] == true) continue;
        batch.update(notifications.doc(item['id'] as String), {'isRead': true});
      }
      await batch.commit();
      if (mounted) {
        setState(() {
          for (final item in _notifications) {
            item['isRead'] = true;
          }
        });
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.message ?? 'Could not mark notifications as read.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _markAsRead(Map<String, dynamic> item) async {
    if (item['isRead'] == true) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(item['id'] as String)
          .update({'isRead': true});
      if (mounted) setState(() => item['isRead'] = true);
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.message ?? 'Could not mark the notification as read.',
            ),
          ),
        );
      }
    }
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LogWorkoutScreen()),
        );
        break;
      case 'history':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WorkoutHistoryScreen()),
        );
        break;
      default:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnalyticsDashboardScreen()),
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
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: _white),
          tooltip: 'Back',
        ),
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
            IconButton(
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
              icon: const Icon(Icons.done_all_rounded, color: _gold),
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
            color: _card,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children:
                    [
                      'All',
                      'Reminders',
                      'Updates',
                      'Recovery',
                      'Achievements',
                    ].map((filter) {
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
                              color: isSelected
                                  ? _gold
                                  : const Color(0xFF2C2F36),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? _gold : _border,
                              ),
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
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _gold))
                : _loadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _loadError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: _gray),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _loadError = null;
                              });
                              _loadNotifications();
                            },
                            child: const Text(
                              'Try again',
                              style: TextStyle(color: _gold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : filteredNotifications.isEmpty
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
                                builder: (_) => _selectedFilter == 'Recovery'
                                    ? const RestDayScreen()
                                    : const AnalyticsDashboardScreen(),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _gold,
                              foregroundColor: _bg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _selectedFilter == 'Recovery'
                                  ? 'View Recovery Tips'
                                  : 'View Analytics',
                            ),
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
                          isThreeLine: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          minLeadingWidth: 36,
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 2),
                              Text(
                                item['subtitle'],
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _gray,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['date'] is DateTime
                                    ? _formatDate(item['date'] as DateTime)
                                    : 'Date unavailable',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: _muted,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (!isRead)
                                TextButton(
                                  onPressed: () => _markAsRead(item),
                                  style: TextButton.styleFrom(
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.only(top: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Mark as read',
                                    style: TextStyle(
                                      color: _gold,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing: Icon(
                            isRead ? Icons.chevron_right : Icons.circle,
                            color: isRead ? _gray : _gold,
                            size: isRead ? 22 : 9,
                          ),
                          onTap: () {
                            if (!isRead) {
                              _markAsRead(item);
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
    );
  }
}
