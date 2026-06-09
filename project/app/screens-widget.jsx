// screens-widget.jsx — the home-screen widget in context (wallpaper + app grid + Catch widget).
// Contract: <WidgetHome t platform />

function AppIcon({ label, color, Icon, dark }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6, width: 60 }}>
      <div style={{ width: 56, height: 56, borderRadius: 14, background: color,
        display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff',
        boxShadow: '0 4px 10px rgba(0,0,0,0.18)' }}>
        <Icon size={28} style={{ strokeWidth: 1.8 }} />
      </div>
      <span style={{ fontSize: 11, color: '#fff', textShadow: '0 1px 3px rgba(0,0,0,0.4)', fontWeight: 500 }}>{label}</span>
    </div>
  );
}

function CatchWidget({ t, platform }) {
  const ios = platform === 'ios';
  const d0 = HOME_DEPS[0], d1 = HOME_DEPS[1];
  return (
    <div style={{
      background: t.dark ? 'rgba(28,32,37,0.82)' : 'rgba(255,255,255,0.9)',
      backdropFilter: 'blur(20px) saturate(160%)', WebkitBackdropFilter: 'blur(20px) saturate(160%)',
      borderRadius: ios ? 24 : 28, padding: 16, color: t.text,
      boxShadow: '0 10px 30px rgba(0,0,0,0.18)', border: `1px solid ${t.dark ? 'rgba(255,255,255,0.08)' : 'rgba(255,255,255,0.5)'}`,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
        <div style={{ width: 22, height: 22, borderRadius: 7, background: t.accent, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <IconArrowR size={14} style={{ color: '#fff', strokeWidth: 2.4 }} />
        </div>
        <span style={{ fontSize: 13, fontWeight: 750, color: t.text }}>Catch</span>
        <span style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 4, fontSize: 12, color: t.textSec, fontWeight: 600 }}>
          <IconHome size={13} style={{ color: t.accent }} />Home
        </span>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, minWidth: 0 }}>
        <span style={{ width: 9, height: 9, borderRadius: 99, background: t.accent, flexShrink: 0 }} />
        <span style={{ fontSize: 21, fontWeight: 780, color: t.accent, letterSpacing: -0.3, whiteSpace: 'nowrap' }}>{leaveLabel(d0.leaveIn)}</span>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 9, minWidth: 0 }}>
        <LineBadge line={d0.line} t={t} size={24} />
        <span style={{ fontSize: 14, fontWeight: 650, color: t.text, whiteSpace: 'nowrap', flexShrink: 0 }}>{d0.headsign}</span>
        <span style={{ marginLeft: 'auto', fontSize: 13, color: t.textSec, fontWeight: 600, flexShrink: 0, ...TNUM }}>{d0.depart}</span>
      </div>
      <div style={{ height: 1, background: t.separator, margin: '11px 0' }} />
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, opacity: 0.85 }}>
        <span style={{ fontSize: 12, color: t.textTer, fontWeight: 600, width: 36 }}>then</span>
        <LineBadge line={d1.line} t={t} size={20} />
        <span style={{ fontSize: 12.5, color: t.textSec }}>{d1.headsign}</span>
        <span style={{ marginLeft: 'auto', fontSize: 12.5, color: t.textTer, ...TNUM }}>{d1.depart}</span>
      </div>
    </div>
  );
}

function WidgetHome({ t, platform }) {
  const ios = platform === 'ios';
  const wallpaper = t.dark
    ? 'linear-gradient(165deg, #1c2530 0%, #0e141b 60%, #0a0f14 100%)'
    : 'linear-gradient(165deg, #b9c7d6 0%, #cdd3dd 45%, #d8d2cf 100%)';
  const topInset = ios ? 58 : 16;
  const apps1 = [
    { label: 'Maps', color: '#3DA15A', Icon: IconPin },
    { label: 'Clock', color: '#1c1c1e', Icon: IconClock },
    { label: 'Weather', color: '#3a86c8', Icon: IconLocate },
    { label: 'Wallet', color: '#2b2b2e', Icon: IconWork },
  ];
  const apps2 = [
    { label: 'Settings', color: '#8a8f98', Icon: IconGear },
    { label: 'Alerts', color: '#e0890b', Icon: IconBell },
    { label: 'Notes', color: '#e8b84b', Icon: IconStar },
    { label: 'Refresh', color: '#6b7785', Icon: IconRefresh },
  ];
  const dock = [
    { label: '', color: '#3DA15A', Icon: IconPin },
    { label: '', color: '#3a86c8', Icon: IconLocate },
    { label: '', color: t.accent, Icon: IconArrowR },
    { label: '', color: '#2b2b2e', Icon: IconClock },
  ];
  return (
    <div style={{ height: '100%', background: wallpaper, fontFamily: t.family,
      display: 'flex', flexDirection: 'column', boxSizing: 'border-box',
      padding: `${topInset}px 18px 14px` }}>
      {!ios && (
        <div style={{ textAlign: 'center', color: '#fff', textShadow: '0 1px 4px rgba(0,0,0,0.35)', padding: '6px 0 16px' }}>
          <div style={{ fontSize: 52, fontWeight: 300, letterSpacing: -1, ...TNUM }}>5:24</div>
          <div style={{ fontSize: 14, fontWeight: 500, marginTop: -2 }}>Tue, June 9 · Heading home</div>
        </div>
      )}
      <CatchWidget t={t} platform={platform} />
      <div style={{ flex: 1 }} />
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 22 }}>
        {apps1.map((a, i) => <AppIcon key={i} {...a} dark={t.dark} />)}
      </div>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 22 }}>
        {apps2.map((a, i) => <AppIcon key={i} {...a} dark={t.dark} />)}
      </div>
      <div style={{ flex: 1 }} />
      {ios ? (
        <div style={{ display: 'flex', justifyContent: 'space-around', padding: 12, borderRadius: 30,
          background: 'rgba(255,255,255,0.22)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)' }}>
          {dock.map((a, i) => (
            <div key={i} style={{ width: 56, height: 56, borderRadius: 14, background: a.color,
              display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff',
              boxShadow: '0 4px 10px rgba(0,0,0,0.18)' }}>
              <a.Icon size={28} style={{ strokeWidth: 1.8 }} />
            </div>
          ))}
        </div>
      ) : (
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '0 18px', height: 52, borderRadius: 26,
          background: 'rgba(255,255,255,0.92)', boxShadow: '0 4px 14px rgba(0,0,0,0.18)' }}>
          <IconLocate size={20} style={{ color: '#5b6570' }} />
          <span style={{ fontSize: 15, color: '#5b6570' }}>Search</span>
          <IconBus size={20} style={{ color: '#5b6570', marginLeft: 'auto' }} />
        </div>
      )}
    </div>
  );
}

Object.assign(window, { WidgetHome, CatchWidget, AppIcon });
