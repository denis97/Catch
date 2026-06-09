import 'models.dart';

const nowLabel = '5:24';
const nowMin   = 17 * 60 + 24; // 5:24 PM

// ── Helpers ──────────────────────────────────────────────────

int _parseMin(String s) {
  final parts = s.split(':');
  int h = int.parse(parts[0]);
  final m = int.parse(parts[1]);
  if (h < 7) h += 12;
  return h * 60 + m;
}

String _fmtClock(int min) {
  int h = (min ~/ 60) % 12;
  if (h == 0) h = 12;
  final m = min % 60;
  return '$h:${m.toString().padLeft(2, '0')}';
}

// ── Mock data ─────────────────────────────────────────────────

const List<Place> kPlaces = [
  Place(id: 'home', kind: PlaceKind.home, name: 'Home',          address: '14 Maple Ave',                    stop: 'Maple Ave',     walk: 4),
  Place(id: 'work', kind: PlaceKind.work, name: 'Work',          address: 'Northgate Studio · Tech Quarter', stop: 'Center Street', walk: 4),
  Place(id: 'gym',  kind: PlaceKind.star, name: 'Riverside Gym', address: '8 Quay Road',                     stop: 'Riverside',     walk: 2),
  Place(id: 'fam',  kind: PlaceKind.star, name: 'Mum & Dad',     address: 'Elm Park',                        stop: 'Elm Park Gate', walk: 6),
];

const List<Departure> kHomeDeps = [
  Departure(id: 'h1', line: '14B', headsign: 'Maple Heights',  from: 'Center Street', walk: 4, leaveIn: 6,  depart: '5:34', arrive: '5:56', duration: 26, every: 10,
    legs: [Leg(TransitMode.walk, 4), Leg(TransitMode.bus,   18, '14B'), Leg(TransitMode.walk, 4)]),
  Departure(id: 'h2', line: '2',   headsign: 'Riverside Loop', from: 'Center Street', walk: 4, leaveIn: 13, depart: '5:41', arrive: '6:01', duration: 24, every: 12,
    legs: [Leg(TransitMode.walk, 4), Leg(TransitMode.tram,  17, '2'),   Leg(TransitMode.walk, 3)]),
  Departure(id: 'h3', line: '14B', headsign: 'Maple Heights',  from: 'Center Street', walk: 4, leaveIn: 16, depart: '5:44', arrive: '6:06', duration: 26, every: 10,
    legs: [Leg(TransitMode.walk, 4), Leg(TransitMode.bus,   18, '14B'), Leg(TransitMode.walk, 4)]),
  Departure(id: 'h4', line: 'RX',  headsign: 'Northern Line',  from: 'Union Station', walk: 9, leaveIn: 19, depart: '5:52', arrive: '6:08', duration: 24, every: 15, transfers: 1,
    legs: [Leg(TransitMode.walk, 9), Leg(TransitMode.train, 11, 'RX'),  Leg(TransitMode.walk, 4)]),
];

const List<Departure> kWorkDeps = [
  Departure(id: 'w1', line: '14B', headsign: 'Tech Quarter', from: 'Maple Ave',    walk: 4, leaveIn: 3,  depart: '5:31', arrive: '5:57', duration: 26, every: 10,
    legs: [Leg(TransitMode.walk, 4), Leg(TransitMode.bus,   18, '14B'), Leg(TransitMode.walk, 4)]),
  Departure(id: 'w2', line: 'M3',  headsign: 'Downtown',     from: 'Maple Square', walk: 6, leaveIn: 9,  depart: '5:39', arrive: '5:58', duration: 19, every: 6,
    legs: [Leg(TransitMode.walk, 6), Leg(TransitMode.metro, 9,  'M3'), Leg(TransitMode.walk, 4)]),
  Departure(id: 'w3', line: '14B', headsign: 'Tech Quarter', from: 'Maple Ave',    walk: 4, leaveIn: 13, depart: '5:41', arrive: '6:07', duration: 26, every: 10,
    legs: [Leg(TransitMode.walk, 4), Leg(TransitMode.bus,   18, '14B'), Leg(TransitMode.walk, 4)]),
];

const List<RouteAlt> kDetailAlts = [
  RouteAlt(line: '14B', mode: TransitMode.bus,   label: 'Bus 14B',  sub: 'Direct · every 10 min',   duration: 26, transfers: 0),
  RouteAlt(line: '2',   mode: TransitMode.tram,  label: 'Tram 2',   sub: 'Direct · every 12 min',   duration: 24, transfers: 0),
  RouteAlt(line: 'RX',  mode: TransitMode.train, label: 'Train RX', sub: '1 change · every 15 min', duration: 24, transfers: 1),
];

List<LeaveSeries> buildSeries(Departure d, {int count = 6}) {
  final baseDepart = _parseMin(d.depart);
  final rideTail = d.duration - d.walk;
  return List.generate(count, (i) {
    final depart  = baseDepart + i * d.every;
    final leaveMin = depart - d.walk;
    return LeaveSeries(
      index: i,
      depart: _fmtClock(depart),
      arrive: _fmtClock(depart + rideTail),
      leave:  _fmtClock(leaveMin),
      leaveIn: leaveMin - nowMin,
      rec: i == 0,
    );
  });
}

String leaveLabel(int leaveIn) {
  if (leaveIn <= 0) return 'Just missed';
  if (leaveIn <= 1) return 'Leave now';
  return 'Leave in $leaveIn min';
}
