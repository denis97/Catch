import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../theme/app_theme.dart';
import '../widgets/line_badge.dart';
import '../widgets/legs_row.dart';
import '../widgets/pill_button.dart';

class DetailScreen extends StatefulWidget {
  final AppTheme t;
  final Departure departure;

  const DetailScreen({super.key, required this.t, required this.departure});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late String _selLine;
  int _openIndex = 0;

  @override
  void initState() {
    super.initState();
    _selLine = widget.departure.line;
  }

  AppTheme get t => widget.t;
  Departure get d => widget.departure;

  @override
  Widget build(BuildContext context) {
    final top  = MediaQuery.of(context).padding.top;
    final series = buildSeries(d);

    return Scaffold(
      backgroundColor: t.pageBg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(top)),
          SliverToBoxAdapter(child: _buildAlts()),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _LeaveTimeCard(
                    t: t, row: series[i], d: d, line: _selLine,
                    expanded: _openIndex == i,
                    onToggle: () => setState(() => _openIndex = _openIndex == i ? -1 : i),
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

  Widget _buildHeader(double top) {
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
                Text(d.headsign, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: t.text, height: 1.1)),
                const SizedBox(height: 2),
                Text('${buildSeries(d).length} ways to leave · from ${d.from}',
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
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 2),
        itemCount: kDetailAlts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final a  = kDetailAlts[i];
          final on = _selLine == a.line;
          return GestureDetector(
            onTap: () => setState(() => _selLine = a.line),
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
                      Text(a.transfers == 0 ? 'Direct' : '${a.transfers} change',
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
  final LeaveSeries row;
  final Departure d;
  final String line;
  final bool expanded;
  final VoidCallback onToggle;

  const _LeaveTimeCard({
    required this.t, required this.row, required this.d,
    required this.line, required this.expanded, required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final urgColor = t.urgencyColor(row.leaveIn);
    final urgBg    = t.urgencyBg(row.leaveIn);
    final ride = d.duration - 2 * d.walk;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: row.rec ? t.accent : t.border),
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
                      if (row.rec) ...[
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
                          Text(row.leave, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: t.text,
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
                        child: Text(leaveLabel(row.leaveIn),
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: urgColor)),
                      ),
                    ),
                    const SizedBox(height: 9),
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(text: 'arrive ', style: TextStyle(fontSize: 12.5, color: t.textSec)),
                        TextSpan(text: row.arrive, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: t.text,
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
              _buildLegs(line, ride),
              const SizedBox(height: 4),
              PillButton(
                t: t, label: 'Remind me to leave', height: 46,
                icon: const Icon(Icons.notifications_none, size: 17, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegs(String selectedLine, int rideMin) {
    final lineMode = kLineColors.containsKey(selectedLine)
        ? _lineMode(selectedLine)
        : TransitMode.bus;
    final lineColor = kLineColors[selectedLine] ?? t.textTer;

    final steps = [
      _Step(TransitMode.walk, 'Walk ${d.walk} min to ${d.from}', null),
      _Step(lineMode, '$selectedLine · $rideMin min ride', selectedLine),
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
                                  color: steps[i].line == null ? t.textTer : lineColor,
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
                              color: steps[i].line == null ? t.textTer : lineColor,
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
                          color: steps[i].line == null ? t.textTer : lineColor,
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

  TransitMode _lineMode(String l) {
    const modes = {
      '14B': TransitMode.bus, '2': TransitMode.tram,
      'M3': TransitMode.metro, 'RX': TransitMode.train, 'F1': TransitMode.ferry,
    };
    return modes[l] ?? TransitMode.bus;
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
