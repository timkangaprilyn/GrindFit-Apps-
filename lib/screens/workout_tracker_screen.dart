import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// =============================================================
//  EXERCISE LIBRARY — totoong detalye ng bawat exercise
// =============================================================

class ExerciseInfo {
  final String name;
  final String target;
  final String equipment;
  final String imageUrl;
  final String tip;
  final List<String> steps;
  final int sets;
  final String repsLabel; // hal. '10-12'
  final int repsPerSet; // ginagamit sa table at sa estimate
  final List<double>? weightsByLevel; // [beginner, intermediate, advanced]; null = bodyweight
  final int restSeconds;
  final double met; // intensity para sa calorie computation

  const ExerciseInfo({
    required this.name,
    required this.target,
    required this.equipment,
    required this.imageUrl,
    required this.tip,
    required this.steps,
    required this.sets,
    required this.repsLabel,
    required this.repsPerSet,
    required this.weightsByLevel,
    required this.restSeconds,
    required this.met,
  });

  // ~4 segundo bawat rep
  int get workSecondsPerSet => repsPerSet * 4;
  int get estimatedSeconds => sets * (workSecondsPerSet + restSeconds);

  double? weightFor(String level) {
    final w = weightsByLevel;
    if (w == null || w.isEmpty) return null;
    final l = level.toLowerCase();
    int index = 0;
    if (l.contains('adv')) {
      index = 2;
    } else if (l.contains('inter')) {
      index = 1;
    }
    if (index >= w.length) index = w.length - 1;
    return w[index];
  }
}

class ExerciseLibrary {
  static const String planTitle = 'Upper Body Strength';
  static const String planFocus = 'Upper Body Focus';

  // Parehong exercises sa Workout Plan Details
  static const List<String> todaysPlan = [
    'Push Up',
    'Dumbbell Row',
    'Shoulder Press',
  ];

  static const int warmupSeconds = 150; // 5 stretches x 30s
  static const int cooldownSeconds = 150;

  static const Map<String, ExerciseInfo> _all = {
    'Push Up': ExerciseInfo(
      name: 'Push Up',
      target: 'Chest, Shoulders, Triceps',
      equipment: 'No Equipment',
      imageUrl:
          'https://images.unsplash.com/photo-1598971639058-fab3c3109a00?auto=format&fit=crop&w=600&q=80',
      tip: 'Keep your core tight and avoid sagging your hips.',
      steps: [
        'Place your hands slightly wider than shoulder-width',
        'Keep your body in a straight line from head to heels',
        'Lower your chest until it is just above the floor',
        'Push back up without locking your elbows',
      ],
      sets: 3,
      repsLabel: '10-12',
      repsPerSet: 10,
      weightsByLevel: null,
      restSeconds: 45,
      met: 4.0,
    ),
    'Dumbbell Row': ExerciseInfo(
      name: 'Dumbbell Row',
      target: 'Back, Biceps',
      equipment: 'Dumbbells',
      imageUrl:
          'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?auto=format&fit=crop&w=600&q=80',
      tip: 'Keep your back flat and avoid twisting your torso.',
      steps: [
        'Support one hand and knee on a bench, back flat',
        'Hold a dumbbell with your free arm fully extended',
        'Pull the dumbbell toward your hip and squeeze your back',
        'Lower it slowly, then repeat on the other side',
      ],
      sets: 3,
      repsLabel: '10-12',
      repsPerSet: 10,
      weightsByLevel: [5.0, 8.0, 12.0],
      restSeconds: 45,
      met: 4.0,
    ),
    'Shoulder Press': ExerciseInfo(
      name: 'Shoulder Press',
      target: 'Shoulders, Triceps',
      equipment: 'Dumbbells',
      imageUrl:
          'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=600&q=80',
      tip: 'Do not arch your lower back; keep your core braced.',
      steps: [
        'Hold the dumbbells at shoulder height, palms forward',
        'Brace your core and keep your ribs down',
        'Press the weights overhead until arms are straight',
        'Lower back to shoulder height with control',
      ],
      sets: 3,
      repsLabel: '10',
      repsPerSet: 10,
      weightsByLevel: [4.0, 6.0, 10.0],
      restSeconds: 45,
      met: 4.0,
    ),
    'Barbell Squat': ExerciseInfo(
      name: 'Barbell Squat',
      target: 'Legs, Glutes, Hamstrings',
      equipment: 'Barbell',
      imageUrl:
          'https://images.unsplash.com/photo-1574680096145-d05b474e2155?auto=format&fit=crop&w=600&q=80',
      tip: 'Keep your back straight, chest up, and knees behind your toes.',
      steps: [
        'Feet shoulder-width apart',
        'Chest up, core tight',
        'Sit back and down',
        'Knees track over toes',
        'Drive through your heels to stand up',
      ],
      sets: 6,
      repsLabel: '10',
      repsPerSet: 10,
      weightsByLevel: [40.0, 60.0, 80.0],
      restSeconds: 60,
      met: 5.0,
    ),
  };

