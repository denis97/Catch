import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PillButton extends StatelessWidget {
  final AppTheme t;
  final String label;
  final VoidCallback? onTap;
  final bool ghost;
  final Widget? icon;
  final double height;

  const PillButton({
    super.key,
    required this.t,
    required this.label,
    this.onTap,
    this.ghost = false,
    this.icon,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final bg = ghost ? Colors.transparent : t.accent;
    final fg = ghost ? t.textSec : Colors.white;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 8)],
              Text(label, style: TextStyle(color: fg, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.1)),
            ],
          ),
        ),
      ),
    );
  }
}
