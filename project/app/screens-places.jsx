// screens-places.jsx — saved places: Home / Work anchors + favorites.
// Contract: <Places t platform onBack openDetail />

function PlaceRow({ t, place, onClick, isLast }) {
  const meta = {
    home: { Icon: IconHome, tint: t.accent },
    work: { Icon: IconWork, tint: '#2D6CDF' },
    star: { Icon: IconStar, tint: t.textSec },
  }[place.kind];
  const { Icon, tint } = meta;
  return (
    <div onClick={onClick} style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '13px 16px',
      cursor: 'pointer', borderBottom: isLast ? 'none' : `1px solid ${t.separator}` }}>
      <IconTile t={t} size={42} radius={13} bg={place.kind === 'star' ? t.chipBg : tint}
        color={place.kind === 'star' ? t.textSec : '#fff'}><Icon size={21} /></IconTile>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 16, fontWeight: 680, color: t.text }}>{place.name}</div>
        <div style={{ fontSize: 13, color: t.textSec, marginTop: 1, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{place.address}</div>
      </div>
      <div style={{ textAlign: 'right', flexShrink: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 4, color: t.textTer, fontSize: 12, justifyContent: 'flex-end' }}>
          <IconWalk size={13} />{place.walk} min
        </div>
        <div style={{ fontSize: 12, color: t.textTer, marginTop: 2 }}>{place.stop}</div>
      </div>
      <IconChevronR size={17} style={{ color: t.textTer, flexShrink: 0 }} />
    </div>
  );
}

function Places({ t, platform, onBack, openDetail }) {
  const dz = densityTokens(t._density);
  const anchors = PLACES.filter((p) => p.kind === 'home' || p.kind === 'work');
  const favs = PLACES.filter((p) => p.kind === 'star');
  const go = (p) => openDetail(p.kind === 'work' ? WORK_DEPS[0] : HOME_DEPS[0]);
  return (
    <div style={{ fontFamily: t.family, paddingBottom: 28 }}>
      <BackBar t={t} platform={platform} title="Places" sub="Home & Work power your suggestions" onBack={onBack}
        trailing={<IconTile t={t} size={38} radius={19} bg={t.accentSoft} color={t.accent}><IconPlus size={20} /></IconTile>} />
      <div style={{ padding: `0 ${dz.cardPad}px` }}>
        <SectionLabel t={t}>Anchors</SectionLabel>
        <Card t={t} style={{ padding: '2px 0', marginBottom: dz.sectionGap }}>
          {anchors.map((p, i) => (
            <PlaceRow key={p.id} t={t} place={p} onClick={() => go(p)} isLast={i === anchors.length - 1} />
          ))}
        </Card>
        <SectionLabel t={t}>Favorites</SectionLabel>
        <Card t={t} style={{ padding: '2px 0' }}>
          {favs.map((p, i) => (
            <PlaceRow key={p.id} t={t} place={p} onClick={() => go(p)} isLast={i === favs.length - 1} />
          ))}
        </Card>
        <button onClick={onBack} style={{
          appearance: 'none', cursor: 'pointer', width: '100%', marginTop: dz.sectionGap,
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, height: 50,
          borderRadius: 16, border: `1.5px dashed ${t.border}`, background: 'transparent',
          color: t.textSec, fontFamily: t.family, fontSize: 15, fontWeight: 600,
        }}>
          <IconPlus size={18} />Add a place
        </button>
      </div>
    </div>
  );
}

Object.assign(window, { Places, PlaceRow });
