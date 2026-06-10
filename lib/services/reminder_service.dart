import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../data/models.dart';

enum ReminderResult { pinned, scheduled, firedNow, tooLate, denied }

String reminderMessage(ReminderResult r) => switch (r) {
      ReminderResult.pinned =>
        'Pinned — live countdown in your notifications until departure',
      ReminderResult.scheduled =>
        "Reminder set — we'll ping you 2 min before it's time to leave",
      ReminderResult.firedNow => 'Almost time — heads up sent now!',
      ReminderResult.tooLate => 'Too late to remind — time to go!',
      ReminderResult.denied =>
        'Notifications are off — enable them in system settings',
    };

/// Schedules local "time to leave" notifications.
///
/// On Android, "Remind me" pins an ongoing notification with a live
/// chronometer counting down to walk-out time (the system ticks it, no app
/// updates needed). An exact alarm replaces it with a "leave now" alert at
/// walk-out time. On iOS, only the scheduled alert is used (live countdowns
/// would require Live Activities).
class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

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

  static const _alertDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'leave_reminders',
      'Leave reminders',
      channelDescription: 'Alerts you when it is time to leave to catch your ride',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
    ),
    iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
  );

  /// Ongoing countdown notification. `when` is walk-out time; the system
  /// chronometer counts down to it live.
  NotificationDetails _countdownDetails(DateTime leaveAt) => NotificationDetails(
        android: AndroidNotificationDetails(
          'live_countdown',
          'Departure countdown',
          channelDescription: 'Live countdown until you need to leave',
          importance: Importance.high,
          priority: Priority.high,
          ongoing: true,
          autoCancel: false,
          onlyAlertOnce: true,
          playSound: false,
          enableVibration: false,
          showWhen: true,
          when: leaveAt.millisecondsSinceEpoch,
          usesChronometer: true,
          chronometerCountDown: true,
          category: AndroidNotificationCategory.status,
          actions: [
            AndroidNotificationAction('dismiss', 'Dismiss', cancelNotification: true),
          ],
        ),
      );

  /// Pins a live countdown (Android) and schedules the walk-out alert.
  Future<ReminderResult> scheduleLeaveReminder(Departure d) async {
    await init();
    final granted = await requestPermission();
    if (!granted) return ReminderResult.denied;

    if (d.leaveIn <= 0) return ReminderResult.tooLate;

    final id = d.id.hashCode;
    final headsUp = d.leaveIn - 2;

    if (headsUp <= 0) {
      // Too close to schedule — fire the alert immediately instead.
      await _plugin.show(id, 'Time to leave',
          'Walk out now to catch the ${d.line} at ${d.depart}', _alertDetails);
      return ReminderResult.firedNow;
    }

    var result = ReminderResult.scheduled;

    // 1) Ongoing live countdown until walk-out time (Android only).
    if (_isAndroid) {
      final leaveAt = DateTime.now().add(Duration(minutes: d.leaveIn));
      await _plugin.show(
        id,
        'Catch the ${d.line} to ${d.headsign}',
        'Departs ${d.depart} from ${d.from} — leave by the timer',
        _countdownDetails(leaveAt),
      );
      result = ReminderResult.pinned;
    }

    // 2) Exact alert 2 min before walk-out, replacing the countdown (same id).
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null &&
        (await android.canScheduleExactNotifications() ?? false) == false) {
      await android.requestExactAlarmsPermission();
    }

    final when = tz.TZDateTime.now(tz.local).add(Duration(minutes: headsUp));
    try {
      await _schedule(id, d, when, AndroidScheduleMode.exactAllowWhileIdle);
    } on PlatformException {
      await _schedule(id, d, when, AndroidScheduleMode.inexactAllowWhileIdle);
    }
    return result;
  }

  Future<void> _schedule(int id, Departure d, tz.TZDateTime when, AndroidScheduleMode mode) {
    return _plugin.zonedSchedule(
      id,
      'Time to leave',
      'Walk out in 2 min to catch the ${d.line} at ${d.depart}',
      when,
      _alertDetails,
      androidScheduleMode: mode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