  static ExerciseInfo byName(String name) {
    final found = _all[name];
    if (found != null) return found;
    return ExerciseInfo(
      name: name,
      target: 'Full body',
      equipment: 'Bodyweight',
      imageUrl: '',
      tip: 'Move with control and stop if you feel pain.',
      steps: const [
        'Keep good posture',
        'Move with control',
        'Breathe steadily',
      ],
      sets: 3,
      repsLabel: '10',
      repsPerSet: 10,
      weightsByLevel: null,
      restSeconds: 45,
      met: 4.0,
    );
  }

  static String sessionName(List<String> queue) =>
      queue.length == 1 ? queue.first : planTitle;

  static int estimatedSeconds(List<String> names) {
    int total = 0;
    for (final n in names) {
      total += byName(n).estimatedSeconds;
    }
    return total;
  }

  static double averageMet(List<String> names) {
    if (names.isEmpty) return 4.0;
    double total = 0;
    for (final n in names) {
      total += byName(n).met;
    }
    return total / names.length;
  }
}

// =============================================================
//  WORKOUT TRACKER — dito galing ang lahat ng totoong numbers
// =============================================================

class WorkoutSession {
  final DateTime date;
  final String name;
  final int durationSeconds;
  final int calories;
  final int exercises;

  const WorkoutSession({
    required this.date,
    required this.name,
    required this.durationSeconds,
    required this.calories,
    required this.exercises,
  });
}

class SafetyStatus {
  final int level; // 0 = good, 1 = caution, 2 = rest needed
  final String label;
  final String detail;

  const SafetyStatus({
    required this.level,
    required this.label,
    required this.detail,
  });
}

class WorkoutTracker extends ChangeNotifier {
  WorkoutTracker._();
  static final WorkoutTracker instance = WorkoutTracker._();

  final List<WorkoutSession> _sessions = [];
  final Map<String, int> _water = {};
  final Map<String, int> _warmupSeconds = {};
  final Map<String, int> _stretchSeconds = {};

  // Lokal na variable para sa timbang para maiwasan ang undefined_getter error
  double weightKg = 60.0;

  static String dayKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
  String get _today => dayKey(DateTime.now());

  double get _weightKg => weightKg;

  // Calories = MET x timbang (kg) x oras
  int caloriesFor({required double met, required int seconds}) {
    return (met * _weightKg * seconds / 3600).round();
  }

  // ---------- Checklist (ngayong araw) ----------
  bool get warmupDone => _warmupSeconds.containsKey(_today);
  bool get stretchDone => _stretchSeconds.containsKey(_today);
  bool get workoutDone => _sessions.any((s) => dayKey(s.date) == _today);

  // ---------- Hydration (35 ml bawat kg, 250 ml bawat baso) ----------
  int get waterToday => _water[_today] ?? 0;
  int get waterGoal {
    final g = (_weightKg * 35 / 250).round();
    if (g < 6) return 6;
    if (g > 12) return 12;
    return g;
  }

  bool get waterDone => waterToday >= waterGoal;

  // ---------- Stats ----------
  int get totalWorkouts => _sessions.length;

  int get caloriesToday {
    int total = 0;
    for (final s in _sessions) {
      if (dayKey(s.date) == _today) total += s.calories;
    }
    total += caloriesFor(met: 2.5, seconds: _warmupSeconds[_today] ?? 0);
    total += caloriesFor(met: 2.3, seconds: _stretchSeconds[_today] ?? 0);
    return total;
  }

