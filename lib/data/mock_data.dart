import 'models.dart';

// ── Time helpers ───────────────────────────────────────────────

String _fmt(DateTime dt) {
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final m = dt.minute.toString().padLeft(2, '0');
  final ampm = dt.hour < 12 ? 'AM' : 'PM';
  return '$h:$m $ampm';
}

String _fmtMin(int min) {
  int h = (min ~/ 60) % 12;
  if (h == 0) h = 12;
  final m = min % 60;
  return '$h:${m.toString().padLeft(2, '0')}';
}

String get nowLabel => _fmt(DateTime.now());

int get _nowMin {
  final n = DateTime.now();
  return n.hour * 60 + n.minute;
}

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

const List<RouteAlt> kDetailAlts = [
  RouteAlt(line: '14B', mode: TransitMode.bus,   label: 'Bus 14B',  sub: 'Direct · every 10 min',   duration: 26, transfers: 0),
  RouteAlt(line: '2',   mode: TransitMode.tram,  label: 'Tram 2',   sub: 'Direct · every 12 min',   duration: 24, transfers: 0),
  RouteAlt(line: 'RX',  mode: TransitMode.train, label: 'Train RX', sub: '1 change · every 15 min', duration: 24, transfers: 1),
];

List<LeaveSeries> buildSeries(Departure d, {int count = 6}) {
  final nowMin = _nowMin;
  return List.generate(count, (i) {
    final depart   = d.departMin + i * d.every;
    final leaveMin = depart - d.walk;
    return LeaveSeries(
      index:   i,
      depart:  _fmtMin(depart),
      arrive:  _fmtMin(depart + d.duration - d.walk),
      leave:   _fmtMin(leaveMin),
      leaveIn: leaveMin - nowMin,
      rec:     i == 0,
    );
  });
}

String leaveLabel(int leaveIn) {
  if (leaveIn <= 0) return 'Just missed';
  if (leaveIn <= 1) return 'Leave now';
  return 'Leave in $leaveIn min';
}
