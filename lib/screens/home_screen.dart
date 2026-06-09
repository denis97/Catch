import 'dart:async';
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../theme/app_theme.dart';
import '../widgets/line_badge.dart';
import '../widgets/legs_row.dart';
import '../widgets/pulse_dot.dart';
import 'detail_screen.dart';
import 'places_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppTheme t;
  final VoidCallback? onToggleTheme;
  const HomeScreen({super.key, required this.t, this.onToggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _goingHome = true;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Refresh every minute so countdowns stay live
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  AppTheme get t => widget.t;
  List<Departure> get deps => _goingHome ? kHomeDeps : kWorkDeps;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: t.pageBg,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(18, top + 18, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ContextHeader(t: t, goingHome: _goingHome, onPlaces: () {
              Navigator.push(context, MaterialPageRoute(
              builder: (_) => PlacesScreen(t: t, onToggleTheme: widget.onToggleTheme)));
            }),
            const SizedBox(height: 14),
            _DestSwitch(t: t, goingHome: _goingHome, onToggle: (v) => setState(() => _goingHome = v)),
            const SizedBox(height: 20),
            _DepartureHero(t: t, d: deps.first, onTap: () => _openDetail(deps.first)),
            const SizedBox(height: 22),
            _SectionLabel(t: t, label: 'If you miss it'),
            _FallbackCard(t: t, deps: deps.skip(1).toList(), onTap: _openDetail),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh, size: 13, color: t.textTer),
                const SizedBox(width: 5),
                Text('Live · updated just now', style: TextStyle(fontSize: 12.5, color: t.textTer)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(Departure d) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(t: t, departure: d)));
  }
}

// ─── Context header ────────────────────────────────────────────

class _ContextHeader extends StatelessWidget {
  final AppTheme t;
  final bool goingHome;
  final VoidCallback onPlaces;
  const _ContextHeader({required this.t, required this.goingHome, required this.onPlaces});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                goingHome ? 'Heading home' : 'Heading to work',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: t.text, letterSpacing: -0.6, height: 1.05),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Container(
                    height: 22, padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(color: t.accentSoft, borderRadius: BorderRadius.circular(7)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.my_location, size: 12, color: t.accent),
                        const SizedBox(width: 4),
                        Text('AUTO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.accent, letterSpacing: 0.3)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "You're at ${goingHome ? 'Work' : 'Home'} · $nowLabel",
                    style: TextStyle(fontSize: 13.5, color: t.textSec, fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ],
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onPlaces,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: t.chipBg, shape: BoxShape.circle),
            child: Icon(Icons.settings_outlined, size: 20, color: t.textSec),
          ),
        ),
      ],
    );
  }
}

// ─── Destination toggle ────────────────────────────────────────

