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
  final int leaveIn;
  final String depart;
  final String arrive;
  final int duration;
  final int every;
  final List<Leg> legs;
  final int transfers;

  const Departure({
    required this.id,
    required this.line,
    required this.headsign,
    required this.from,
    required this.walk,
    required this.leaveIn,
    required this.depart,
    required this.arrive,
    required this.duration,
    required this.every,
    required this.legs,
    this.transfers = 0,
  });
}

class Place {
  final String id;
  final PlaceKind kind;
  final String name;
  final String address;
  final String stop;
  final int walk;

  const Place({
    required this.id,
    required this.kind,
    required this.name,
    required this.address,
    required this.stop,
    required this.walk,
  });
}

class LeaveSeries {
  final int index;
  final String depart;
  final String arrive;
  final String leave;
  final int leaveIn;
  final bool rec;

  const LeaveSeries({
    required this.index,
    required this.depart,
    required this.arrive,
    required this.leave,
    required this.leaveIn,
    required this.rec,
  });
}

class RouteAlt {
  final String line;
  final TransitMode mode;
  final String label;
  final String sub;
  final int duration;
  final int transfers;

  const RouteAlt({
    required this.line,
    required this.mode,
    required this.label,
    required this.sub,
    required this.duration,
    required this.transfers,
  });
}
