enum TransitMode { bus, train, metro, tram, ferry, walk }
enum PlaceKind { home, work, star }

class Leg {
  final TransitMode mode;
  final int minutes;
  final String? line;
  const Leg(this.mode, this.minutes, [this.line]);
}

class Departure {
  final String id;
  final String line;
  final String headsign;
  final String from;
  final int walk;
  final String depart;
  final String arrive;
  final int duration;
  final int every;
  final List<Leg> legs;
  final int transfers;
  final int departMin; // minutes since midnight

  const Departure({
    required this.id,
    required this.line,
    required this.headsign,
    required this.from,
    required this.walk,
    required this.depart,
    required this.arrive,
    required this.duration,
    required this.every,
    required this.legs,
    this.transfers = 0,
    this.departMin = 0,
  });

  /// Minutes until the user must walk out — computed from the departure
  /// time so countdowns stay accurate without refetching.
  int get leaveIn {
    final now = DateTime.now();
    var diff = departMin - walk - (now.hour * 60 + now.minute);
    if (diff < -720) diff += 1440; // departure is past midnight
    return diff;
  }

  /// The primary (non-walk) transit mode of this departure.
  TransitMode get mode {
    for (final l in legs) {
      if (l.mode != TransitMode.walk) return l.mode;
    }
    return TransitMode.bus;
  }
}

class Place {
  final String id;
  final PlaceKind kind;
  final String name;
  final String address;
  final String stop;
  final int walk;
  final double? lat;
  final double? lng;
  final String? placeId;

  const Place({
    required this.id,
    required this.kind,
    required this.name,
    required this.address,
    this.stop = '',
    this.walk = 0,
    this.lat,
    this.lng,
    this.placeId,
  });

  bool get hasCoords => lat != null && lng != null;

  /// Destination string for the Directions API.
  /// place_id is the most precise (same routing as Google Maps app).
  /// Falls back to address string if place_id not available.
  String get destinationParam => placeId != null ? 'place_id:$placeId' : address;

  Place copyWith({String? name, String? address, double? lat, double? lng}) => Place(
        id: id, kind: kind,
        name: name ?? this.name,
        address: address ?? this.address,
        stop: stop, walk: walk,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        placeId: placeId,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'kind': kind.name, 'name': name, 'address': address,
        'stop': stop, 'walk': walk, 'lat': lat, 'lng': lng, 'placeId': placeId,
      };

  factory Place.fromJson(Map<String, dynamic> j) => Place(
        id: j['id'] as String,
        kind: PlaceKind.values.byName(j['kind'] as String),
        name: j['name'] as String,
        address: j['address'] as String,
        stop: (j['stop'] as String?) ?? '',
        walk: (j['walk'] as int?) ?? 0,
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        placeId: j['placeId'] as String?,
      );
}

/// A recurring window during which the app proactively shows the next
/// departure on the lock screen — when the user is near [atPlaceId] and
/// presumably about to head to [toPlaceId].
class CommuteAlert {
  final String id;
  final String atPlaceId; // where the user is (geofence anchor)
  final String toPlaceId; // destination to route to
  final int startMin;     // window start, minutes since midnight
  final int endMin;       // window end, minutes since midnight
  final List<int> days;   // DateTime.weekday values (1=Mon … 7=Sun)
  final bool enabled;

  const CommuteAlert({
    required this.id,
    required this.atPlaceId,
    required this.toPlaceId,
    required this.startMin,
    required this.endMin,
    required this.days,
    this.enabled = true,
  });

  bool activeAt(DateTime now) {
    final nowMin = now.hour * 60 + now.minute;
    return days.contains(now.weekday) && nowMin >= startMin && nowMin < endMin;
  }

  /// Next moment this alert needs attention: now if the window is open,
  /// otherwise the start of the next scheduled window.
  DateTime nextRun(DateTime now) {
    if (activeAt(now)) return now;
    for (int i = 0; i < 8; i++) {
      final day = DateTime(now.year, now.month, now.day).add(Duration(days: i));
      if (!days.contains(day.weekday)) continue;
      final start = day.add(Duration(minutes: startMin));
      if (start.isAfter(now)) return start;
    }
    return now.add(const Duration(days: 7)); // unreachable with valid days
  }

  CommuteAlert copyWith({bool? enabled}) => CommuteAlert(
        id: id, atPlaceId: atPlaceId, toPlaceId: toPlaceId,
        startMin: startMin, endMin: endMin, days: days,
        enabled: enabled ?? this.enabled,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'at': atPlaceId, 'to': toPlaceId,
        'start': startMin, 'end': endMin, 'days': days, 'enabled': enabled,
      };

  factory CommuteAlert.fromJson(Map<String, dynamic> j) => CommuteAlert(
        id: j['id'] as String,
        atPlaceId: j['at'] as String,
        toPlaceId: j['to'] as String,
        startMin: j['start'] as int,
        endMin: j['end'] as int,
        days: (j['days'] as List<dynamic>).cast<int>(),
        enabled: (j['enabled'] as bool?) ?? true,
      );
}
