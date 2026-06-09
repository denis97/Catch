// screens-detail.jsx — "When to leave": full list of leave times for the tapped route.
// Contract: <LeaveTimes t d onBack /> where d is the tapped departure.

const { useState: useStateDetail } = React;

function BackBar({ t, title, sub, onBack, trailing, platform }) {
  const topInset = platform === 'ios' ? 50 : 6;
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 4, padding: `${topInset}px 12px 12px`,
      background: t.pageBg, position: 'sticky', top: 0, zIndex: 5,
    }}>
      <button onClick={onBack} style={{
        appearance: 'none', border: 'none', background: 'transparent', cursor: 'pointer',
        width: 40, height: 40, marginLeft: -6, display: 'flex', alignItems: 'center',
        justifyContent: 'center', color: t.accent, flexShrink: 0,
      }}>
        <IconChevronL size={24} style={{ strokeWidth: 2.4 }} />
      </button>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 19, fontWeight: 760, letterSpacing: -0.3, color: t.text, lineHeight: 1.1 }}>{title}</div>
        {sub && <div style={{ fontSize: 12.5, color: t.textSec, marginTop: 2 }}>{sub}</div>}
      </div>
      {trailing}
    </div>
  );
}

function RouteAlts({ t, alts, sel, setSel }) {
  return (
    <div style={{ display: 'flex', gap: 8, overflowX: 'auto', padding: '0 18px 2px' }}>
      {alts.map((a) => {
        const on = sel === a.line;
        return (
          <button key={a.line} onClick={() => setSel(a.line)} style={{
            appearance: 'none', cursor: 'pointer', flexShrink: 0,
            display: 'flex', alignItems: 'center', gap: 8, padding: '8px 12px 8px 8px',
            borderRadius: 14, background: t.card, fontFamily: t.family,
            border: `1.5px solid ${on ? t.accent : t.border}`,
            boxShadow: on ? 'none' : t.shadow,
          }}>
            <LineBadge line={a.line} t={t} size={26} />
            <div style={{ textAlign: 'left', whiteSpace: 'nowrap' }}>
              <div style={{ fontSize: 13.5, fontWeight: 700, color: t.text, lineHeight: 1.1 }}>{a.duration} min</div>
              <div style={{ fontSize: 11, color: t.textSec, marginTop: 1 }}>
                {a.transfers === 0 ? 'Direct' : `${a.transfers} change`}
              </div>
            </div>
          </button>
        );
      })}
    </div>
  );
}

