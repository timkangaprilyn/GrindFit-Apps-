import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/app_alert.dart';
import '../models/training_program.dart';
import '../models/workout_plan.dart';
import 'offline_store.dart';

class AppNotifications with WidgetsBindingObserver {
  AppNotifications._();
  static final instance = AppNotifications._();
  final _plugin = FlutterLocalNotificationsPlugin();
  final _events = StreamController<AppAlert?>.broadcast(sync: true);
  Stream<AppAlert?> get alerts => _events.stream;
  ValueChanged<AppAlert>? onOpen;
  AppAlert? _pendingOpen;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profile;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _inbox;
  String? _uid;
  Map<String, dynamic> _settings = {};
  Map<String, dynamic> _profileData = {};
  bool _nativeReady = false;
  bool _foreground = true;
  bool _scheduleAgain = false;
  bool _scheduling = false;
  String _scheduleKey = '';
  String _completedToday = '';
  SharedPreferences? _prefs;
  Timer? _dailyTimer;
  String _popupDay = '';
  bool get _mobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'grindfit_alerts_v1',
      'GrindFit alerts',
      channelDescription: 'Workout reminders, recovery and member updates',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_grindfit',
      color: Color(0xFFF5B800),
      visibility: NotificationVisibility.private,
      onlyAlertOnce: true,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    ),
  );

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    WidgetsBinding.instance.addObserver(this);
    _dailyTimer?.cancel();
    _dailyTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkDailyPopup(),
    );
    if (_mobile) {
      try {
        tzdata.initializeTimeZones();
        final zone = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(zone.identifier));
        await _plugin.initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('ic_stat_grindfit'),
            iOS: DarwinInitializationSettings(
              requestAlertPermission: false,
              requestBadgePermission: false,
              requestSoundPermission: false,
            ),
          ),
          onDidReceiveNotificationResponse: (response) =>
              _handlePayload(response.payload),
        );
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(
              const AndroidNotificationChannel(
                'grindfit_alerts_v1',
                'GrindFit alerts',
                description: 'Workout reminders, recovery and member updates',
                importance: Importance.high,
              ),
            );
        _nativeReady = true;
        final launch = await _plugin.getNotificationAppLaunchDetails();
        if (launch?.didNotificationLaunchApp == true) {
          _handlePayload(launch?.notificationResponse?.payload);
        }
      } catch (_) {
        _nativeReady = false;
      } // In-app alerts still work.
    }
    FirebaseAuth.instance.authStateChanges().listen(
      (user) => unawaited(_bind(user?.uid)),
    );
  }

  Future<void> _bind(String? uid) async {
    if (_uid == uid) return;
    _uid = uid;
    _events.add(null);
    final oldProfile = _profile;
    final oldInbox = _inbox;
    _profile = null;
    _inbox = null;
    await oldProfile?.cancel();
    await oldInbox?.cancel();
    if (_uid != uid) return;
    _settings = {};
    _profileData = {};
    _scheduleKey = '';
    _completedToday = '';
    _popupDay = '';
    if (_nativeReady) {
      try {
        await _plugin.cancelAll();
      } catch (_) {}
    }
    if (_uid != uid || uid == null) return;
    final started = DateTime.now();
    final gate = AlertDeliveryGate(started);
    var initial = true;
    _profile = FirebaseFirestore.instance.doc('users/$uid').snapshots().listen((
      snapshot,
    ) {
      if (_uid != uid) return;
      _profileData = snapshot.data() ?? {};
      _settings = _profileData['notificationSettings'] is Map
          ? Map<String, dynamic>.from(
              _profileData['notificationSettings'] as Map,
            )
          : {};
      unawaited(_reschedule());
      // Let the root popup host attach before delivering a cached reminder.
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkDailyPopup());
      _inbox ??= FirebaseFirestore.instance
          .collection('users/$uid/notifications')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots()
          .listen(
            (inbox) {
              if (_uid != uid) return;
              for (final doc in inbox.docs) {
                final data = doc.data();
                final stamp = data['timestamp'];
                final alert = AppAlert(
                  id: doc.id,
                  title: data['title']?.toString() ?? 'GrindFit update',
                  body: data['subtitle']?.toString() ?? '',
                  type: data['type']?.toString() ?? 'Updates',
                  route: data['route']?.toString() ?? 'notifications',
                  ownerUid: uid,
                  isRead: data['isRead'] == true,
                  createdAt: stamp is Timestamp ? stamp.toDate() : null,
                );
                if (gate.accept(alert, initial: initial, settings: _settings)) {
                  deliver(alert);
                }
              }
              initial = false;
            },
            onError: (Object _) {
              /* Cached inbox remains accessible. */
            },
          );
    }, onError: (Object _) {});
  }

  void deliver(AppAlert alert) {
    if (alert.ownerUid != _uid || !alert.enabledBy(_settings)) return;
    if (_foreground) {
      _events.add(alert);
    } else {
      unawaited(_showPhone(alert));
    }
  }

  void previewPopup() {
    final uid = _uid;
    if (uid == null) return;
    _events.add(
      AppAlert(
        id: 'preview-${DateTime.now().microsecondsSinceEpoch}',
        title: 'Notifications are ready',
        body: 'Workout reminders and new updates will appear here.',
        ownerUid: uid,
      ),
    );
  }

  Future<bool> testPhoneAlert() async {
    if (!await requestPermissions()) return false;
    final uid = _uid;
    if (uid == null) return false;
    return _showPhone(
      AppAlert(
        id: 'phone-test',
        title: 'GrindFit notifications are on',
        body: 'Your phone can now show workout and recovery alerts.',
        ownerUid: uid,
      ),
    );
  }

  /// Whether this phone will show GrindFit alerts outside the app: true or
  /// false on Android, null where it cannot be checked (iOS, web, desktop).
  Future<bool?> phoneAlertsEnabled() async {
    if (!_nativeReady) return _mobile ? false : null;
    try {
      return await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();
    } catch (_) {
      return null;
    }
  }

  Future<bool> requestPermissions({bool once = false}) async {
    if (!_nativeReady) return false;
    if (once && _prefs?.getBool('notification-permission-asked') == true) {
      return false;
    }
    await _prefs?.setBool('notification-permission-asked', true);
    try {
      final allowed = defaultTargetPlatform == TargetPlatform.android
          ? await _plugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >()
                ?.requestNotificationsPermission()
          : await _plugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, badge: true, sound: true);
      _scheduleKey = '';
      await _reschedule();
      return allowed == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _showPhone(AppAlert alert) async {
    if (!_nativeReady || alert.ownerUid != _uid) return false;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null && await android.areNotificationsEnabled() == false) {
        return false;
      }
      if (alert.ownerUid != _uid) return false;
      await _plugin.show(
        id: _stableId(alert.id),
        title: alert.title,
        body: alert.body,
        notificationDetails: _details,
        payload: jsonEncode({
          'uid': alert.ownerUid,
          'id': alert.id,
          'route': alert.route,
        }),
      );
      if (alert.ownerUid != _uid) {
        await _plugin.cancel(id: _stableId(alert.id));
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  int _stableId(String value) =>
      value.codeUnits.fold<int>(0, (hash, c) => (hash * 31 + c) & 0x3fffffff) +
      10000;

  void _handlePayload(String? payload) {
    try {
      final value = jsonDecode(payload ?? '') as Map;
      _pendingOpen = AppAlert(
        id: value['id']?.toString() ?? '',
        title: '',
        body: '',
        route: value['route']?.toString() ?? 'notifications',
        ownerUid: value['uid'] as String,
      );
      openPending();
    } catch (_) {
      /* Ignore malformed or external notification payloads. */
    }
  }

  void openPending() {
    final alert = _pendingOpen;
    if (alert == null ||
        alert.ownerUid != FirebaseAuth.instance.currentUser?.uid ||
        onOpen == null) {
      return;
    }
    _pendingOpen = null;
    onOpen!(alert);
  }

  Future<void> markRead(AppAlert alert) async {
    if (alert.ownerUid != _uid ||
        alert.id.startsWith('preview-') ||
        alert.id == 'phone-test' ||
        alert.id.startsWith('scheduled-')) {
      return;
    }
    try {
      await OfflineStore.instance.write(
        'users/$_uid/notifications/${alert.id}',
        {'isRead': true},
        merge: true,
      );
    } catch (_) {}
  }

  Future<void> setReminderTime(int hour, int minute) async {
    if (_uid == null) return;
    _profileData = {
      ..._profileData,
      'notificationReminderHour': hour,
      'notificationReminderMinute': minute,
    };
    await OfflineStore.instance.saveProfile({
      'notificationReminderHour': hour,
      'notificationReminderMinute': minute,
    });
    await _reschedule();
  }

  (int, int) get reminderTime => (
    (_profileData['notificationReminderHour'] as num?)?.toInt().clamp(0, 23) ??
        18,
    (_profileData['notificationReminderMinute'] as num?)?.toInt().clamp(
          0,
          59,
        ) ??
        0,
  );

  void onWorkoutDates(Iterable<DateTime> completed) {
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    final done = completed.any((d) {
      final local = d.toLocal();
      return local.year == now.year &&
          local.month == now.month &&
          local.day == now.day;
    });
    final value = done ? today : '';
    if (value == _completedToday) return;
    _completedToday = value;
    unawaited(_reschedule());
  }

  static ({String title, String body}) dailyReminderContent(
    Map<String, dynamic> profile, {
    required bool workout,
  }) {
    if (!workout) {
      return (
        title: 'Today is your rest day',
        body: 'Recovery day: gentle stretching, hydration and rest. Check in with your energy before your next session.',
      );
    }
    final focus = profile['workoutFocus']?.toString() ?? 'Full Body';
    final duration = profile['sessionDuration']?.toString() ?? '45 min';
    final goal = profile['fitnessGoal']?.toString() ?? 'Muscle Gain / Strength';
    final environment = profile['workoutEnvironment']?.toString() ?? 'Gym';
    final request = profile['workoutRequest']?.toString() ?? '';
    final days =
        (profile['workoutDays'] as List?)?.whereType<String>().join(',') ?? '';
    final context = '$goal|$environment|$focus|$request|$duration|$days';
    List<PlanExercise>? generated;
    if (profile['generatedContext'] == context &&
        profile['generatedPlan'] is List) {
      try {
        generated = (profile['generatedPlan'] as List)
            .whereType<Map>()
            .map((e) => PlanExercise.fromMap(Map<String, dynamic>.from(e)))
            .toList();
        if (generated.isEmpty) generated = null;
      } catch (_) {
        /* Use the on-device catalog for invalid saved plans. */
      }
    }
    // Without a saved online plan, use the weekly program (or today's focus).
    var label = focus;
    if (generated == null) {
      final owned = Gear.effective(
        environment,
        Gear.clean(
          profile['equipment'] is List
              ? profile['equipment'] as List
              : const [],
        ),
      );
      final started = profile['programStartedAt'] ?? profile['createdAt'];
      final start = started is Timestamp ? started.toDate() : DateTime.now();
      final followsProgram =
          focus == 'Full Body' || focus == TrainingProgram.programFocus;
      if (followsProgram) {
        final session = TrainingProgram.upcoming(
          DateTime.now(),
          goal: goal,
          days:
              (profile['workoutDays'] as List?)?.whereType<String>().toList() ??
              const [],
          owned: owned,
          sessionDuration: duration,
          start: start,
          months: (profile['programDurationMonths'] as num?)?.toInt() ?? 3,
        );
        generated = session.exercises;
        label = session.dayName;
      } else {
        generated = TrainingProgram.focusSession(
          focus,
          goal: goal,
          owned: focus == 'No Equipment' ? const {} : owned,
          sessionDuration: duration,
          weekIndex: TrainingProgram.weekIndexOf(DateTime.now(), start),
        );
      }
    }
    final plan = WorkoutPlan.personalized(
      goal: goal,
      environment: environment,
      focus: focus,
      request: request,
      basePlan: generated,
    );
    final names = plan.take(3).map((e) => e.name).join(', ');
    return (
      title: 'Workout today: $label',
      body:
          '$duration session${names.isEmpty ? '' : ': $names'}. Open your current plan to review and start.',
    );
  }

  void _checkDailyPopup() {
    final uid = _uid;
    if (!_foreground || uid == null || _profileData.isEmpty) return;
    final now = DateTime.now();
    final (hour, minute) = reminderTime;
    if (now.hour * 60 + now.minute < hour * 60 + minute) return;
    final days = _profileData['workoutDays'];
    if (days is! List || days.isEmpty) return;
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final workout = days.contains(names[now.weekday - 1]);
    final today = '${now.year}-${now.month}-${now.day}';
    if (workout && _completedToday == today) return;
    final key = 'daily-popup-$uid-$today';
    if (_popupDay == key || _prefs?.getBool(key) == true) return;
    final content = dailyReminderContent(_profileData, workout: workout);
    final alert = AppAlert(
      id: 'scheduled-daily-$today',
      title: content.title,
      body: content.body,
      type: workout ? 'Reminders' : 'Recovery',
      route: workout ? 'workout' : 'rest',
      ownerUid: uid,
    );
    if (!alert.enabledBy(_settings)) return;
    _popupDay = key;
    unawaited(_prefs?.setBool(key, true));
    deliver(alert);
  }

  Future<void> _reschedule() async {
    if (!_nativeReady || _uid == null) return;
    if (_scheduling) {
      _scheduleAgain = true;
      return;
    }
    _scheduling = true;
    final uid = _uid!;
    try {
      final rawDays = _profileData['workoutDays'];
      final days = rawDays is List
          ? rawDays.whereType<String>().toSet()
          : <String>{};
      final (hour, minute) = reminderTime;
      final now = tz.TZDateTime.now(tz.local);
      final workoutContent = dailyReminderContent(_profileData, workout: true);
      final key =
          '$uid|${days.toList()..sort()}|$hour:$minute|$_settings|$_completedToday|${now.year}-${now.month}-${now.day}|${tz.local.name}|$workoutContent';
      if (key == _scheduleKey) return;
      for (var day = 1; day <= 7; day++) {
        await _plugin.cancel(id: 1000 + day);
        if (_uid != uid) return;
        const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final workout = days.contains(names[day - 1]);
        if (days.isEmpty ||
            (workout
                ? _settings['workout'] == false
                : _settings['rest'] == false)) {
          continue;
        }
        var date = nextReminder(now, day, hour, minute);
        if (workout &&
            _completedToday.isNotEmpty &&
            date.year == now.year &&
            date.month == now.month &&
            date.day == now.day) {
          date = tz.TZDateTime(
            tz.local,
            date.year,
            date.month,
            date.day + 7,
            hour,
            minute,
          );
        }
        final content = workout
            ? workoutContent
            : dailyReminderContent(_profileData, workout: false);
        await _plugin.zonedSchedule(
          id: 1000 + day,
          title: content.title,
          body: content.body,
          scheduledDate: date,
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: jsonEncode({
            'uid': uid,
            'id': 'scheduled-${workout ? 'workout' : 'rest'}-$day',
            'route': workout ? 'workout' : 'rest',
          }),
        );
        if (_uid != uid) {
          await _plugin.cancel(id: 1000 + day);
          return;
        }
      }
      if (_uid == uid) _scheduleKey = key;
    } catch (_) {
      _scheduleKey = '';
    } finally {
      _scheduling = false;
      if (_scheduleAgain) {
        _scheduleAgain = false;
        unawaited(_reschedule());
      }
    }
  }

  static tz.TZDateTime nextReminder(
    tz.TZDateTime now,
    int weekday,
    int hour,
    int minute,
  ) {
    final days = (weekday - now.weekday + 7) % 7;
    var next = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day + days,
      hour,
      minute,
    );
    if (!next.isAfter(now)) {
      next = tz.TZDateTime(
        now.location,
        next.year,
        next.month,
        next.day + 7,
        hour,
        minute,
      );
    }
    return next;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _scheduleKey = '';
      unawaited(_refreshTimezone());
      openPending();
      _checkDailyPopup();
    }
  }

  Future<void> _refreshTimezone() async {
    if (!_nativeReady) return;
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      /* Retain the last known device timezone. */
    }
    await _reschedule();
  }
}