  DateTime get _weekStart {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month, now.day);
    return d.subtract(Duration(days: d.weekday - 1)); // Lunes
  }

  int get workoutsThisWeek {
    final start = _weekStart;
    return _sessions.where((s) => !s.date.isBefore(start)).length;
  }

  // Minuto bawat araw (Mon..Sun) ng linggong ito
  List<int> get weeklyMinutes {
    final start = _weekStart;
    final result = List<int>.filled(7, 0);
    for (final s in _sessions) {
      if (s.date.isBefore(start)) continue;
      final idx = s.date.weekday - 1;
      if (idx >= 0 && idx < 7) {
        result[idx] += (s.durationSeconds / 60).ceil();
      }
    }
    return result;
  }

  int get streak {
    final days = _sessions.map((s) => dayKey(s.date)).toSet();
    DateTime cursor = DateTime.now();
    if (!days.contains(dayKey(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    int count = 0;
    while (days.contains(dayKey(cursor))) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  SafetyStatus get safety {
    final s = streak;
    if (s >= 5) {
      return SafetyStatus(
        level: 2,
        label: 'Rest day',
        detail: '$s days in a row. Recover today.',
      );
    }
    if (s >= 3) {
      return SafetyStatus(
        level: 1,
        label: 'Caution',
        detail: '$s days in a row. Watch recovery.',
      );
    }
    return const SafetyStatus(
      level: 0,
      label: 'Good',
      detail: 'Low injury risk',
    );
  }

  // ---------- Actions ----------
  void markWarmupDone(int seconds) {
    _warmupSeconds[_today] =
        (_warmupSeconds[_today] ?? 0) + (seconds > 0 ? seconds : 1);
    NotificationCenter.instance.sync();
    notifyListeners();
  }

  void markStretchDone(int seconds) {
    _stretchSeconds[_today] =
        (_stretchSeconds[_today] ?? 0) + (seconds > 0 ? seconds : 1);
    NotificationCenter.instance.sync();
    notifyListeners();
  }

  void setWater(int glasses) {
    int g = glasses;
    if (g < 0) g = 0;
    if (g > 20) g = 20;
    _water[_today] = g;
    NotificationCenter.instance.sync();
    notifyListeners();
  }

  void addWater() => setWater(waterToday + 1);

  void addSession({
    required String name,
    required int durationSeconds,
    required int exercises,
    required double met,
  }) {
    final session = WorkoutSession(
      date: DateTime.now(),
      name: name,
      durationSeconds: durationSeconds,
      calories: caloriesFor(met: met, seconds: durationSeconds),
      exercises: exercises,
    );
    _sessions.add(session);
    NotificationCenter.instance.onWorkoutCompleted(
      session,
      totalWorkouts: _sessions.length,
      streak: streak,
    );
    notifyListeners();
  }
}

// =============================================================
//  NOTIFICATIONS — gumagana base sa totoong ginawa ng user
// =============================================================

enum NotifKind { reminder, update }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  final NotifKind kind;
  final IconData icon;
  final String action; // 'workout' | 'rest' | 'ai' | 'water' | 'none'
  bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.kind,
    required this.icon,
    required this.action,
    this.read = false,
  });
}

class NotificationCenter extends ChangeNotifier {
  NotificationCenter._();
  static final NotificationCenter instance = NotificationCenter._();

  final List<AppNotification> _items = [];
  final Set<String> _dismissed = {};

  List<AppNotification> get items {
    final list = List<AppNotification>.from(_items);
    list.sort((a, b) => b.time.compareTo(a.time));
    return list;
  }

  int get unreadCount => _items.where((n) => !n.read).length;

  int unreadOf(NotifKind kind) =>
      _items.where((n) => !n.read && n.kind == kind).length;

  bool _add(AppNotification n) {
    if (_dismissed.contains(n.id)) return false;
    if (_items.any((e) => e.id == n.id)) return false;
    _items.add(n);
    return true;
  }

  bool _removeInternal(String id) {
    final before = _items.length;
    _items.removeWhere((n) => n.id == id);
    return _items.length != before;
  }

