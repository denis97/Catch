import 'package:flutter/material.dart';
import '../data/models.dart';
import '../theme/app_theme.dart';
import 'mode_icon.dart';

class LegsRow extends StatelessWidget {
  final List<Leg> legs;
  final AppTheme t;
  final bool compact;

  const LegsRow({super.key, required this.legs, required this.t, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (int i = 0; i < legs.length; i++) {
      if (i > 0) {
        items.add(Icon(Icons.chevron_right, size: 13, color: t.textTer));
      }
      items.add(_pill(legs[i]));
    }
    return Wrap(spacing: 5, runSpacing: 5, crossAxisAlignment: WrapCrossAlignment.center, children: items);
  }

  Widget _pill(Leg leg) {
    final isWalk = leg.mode == TransitMode.walk;
    final lineColor = leg.line != null ? (kLineColors[leg.line!]) : null;
    final bg    = lineColor ?? t.chipBg;
    final fg    = lineColor != null ? Colors.white : t.textSec;
    final label = isWalk ? '${leg.minutes}' : (compact ? (leg.line ?? '') : (leg.line ?? ''));

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ModeIcon(mode: leg.mode, size: 14, color: fg, strokeWidth: 1.9),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12.5, fontWeight: lineColor != null ? FontWeight.w700 : FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}
