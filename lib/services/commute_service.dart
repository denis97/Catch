import 'dart:io' show Platform;
import 'dart:ui' show DartPluginRegistrant;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/commute_repository.dart';
import '../data/mock_data.dart' show fmtClock;
import '../data/places_repository.dart';
import 'transit_service.dart';

/// Top-level alarm callback — runs in a background isolate, so it can only
/// reach static state and must re-initialize plugins itself.
@pragma('vm:entry-point')
Future<void> commuteCheckCallback() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  await CommuteService.runCheck();
}

/// Proactive lock-screen departure notifications.
///
/// During a configured commute window (e.g. Work → Home, 17:00–18:00,
/// Mon–Fri), an alarm fires every few minutes. If the device is within
/// ~400 m of the window's anchor place, the next departure is fetched and
/// shown as a silent notification. It disappears once the user leaves the
/// geofence or the window closes. Android only.
class CommuteService {
  static const _alarmId = 7001;
  static const _notifId = 7002;
  static const _checkInterval = Duration(minutes: 5);
  static const _nearMeters = 400.0;

  static bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  /// (Re)arms the alarm for the next relevant moment: now if a window is
  /// currently open, otherwise the earliest upcoming window start.
  /// Call after any alert change and on app start.
  static Future<void> reschedule() async {
    if (!_isAndroid) return;
    final prefs = await SharedPreferences.getInstance();
    final alerts =
        CommuteRepository(prefs).all.where((a) => a.enabled).toList();

    await AndroidAlarmManager.cancel(_alarmId);
    if (alerts.isEmpty) {
      await _notifPlugin().cancel(_notifId);
      return;
    }

    final now = DateTime.now();
    var next = alerts.first.nextRun(now);
    for (final a in alerts.skip(1)) {
      final t = a.nextRun(now);
      if (t.isBefore(next)) next = t;
    }
    await _arm(next.isBefore(now) ? now : next);
  }

  static Future<void> _arm(DateTime at) async {
    await AndroidAlarmManager.oneShotAt(
      // A couple of seconds of slack so "fire now" doesn't land in the past.
      at.add(const Duration(seconds: 3)),
      _alarmId,
      commuteCheckCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }

  /// One check cycle: evaluate active windows, post or clear the
  /// notification, and arm the next alarm.
  static Future<void> runCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final places = PlacesRepository(prefs);
    final alerts =
        CommuteRepository(prefs).all.where((a) => a.enabled).toList();
    final now = DateTime.now();

    final active = alerts.where((a) => a.activeAt(now)).toList();
    final plugin = _notifPlugin();
    await plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ));

    var shown = false;
    if (active.isNotEmpty) {
      final pos = await _position();
      if (pos != null) {
        for (final alert in active) {
          final at = places.byId(alert.atPlaceId);
          final to = places.byId(alert.toPlaceId);
          if (at == null || to == null || !at.hasCoords) continue;

          final dist = Geolocator.distanceBetween(
              pos.latitude, pos.longitude, at.lat!, at.lng!);
          if (dist > _nearMeters) continue;

          try {
            final deps = await TransitService().getDepartures(
              originLat: pos.latitude,
              originLng: pos.longitude,
              destination: to.destinationParam,
            );
            final next = deps.where((d) => d.leaveIn > 0).toList();
            if (next.isEmpty) continue;
            final d = next.first;
            await plugin.show(
              _notifId,
              '${d.line} to ${to.name} — leave in ${d.leaveIn} min',
              'Departs ${d.depart} from ${d.from} · walk out ${fmtClock(d.departMin - d.walk)}',
              _details,
            );
            shown = true;
          } catch (_) {
            // Network/API failure: keep whatever notification is showing
            // rather than flashing it away; next cycle retries.
            shown = true;
          }
          break;
        }
      }
    }
    if (!shown) await plugin.cancel(_notifId);

    // Arm the next cycle: soon if a window is open, else next window start.
    DateTime? next;
    if (active.isNotEmpty) {
      next = now.add(_checkInterval);
    } else {
      for (final a in alerts) {
        final t = a.nextRun(now);
        if (next == null || t.isBefore(next)) next = t;
      }
    }
    if (next != null) await _arm(next);
  }

  static FlutterLocalNotificationsPlugin _notifPlugin() =>
      FlutterLocalNotificationsPlugin();

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'commute_alerts',
      'Commute alerts',
      channelDescription:
          'Shows the next departure on your lock screen during your usual commute window',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: false,
      enableVibration: false,
      onlyAlertOnce: true,
      autoCancel: false,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.status,
    ),
  );

  static Future<Position?> _position() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null &&
          DateTime.now().difference(last.timestamp) <
              const Duration(minutes: 10)) {
        return last;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
