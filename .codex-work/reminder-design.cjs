const fs = require('node:fs');
const file = 'lib/screens/device_reminders_screen.dart';
let s = fs.readFileSync(file, 'utf8');
const start = s.indexOf('  @override\n  Widget build(BuildContext context)', s.indexOf('class _DeviceRemindersScreenState'));
if (start < 0) throw Error('Screen build not found');
s = s.slice(0, start) + String.raw`  static const _bg = Color(0xFF0C0C0E);
  static const _surface = Color(0xFF18181C);
  static const _border = Color(0xFF38383F);
  static const _gold = Color(0xFFF5B800);
  static const _gray = Color(0xFF9CA3AF);

  Widget _panel(Widget child, {bool highlighted = false}) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: highlighted ? _gold.withValues(alpha: .35) : _border),
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg, elevation: 0, scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text('Device Reminders', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        leading: Padding(padding: const EdgeInsets.only(left: 16), child: IconButton(
          tooltip: 'Back', onPressed: () => Navigator.maybePop(context),
          style: IconButton.styleFrom(backgroundColor: _surface, side: const BorderSide(color: _border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
        )),
      ),
      body: SafeArea(child: uid == null
        ? Center(child: Padding(padding: const EdgeInsets.all(24), child: _panel(const Text('Sign in to manage your reminders.', style: TextStyle(color: _gray)))))
        : StreamBuilder(
          stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: _gold));
            }
            final profile = snapshot.data?.data();
            final raw = profile?['notificationSettings'];
            final settings = raw is Map ? raw : {};
            final enabled = settings['deviceReminders'] == true;
            final supported = ReminderService.instance.supported;
            final available = !_busy && supported && !snapshot.hasError;
            final days = (profile?['workoutDays'] as List?)?.whereType<String>().toList() ?? <String>[];
            final time = TimeOfDay(
              hour: ((settings['reminderHour'] as num?)?.toInt() ?? 18).clamp(0, 23),
              minute: ((settings['reminderMinute'] as num?)?.toInt() ?? 0).clamp(0, 59),
            );
            Future<void> pickTime() async {
              final picked = await showTimePicker(
                context: context, initialTime: time,
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark(primary: _gold, onPrimary: Colors.black, surface: _surface, onSurface: Colors.white)),
                  child: child!,
                ),
              );
              if (picked != null && mounted) await _save(enabled, picked);
            }
            return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 32), children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_gold.withValues(alpha: .16), _surface]),
                  border: Border.all(color: _gold.withValues(alpha: .28)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _gold.withValues(alpha: .13), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.notifications_active_outlined, color: _gold, size: 28)),
                  const SizedBox(height: 20),
                  const Text('Make time for you.', style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900, letterSpacing: -.6)),
                  const SizedBox(height: 8),
                  const Text('A little nudge to keep your workout routine on track, even when GrindFit is closed.', style: TextStyle(color: _gray, fontSize: 14, height: 1.6)),
                ]),
              ),
              const SizedBox(height: 24),
              const Text('YOUR REMINDERS', style: TextStyle(color: _gray, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.6)),
              const SizedBox(height: 12),
              _panel(Row(children: [
                Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: _gold.withValues(alpha: .1), borderRadius: BorderRadius.circular(13)),
                  child: const Icon(Icons.notifications_none_rounded, color: _gold, size: 23)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Workout reminders', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(enabled ? 'Reminders are switched on' : 'Turn on when you’re ready', style: const TextStyle(color: _gray, fontSize: 12, height: 1.4)),
                ])),
                Switch(value: enabled, activeThumbColor: Colors.black, activeTrackColor: _gold,
                  inactiveThumbColor: _gray, inactiveTrackColor: _bg,
                  onChanged: available ? (value) => _save(value, time) : null),
              ])),
              const SizedBox(height: 14),
              _panel(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Row(children: [Icon(Icons.schedule_rounded, color: _gold, size: 20), SizedBox(width: 10),
                  Text('REMINDER TIME', style: TextStyle(color: _gray, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w800))]),
                const SizedBox(height: 16),
                Text(time.format(context), style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -1)),
                const SizedBox(height: 4),
                const Text('Uses this device’s local time', style: TextStyle(color: _gray, fontSize: 12)),
                const SizedBox(height: 20),
                OutlinedButton.icon(onPressed: available ? pickTime : null,
                  style: OutlinedButton.styleFrom(foregroundColor: _gold, side: BorderSide(color: _gold.withValues(alpha: .5)),
                    padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  icon: const Icon(Icons.edit_outlined, size: 18), label: const Text('Change time', style: TextStyle(fontWeight: FontWeight.w800))),
              ]), highlighted: true),
              const SizedBox(height: 14),
              _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Workout days', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text('Follows your saved workout schedule', style: TextStyle(color: _gray, fontSize: 12, height: 1.5)),
                const SizedBox(height: 16),
                Wrap(spacing: 7, runSpacing: 8, children: [
                  for (final day in const ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'])
                    Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                      decoration: BoxDecoration(color: days.contains(day) ? _gold.withValues(alpha: .14) : _bg,
                        border: Border.all(color: days.contains(day) ? _gold.withValues(alpha: .5) : _border), borderRadius: BorderRadius.circular(10)),
                      child: Text(day, style: TextStyle(color: days.contains(day) ? _gold : _gray, fontSize: 12, fontWeight: FontWeight.w700))),
                ]),
                if (days.isEmpty) const Padding(padding: EdgeInsets.only(top: 12), child: Text('Choose workout days in your workout schedule first.', style: TextStyle(color: _gray, fontSize: 12))),
              ])),
              const SizedBox(height: 18),
              _note(Icons.info_outline_rounded, 'Workout reminders must also be enabled in Notification Settings. Android may delay reminders to save battery. Reopen GrindFit after changing time zones or updating your schedule on another device.'),
              if (!supported) ...[const SizedBox(height: 12), _note(Icons.phone_android_rounded, 'Device reminders are currently available on Android.')],
              if (profile?['hasInjuryOrCondition'] == true) ...[const SizedBox(height: 12), _note(Icons.health_and_safety_outlined, 'Reminders are paused while your reported injury or condition needs professional review.')],
              if (_busy) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator(color: _gold, backgroundColor: _border)),
              if (_message != null) ...[const SizedBox(height: 14), _note(Icons.chat_bubble_outline_rounded, _message!)],
              if (snapshot.hasError) ...[const SizedBox(height: 14), _note(Icons.cloud_off_rounded, 'Could not load saved preferences. Check your connection and try again.')],
            ]);
          },
        )),
    );
  }

  Widget _note(IconData icon, String text) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, color: _gold, size: 18), const SizedBox(width: 10),
    Expanded(child: Text(text, style: const TextStyle(color: _gray, fontSize: 12, height: 1.6))),
  ]);
}
`;
fs.writeFileSync(file,s);
