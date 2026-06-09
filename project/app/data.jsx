// data.jsx — mock transit data, theme tokens, format helpers for Catch.
// Scenario: weekday 5:24 PM, auto-detected "at Work → heading Home".

const NOW_LABEL = '5:24';
const NOW_MIN = 17 * 60 + 24; // 5:24 PM

// time helpers: minutes-from-midnight <-> "h:mm" (12h, no meridiem)
function parseMin(s) { const [h, m] = s.split(':').map(Number); const H = h < 7 ? h + 12 : h; return H * 60 + m; }
function fmtClock(min) { let h = Math.floor(min / 60) % 12; if (h === 0) h = 12; const m = min % 60; return `${h}:${String(m).padStart(2, '0')}`; }

// ── Line palette (badge colors, independent of the app accent) ──
const LINES = {
  '14B': { color: '#2D6CDF', mode: 'bus' },
  '2':   { color: '#2AA198', mode: 'tram' },
  'M3':  { color: '#7A52CC', mode: 'metro' },
  'RX':  { color: '#C24A3B', mode: 'train' },
  'F1':  { color: '#1E88C7', mode: 'ferry' },
};

// ── Saved places ───────────────────────────────────────────
const PLACES = [
  { id: 'home', kind: 'home',  name: 'Home',    address: '14 Maple Ave', stop: 'Maple Ave', walk: 4 },
  { id: 'work', kind: 'work',  name: 'Work',    address: 'Northgate Studio · Tech Quarter', stop: 'Center Street', walk: 4 },
  { id: 'gym',  kind: 'star',  name: 'Riverside Gym', address: '8 Quay Road', stop: 'Riverside', walk: 2 },
  { id: 'fam',  kind: 'star',  name: "Mum & Dad", address: 'Elm Park', stop: 'Elm Park Gate', walk: 6 },
];

// A departure = one specific ride you could take right now toward a place.
// leaveIn = minutes until you must walk out the door to catch it.
function dep(o) { return { transfers: 0, status: 'ontime', ...o }; }

// Heading HOME from Work (Center Street, 4 min walk). now 5:24.
const HOME_DEPS = [
  dep({ id: 'h1', line: '14B', headsign: 'Maple Heights', from: 'Center Street', walk: 4,
        leaveIn: 6, depart: '5:34', arrive: '5:56', duration: 26, every: 10,
        legs: [['walk', 4], ['bus', 18, '14B'], ['walk', 4]] }),
  dep({ id: 'h2', line: '2', headsign: 'Riverside Loop', from: 'Center Street', walk: 4,
        leaveIn: 13, depart: '5:41', arrive: '6:01', duration: 24, every: 12,
        legs: [['walk', 4], ['tram', 17, '2'], ['walk', 3]] }),
  dep({ id: 'h3', line: '14B', headsign: 'Maple Heights', from: 'Center Street', walk: 4,
        leaveIn: 16, depart: '5:44', arrive: '6:06', duration: 26, every: 10,
        legs: [['walk', 4], ['bus', 18, '14B'], ['walk', 4]] }),
  dep({ id: 'h4', line: 'RX', headsign: 'Northern Line', from: 'Union Station', walk: 9,
        leaveIn: 19, depart: '5:52', arrive: '6:08', duration: 24, every: 15, transfers: 1,
        legs: [['walk', 9], ['train', 11, 'RX'], ['walk', 4]] }),
];

// Heading to WORK from Home (Maple Ave, 4 min walk). (toggle demo)
const WORK_DEPS = [
  dep({ id: 'w1', line: '14B', headsign: 'Tech Quarter', from: 'Maple Ave', walk: 4,
        leaveIn: 3, depart: '5:31', arrive: '5:57', duration: 26, every: 10,
        legs: [['walk', 4], ['bus', 18, '14B'], ['walk', 4]] }),
  dep({ id: 'w2', line: 'M3', headsign: 'Downtown', from: 'Maple Square', walk: 6,
        leaveIn: 9, depart: '5:39', arrive: '5:58', duration: 19, every: 6,
        legs: [['walk', 6], ['metro', 9, 'M3'], ['walk', 4]] }),
  dep({ id: 'w3', line: '14B', headsign: 'Tech Quarter', from: 'Maple Ave', walk: 4,
        leaveIn: 13, depart: '5:41', arrive: '6:07', duration: 26, every: 10,
        legs: [['walk', 4], ['bus', 18, '14B'], ['walk', 4]] }),
];

// Longer list of leave-times for the detail screen (recommended 14B home).
const DETAIL_LEAVE_TIMES = [
  { leave: '5:30', depart: '5:34', arrive: '5:56', leaveIn: 6,  rec: true },
  { leave: '5:40', depart: '5:44', arrive: '6:06', leaveIn: 16 },
  { leave: '5:50', depart: '5:54', arrive: '6:16', leaveIn: 26 },
  { leave: '6:00', depart: '6:04', arrive: '6:26', leaveIn: 36 },
  { leave: '6:10', depart: '6:14', arrive: '6:36', leaveIn: 46 },
  { leave: '6:20', depart: '6:24', arrive: '6:46', leaveIn: 56 },
];

