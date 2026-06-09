import 'package:flutter/material.dart';
import '../data/models.dart';
import '../theme/app_theme.dart';
import 'mode_icon.dart';

class LineBadge extends StatelessWidget {
  final String line;
  final AppTheme t;
  final double size;

  const LineBadge({super.key, required this.line, required this.t, this.size = 28});

  @override
  Widget build(BuildContext context) {
    final color = kLineColors[line] ?? t.textSec;
    final mode  = _lineMode(line);
    final fs    = size <= 24 ? 12.0 : 13.5;
    final iconSz = size <= 24 ? 15.0 : 17.0;

    return Container(
      height: size,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(9)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ModeIcon(mode: mode, size: iconSz, color: Colors.white, strokeWidth: 1.9),
          const SizedBox(width: 5),
          Text(line, style: TextStyle(fontSize: fs, fontWeight: FontWeight.w700,
              color: Colors.white, letterSpacing: 0.2, height: 1)),
        ],
      ),
    );
  }

  TransitMode _lineMode(String l) {
    const modes = {
      '14B': TransitMode.bus, '2': TransitMode.tram,
      'M3': TransitMode.metro, 'RX': TransitMode.train, 'F1': TransitMode.ferry,
    };
    return modes[l] ?? TransitMode.bus;
  }
}
