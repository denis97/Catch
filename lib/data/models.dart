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
