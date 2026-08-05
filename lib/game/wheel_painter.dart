import 'dart:math' as math;
import 'package:flutter/material.dart';

class RewardWheelPainter extends CustomPainter {
  final double rotation;
  final List<WheelSegment> segments;

  RewardWheelPainter({required this.rotation, required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.95;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center + const Offset(0, 8), radius, shadowPaint);

    // segments
    double startAngle = -math.pi / 2 + rotation;
    double sweep = (2 * math.pi) / segments.length;

    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          colors: [seg.color, seg.color.withOpacity(0.8)],
        ).createShader(rect);

      canvas.drawArc(rect, startAngle, sweep, true, paint);

      // border
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawArc(rect, startAngle, sweep, true, borderPaint);

      // icon/text
      final midAngle = startAngle + sweep / 2;
      final textRadius = radius * 0.68;
      final textOffset = Offset(
        center.dx + math.cos(midAngle) * textRadius,
        center.dy + math.sin(midAngle) * textRadius,
      );

      canvas.save();
      canvas.translate(textOffset.dx, textOffset.dy);
      canvas.rotate(midAngle + math.pi / 2);

      final textPainter = TextPainter(
        text: TextSpan(
          text: seg.label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: radius * 0.12,
            shadows: [
              Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 4, offset: const Offset(1, 1)),
            ],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();

      startAngle += sweep;
    }

    // center hub
    final hubPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white, Colors.grey.shade300],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.22));
    canvas.drawCircle(center, radius * 0.22, hubPaint);

    final hubBorder = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius * 0.22, hubBorder);

    // center gem
    final gemPaint = Paint()..color = const Color(0xFFFFD700);
    canvas.drawCircle(center, radius * 0.08, gemPaint);

    // outer ring
    final outerRing = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..shader = SweepGradient(
        colors: [const Color(0xFFFFD700), const Color(0xFFFFA500), const Color(0xFFFFD700)],
      ).createShader(rect);
    canvas.drawCircle(center, radius, outerRing);

    // tick marks / lights
    final lightPaint = Paint()..color = Colors.white;
    for (int i = 0; i < segments.length * 2; i++) {
      double angle = rotation + (2 * math.pi / (segments.length * 2)) * i;
      final p = Offset(
        center.dx + math.cos(angle) * (radius + 4),
        center.dy + math.sin(angle) * (radius + 4),
      );
      canvas.drawCircle(p, 4, lightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RewardWheelPainter oldDelegate) => oldDelegate.rotation != rotation;
}

class WheelSegment {
  final String label;
  final Color color;
  final int value;
  WheelSegment({required this.label, required this.color, required this.value});
}

class SpinPointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF4757)
      ..style = PaintingStyle.fill;
    final shadow = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final pathShadow = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(pathShadow, shadow);

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);

    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
