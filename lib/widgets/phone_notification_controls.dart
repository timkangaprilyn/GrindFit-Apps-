import 'package:flutter/material.dart';

import '../services/app_notifications.dart';
import '../theme/grindfit_theme.dart';

class PhoneNotificationControls extends StatefulWidget {
  const PhoneNotificationControls({super.key});
  @override
  State<PhoneNotificationControls> createState() =>
      _PhoneNotificationControlsState();
}

class _PhoneNotificationControlsState extends State<PhoneNotificationControls> {
  bool _busy = false;
  @override
  Widget build(BuildContext context) {
    final service = AppNotifications.instance;
    final (hour, minute) = service.reminderTime;
    final time = TimeOfDay(hour: hour, minute: minute);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GrindFitTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GrindFitTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Daily workout reminders',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Get your workout focus, duration and exercises on training days, and a recovery reminder on rest days. Allow phone notifications to receive reminders when the app is closed.',
            style: TextStyle(
              color: GrindFitTheme.gray,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => service.previewPopup(),
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Preview in-app pop-up'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    final sent = await service.testPhoneAlert();
                    if (!context.mounted) return;
                    setState(() => _busy = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          sent
                              ? 'Phone alert sent. Check your notification tray.'
                              : 'Allow notifications in your phone settings, then try again.',
                        ),
                      ),
                    );
                  },
            icon: const Icon(Icons.phone_android_rounded),
            label: Text(
              _busy ? 'Checking permission…' : 'Enable / test phone alert',
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.access_time_rounded,
              color: GrindFitTheme.gold,
            ),
            title: Text('Remind me around ${time.format(context)}'),
            subtitle: const Text(
              'Local time • follows your workout and rest-day settings',
            ),
            trailing: const Icon(
              Icons.edit_outlined,
              color: GrindFitTheme.gray,
              size: 18,
            ),
            onTap: () async {
              final choice = await showTimePicker(
                context: context,
                initialTime: time,
              );
              if (choice == null) return;
              try {
                await service.setReminderTime(choice.hour, choice.minute);
                if (mounted) setState(() {});
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Could not save reminder time. Please retry.',
                      ),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
