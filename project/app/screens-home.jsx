// screens-home.jsx — the Home screen: context header + next-departure hero + "if you miss it" timeline.

function DestSwitch({ t, dest, setDest }) {
  const opt = (id, label, Icon) => {
    const on = dest === id;
    return (
      <button onClick={() => setDest(id)} style={{
        appearance: 'none', border: 'none', cursor: 'pointer',
        flex: 1, height: 38, borderRadius: 11,
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
        background: on ? t.card : 'transparent',
        color: on ? t.text : t.textSec,
        boxShadow: on ? '0 1px 3px rgba(16,20,24,0.12)' : 'none',
        fontFamily: t.family, fontSize: 14.5, fontWeight: 650,
        transition: 'all .15s ease',
      }}>
        <Icon size={17} style={{ color: on ? t.accent : t.textTer }} />
        {label}
      </button>
    );
  };
  return (
    <div style={{ display: 'flex', gap: 3, padding: 3, background: t.chipBg, borderRadius: 14 }}>
      {opt('home', 'Home', IconHome)}
      {opt('work', 'Work', IconWork)}
    </div>
  );
}

function ContextHeader({ t, dest }) {
  const atWork = dest === 'home';
  return (
    <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 14 }}>
      <div>
        <div style={{ fontSize: 30, fontWeight: 760, color: t.text, letterSpacing: -0.6, lineHeight: 1.05 }}>
          {dest === 'home' ? 'Heading home' : 'Heading to work'}
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 7 }}>
          <span style={{
            display: 'inline-flex', alignItems: 'center', gap: 4, height: 22, padding: '0 8px',
            borderRadius: 7, background: t.accentSoft, color: t.accent, fontSize: 12, fontWeight: 700,
            letterSpacing: 0.3,
          }}>
            <IconLocate size={12} style={{ strokeWidth: 2 }} />AUTO
          </span>
          <span style={{ fontSize: 13.5, color: t.textSec, ...TNUM }}>
            You're at {atWork ? 'Work' : 'Home'} · {NOW_LABEL} PM
          </span>
        </div>
      </div>
      <IconTile t={t} size={40} radius={20}>
        <IconGear size={20} style={{ color: t.textSec }} />
      </IconTile>
    </div>
  );
}