function LeaveTimeCard({ t, row, d, line, expanded, onToggle }) {
  const u = urgency(row.leaveIn);
  const uc = urgColor(t, u);
  const ride = d.duration - 2 * d.walk;
  return (
    <Card t={t} active={row.rec} onClick={onToggle} style={{ padding: 16, cursor: 'pointer' }}>
      <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
        <div style={{ flex: 1, minWidth: 0 }}>
          {row.rec && (
            <div style={{ display: 'inline-flex', alignItems: 'center', gap: 4, height: 20, padding: '0 8px',
              borderRadius: 6, background: t.accentSoft, color: t.accent, fontSize: 11, fontWeight: 700,
              letterSpacing: 0.3, marginBottom: 8 }}>
              <IconStar size={12} style={{ strokeWidth: 2 }} />BEST NOW
            </div>
          )}
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
            <span style={{ fontSize: 12, fontWeight: 700, color: t.textTer, textTransform: 'uppercase', letterSpacing: 0.6 }}>Leave</span>
            <span style={{ fontSize: 26, fontWeight: 780, letterSpacing: -0.6, color: t.text, ...TNUM }}>{row.leave}</span>
          </div>
          <div style={{ marginTop: 10 }}>
            <Legs legs={d.legs} t={t} compact />
          </div>
        </div>
        <div style={{ textAlign: 'right', flexShrink: 0 }}>
          <div style={{ display: 'inline-flex', height: 24, padding: '0 9px', borderRadius: 7, alignItems: 'center',
            background: u === 'go' ? t.accentSoft : u === 'now' ? t.amberSoft : t.chipBg, color: uc,
            fontSize: 12.5, fontWeight: 700, whiteSpace: 'nowrap' }}>
            {leaveLabel(row.leaveIn)}
          </div>
          <div style={{ fontSize: 12.5, color: t.textSec, marginTop: 9 }}>
            arrive <span style={{ fontWeight: 760, color: t.text, ...TNUM }}>{row.arrive}</span>
          </div>
          <div style={{ fontSize: 12, color: t.textTer, marginTop: 2, ...TNUM }}>{d.duration} min trip</div>
        </div>
      </div>
      {expanded && (
        <div style={{ marginTop: 14, paddingTop: 14, borderTop: `1px solid ${t.separator}` }}>
          {[
            ['walk', `Walk ${d.walk} min to ${d.from}`, null],
            [LINES[line] ? LINES[line].mode : 'bus', `${line} · ${ride} min ride`, line],
            ['walk', `Walk ${d.walk} min to ${d.headsign}`, null],
          ].map(([mode, label, ln], i, arr) => {
            const c = ln ? (LINES[ln] || {}).color : t.textTer;
            const isWalk = !ln;
            return (
              <div key={i} style={{ display: 'flex', gap: 12, alignItems: 'flex-start' }}>
                <div style={{ position: 'relative', width: 22, alignSelf: 'stretch', flexShrink: 0 }}>
                  <div style={{ position: 'absolute', left: 10, top: 4, bottom: i === arr.length - 1 ? '50%' : -2, width: 2,
                    borderLeft: isWalk ? `2px dotted ${t.textTer}` : `2px solid ${c}` }} />
                  <div style={{ position: 'absolute', left: 6, top: 4, width: 10, height: 10, borderRadius: 99,
                    background: t.card, border: `2.5px solid ${c}`, boxSizing: 'border-box' }} />
                </div>
                <div style={{ flex: 1, paddingBottom: 14, display: 'flex', alignItems: 'center', gap: 8,
                  color: isWalk ? t.textSec : t.text, fontSize: 13.5, fontWeight: isWalk ? 500 : 650 }}>
                  {React.createElement(MODE_ICON[mode], { size: 16, style: { color: isWalk ? t.textTer : c } })}
                  {label}
                </div>
              </div>
            );
          })}
          <PillButton t={t} icon={<IconBell size={17} />} style={{ height: 46 }}>Remind me to leave</PillButton>
        </div>
      )}
    </Card>
  );
}

function LeaveTimes({ t, platform, d, onBack }) {
  const dz = densityTokens(t._density);
  const [sel, setSel] = useStateDetail(d.line);
  const [open, setOpen] = useStateDetail(0);
  const series = buildSeries(d, 6);
  return (
    <div style={{ fontFamily: t.family, paddingBottom: 28 }}>
      <BackBar t={t} platform={platform} title={d.headsign} sub={`${series.length} ways to leave · from ${d.from}`} onBack={onBack}
        trailing={
          <IconTile t={t} size={38} radius={19} bg={t.card}>
            <IconSwap size={18} style={{ color: t.textSec }} />
          </IconTile>
        } />
      <div style={{ paddingBottom: 14 }}>
        <RouteAlts t={t} alts={DETAIL_ALTS} sel={sel} setSel={setSel} />
      </div>
      <div style={{ padding: `0 ${dz.cardPad}px`, display: 'flex', flexDirection: 'column', gap: 12 }}>
        {series.map((row) => (
          <LeaveTimeCard key={row.i} t={t} row={row} d={d} line={sel}
            expanded={open === row.i} onToggle={() => setOpen(open === row.i ? -1 : row.i)} />
        ))}
      </div>
    </div>
  );
}

Object.assign(window, { LeaveTimes, BackBar, RouteAlts });
