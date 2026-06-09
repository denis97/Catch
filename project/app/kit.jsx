// kit.jsx — shared UI atoms for Catch screens. Every atom takes a theme `t`.

function urgColor(t, u) {
  return u === 'go' ? t.accent : u === 'now' ? t.amber : t.missed;
}

// Colored line badge with mode glyph + line id.
function LineBadge({ line, t, size = 28 }) {
  const meta = LINES[line] || { color: t.textSec, mode: 'bus' };
  const Icon = MODE_ICON[meta.mode];
  const fs = size <= 24 ? 12 : 13.5;
  return (
    <div style={{
      height: size, minWidth: size, padding: '0 8px', borderRadius: 9,
      background: meta.color, color: '#fff',
      display: 'inline-flex', alignItems: 'center', gap: 5, flexShrink: 0,
    }}>
      <Icon size={size <= 24 ? 15 : 17} style={{ strokeWidth: 1.9 }} />
      <span style={{ fontSize: fs, fontWeight: 700, letterSpacing: 0.2 }}>{line}</span>
    </div>
  );
}

// Compact journey legs: walk · ride · walk
function Legs({ legs, t, compact = false }) {
  const sep = (
    <div style={{ display: 'flex', alignItems: 'center', color: t.textTer, padding: '0 1px' }}>
      <IconChevronR size={13} style={{ strokeWidth: 2 }} />
    </div>
  );
  const pill = (mode, label, color, key) => (
    <div key={key} style={{
      display: 'inline-flex', alignItems: 'center', gap: 4,
      height: 24, padding: '0 8px', borderRadius: 7,
      background: color ? color : t.chipBg,
      color: color ? '#fff' : t.textSec,
      fontSize: 12.5, fontWeight: color ? 700 : 600,
    }}>
      {React.createElement(MODE_ICON[mode], { size: 14, style: { strokeWidth: 1.9 } })}
      <span>{label}</span>
    </div>
  );
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 5, flexWrap: 'wrap' }}>
      {legs.map((leg, i) => {
        const [mode, min, line] = leg;
        const meta = line ? (LINES[line] || {}) : {};
        const node = mode === 'walk'
          ? pill('walk', `${min}`, null, i)
          : pill(mode, compact ? line : `${line}`, meta.color, i);
        return (
          <React.Fragment key={i}>
            {i > 0 && sep}
            {node}
          </React.Fragment>
        );
      })}
    </div>
  );
}

// Soft rounded card surface.
function Card({ t, children, style = {}, onClick, active = false }) {
  return (
    <div onClick={onClick} style={{
      background: t.card, borderRadius: t.radius,
      border: `1px solid ${active ? t.accent : t.border}`,
      boxShadow: t.shadow, boxSizing: 'border-box',
      cursor: onClick ? 'pointer' : 'default',
      transition: 'border-color .15s ease',
      ...style,
    }}>{children}</div>
  );
}

// Small uppercase section label.
function SectionLabel({ t, children, style = {} }) {
  return (
    <div style={{
      fontSize: 12.5, fontWeight: 700, letterSpacing: 0.6, textTransform: 'uppercase',
      color: t.textTer, padding: '0 4px 8px', ...style,
    }}>{children}</div>
  );
}

// Pill button (primary / ghost).
function PillButton({ t, children, onClick, kind = 'primary', style = {}, icon }) {
  const primary = kind === 'primary';
  return (
    <button onClick={onClick} style={{
      appearance: 'none', border: 'none', cursor: 'pointer',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
      height: 52, padding: '0 22px', borderRadius: 16, width: '100%',
      background: primary ? t.accent : t.chipBg,
      color: primary ? '#fff' : t.text,
      fontFamily: t.family, fontSize: 17, fontWeight: 650,
      letterSpacing: 0.1, whiteSpace: 'nowrap', ...style,
    }}>
      {icon}{children}
    </button>
  );
}

// Round icon tile (place avatar, header buttons).
function IconTile({ t, children, bg, color, size = 40, radius = 12 }) {
  return (
    <div style={{
      width: size, height: size, borderRadius: radius, flexShrink: 0,
      background: bg || t.chipBg, color: color || t.text,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
    }}>{children}</div>
  );
}

const TNUM = { fontVariantNumeric: 'tabular-nums', fontFeatureSettings: '"tnum"' };

Object.assign(window, { urgColor, LineBadge, Legs, Card, SectionLabel, PillButton, IconTile, TNUM });
