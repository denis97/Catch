import 'package:flutter/material.dart';

class PulseDot extends StatefulWidget {
  final Color color;
  final bool animate;
  final double size;

  const PulseDot({super.key, required this.color, this.animate = true, this.size = 10});

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _scale = Tween<double>(begin: 0.8, end: 2.6).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.7, curve: Curves.easeOut)));
    _opacity = Tween<double>(begin: 0.55, end: 0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0, 1, curve: Curves.easeOut)));
    if (widget.animate) _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s, height: s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.animate)
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Transform.scale(
                scale: _scale.value,
                child: Container(
                  width: s, height: s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: _opacity.value * 0.35),
                  ),
                ),
              ),
            ),
          Container(
            width: s * 0.6, height: s * 0.6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
          ),
        ],
      ),
    );
  }
}
