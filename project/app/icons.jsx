// icons.jsx — minimal line icons (mode glyphs + UI) for Catch.
// All icons take { size, stroke, fill, style }. Stroke uses currentColor by default.

function _svg(children, { size = 24, viewBox = '0 0 24 24', style } = {}) {
  return (
    <svg width={size} height={size} viewBox={viewBox} fill="none"
      stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round"
      style={style}>
      {children}
    </svg>
  );
}

// ── Transit modes ───────────────────────────────────────────
const IconBus = (p) => _svg(<>
  <rect x="4" y="3.5" width="16" height="14" rx="3" />
  <path d="M4 11h16" />
  <path d="M7.5 14.5h.01M16.5 14.5h.01" />
  <path d="M7 17.5v2M17 17.5v2" />
</>, p);

const IconTrain = (p) => _svg(<>
  <rect x="5" y="3" width="14" height="13" rx="3" />
  <path d="M5 10h14" />
  <path d="M8.5 13h.01M15.5 13h.01" />
  <path d="M7 16l-2 4M17 16l2 4" />
</>, p);

const IconMetro = (p) => _svg(<>
  <path d="M12 3c-4 0-7 .8-7 4v6.5a3 3 0 003 3h8a3 3 0 003-3V7c0-3.2-3-4-7-4z" />
  <path d="M8.5 11h.01M15.5 11h.01" />
  <path d="M6.5 20l1.8-2.5M17.5 20l-1.8-2.5" />
</>, p);

const IconTram = (p) => _svg(<>
  <rect x="6" y="4" width="12" height="13" rx="2.5" />
  <path d="M9 4l-1.5-2M15 4l1.5-2" />
  <path d="M6 10h12" />
  <path d="M9.5 13.5h.01M14.5 13.5h.01" />
  <path d="M8 17l-1.5 3M16 17l1.5 3" />
</>, p);

const IconFerry = (p) => _svg(<>
  <path d="M4 14l1.6-5.2A2 2 0 017.5 7.3h9a2 2 0 011.9 1.5L20 14" />
  <path d="M12 4v3.3" />
  <path d="M3.5 14c1.5 0 1.5 1.5 3 1.5s1.5-1.5 3-1.5 1.5 1.5 3 1.5 1.5-1.5 3-1.5 1.5 1.5 3 1.5" />
  <path d="M4.5 18c1.5 0 1.5 1.5 3 1.5s1.5-1.5 3-1.5 1.5 1.5 3 1.5 1.5-1.5 3-1.5" />
</>, p);

const IconWalk = (p) => _svg(<>
  <circle cx="13" cy="4.5" r="1.6" />
  <path d="M11 21l1.5-5-2.5-2 1-5 3 2 2 1" />
  <path d="M10 9l-2 3" />
  <path d="M12.5 16l-2 5" />
</>, p);

const MODE_ICON = { bus: IconBus, train: IconTrain, metro: IconMetro, tram: IconTram, ferry: IconFerry, walk: IconWalk };

// ── UI glyphs ───────────────────────────────────────────────
const IconChevronR = (p) => _svg(<path d="M9 5l7 7-7 7" />, p);
const IconChevronL = (p) => _svg(<path d="M15 5l-7 7 7 7" />, p);
const IconChevronDown = (p) => _svg(<path d="M5 9l7 7 7-7" />, p);
const IconArrowR = (p) => _svg(<><path d="M5 12h14" /><path d="M13 6l6 6-6 6" /></>, p);
const IconClock = (p) => _svg(<><circle cx="12" cy="12" r="8.5" /><path d="M12 7.5V12l3 2" /></>, p);
const IconPin = (p) => _svg(<><path d="M12 21s7-5.5 7-11a7 7 0 10-14 0c0 5.5 7 11 7 11z" /><circle cx="12" cy="10" r="2.5" /></>, p);
const IconHome = (p) => _svg(<><path d="M4 11l8-7 8 7" /><path d="M6 9.5V20h12V9.5" /></>, p);
const IconWork = (p) => _svg(<><rect x="3.5" y="7.5" width="17" height="12" rx="2.5" /><path d="M8.5 7.5V6a2 2 0 012-2h3a2 2 0 012 2v1.5" /><path d="M3.5 12.5h17" /></>, p);
const IconStar = (p) => _svg(<path d="M12 4l2.4 4.9 5.4.8-3.9 3.8.9 5.4-4.8-2.5-4.8 2.5.9-5.4L4.2 9.7l5.4-.8L12 4z" />, p);
const IconPlus = (p) => _svg(<><path d="M12 5v14" /><path d="M5 12h14" /></>, p);
const IconBell = (p) => _svg(<><path d="M6 9a6 6 0 1112 0c0 5 2 6 2 6H4s2-1 2-6z" /><path d="M10 20a2 2 0 004 0" /></>, p);
const IconGear = (p) => _svg(<><circle cx="12" cy="12" r="3" /><path d="M12 3v2.5M12 18.5V21M4.2 7.5l2.2 1.3M17.6 15.2l2.2 1.3M19.8 7.5l-2.2 1.3M6.4 15.2l-2.2 1.3" /></>, p);
const IconCheck = (p) => _svg(<path d="M5 12.5l4.5 4.5L19 7" />, p);
const IconSwap = (p) => _svg(<><path d="M7 4l-3 3 3 3" /><path d="M4 7h13" /><path d="M17 20l3-3-3-3" /><path d="M20 17H7" /></>, p);
const IconLocate = (p) => _svg(<><circle cx="12" cy="12" r="3.5" /><path d="M12 2v3M12 19v3M2 12h3M19 12h3" /></>, p);
const IconRefresh = (p) => _svg(<><path d="M4 12a8 8 0 0113.5-5.8L20 8" /><path d="M20 4v4h-4" /><path d="M20 12a8 8 0 01-13.5 5.8L4 16" /><path d="M4 20v-4h4" /></>, p);

Object.assign(window, {
  IconBus, IconTrain, IconMetro, IconTram, IconFerry, IconWalk, MODE_ICON,
  IconChevronR, IconChevronL, IconChevronDown, IconArrowR, IconClock, IconPin,
  IconHome, IconWork, IconStar, IconPlus, IconBell, IconGear, IconCheck,
  IconSwap, IconLocate, IconRefresh,
});
