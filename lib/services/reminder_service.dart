import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../data/models.dart';

enum ReminderResult { scheduled, firedNow, tooLate, denied }

String reminderMessage(ReminderResult r) => switch (r) {
      ReminderResult.scheduled =>
        "Reminder set — we'll ping you 2 min before it's time to leave",
      ReminderResult.firedNow => 'Almost time — heads up sent now!',
      ReminderResult.tooLate => 'Too late to remind — time to go!',
      ReminderResult.denied =>
        'Notifications are off — enable them in system settings',
    };

/// Schedules local "time to leave" notifications.
class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ));
    _ready = true;
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    return false;
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'leave_reminders',
      'Leave reminders',
      channelDescription: 'Reminds you when it is time to leave to catch your ride',
      importance: Importance.max,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
  );

  /// Schedules a reminder 2 minutes before it's time to walk out.
  Future<ReminderResult> scheduleLeaveReminder(Departure d) async {
    await init();
    final granted = await requestPermission();
    if (!granted) return ReminderResult.denied;

    if (d.leaveIn <= 0) return ReminderResult.tooLate;

    final headsUp = d.leaveIn - 2;
    if (headsUp <= 0) {
      // Too close to schedule — fire immediately instead.
      await _plugin.show(d.id.hashCode, 'Time to leave',
          'Walk out now to catch the ${d.line} at ${d.depart}', _details);
      return ReminderResult.firedNow;
    }

    // Exact alarms can be denied on Android 12+; ask, then fall back to
    // inexact scheduling if still not allowed.
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null &&
        (await android.canScheduleExactNotifications() ?? false) == false) {
      await android.requestExactAlarmsPermission();
    }

    final when = tz.TZDateTime.now(tz.local).add(Duration(minutes: headsUp));
    try {
      await _schedule(d, when, AndroidScheduleMode.exactAllowWhileIdle);
    } on PlatformException {
      await _schedule(d, when, AndroidScheduleMode.inexactAllowWhileIdle);
    }
    return ReminderResult.scheduled;
  }

  Future<void> _schedule(Departure d, tz.TZDateTime when, AndroidScheduleMode mode) {
    return _plugin.zonedSchedule(
      d.id.hashCode,
      'Time to leave',
      'Walk out in 2 min to catch the ${d.line} at ${d.depart}',
      when,
      _details,
      androidScheduleMode: mode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