class _DestSwitch extends StatelessWidget {
  final AppTheme t;
  final bool goingHome;
  final ValueChanged<bool> onToggle;
  const _DestSwitch({required this.t, required this.goingHome, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: t.chipBg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          _tab('Home', Icons.home_outlined, true),
          _tab('Work', Icons.work_outline, false),
        ],
      ),
    );
  }

  Widget _tab(String label, IconData icon, bool isHome) {
    final on = goingHome == isHome;
    return Expanded(
      child: GestureDetector(
        onTap: () => onToggle(isHome),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 38,
          decoration: BoxDecoration(
            color: on ? t.tabActiveBg : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: on ? [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 3, offset: const Offset(0, 1))] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: on ? t.accent : t.textTer),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: on ? t.text : t.textSec)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hero departure card ───────────────────────────────────────

class _DepartureHero extends StatelessWidget {
  final AppTheme t;
  final Departure d;
  final VoidCallback onTap;
  const _DepartureHero({required this.t, required this.d, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final urgColor = t.urgencyColor(d.leaveIn);
    final urgBg    = t.urgencyBg(d.leaveIn);
    final animate  = d.leaveIn > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: t.border),
          boxShadow: t.shadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // urgency band
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: BoxDecoration(
                color: urgBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radius)),
              ),
              child: Row(
                children: [
                  PulseDot(color: urgColor, animate: animate),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      leaveLabel(d.leaveIn),
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: urgColor, letterSpacing: -0.3),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    icon: Icon(Icons.notifications_none, size: 16, color: t.textSec),
                    label: Text('Remind me', style: TextStyle(fontSize: 13, color: t.textSec, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            // body
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 15, 18, 17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      LineBadge(line: d.line, t: t, size: 30),
                      const SizedBox(width: 10),
                      Text(d.headsign, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: t.text, letterSpacing: -0.2)),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Icon(Icons.directions_walk, size: 15, color: t.textTer),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text('Board at ${d.from} · ${d.walk} min walk',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13.5, color: t.textSec)),
                      ),
                    ],
                  ),
                  Divider(color: t.separator, height: 28),
                  Row(
                    children: [
                      Text('${d.depart} → ${d.arrive}',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: t.text,
                              fontFeatures: const [FontFeature.tabularFigures()])),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('· ${d.duration} min · every ${d.every} min',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13.5, color: t.textSec,
                                fontFeatures: const [FontFeature.tabularFigures()])),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  LegsRow(legs: d.legs, t: t),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── "If you miss it" fallback card ───────────────────────────

class _FallbackCard extends StatelessWidget {
  final AppTheme t;
  final List<Departure> deps;
  final ValueChanged<Departure> onTap;
  const _FallbackCard({required this.t, required this.deps, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: t.border),
        boxShadow: t.shadow,
      ),
      child: Column(
        children: [
          for (int i = 0; i < deps.length; i++)
            _DepartureRow(t: t, d: deps[i], isLast: i == deps.length - 1, onTap: () => onTap(deps[i])),
        ],
      ),
    );
  }
}

class _DepartureRow extends StatelessWidget {
  final AppTheme t;
  final Departure d;
  final bool isLast;
  final VoidCallback onTap;
  const _DepartureRow({required this.t, required this.d, required this.isLast, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final urgColor = t.urgencyColor(d.leaveIn);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // time column
            SizedBox(
              width: 46,
              child: Padding(
                padding: const EdgeInsets.only(top: 13, right: 8),
                child: Text(d.depart, textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: t.text,
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ),
            ),
            // rail column
            SizedBox(
              width: 22,
              child: Stack(
                children: [
                  Positioned(
                    left: 10, top: 0,
                    bottom: isLast ? null : 0,
                    height: isLast ? null : null,
                    child: Container(
                      width: 2,
                      height: isLast ? 24 : null,
                      color: t.separator,
                    ),
                  ),
                  if (isLast)
                    Positioned(left: 10, top: 24, bottom: 0, child: Container(width: 2, color: t.separator.withValues(alpha: 0))),
                  Positioned(
                    left: 6, top: 18,
                    child: Container(
                      width: 11, height: 11,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: t.card,
                        border: Border.all(color: urgColor, width: 2.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // content column
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 12, 0, 12),
                decoration: BoxDecoration(
                  border: isLast ? null : Border(bottom: BorderSide(color: t.separator)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        LineBadge(line: d.line, t: t, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(d.headsign,
                              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: t.text)),
                        ),
                        Text('arr ${d.arrive}',
                            style: TextStyle(fontSize: 13, color: t.textSec,
                                fontFeatures: const [FontFeature.tabularFigures()])),
                      ],
                    ),
                    const SizedBox(height: 5),
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(text: leaveLabel(d.leaveIn),
                            style: TextStyle(fontSize: 12.5, color: urgColor, fontWeight: FontWeight.w600)),
                        TextSpan(text: ' · every ${d.every} min · ${d.duration} min',
                            style: TextStyle(fontSize: 12.5, color: t.textTer, fontWeight: FontWeight.w500)),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final AppTheme t;
  final String label;
  const _SectionLabel({required this.t, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label.toUpperCase(),
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: t.textTer)),
    );
  }
}
