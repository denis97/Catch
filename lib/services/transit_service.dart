import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../data/models.dart';

class TransitService {
  Future<List<Departure>> getDepartures({
    required double originLat,
    required double originLng,
    required String destination,
    DateTime? departureTime,
  }) async {
    final departureTimeSec =
        (departureTime ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;

    final uri = Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
      'origin': '$originLat,$originLng',
      'destination': destination,
      'mode': 'transit',
      'departure_time': departureTimeSec.toString(),
      'alternatives': 'true',
      'key': kGoogleMapsApiKey,
    });

    final resp = await http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final status = body['status'] as String;
    if (status == 'ZERO_RESULTS' || status == 'NOT_FOUND') return [];
    if (status != 'OK') throw Exception('Directions API: $status');

    final routes = body['routes'] as List<dynamic>;
    final now = DateTime.now();

    final deps = <Departure>[];
    for (int i = 0; i < routes.length; i++) {
      final d = _parseRoute(routes[i] as Map<String, dynamic>, i, now);
      if (d != null) deps.add(d);
    }

    deps.sort((a, b) => a.leaveIn.compareTo(b.leaveIn));
    return deps;
  }

  /// Probes several shifted departure times to build a series of upcoming
  /// departures (the Directions API only returns the next one per request).
  Future<List<Departure>> getDepartureSeries({
    required double originLat,
    required double originLng,
    required String destination,
    int probes = 4,
    int stepMin = 12,
  }) async {
    final now = DateTime.now();
    final byKey = <String, Departure>{};

    for (int i = 0; i < probes; i++) {
      try {
        final deps = await getDepartures(
          originLat: originLat,
          originLng: originLng,
          destination: destination,
          departureTime: now.add(Duration(minutes: i * stepMin)),
        );
        for (final d in deps) {
          byKey['${d.line}|${d.depart}'] = d;
        }
      } catch (_) {
        if (byKey.isEmpty && i == probes - 1) rethrow;
      }
    }

    final all = byKey.values.toList()
      ..sort((a, b) => a.leaveIn.compareTo(b.leaveIn));
    return all;
  }

  Departure? _parseRoute(Map<String, dynamic> route, int index, DateTime now) {
    final legsList = route['legs'] as List<dynamic>?;
    if (legsList == null || legsList.isEmpty) return null;
    final leg = legsList.first as Map<String, dynamic>;

    final stepsList = leg['steps'] as List<dynamic>? ?? [];

    Map<String, dynamic>? transitStep;
    int walkBeforeSec = 0;
    int walkAfterSec  = 0;
    int transitCount  = 0;

    for (final s in stepsList) {
      final step = s as Map<String, dynamic>;
      final mode = step['travel_mode'] as String;
      final durMap = step['duration'] as Map<String, dynamic>?;
      final dur  = durMap != null ? (durMap['value'] as int? ?? 0) : 0;

      if (mode == 'TRANSIT') {
        transitStep ??= step;
        transitCount++;
      } else if (mode == 'WALKING') {
        if (transitStep == null) { walkBeforeSec += dur; }
        else { walkAfterSec += dur; }
      }
    }

    if (transitStep == null) return null;

    final td      = transitStep['transit_details'] as Map<String, dynamic>? ?? {};
    final lineMap = td['line']           as Map<String, dynamic>? ?? {};
    final vehicle = lineMap['vehicle']   as Map<String, dynamic>? ?? {};
    final depStop = td['departure_stop'] as Map<String, dynamic>? ?? {};
    final depTime = td['departure_time'] as Map<String, dynamic>? ?? {};

    final legArrTime  = leg['arrival_time']  as Map<String, dynamic>? ?? {};
    final legDuration = leg['duration']      as Map<String, dynamic>? ?? {};

    final departureUnix = depTime['value']   as int? ?? 0;
    final arrivalUnix   = legArrTime['value'] as int? ?? 0;
    final departAt = DateTime.fromMillisecondsSinceEpoch(departureUnix * 1000);
    final arriveAt = DateTime.fromMillisecondsSinceEpoch(arrivalUnix * 1000);

    final walkBefore = (walkBeforeSec / 60).round().clamp(1, 60);
    final walkAfter  = (walkAfterSec  / 60).round().clamp(1, 60);

    final leaveAt = departAt.subtract(Duration(minutes: walkBefore));
    final leaveIn = leaveAt.difference(now).inMinutes;

    final totalSec   = legDuration['value']                               as int? ?? 0;
    final transitDurMap = transitStep['duration'] as Map<String, dynamic>? ?? {};
    final transitSec = transitDurMap['value']                             as int? ?? 0;

    final lineName    = (lineMap['short_name'] as String?) ?? (lineMap['name'] as String?) ?? '?';
    final headsign    = (td['headsign']        as String?) ?? lineName;
    final vehicleType = (vehicle['type']       as String?) ?? 'BUS';
    final mode        = _vehicleMode(vehicleType);

    return Departure(
      id:       '$lineName-$departureUnix',
      line:     lineName,
      headsign: headsign,
      from:     (depStop['name'] as String?) ?? '',
      walk:     walkBefore,
      leaveIn:  leaveIn,
      depart:   _fmt(departAt),
      arrive:   _fmt(arriveAt),
      duration: (totalSec / 60).round(),
      every:    _guessFrequency(vehicleType),
      legs: [
        Leg(TransitMode.walk, walkBefore),
        Leg(mode, (transitSec / 60).round(), lineName),
        Leg(TransitMode.walk, walkAfter),
      ],
      transfers: transitCount - 1,
      departMin: departAt.hour * 60 + departAt.minute,
    );
  }

  TransitMode _vehicleMode(String type) {
    switch (type.toUpperCase()) {
      case 'SUBWAY':
      case 'METRO_RAIL':
        return TransitMode.metro;
      case 'TRAM':
      case 'LIGHT_RAIL':
      case 'CABLE_CAR':
      case 'GONDOLA_LIFT':
        return TransitMode.tram;
      case 'FERRY':
        return TransitMode.ferry;
      case 'RAIL':
      case 'HEAVY_RAIL':
      case 'COMMUTER_TRAIN':
      case 'HIGH_SPEED_TRAIN':
        return TransitMode.train;
      default:
        return TransitMode.bus;
    }
  }

  int _guessFrequency(String vehicleType) {
    switch (vehicleType.toUpperCase()) {
      case 'SUBWAY':
      case 'METRO_RAIL':
        return 5;
      case 'TRAM':
      case 'LIGHT_RAIL':
        return 10;
      case 'RAIL':
      case 'HEAVY_RAIL':
      case 'COMMUTER_TRAIN':
        return 15;
      case 'FERRY':
        return 30;
      default:
        return 10;
    }
  }

  String _fmt(DateTime dt) {
    final h    = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m    = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }
}
