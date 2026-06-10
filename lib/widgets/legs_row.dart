import 'package:flutter/material.dart';
import '../data/models.dart';
import '../theme/app_theme.dart';
import 'line_badge.dart';
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
    final color  = leg.line != null ? lineColor(leg.line!) : null;
    final bg     = color ?? t.chipBg;
    final fg     = color != null ? Colors.white : t.textSec;
    final label  = isWalk ? '${leg.minutes}' : (leg.line ?? '');

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ModeIcon(mode: leg.mode, size: 14, color: fg, strokeWidth: 1.9),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12.5, fontWeight: color != null ? FontWeight.w700 : FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}
