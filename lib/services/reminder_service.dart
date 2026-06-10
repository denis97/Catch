import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../data/models.dart';

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

  /// Schedules a reminder 2 minutes before it's time to walk out.
  /// Returns false if the departure is too soon to remind about.
  Future<bool> scheduleLeaveReminder(Departure d) async {
    await init();
    final headsUp = d.leaveIn - 2;
    if (headsUp <= 0) return false;

    await requestPermission();
    await _plugin.zonedSchedule(
      d.id.hashCode,
      'Time to leave',
      'Walk out in 2 min to catch the ${d.line} at ${d.depart}',
      tz.TZDateTime.now(tz.local).add(Duration(minutes: headsUp)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'leave_reminders',
          'Leave reminders',
          channelDescription: 'Reminds you when it is time to leave to catch your ride',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    return true;
  }
}
