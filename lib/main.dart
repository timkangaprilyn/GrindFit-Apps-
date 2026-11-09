import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/offline_store.dart';
import 'services/voice_coach.dart';
import 'theme/grindfit_theme.dart';
import 'services/app_notifications.dart';
import 'widgets/notification_popup_host.dart';
import 'screens/notifications_screen.dart';
import 'screens/workout_history_screen.dart';
import 'screens/rest_day_screen.dart';
import 'screens/ai_recommendations_screen.dart';
import 'screens/member_features_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'models/app_alert.dart';
import 'models/app_state.dart';
import 'screens/workout_plan_detail_screen.dart';

final grindFitNavigatorKey = GlobalKey<NavigatorState>();

void _openAlert(AppAlert alert) {
  if (FirebaseAuth.instance.currentUser?.uid != alert.ownerUid) return;
  final navigator = grindFitNavigatorKey.currentState;
  if (navigator == null) return;
  AppNotifications.instance.markRead(alert);
  final Widget page = switch (alert.route) {
    'history' => const WorkoutHistoryScreen(),
    'rest' => const RestDayScreen(),
    'workout' || 'log' => WorkoutPlanDetailScreen(
      exercises: AppState.instance.recommendedPlan,
    ),
    'ai' => const AiRecommendationsScreen(),
    'coach' => const MemberFeaturesScreen(),
    _ => const NotificationsScreen(),
  };
  navigator.push(MaterialPageRoute(builder: (_) => page));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await OfflineStore.instance.initialize();
  await VoiceCoach.instance.initialize();
  await AppNotifications.instance.initialize();
  AppNotifications.instance.onOpen = _openAlert;
  runApp(const GrindFitApp());
}

class GrindFitApp extends StatelessWidget {
  const GrindFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GrindFit',
      navigatorKey: grindFitNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: GrindFitTheme.dark,
      builder: (context, child) => NotificationPopupHost(
        alerts: AppNotifications.instance.alerts,
        onOpen: _openAlert,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const SplashScreen(),
    );
  }
}