// Alternative routes shown on the detail screen.
const DETAIL_ALTS = [
  { line: '14B', mode: 'bus',  label: 'Bus 14B', sub: 'Direct · every 10 min',  duration: 26, transfers: 0 },
  { line: '2',   mode: 'tram', label: 'Tram 2',  sub: 'Direct · every 12 min',  duration: 24, transfers: 0 },
  { line: 'RX',  mode: 'train',label: 'Train RX',sub: '1 change · every 15 min', duration: 24, transfers: 1 },
];

// ── Urgency from leaveIn minutes ───────────────────────────
// go  = comfortable (green), now = leave immediately (amber), missed = gone (gray)
function urgency(leaveIn) {
  if (leaveIn <= 0) return 'missed';
  if (leaveIn <= 3) return 'now';
  return 'go';
}

// ── Format helpers ─────────────────────────────────────────
function leaveLabel(leaveIn) {
  if (leaveIn <= 0) return 'Just missed';
  if (leaveIn <= 1) return 'Leave now';
  return `Leave in ${leaveIn} min`;
}

// ── Density tokens ─────────────────────────────────────────
function densityTokens(d) {
  if (d === 'compact') return { cardPad: 14, rowPad: 11, gap: 9, sectionGap: 14 };
  if (d === 'comfy')   return { cardPad: 22, rowPad: 18, gap: 15, sectionGap: 24 };
  return { cardPad: 18, rowPad: 14, gap: 12, sectionGap: 18 }; // regular
}

// ── Theme ──────────────────────────────────────────────────
function buildTheme({ accent, dark, font }, platform) {
  const native = platform === 'ios'
    ? '-apple-system, "SF Pro Text", system-ui, sans-serif'
    : 'Roboto, system-ui, sans-serif';
  const family = (!font || font === 'Native') ? native : `"${font}", ${native}`;
  const soft = (pct) => `color-mix(in srgb, ${accent} ${pct}%, transparent)`;

  const base = {
    accent,
    accentText: '#ffffff',
    accentSoft: soft(dark ? 22 : 12),
    accentSoftStrong: soft(dark ? 30 : 16),
    amber: dark ? '#F2A93B' : '#D9850A',
    amberSoft: dark ? 'rgba(242,169,59,0.18)' : 'rgba(217,133,10,0.12)',
    missed: dark ? '#727B85' : '#98A2AD',
    family,
    radius: 22, radiusSm: 14,
  };
  const light = {
    pageBg: '#F1F3F5', card: '#FFFFFF', cardAlt: '#F6F7F9',
    text: '#101418', textSec: '#5B6570', textTer: '#9AA3AD',
    border: 'rgba(16,20,24,0.07)', separator: 'rgba(16,20,24,0.06)',
    shadow: '0 1px 2px rgba(16,20,24,0.05), 0 8px 24px rgba(16,20,24,0.05)',
    chipBg: 'rgba(16,20,24,0.05)',
  };
  const night = {
    pageBg: platform === 'ios' ? '#000000' : '#0C0E11', card: '#16191D', cardAlt: '#1F2429',
    text: '#F2F4F6', textSec: '#9AA3AD', textTer: '#69727C',
    border: 'rgba(255,255,255,0.09)', separator: 'rgba(255,255,255,0.07)',
    shadow: '0 1px 2px rgba(0,0,0,0.4), 0 10px 30px rgba(0,0,0,0.4)',
    chipBg: 'rgba(255,255,255,0.08)',
  };
  return { ...base, ...(dark ? night : light) };
}

// Build a schedule of upcoming leave-times for a tapped departure.
function buildSeries(d, count = 6) {
  const baseDepart = parseMin(d.depart);
  const rideTail = d.duration - d.walk; // ride + final walk
  const out = [];
  for (let i = 0; i < count; i++) {
    const depart = baseDepart + i * d.every;
    const leaveMin = depart - d.walk;
    out.push({
      i, depart: fmtClock(depart), arrive: fmtClock(depart + rideTail),
      leave: fmtClock(leaveMin), leaveIn: leaveMin - NOW_MIN, rec: i === 0,
    });
  }
  return out;
}

Object.assign(window, {
  NOW_LABEL, NOW_MIN, parseMin, fmtClock, LINES, PLACES, HOME_DEPS, WORK_DEPS,
  DETAIL_LEAVE_TIMES, DETAIL_ALTS, buildSeries,
  urgency, leaveLabel, densityTokens, buildTheme,
});
