import 'models.dart';

// ── Time helpers ───────────────────────────────────────────────

String _fmt(DateTime dt) {
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final m = dt.minute.toString().padLeft(2, '0');
  final ampm = dt.hour < 12 ? 'AM' : 'PM';
  return '$h:$m $ampm';
}

String fmtClock(int min) {
  int h = (min ~/ 60) % 12;
  if (h == 0) h = 12;
  final m = min % 60;
  return '$h:${m.toString().padLeft(2, '0')}';
}

String get nowLabel => _fmt(DateTime.now());

// inMin: bus departs this many minutes from now
Departure _dep(
  String id, String line, String headsign, String from, {
  required int walk,
  required int inMin,
  required int ride,
  required int every,
  required List<Leg> legs,
  int transfers = 0,
}) {
  final now      = DateTime.now();
  final departAt = now.add(Duration(minutes: inMin));
  final departMin = departAt.hour * 60 + departAt.minute;
  return Departure(
    id: id, line: line, headsign: headsign, from: from, walk: walk,
    leaveIn:   inMin - walk,
    depart:    _fmt(departAt),
    arrive:    _fmt(departAt.add(Duration(minutes: ride))),
    duration:  walk + ride + walk,
    every:     every,
    legs:      legs,
    transfers: transfers,
    departMin: departMin,
  );
}

// ── Mock data ─────────────────────────────────────────────────

const List<Place> kPlaces = [
  Place(id: 'home', kind: PlaceKind.home, name: 'Home',          address: '14 Maple Ave',                    stop: 'Maple Ave',     walk: 4),
  Place(id: 'work', kind: PlaceKind.work, name: 'Work',          address: 'Northgate Studio · Tech Quarter', stop: 'Center Street', walk: 4),
  Place(id: 'gym',  kind: PlaceKind.star, name: 'Riverside Gym', address: '8 Quay Road',                     stop: 'Riverside',     walk: 2),
  Place(id: 'fam',  kind: PlaceKind.star, name: 'Mum & Dad',     address: 'Elm Park',                        stop: 'Elm Park Gate', walk: 6),
];

List<Departure> get kHomeDeps => [
  _dep('h1', '14B', 'Maple Heights',  'Center Street', walk: 4, inMin: 10, ride: 18, every: 10,
    legs: [Leg(TransitMode.walk, 4), Leg(TransitMode.bus,   18, '14B'), Leg(TransitMode.walk, 4)]),
  _dep('h2', '2',   'Riverside Loop', 'Center Street', walk: 4, inMin: 17, ride: 17, every: 12,
    legs: [Leg(TransitMode.walk, 4), Leg(TransitMode.tram,  17, '2'),   Leg(TransitMode.walk, 3)]),
  _dep('h3', '14B', 'Maple Heights',  'Center Street', walk: 4, inMin: 20, ride: 18, every: 10,
    legs: [Leg(TransitMode.walk, 4), Leg(TransitMode.bus,   18, '14B'), Leg(TransitMode.walk, 4)]),
  _dep('h4', 'RX',  'Northern Line',  'Union Station', walk: 9, inMin: 28, ride: 11, every: 15,
    transfers: 1,
    legs: [Leg(TransitMode.walk, 9), Leg(TransitMode.train, 11, 'RX'),  Leg(TransitMode.walk, 4)]),
];

List<Departure> get kWorkDeps => [
  _dep('w1', '14B', 'Tech Quarter', 'Maple Ave',    walk: 4, inMin:  7, ride: 18, every: 10,
    legs: [Leg(TransitMode.walk, 4), Leg(TransitMode.bus,   18, '14B'), Leg(TransitMode.walk, 4)]),
  _dep('w2', 'M3',  'Downtown',     'Maple Square', walk: 6, inMin: 15, ride:  9, every:  6,
    legs: [Leg(TransitMode.walk, 6), Leg(TransitMode.metro,  9, 'M3'),  Leg(TransitMode.walk, 4)]),
  _dep('w3', '14B', 'Tech Quarter', 'Maple Ave',    walk: 4, inMin: 17, ride: 18, every: 10,
    legs: [Leg(TransitMode.walk, 4), Leg(TransitMode.bus,   18, '14B'), Leg(TransitMode.walk, 4)]),
];

/// A copy of [d] departing [byMin] minutes later, with all derived fields
/// recomputed. Used to synthesize later departures from a known one.
Departure shiftDeparture(Departure d, int byMin) {
  final departMin = d.departMin + byMin;
  return Departure(
    id:        '${d.id}+$byMin',
    line:      d.line,
    headsign:  d.headsign,
    from:      d.from,
    walk:      d.walk,
    leaveIn:   d.leaveIn + byMin,
    depart:    fmtClock(departMin),
    arrive:    fmtClock(departMin + d.duration - d.walk),
    duration:  d.duration,
    every:     d.every,
    legs:      d.legs,
    transfers: d.transfers,
    departMin: departMin,
  );
}

/// Synthesized series of upcoming departures based on the line frequency.
List<Departure> buildSeries(Departure d, {int count = 6}) =>
    List.generate(count, (i) => shiftDeparture(d, i * d.every));

String leaveLabel(int leaveIn) {
  if (leaveIn <= 0) return 'Just missed';
  if (leaveIn <= 1) return 'Leave now';
  return 'Leave in $leaveIn min';
}