function DepartureHero({ t, d, onClick }) {
  const u = urgency(d.leaveIn);
  const uc = urgColor(t, u);
  return (
    <Card t={t} onClick={onClick} style={{ padding: 0, overflow: 'hidden' }}>
      {/* urgency band */}
      <div style={{
        background: u === 'go' ? t.accentSoft : u === 'now' ? t.amberSoft : t.chipBg,
        padding: '13px 18px', display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 9, minWidth: 0, flex: '1 1 auto' }}>
          <span style={{ position: 'relative', width: 10, height: 10, flexShrink: 0 }}>
            <span style={{ position: 'absolute', inset: 0, borderRadius: 99, background: uc, opacity: 0.35,
              animation: u === 'missed' ? 'none' : 'catchPulse 1.8s ease-out infinite' }} />
            <span style={{ position: 'absolute', inset: 2, borderRadius: 99, background: uc }} />
          </span>
          <span style={{ fontSize: 22, fontWeight: 770, color: uc, letterSpacing: -0.3, whiteSpace: 'nowrap' }}>
            {leaveLabel(d.leaveIn)}
          </span>
        </div>
        <button onClick={(e) => { e.stopPropagation(); }} style={{
          appearance: 'none', border: 'none', cursor: 'pointer', background: 'transparent',
          display: 'flex', alignItems: 'center', gap: 5, color: t.textSec, fontFamily: t.family,
          fontSize: 13, fontWeight: 650, flexShrink: 0, whiteSpace: 'nowrap',
        }}>
          <IconBell size={16} />Remind me
        </button>
      </div>
      {/* body */}
      <div style={{ padding: '15px 18px 17px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, minWidth: 0 }}>
          <LineBadge line={d.line} t={t} size={30} />
          <span style={{ fontSize: 18, fontWeight: 720, color: t.text, letterSpacing: -0.2, whiteSpace: 'nowrap', flexShrink: 0 }}>{d.headsign}</span>
        </div>
        <div style={{ fontSize: 13.5, color: t.textSec, marginTop: 7, display: 'flex', alignItems: 'center', gap: 5 }}>
          <IconWalk size={15} style={{ color: t.textTer, flexShrink: 0 }} />
          <span style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>Board at {d.from} · {d.walk} min walk</span>
        </div>
        <div style={{ height: 1, background: t.separator, margin: '14px 0' }} />
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginBottom: 11, minWidth: 0 }}>
          <span style={{ fontSize: 17, fontWeight: 720, color: t.text, whiteSpace: 'nowrap', ...TNUM }}>{d.depart} → {d.arrive}</span>
          <span style={{ fontSize: 13.5, color: t.textSec, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', minWidth: 0, ...TNUM }}>· {d.duration} min · every {d.every} min</span>
        </div>
        <Legs legs={d.legs} t={t} />
      </div>
    </Card>
  );
}

function DepartureRow({ t, d, onClick, isLast }) {
  const u = urgency(d.leaveIn);
  const uc = urgColor(t, u);
  return (
    <div onClick={onClick} style={{ display: 'grid', gridTemplateColumns: '46px 22px 1fr', cursor: 'pointer' }}>
      {/* leave time */}
      <div style={{ textAlign: 'right', paddingRight: 8, paddingTop: 13 }}>
        <div style={{ fontSize: 14.5, fontWeight: 700, color: t.text, ...TNUM }}>{d.depart}</div>
      </div>
      {/* rail */}
      <div style={{ position: 'relative', display: 'flex', justifyContent: 'center' }}>
        <div style={{ position: 'absolute', top: 0, bottom: isLast ? '50%' : 0, width: 2, background: t.separator }} />
        <div style={{ position: 'absolute', top: 18, width: 11, height: 11, borderRadius: 99,
          background: t.card, border: `2.5px solid ${uc}`, boxSizing: 'border-box' }} />
      </div>
      {/* content */}
      <div style={{ padding: '12px 0 12px 6px', borderBottom: isLast ? 'none' : `1px solid ${t.separator}` }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 8 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, minWidth: 0 }}>
            <LineBadge line={d.line} t={t} size={24} />
            <span style={{ fontSize: 14.5, fontWeight: 650, color: t.text, whiteSpace: 'nowrap', flexShrink: 0 }}>{d.headsign}</span>
          </div>
          <span style={{ fontSize: 13, color: t.textSec, flexShrink: 0, ...TNUM }}>arr {d.arrive}</span>
        </div>
        <div style={{ fontSize: 12.5, color: uc, fontWeight: 600, marginTop: 5, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
          {leaveLabel(d.leaveIn)} <span style={{ color: t.textTer, fontWeight: 500 }}>· every {d.every} min · {d.duration} min</span>
        </div>
      </div>
    </div>
  );
}

function Home({ t, platform, dest, setDest, openDetail }) {
  const deps = dest === 'home' ? HOME_DEPS : WORK_DEPS;
  const dz = densityTokens(t._density);
  const [hero, ...rest] = deps;
  const topInset = platform === 'ios' ? 54 : 8;
  return (
    <div style={{ padding: `${topInset}px ${dz.cardPad}px 28px`, fontFamily: t.family }}>
      <ContextHeader t={t} dest={dest} />
      <DestSwitch t={t} dest={dest} setDest={setDest} />
      <div style={{ height: dz.sectionGap }} />
      <DepartureHero t={t} d={hero} onClick={() => openDetail(hero)} />
      <div style={{ height: dz.sectionGap + 2 }} />
      <SectionLabel t={t}>If you miss it</SectionLabel>
      <Card t={t} style={{ padding: '2px 16px' }}>
        {rest.map((d, i) => (
          <DepartureRow key={d.id} t={t} d={d} isLast={i === rest.length - 1} onClick={() => openDetail(d)} />
        ))}
      </Card>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
        marginTop: 16, color: t.textTer, fontSize: 12.5 }}>
        <IconRefresh size={13} /> Live · updated just now
      </div>
    </div>
  );
}

Object.assign(window, { Home, DepartureHero, DepartureRow, DestSwitch, ContextHeader });
