// screens-onboarding.jsx — first run: welcome → location → set Home/Work.
// Contract: <Onboarding t platform onFinish />

const { useState: useStateOnb } = React;

// Floating preview of the "leave in" promise.
function PromiseCard({ t }) {
  return (
    <div style={{ background: t.card, borderRadius: 20, padding: 16, width: 232,
      boxShadow: '0 24px 60px rgba(16,20,24,0.18)', transform: 'rotate(-2.5deg)' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 9 }}>
        <LineBadge line="14B" t={t} size={28} />
        <span style={{ fontSize: 14.5, fontWeight: 720, color: t.text }}>Maple Heights</span>
        <span style={{ marginLeft: 'auto', width: 9, height: 9, borderRadius: 99, background: t.accent }} />
      </div>
      <div style={{ marginTop: 13, color: t.accent }}>
        <div style={{ fontSize: 10.5, fontWeight: 700, letterSpacing: 1, textTransform: 'uppercase' }}>Leave in</div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 5 }}>
          <span style={{ fontSize: 42, fontWeight: 800, letterSpacing: -1.5, ...TNUM }}>6</span>
          <span style={{ fontSize: 18, fontWeight: 700 }}>min</span>
        </div>
      </div>
      <div style={{ marginTop: 4, fontSize: 12, color: t.textTer, ...TNUM }}>Arrive home by 5:56</div>
    </div>
  );
}

function PlaceField({ t, Icon, label, value, tint }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 13, background: t.card, borderRadius: 16,
      padding: '13px 15px', border: `1px solid ${t.border}`, boxShadow: t.shadow }}>
      <IconTile t={t} size={38} radius={11} bg={tint} color="#fff"><Icon size={20} /></IconTile>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 11.5, fontWeight: 700, color: t.textTer, textTransform: 'uppercase', letterSpacing: 0.5 }}>{label}</div>
        <div style={{ fontSize: 15, fontWeight: 600, color: t.text, marginTop: 1 }}>{value}</div>
      </div>
      <IconCheck size={20} style={{ color: t.accent }} />
    </div>
  );
}

function Onboarding({ t, platform, onFinish }) {
  const [step, setStep] = useStateOnb(0);
  const total = 3;
  const next = () => (step < total - 1 ? setStep(step + 1) : onFinish());
  const topInset = platform === 'ios' ? 56 : 18;

  const dots = (
    <div style={{ display: 'flex', gap: 7, justifyContent: 'center' }}>
      {Array.from({ length: total }).map((_, i) => (
        <div key={i} style={{ width: i === step ? 22 : 7, height: 7, borderRadius: 99,
          background: i === step ? t.accent : t.chipBg, transition: 'width .25s, background .25s' }} />
      ))}
    </div>
  );

  let body, primary, ghost;
  if (step === 0) {
    primary = 'Get started'; ghost = 'I already have an account';
    body = (
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', textAlign: 'center' }}>
        <div style={{ height: 196, display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 18 }}>
          <PromiseCard t={t} />
        </div>
        <div style={{ fontSize: 40, fontWeight: 800, letterSpacing: -1.4, color: t.text }}>Catch</div>
        <div style={{ fontSize: 19, fontWeight: 700, color: t.text, marginTop: 12, letterSpacing: -0.3 }}>Know when to leave.</div>
        <div style={{ fontSize: 15, color: t.textSec, marginTop: 8, lineHeight: 1.5, maxWidth: 270 }}>
          Your next ride home or to work — and the minute to walk out the door.
        </div>
      </div>
    );
  } else if (step === 1) {
    primary = 'Allow location'; ghost = 'Enter location manually';
    body = (
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', textAlign: 'center' }}>
        <IconTile t={t} size={92} radius={28} bg={t.accentSoft} color={t.accent}><IconPin size={46} /></IconTile>
        <div style={{ fontSize: 26, fontWeight: 780, letterSpacing: -0.6, color: t.text, marginTop: 28, maxWidth: 300 }}>
          Find your stops automatically
        </div>
        <div style={{ fontSize: 15, color: t.textSec, marginTop: 12, lineHeight: 1.5, maxWidth: 300 }}>
          Catch uses your location to show departures from the stops nearest you — and switches between Home and Work as your day moves.
        </div>
      </div>
    );
  } else {
    primary = "I'm all set"; ghost = 'Skip for now';
    body = (
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
        <div style={{ fontSize: 26, fontWeight: 780, letterSpacing: -0.6, color: t.text }}>Set your two anchors</div>
        <div style={{ fontSize: 15, color: t.textSec, marginTop: 8, marginBottom: 24, lineHeight: 1.5 }}>
          Home and Work power your daily suggestions. You can add more places anytime.
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <PlaceField t={t} Icon={IconHome} label="Home" value="14 Maple Ave" tint={t.accent} />
          <PlaceField t={t} Icon={IconWork} label="Work" value="Northgate Studio, Tech Quarter" tint="#2D6CDF" />
        </div>
      </div>
    );
  }

  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', boxSizing: 'border-box',
      fontFamily: t.family, color: t.text, padding: `${topInset + 14}px 24px 26px` }}>
      <div style={{ paddingBottom: 14 }}>{dots}</div>
      {body}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 6, paddingTop: 16 }}>
        <PillButton t={t} onClick={next}>{primary}</PillButton>
        <PillButton t={t} kind="ghost" onClick={onFinish} style={{ background: 'transparent', color: t.textSec, height: 46, fontWeight: 600 }}>{ghost}</PillButton>
      </div>
    </div>
  );
}

Object.assign(window, { Onboarding });
