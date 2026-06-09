// TransitApp.jsx — per-device screen router. Navigation is mirrored across both
// devices via shared state lifted to <App> in Catch.html.
// Contract: <TransitApp t platform screen setScreen dest setDest detail setDetail />

function TransitApp({ t, platform, screen, setScreen, dest, setDest, detail, setDetail }) {
  const openDetail = (d) => { setDetail(d); setScreen('detail'); };
  const goHome = () => setScreen('home');

  let content;
  if (screen === 'onboarding') {
    content = <Onboarding t={t} platform={platform} onFinish={goHome} />;
  } else if (screen === 'widget') {
    content = <WidgetHome t={t} platform={platform} />;
  } else if (screen === 'detail') {
    content = <LeaveTimes t={t} platform={platform} d={detail || HOME_DEPS[0]} onBack={goHome} />;
  } else if (screen === 'places') {
    content = <Places t={t} platform={platform} onBack={goHome} openDetail={openDetail} />;
  } else {
    content = <Home t={t} platform={platform} dest={dest} setDest={setDest} openDetail={openDetail} />;
  }

  return (
    <div style={{ minHeight: '100%', background: t.pageBg, color: t.text }}>
      {content}
    </div>
  );
}

Object.assign(window, { TransitApp });
