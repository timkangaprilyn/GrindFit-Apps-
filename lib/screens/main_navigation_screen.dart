import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_state.dart';
import '../widgets/sync_status.dart';
import '../services/app_notifications.dart';
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

class MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex = widget.initialIndex;
  DateTime? _lastBackPress;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _activity;
  late final AnimationController _tabController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    value: 1,
  );
  late final Animation<double> _tabFade = _tabController.drive(
    Tween(begin: .85, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic)),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppNotifications.instance.requestPermissions(once: true);
      AppNotifications.instance.openPending();
    });
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _activity = FirebaseFirestore.instance
          .collection('users/$uid/workouts')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots()
          .listen(
            (snapshot) {
              AppState.instance.updateActivity(
                snapshot.docs
                    .map((doc) => doc.data()['timestamp'])
                    .whereType<Timestamp>()
                    .map((t) => t.toDate()),
              );
              AppNotifications.instance.onWorkoutDates(
                snapshot.docs
                    .map((d) => d.data()['timestamp'])
                    .whereType<Timestamp>()
                    .map((t) => t.toDate()),
              );
            },
            onError: (Object _) {
              /* Keep the cached plan available offline. */
            },
          );
    }
  }

  @override
  void dispose() {
    _activity?.cancel();
    _tabController.dispose();
    super.dispose();
  }

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
    if (!MediaQuery.disableAnimationsOf(context)) {
      _tabController.forward(from: 0);
    }
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
    final bool confirmed =
        _lastBackPress != null &&
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
        body: Column(
          children: [
            const SyncStatus(),
            Expanded(
              child: FadeTransition(
                opacity: _tabFade,
                child: IndexedStack(
                  index: _currentIndex,
                  children: [
                    for (var i = 0; i < _tabs.length; i++)
                      TickerMode(
                        enabled: i == _currentIndex,
                        child: RepaintBoundary(child: _tabs[i]),
                      ),
                  ],
                ),
              ),
            ),
          ],
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
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            elevation: 0,
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
                icon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
