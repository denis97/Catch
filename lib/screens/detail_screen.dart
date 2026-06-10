import 'dart:async';
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../theme/app_theme.dart';
import '../widgets/line_badge.dart';
import '../widgets/legs_row.dart';
import '../widgets/pill_button.dart';
import '../services/reminder_service.dart';
import '../services/transit_service.dart';

class DetailScreen extends StatefulWidget {
  final AppTheme t;
  final Departure departure;
  /// Alternative routes (other lines) shown as chips. Usually the
  /// home-screen departure list.
  final List<Departure> alts;
  // When set, later departures are fetched live instead of synthesized.
  final double? originLat;
  final double? originLng;
  final String? destination;

  const DetailScreen({
    super.key,
    required this.t,
    required this.departure,
    this.alts = const [],
    this.originLat,
    this.originLng,
    this.destination,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late String _selLine;
  int _openIndex = 0;
  Timer? _ticker;
  List<Departure>? _liveSeries; // all fetched upcoming departures (all lines)
  bool _fetchingSeries = false;

  bool get _isLive =>
      widget.originLat != null && widget.originLng != null && widget.destination != null;

  @override
  void initState() {
    super.initState();
    _selLine = widget.departure.line;
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
    if (_isLive) _fetchSeries();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _fetchSeries() async {
    setState(() => _fetchingSeries = true);
    try {
      final series = await TransitService().getDepartureSeries(
        originLat: widget.originLat!,
        originLng: widget.originLng!,
        destination: widget.destination!,
      );
      if (!mounted) return;
      setState(() { _liveSeries = series; _fetchingSeries = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _fetchingSeries = false); // falls back to synthetic
    }
  }

  AppTheme get t => widget.t;
  Departure get d => widget.departure;

  /// Unique lines for the chips row, derived from the alternatives.
  List<Departure> get _chipAlts {
    final seen = <String>{};
    final out = <Departure>[];
    for (final a in [d, ...widget.alts, ...?_liveSeries]) {
      if (seen.add(a.line)) out.add(a);
    }
    return out;
  }

  /// The departure the series is anchored on (first of the selected line).
  Departure get _base =>
      _chipAlts.firstWhere((a) => a.line == _selLine, orElse: () => d);

  /// Upcoming departures of the selected line: live where available,
  /// padded with synthesized ones to always show a useful list.
  List<Departure> get _series {
    final live = (_liveSeries ?? [])
        .where((x) => x.line == _selLine && x.leaveIn > -5)
        .toList();
    if (live.isEmpty) return buildSeries(_base);
    if (live.length >= 4) return live;
    final last = live.last;
    return [
      ...live,
      for (int i = 1; i <= 4 - live.length; i++) shiftDeparture(last, i * last.every),
    ];
  }

  Future<void> _remind(Departure dep) async {
    final ok = await ReminderService.instance.scheduleLeaveReminder(dep);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? "Reminder set — we'll ping you 2 min before it's time to leave"
          : 'Too late to remind — time to go!'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final series = _series;

    return Scaffold(
      backgroundColor: t.pageBg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(top, series.length)),
          SliverToBoxAdapter(child: _buildAlts()),
          if (_fetchingSeries)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Center(
                  child: SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: t.accent)),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _LeaveTimeCard(
                    t: t, d: series[i], rec: i == 0,
                    expanded: _openIndex == i,
                    onToggle: () => setState(() => _openIndex = _openIndex == i ? -1 : i),
                    onRemind: () => _remind(series[i]),
                  ),
                ),
                childCount: series.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double top, int count) {
    return Container(
      color: t.pageBg,
      padding: EdgeInsets.fromLTRB(12, top + 6, 16, 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: t.accent, size: 28),
            onPressed: () => Navigator.pop(context),
            padding: const EdgeInsets.only(right: 4),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_base.headsign, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: t.text, height: 1.1)),
                const SizedBox(height: 2),
                Text('$count ways to leave · from ${_base.from}',
                    style: TextStyle(fontSize: 12.5, color: t.textSec)),
              ],
            ),
          ),
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: t.card, shape: BoxShape.circle, boxShadow: t.shadow),
            child: Icon(Icons.swap_horiz, size: 18, color: t.textSec),
          ),
        ],
      ),
    );
  }

  Widget _buildAlts() {
    final alts = _chipAlts;
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 2),
        itemCount: alts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final a  = alts[i];
          final on = _selLine == a.line;
          return GestureDetector(
            onTap: () => setState(() { _selLine = a.line; _openIndex = 0; }),
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              decoration: BoxDecoration(
                color: t.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: on ? t.accent : t.border, width: on ? 1.5 : 1),
                boxShadow: on ? null : t.shadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LineBadge(line: a.line, t: t, size: 26),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${a.duration} min', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: t.text, height: 1.1)),
                      Text(a.transfers == 0 ? 'Direct' : '${a.transfers} change${a.transfers > 1 ? 's' : ''}',
                          style: TextStyle(fontSize: 11, color: t.textSec)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LeaveTimeCard extends StatelessWidget {
  final AppTheme t;
  final Departure d;
  final bool rec;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onRemind;

  const _LeaveTimeCard({
    required this.t, required this.d, required this.rec,
    required this.expanded, required this.onToggle, required this.onRemind,
  });

  @override
  Widget build(BuildContext context) {
    final urgColor = t.urgencyColor(d.leaveIn);
    final urgBg    = t.urgencyBg(d.leaveIn);
    final ride = d.duration - 2 * d.walk;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: rec ? t.accent : t.border),
          boxShadow: t.shadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (rec) ...[
                        Container(
                          height: 20,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(color: t.accentSoft, borderRadius: BorderRadius.circular(6)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 12, color: t.accent),
                              const SizedBox(width: 4),
                              Text('BEST NOW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: t.accent, letterSpacing: 0.3)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('Leave', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.textTer, letterSpacing: 0.6)),
                          const SizedBox(width: 8),
                          Text(fmtClock(d.departMin - d.walk), style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: t.text,
                              fontFeatures: const [FontFeature.tabularFigures()])),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LegsRow(legs: d.legs, t: t, compact: true),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      height: 24, padding: const EdgeInsets.symmetric(horizontal: 9),
                      decoration: BoxDecoration(color: urgBg, borderRadius: BorderRadius.circular(7)),
                      child: Center(
                        child: Text(leaveLabel(d.leaveIn),
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: urgColor)),
                      ),
                    ),
                    const SizedBox(height: 9),
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(text: 'arrive ', style: TextStyle(fontSize: 12.5, color: t.textSec)),
                        TextSpan(text: d.arrive, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: t.text,
                            fontFeatures: const [FontFeature.tabularFigures()])),
                      ]),
                    ),
                    const SizedBox(height: 2),
                    Text('${d.duration} min trip', style: TextStyle(fontSize: 12, color: t.textTer,
                        fontFeatures: const [FontFeature.tabularFigures()])),
                  ],
                ),
              ],
            ),
            if (expanded) ...[
              const SizedBox(height: 14),
              Divider(color: t.separator, height: 1),
              const SizedBox(height: 14),
              _buildLegs(d.line, ride),
              const SizedBox(height: 4),
              PillButton(
                t: t, label: 'Remind me to leave', height: 46,
                icon: const Icon(Icons.notifications_none, size: 17, color: Colors.white),
                onTap: onRemind,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegs(String selectedLine, int rideMin) {
    final legColor = lineColor(selectedLine);

    final steps = [
      _Step(TransitMode.walk, 'Walk ${d.walk} min to ${d.from}', null),
      _Step(d.mode, '$selectedLine · $rideMin min ride', selectedLine),
      _Step(TransitMode.walk, 'Walk ${d.walk} min to ${d.headsign}', null),
    ];

    return Column(
      children: [
        for (int i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 22,
                  child: Stack(
                    children: [
                      if (i < steps.length - 1)
                        Positioned(
                          left: 10, top: 4, bottom: 0,
                          child: Container(
                            width: 2,
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: steps[i].line == null ? t.textTer : legColor,
                                  width: 2,
                                  style: steps[i].line == null ? BorderStyle.none : BorderStyle.solid,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (i < steps.length - 1 && steps[i].line == null)
                        Positioned(
                          left: 10, top: 4, bottom: 0,
                          child: LayoutBuilder(builder: (_, c) {
                            return Column(
                              children: List.generate(
                                (c.maxHeight / 8).ceil(),
                                (_) => Container(width: 2, height: 4, margin: const EdgeInsets.only(bottom: 4), color: t.textTer),
                              ),
                            );
                          }),
                        ),
                      Positioned(
                        left: 6, top: 4,
                        child: Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: t.card,
                            border: Border.all(
                              color: steps[i].line == null ? t.textTer : legColor,
                              width: 2.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        // small mode icon
                        Icon(
                          _modeIconData(steps[i].mode),
                          size: 16,
                          color: steps[i].line == null ? t.textTer : legColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          steps[i].label,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: steps[i].line == null ? FontWeight.w500 : FontWeight.w700,
                            color: steps[i].line == null ? t.textSec : t.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  IconData _modeIconData(TransitMode m) {
    switch (m) {
      case TransitMode.walk:  return Icons.directions_walk;
      case TransitMode.bus:   return Icons.directions_bus;
      case TransitMode.train: return Icons.train;
      case TransitMode.metro: return Icons.subway;
      case TransitMode.tram:  return Icons.tram;
      case TransitMode.ferry: return Icons.directions_boat;
    }
  }
}

class _Step {
  final TransitMode mode;
  final String label;
  final String? line;
  const _Step(this.mode, this.label, this.line);
}
