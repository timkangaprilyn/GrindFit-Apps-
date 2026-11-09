class AppAlert {
  const AppAlert({
    required this.id,
    required this.title,
    required this.body,
    this.type = 'Updates',
    this.route = 'notifications',
    required this.ownerUid,
    this.createdAt,
    this.isRead = false,
  });
  final String id;
  final String title;
  final String body;
  final String type;
  final String route;
  final String ownerUid;
  final DateTime? createdAt;
  final bool isRead;

  bool enabledBy(Map<String, dynamic> settings) => switch (type) {
    'Reminders' => settings['workout'] != false,
    'Recovery' => settings['rest'] != false,
    'Achievements' => settings['achievements'] != false,
    _ => true,
  };
}

/// Initial inbox contents and reconnect edits never replay old pop-ups.
class AlertDeliveryGate {
  AlertDeliveryGate(this.startedAt);
  final DateTime startedAt;
  final Set<String> _seen = {};
  bool accept(
    AppAlert alert, {
    required bool initial,
    required Map<String, dynamic> settings,
  }) {
    if (_seen.contains(alert.id)) return false;
    if (initial || alert.isRead || !alert.enabledBy(settings)) {
      _seen.add(alert.id);
      return false;
    }
    final date = alert.createdAt;
    if (date == null) return false; // Wait for a pending server timestamp.
    _seen.add(alert.id);
    return !date.isBefore(startedAt);
  }
}
