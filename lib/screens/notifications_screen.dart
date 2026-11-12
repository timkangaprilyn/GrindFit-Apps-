import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../animations/fade_slide_in.dart';
import '../animations/motion.dart';
import '../models/app_state.dart';
import '../models/notification_time.dart';
import '../services/app_notifications.dart';
import '../services/offline_store.dart';
import 'ai_recommendation_update_screen.dart';
import 'analytics_dashboard_screen.dart';
import 'log_workout_screen.dart';
import 'member_features_screen.dart';
import 'rest_day_screen.dart';
import 'workout_history_screen.dart';
import 'workout_plan_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

/// One inbox entry, from Firestore or created on this device.
class _Item {
  _Item({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.route,
    required this.date,
    required this.isRead,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final String route;
  final DateTime? date;
  bool isRead;
}

class _TypeStyle {
  const _TypeStyle(this.icon, this.color, this.label);
  final IconData icon;
  final Color color;
  final String label;
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with WidgetsBindingObserver {
  static const Color _bg = Color(0xFF121212);
  static const Color _card = Color(0xFF1C1C1E);
  static const Color _border = Color(0xFF2E2E31);
  static const Color _gold = Color(0xFFF5B800);
  static const Color _gray = Color(0xFF9CA3AF);
  static const Color _muted = Color(0xFF6B7280);
  static const _filters = [
    'All',
    'Reminders',
    'Updates',
    'Recovery',
    'Achievements',
  ];

  static const _types = {
    'Reminders': _TypeStyle(Icons.fitness_center_rounded, _gold, 'Workout'),
    'Recovery': _TypeStyle(
      Icons.self_improvement_rounded,
      Color(0xFF34D399),
      'Recovery',
    ),
    'Achievements': _TypeStyle(
      Icons.emoji_events_rounded,
      Color(0xFFFB923C),
      'Achievement',
    ),
    'Updates': _TypeStyle(
      Icons.auto_awesome_rounded,
      Color(0xFF60A5FA),
      'Update',
    ),
  };

  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _inbox;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;
  Map<String, dynamic> _settings = const {};
  bool _checkedToday = false;

  /// Created on this device and possibly not synced yet.
  final Map<String, _Item> _local = {};

  /// Marked read here; shown as read before the write reaches the server.
  final Set<String> _readHere = {};
  String _filter = 'All';
  bool? _phoneEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final uid = _uid;
    if (uid != null) {
      _inbox = FirebaseFirestore.instance
          .collection('users/$uid/notifications')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots();
      _profileSub = FirebaseFirestore.instance
          .doc('users/$uid')
          .snapshots()
          .listen(_onProfile, onError: (Object _) {});
    }
    _checkPhone();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _profileSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Returning from phone Settings may have changed the permission.
    if (state == AppLifecycleState.resumed) _checkPhone();
  }

  Future<void> _checkPhone() async {
    final enabled = await AppNotifications.instance.phoneAlertsEnabled();
    if (mounted) setState(() => _phoneEnabled = enabled);
  }

  void _onProfile(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final profile = snapshot.data() ?? const <String, dynamic>{};
    final raw = profile['notificationSettings'];
    setState(() {
      _settings = raw is Map ? Map<String, dynamic>.from(raw) : const {};
    });
    if (_checkedToday) return;
    _checkedToday = true;
    unawaited(_addDailyNotices(profile));
  }

  bool _enabled(String type) => switch (type) {
    'Reminders' => _settings['workout'] != false,
    'Recovery' => _settings['rest'] != false,
    'Achievements' => _settings['achievements'] != false,
    _ => true,
  };

  // ---------------------------------------------------------------------
  // Daily notices: a workout reminder on training days, and a rest-day
  // nudge after five days in a row. Written once per day, without waiting
  // for the server, so this screen also works offline.
  // ---------------------------------------------------------------------
  Future<void> _addDailyNotices(Map<String, dynamic> profile) async {
    final uid = _uid;
    if (uid == null) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final key = DateFormat('yyyy-MM-dd').format(today);
    List<DateTime> recent;
    try {
      final workouts = await FirebaseFirestore.instance
          .collection('users/$uid/workouts')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(
              today.subtract(const Duration(days: 6)),
            ),
          )
          .get();
      recent = workouts.docs
          .map((d) => d.data()['timestamp'])
          .whereType<Timestamp>()
          .map((t) {
            final d = t.toDate();
            return DateTime(d.year, d.month, d.day);
          })
          .toList();
    } catch (_) {
      return; // Without workout history, do not guess.
    }

    final days = profile['workoutDays'];
    final trainingDay =
        days is List &&
        days.whereType<String>().contains(DateFormat('E').format(now));
    if (trainingDay && !recent.contains(today)) {
      await _addOnce(
        id: 'workout-reminder-$key',
        title: 'Workout day',
        body: "Today is one of your training days. Open your plan when you're ready to start.",
        type: 'Reminders',
        route: 'workout',
      );
    }

    final trained = recent.toSet();
    var streak = 0;
    var day = trained.contains(today)
        ? today
        : today.subtract(const Duration(days: 1));
    while (trained.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    if (streak >= 5) {
      await _addOnce(
        id: 'recovery-$key',
        title: 'Time for a rest day',
        body:
            "You've trained $streak days in a row. A recovery day helps you come back stronger.",
        type: 'Recovery',
        route: 'rest',
      );
    }
  }

  Future<void> _addOnce({
    required String id,
    required String title,
    required String body,
    required String type,
    required String route,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final existing = await FirebaseFirestore.instance
          .doc('users/$uid/notifications/$id')
          .get();
      if (existing.exists) return;
    } catch (_) {
      return; // Unknown whether it exists; avoid a duplicate.
    }
    final now = DateTime.now();
    if (mounted) {
      setState(() {
        _local[id] = _Item(
          id: id,
          title: title,
          body: body,
          type: type,
          route: route,
          date: now,
          isRead: false,
        );
      });
    }
    try {
      await OfflineStore.instance.write('users/$uid/notifications/$id', {
        'title': title,
        'subtitle': body,
        'type': type,
        'route': route,
        'isRead': false,
        'timestamp': now,
      });
    } catch (_) {}
  }

  // ---------------------------------------------------------------------
  // Reading and opening
  // ---------------------------------------------------------------------
  List<_Item> _items(QuerySnapshot<Map<String, dynamic>>? snapshot) {
    final byId = <String, _Item>{..._local};
    final docs =
        snapshot?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final doc in docs) {
      final data = doc.data();
      // A server timestamp not yet confirmed reads as null; it was just made.
      final stamp =
          data['timestamp'] ??
          (doc.metadata.hasPendingWrites ? Timestamp.now() : null);
      byId[doc.id] = _Item(
        id: doc.id,
        title: data['title']?.toString() ?? 'GrindFit update',
        body: data['subtitle']?.toString() ?? '',
        type: _types.containsKey(data['type'])
            ? data['type'] as String
            : 'Updates',
        route: data['route']?.toString() ?? 'analytics',
        date: switch (stamp) {
          Timestamp value => value.toDate(),
          String value => DateTime.tryParse(value),
          _ => DateTime.tryParse(data['date']?.toString() ?? ''),
        },
        isRead: data['isRead'] == true,
      );
    }
    final items = byId.values.where((i) => _enabled(i.type)).toList()
      ..sort((a, b) {
        if (a.date == null) return b.date == null ? 0 : 1;
        if (b.date == null) return -1;
        return b.date!.compareTo(a.date!);
      });
    for (final item in items) {
      if (_readHere.contains(item.id)) item.isRead = true;
    }
    return items;
  }

  void _markRead(Iterable<_Item> items) {
    final uid = _uid;
    if (uid == null) return;
    final unread = items.where((i) => !i.isRead).toList();
    if (unread.isEmpty) return;
    setState(() {
      for (final item in unread) {
        _readHere.add(item.id);
        item.isRead = true;
      }
    });
    for (final item in unread) {
      unawaited(
        OfflineStore.instance
            .write('users/$uid/notifications/${item.id}', {
              'isRead': true,
            }, merge: true)
            .catchError((Object _) {}),
      );
    }
  }

  void _open(_Item item) {
    _markRead([item]);
    final Widget page = switch (item.route) {
      'ai' => const AiRecommendationUpdateScreen(),
      'rest' => const RestDayScreen(),
      'log' => const LogWorkoutScreen(),
      'workout' => WorkoutPlanDetailScreen(
        exercises: AppState.instance.recommendedPlan,
      ),
      'history' => const WorkoutHistoryScreen(),
      'coach' => const MemberFeaturesScreen(),
      _ => const AnalyticsDashboardScreen(),
    };
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _turnOnPhoneAlerts() async {
    final allowed = await AppNotifications.instance.requestPermissions();
    await _checkPhone();
    if (!mounted || allowed || _phoneEnabled == true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Notifications are blocked for GrindFit. Open your phone Settings › Apps › GrindFit › Notifications and turn them on.',
        ),
        duration: Duration(seconds: 6),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          tooltip: 'Back',
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
      ),
      body: _inbox == null
          ? _emptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Sign in to see notifications',
              body: 'Your reminders and updates appear here once you sign in.',
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _inbox,
              builder: (context, snapshot) {
                if (snapshot.hasError && !snapshot.hasData) {
                  return _emptyState(
                    icon: Icons.cloud_off_rounded,
                    title: 'Could not load notifications',
                    body:
                        'Check your connection, then come back to this screen.',
                  );
                }
                if (!snapshot.hasData && _local.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: _gold),
                  );
                }
                return _content(_items(snapshot.data));
              },
            ),
    );
  }

  Widget _content(List<_Item> all) {
    final unread = all.where((i) => !i.isRead).toList();
    final shown = _filter == 'All'
        ? all
        : all.where((i) => i.type == _filter).toList();
    final now = DateTime.now();

    final children = <Widget>[
      if (_phoneEnabled == false) _phoneOffCard(),
      _summary(unread),
      const SizedBox(height: 14),
      _filterBar(all),
      const SizedBox(height: 6),
    ];

    if (shown.isEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 40),
          child: _emptyState(
            icon: Icons.notifications_none_rounded,
            title: _filter == 'All'
                ? "You're all caught up"
                : 'No ${_filter.toLowerCase()} yet',
            body: 'Workout reminders, recovery tips and achievements will show up here.',
          ),
        ),
      );
    } else {
      String? section;
      for (final (index, item) in shown.indexed) {
        final heading = notificationSection(item.date, now);
        if (heading != section) {
          section = heading;
          children.add(_sectionHeader(heading));
        }
        children.add(
          FadeSlideIn(
            delay: Motion.step * index.clamp(0, 6),
            duration: Motion.medium,
            offset: const Offset(0, .04),
            child: _tile(item, now),
          ),
        );
      }
      children.add(
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text(
            'Swipe a notification to mark it as read.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 11.5),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: children,
    );
  }

  Widget _summary(List<_Item> unread) {
    final count = unread.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_gold.withAlpha(46), _card],
        ),
        border: Border.all(color: _gold.withAlpha(70)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _gold,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.notifications_rounded,
              color: Colors.black,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count == 0
                      ? 'All caught up'
                      : count == 1
                      ? '1 unread'
                      : '$count unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  count == 0
                      ? 'Nice work staying on top of things.'
                      : 'Tap one to open it.',
                  style: const TextStyle(color: _gray, fontSize: 12.5),
                ),
              ],
            ),
          ),
          if (count > 0)
            TextButton.icon(
              onPressed: () => _markRead(unread),
              style: TextButton.styleFrom(foregroundColor: _gold),
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text(
                'Mark all',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }

  Widget _phoneOffCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1F12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7C5A1A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_off_rounded, color: _gold),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Phone alerts are off, so reminders won't appear when the app is closed.",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _turnOnPhoneAlerts,
            style: FilledButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              minimumSize: const Size(0, 36),
            ),
            child: const Text(
              'Turn on',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterBar(List<_Item> all) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final selected = _filter == filter;
          final unread = all
              .where((i) => !i.isRead && (filter == 'All' || i.type == filter))
              .length;
          return ChoiceChip(
            selected: selected,
            showCheckmark: false,
            onSelected: (_) => setState(() => _filter = filter),
            backgroundColor: _card,
            selectedColor: _gold,
            side: BorderSide(color: selected ? _gold : _border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  filter,
                  style: TextStyle(
                    color: selected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                if (unread > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? Colors.black : _gold,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unread',
                      style: TextStyle(
                        color: selected ? _gold : Colors.black,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: _muted,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
      ),
    ),
  );

  Widget _tile(_Item item, DateTime now) {
    final style = _types[item.type] ?? _types['Updates']!;
    final unread = !item.isRead;
    final tile = Material(
      color: unread ? const Color(0xFF211F1A) : _card,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(item),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: unread ? _gold.withAlpha(90) : _border),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  color: unread ? style.color : Colors.transparent,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: style.color.withAlpha(36),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(style.icon, color: style.color, size: 21),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    style.label.toUpperCase(),
                                    style: TextStyle(
                                      color: style.color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    notificationTime(item.date, now),
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (unread) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: _gold,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                item.title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: unread
                                      ? FontWeight.w800
                                      : FontWeight.w700,
                                ),
                              ),
                              if (item.body.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  item.body,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _gray,
                                    fontSize: 12.5,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: unread
          ? Dismissible(
              key: ValueKey('unread-${item.id}'),
              direction: DismissDirection.horizontal,
              confirmDismiss: (_) async {
                _markRead([item]);
                return false; // Keep it in the list, now read.
              },
              background: _swipeBackground(Alignment.centerLeft),
              secondaryBackground: _swipeBackground(Alignment.centerRight),
              child: tile,
            )
          : tile,
    );
  }

  Widget _swipeBackground(Alignment alignment) => Container(
    alignment: alignment,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      color: _gold.withAlpha(40),
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.done_rounded, color: _gold, size: 20),
        SizedBox(width: 6),
        Text(
          'Mark read',
          style: TextStyle(color: _gold, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _gold.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _gold, size: 34),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _gray, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