  // Time-based na reminders (tinatawag pagbukas ng Home / Notifications)
  void sync() {
    final t = WorkoutTracker.instance;
    final now = DateTime.now();
    final day = WorkoutTracker.dayKey(now);
    bool changed = false;

    // Workout reminder — mawawala kapag tapos na ang workout
    if (t.workoutDone) {
      changed = _removeInternal('workout-$day') || changed;
    } else if (now.hour >= 8) {
      changed = _add(AppNotification(
            id: 'workout-$day',
            title: 'Workout Reminder',
            message: 'Time for your scheduled workout: ${ExerciseLibrary.planTitle}',
            time: now,
            kind: NotifKind.reminder,
            icon: Icons.fitness_center_rounded,
            action: 'workout',
          )) ||
          changed;
    }

    // Hydration reminder — pagkatapos ng 2 PM kung kulang pa sa kalahati
    final halfGoal = (t.waterGoal / 2).ceil();
    if (t.waterToday >= halfGoal) {
      changed = _removeInternal('water-$day') || changed;
    } else if (now.hour >= 14) {
      changed = _add(AppNotification(
            id: 'water-$day',
            title: 'Stay Hydrated',
            message:
                "You've had ${t.waterToday} of ${t.waterGoal} glasses today. Tap to log a glass.",
            time: now,
            kind: NotifKind.reminder,
            icon: Icons.water_drop_rounded,
            action: 'water',
          )) ||
          changed;
    }

    // Rest day alert — kapag 5+ araw na magkakasunod
    if (t.safety.level >= 2) {
      changed = _add(AppNotification(
            id: 'rest-$day',
            title: 'Rest Day Alert',
            message:
                "You've trained ${t.streak} days in a row. It's time to rest and recover.",
            time: now,
            kind: NotifKind.reminder,
            icon: Icons.self_improvement_rounded,
            action: 'rest',
          )) ||
          changed;
    }

    if (changed) notifyListeners();
  }

  void onWorkoutCompleted(
    WorkoutSession s, {
    required int totalWorkouts,
    required int streak,
  }) {
    final now = DateTime.now();
    final stamp = now.microsecondsSinceEpoch;
    final mins = (s.durationSeconds / 60).ceil();

    _removeInternal('workout-${WorkoutTracker.dayKey(now)}');

    _add(AppNotification(
      id: 'done-$stamp',
      title: 'Workout Complete',
      message:
          '${s.name}: ${s.exercises} exercises • $mins min • ${s.calories} kcal burned',
      time: now,
      kind: NotifKind.update,
      icon: Icons.check_circle_rounded,
      action: 'none',
    ));

    const workoutMilestones = [1, 5, 10, 25, 50, 100];
    if (workoutMilestones.contains(totalWorkouts)) {
      _add(AppNotification(
        id: 'milestone-$totalWorkouts',
        title: 'Goal Milestone',
        message: totalWorkouts == 1
            ? 'You completed your first workout!'
            : 'You completed $totalWorkouts workouts!',
        time: now,
        kind: NotifKind.update,
        icon: Icons.emoji_events_rounded,
        action: 'none',
      ));
    }

    const streakMilestones = [3, 7, 14, 30];
    if (streakMilestones.contains(streak)) {
      _add(AppNotification(
        id: 'streak-$streak',
        title: 'Streak Milestone',
        message: "You're on a $streak-day workout streak. Keep it going!",
        time: now,
        kind: NotifKind.update,
        icon: Icons.local_fire_department_rounded,
        action: 'none',
      ));
    }

    _add(AppNotification(
      id: 'ai-$stamp',
      title: 'New Recommendation',
      message: 'Your next session is ready. Tap to review your plan.',
      time: now,
      kind: NotifKind.update,
      icon: Icons.auto_awesome_rounded,
      action: 'ai',
    ));

    sync();
    notifyListeners();
  }

  void markRead(String id) {
    final i = _items.indexWhere((n) => n.id == id);
    if (i >= 0 && !_items[i].read) {
      _items[i].read = true;
      notifyListeners();
    }
  }

  void markAllRead() {
    for (final n in _items) {
      n.read = true;
    }
    notifyListeners();
  }

  void remove(String id) {
    _dismissed.add(id);
    _removeInternal(id);
    notifyListeners();
  }

  static String timeLabel(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(t.year, t.month, t.day);
    final diff = today.difference(that).inDays;
    final clock = DateFormat('h:mm a').format(t);
    if (diff == 0) return 'Today, $clock';
    if (diff == 1) return 'Yesterday, $clock';
    return DateFormat('EEE, MMM d').format(t);
  }
}