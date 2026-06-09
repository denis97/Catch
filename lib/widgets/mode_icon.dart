import 'package:flutter/material.dart';
import '../data/models.dart';

class ModeIcon extends StatelessWidget {
  final TransitMode mode;
  final double size;
  final Color? color;
  final double strokeWidth;

  const ModeIcon({
    super.key,
    required this.mode,
    this.size = 24,
    this.color,
    this.strokeWidth = 1.7,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? DefaultTextStyle.of(context).style.color ?? Colors.black;
    return CustomPaint(
      size: Size(size, size),
      painter: _ModePainter(mode: mode, color: c, strokeWidth: strokeWidth),
    );
  }
}

class _ModePainter extends CustomPainter {
  final TransitMode mode;
  final Color color;
  final double strokeWidth;
  _ModePainter({required this.mode, required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final s = size.width;
    final ratio = s / 24;

    void line(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(Offset(x1 * ratio, y1 * ratio), Offset(x2 * ratio, y2 * ratio), p);
    void rect(double x, double y, double w, double h, double r) {
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(x * ratio, y * ratio, w * ratio, h * ratio), Radius.circular(r * ratio)), p);
    }
    void circle(double cx, double cy, double r) =>
        canvas.drawCircle(Offset(cx * ratio, cy * ratio), r * ratio, p);
    void moveTo(double x, double y, Path path) => path.moveTo(x * ratio, y * ratio);
    void lineTo(double x, double y, Path path) => path.lineTo(x * ratio, y * ratio);

    switch (mode) {
      case TransitMode.bus:
        rect(4, 3.5, 16, 14, 3);
        line(4, 11, 20, 11);
        line(7.5, 14.5, 7.51, 14.5);
        line(16.5, 14.5, 16.51, 14.5);
        line(7, 17.5, 7, 19.5);
        line(17, 17.5, 17, 19.5);
      case TransitMode.train:
        rect(5, 3, 14, 13, 3);
        line(5, 10, 19, 10);
        line(8.5, 13, 8.51, 13);
        line(15.5, 13, 15.51, 13);
        line(7, 16, 5, 20);
        line(17, 16, 19, 20);
      case TransitMode.metro:
        final path = Path();
        moveTo(12, 3, path);
        path.cubicTo(8 * ratio, 3 * ratio, 5 * ratio, 3.8 * ratio, 5 * ratio, 7 * ratio);
        path.lineTo(5 * ratio, 13.5 * ratio);
        path.arcToPoint(Offset(8 * ratio, 16.5 * ratio),
            radius: Radius.circular(3 * ratio), clockwise: false);
        path.lineTo(16 * ratio, 16.5 * ratio);
        path.arcToPoint(Offset(19 * ratio, 13.5 * ratio),
            radius: Radius.circular(3 * ratio), clockwise: false);
        path.lineTo(19 * ratio, 7 * ratio);
        path.cubicTo(19 * ratio, 3.8 * ratio, 16 * ratio, 3 * ratio, 12 * ratio, 3 * ratio);
        path.close();
        canvas.drawPath(path, p);
        line(8.5, 11, 8.51, 11);
        line(15.5, 11, 15.51, 11);
        line(6.5, 20, 8.3, 17.5);
        line(17.5, 20, 15.7, 17.5);
      case TransitMode.tram:
        rect(6, 4, 12, 13, 2.5);
        line(9, 4, 7.5, 2);
        line(15, 4, 16.5, 2);
        line(6, 10, 18, 10);
        line(9.5, 13.5, 9.51, 13.5);
        line(14.5, 13.5, 14.51, 13.5);
        line(8, 17, 6.5, 20);
        line(16, 17, 17.5, 20);
      case TransitMode.ferry:
        final path = Path();
        moveTo(4, 14, path);
        path.lineTo(5.6 * ratio, 8.8 * ratio);
        path.arcToPoint(Offset(7.5 * ratio, 7.3 * ratio),
            radius: Radius.circular(2 * ratio), clockwise: false);
        path.lineTo(16.5 * ratio, 7.3 * ratio);
        path.arcToPoint(Offset(18.4 * ratio, 8.8 * ratio),
            radius: Radius.circular(2 * ratio), clockwise: false);
        lineTo(20, 14, path);
        canvas.drawPath(path, p);
        line(12, 4, 12, 7.3);
        line(3.5, 14, 3.5, 14);
        // wave lines simplified
        final wave = Path()
          ..moveTo(3.5 * ratio, 14 * ratio)
          ..cubicTo(5 * ratio, 14 * ratio, 5 * ratio, 15.5 * ratio, 6.5 * ratio, 15.5 * ratio)
          ..cubicTo(8 * ratio, 15.5 * ratio, 8 * ratio, 14 * ratio, 9.5 * ratio, 14 * ratio)
          ..cubicTo(11 * ratio, 14 * ratio, 11 * ratio, 15.5 * ratio, 12.5 * ratio, 15.5 * ratio)
          ..cubicTo(14 * ratio, 15.5 * ratio, 14 * ratio, 14 * ratio, 15.5 * ratio, 14 * ratio)
          ..cubicTo(17 * ratio, 14 * ratio, 17 * ratio, 15.5 * ratio, 18.5 * ratio, 15.5 * ratio)
          ..cubicTo(20 * ratio, 15.5 * ratio, 20 * ratio, 14 * ratio, 20.5 * ratio, 14 * ratio);
        canvas.drawPath(wave, p);
      case TransitMode.walk:
        circle(13, 4.5, 1.6);
        final body = Path()
          ..moveTo(11 * ratio, 21 * ratio)
          ..lineTo(12.5 * ratio, 16 * ratio)
          ..lineTo(10 * ratio, 14 * ratio)
          ..lineTo(11 * ratio, 9 * ratio)
          ..lineTo(14 * ratio, 11 * ratio)
          ..lineTo(16 * ratio, 12 * ratio);
        canvas.drawPath(body, p);
        line(10, 9, 8, 12);
        line(12.5, 16, 10.5, 21);
    }
  }

  @override
  bool shouldRepaint(_ModePainter old) =>
      old.mode != mode || old.color != color || old.strokeWidth != strokeWidth;
}
