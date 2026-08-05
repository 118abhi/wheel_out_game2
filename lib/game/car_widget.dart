import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/car.dart';
import '../theme/app_theme.dart';

class CarWidget extends StatefulWidget {
  final CarModel car;
  final double cellSize;
  final double wheelRotation; // in radians
  final bool isDragging;
  final bool isSelected;

  const CarWidget({
    super.key,
    required this.car,
    required this.cellSize,
    this.wheelRotation = 0,
    this.isDragging = false,
    this.isSelected = false,
  });

  @override
  State<CarWidget> createState() => _CarWidgetState();
}

class _CarWidgetState extends State<CarWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;
    final cell = widget.cellSize;
    final width = car.isHorizontal ? cell * car.length : cell;
    final height = car.isHorizontal ? cell : cell * car.length;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        final targetBreath = car.isTarget && !widget.isDragging ? 1 + (_pulseAnim.value * 0.018) : 1.0;
        return Transform.scale(scale: targetBreath, child: child);
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cell * 0.24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(widget.isDragging ? 0.46 : 0.28),
              blurRadius: widget.isDragging ? 18 : 10,
              offset: Offset(0, widget.isDragging ? 9 : 5),
            ),
            if (widget.isSelected)
              BoxShadow(
                color: car.color.withOpacity(0.55),
                blurRadius: 16,
                spreadRadius: 1.4,
              ),
            if (car.isTarget)
              BoxShadow(
                color: AppTheme.targetRed.withOpacity(0.18),
                blurRadius: 18,
                spreadRadius: 1,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(cell * 0.24),
          child: CustomPaint(
            painter: RealCarPainter(
              car: car,
              wheelRotation: widget.wheelRotation,
              selected: widget.isSelected,
              dragging: widget.isDragging,
              pulse: _pulseAnim.value,
            ),
            size: Size(width, height),
          ),
        ),
      ),
    );
  }
}

class RealCarPainter extends CustomPainter {
  final CarModel car;
  final double wheelRotation;
  final bool selected;
  final bool dragging;
  final double pulse;

  RealCarPainter({
    required this.car,
    required this.wheelRotation,
    required this.selected,
    required this.dragging,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (car.isHorizontal) {
      _paintHorizontal(canvas, size);
    } else {
      canvas.save();
      canvas.translate(size.width / 2, size.height / 2);
      canvas.rotate(math.pi / 2);
      canvas.translate(-size.height / 2, -size.width / 2);
      _paintHorizontal(canvas, Size(size.height, size.width));
      canvas.restore();
    }
  }

  void _paintHorizontal(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = Rect.fromLTWH(w * 0.035, h * 0.125, w * 0.93, h * 0.75);
    final radius = h * 0.24;

    _paintUnderGlow(canvas, size, body);
    _paintWheels(canvas, size);
    _paintWheelArches(canvas, size);
    _paintBody(canvas, body, radius);
    _paintPanels(canvas, body);
    _paintCabinAndGlass(canvas, body);
    _paintLightsAndDetails(canvas, body);
    if (car.isTarget) _paintTargetDecal(canvas, body);
    if (selected) _paintSelectedOutline(canvas, body, radius);
  }

  void _paintUnderGlow(Canvas canvas, Size size, Rect body) {
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(dragging ? 0.35 : 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body.shift(Offset(0, size.height * 0.08)), Radius.circular(size.height * 0.22)),
      shadowPaint,
    );

    if (car.isTarget || selected) {
      final glow = Paint()
        ..color = (car.isTarget ? AppTheme.accent : car.color).withOpacity(0.10 + pulse * 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawRRect(RRect.fromRectAndRadius(body.inflate(size.height * 0.08), Radius.circular(size.height * 0.3)), glow);
    }
  }

  void _paintBody(Canvas canvas, Rect body, double radius) {
    final bodyPath = Path()
      ..moveTo(body.left + radius, body.top)
      ..lineTo(body.right - radius * 0.72, body.top)
      ..quadraticBezierTo(body.right, body.top + radius * 0.22, body.right, body.top + radius)
      ..lineTo(body.right, body.bottom - radius)
      ..quadraticBezierTo(body.right, body.bottom - radius * 0.22, body.right - radius * 0.72, body.bottom)
      ..lineTo(body.left + radius, body.bottom)
      ..quadraticBezierTo(body.left, body.bottom, body.left, body.bottom - radius)
      ..lineTo(body.left, body.top + radius)
      ..quadraticBezierTo(body.left, body.top, body.left + radius, body.top)
      ..close();

    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _lighten(car.color, 0.18),
          car.color,
          car.darkColor,
        ],
        stops: const [0.0, 0.48, 1.0],
      ).createShader(body);
    canvas.drawPath(bodyPath, basePaint);

    final sidePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black.withOpacity(0.18)],
      ).createShader(body);
    canvas.drawPath(bodyPath, sidePaint);

    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withOpacity(0.38), Colors.white.withOpacity(0.05), Colors.transparent],
        stops: const [0.0, 0.38, 1.0],
      ).createShader(body);
    canvas.drawPath(bodyPath, highlightPaint);

    final border = Paint()
      ..color = Colors.white.withOpacity(0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(bodyPath, border);
  }

  void _paintPanels(Canvas canvas, Rect body) {
    final panel = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    final soft = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    final hoodX = body.left + body.width * 0.72;
    final trunkX = body.left + body.width * 0.22;
    canvas.drawLine(Offset(hoodX, body.top + body.height * 0.12), Offset(hoodX, body.bottom - body.height * 0.12), panel);
    canvas.drawLine(Offset(trunkX, body.top + body.height * 0.14), Offset(trunkX, body.bottom - body.height * 0.14), panel);

    if (car.length > 2) {
      final mid = body.left + body.width * 0.49;
      canvas.drawLine(Offset(mid, body.top + body.height * 0.10), Offset(mid, body.bottom - body.height * 0.10), panel);
      canvas.drawLine(Offset(body.left + body.width * 0.36, body.center.dy), Offset(body.left + body.width * 0.63, body.center.dy), soft);
    }

    canvas.drawLine(Offset(body.left + body.width * 0.08, body.top + body.height * 0.22), Offset(body.right - body.width * 0.08, body.top + body.height * 0.22), soft);
  }

  void _paintCabinAndGlass(Canvas canvas, Rect body) {
    final cabin = Rect.fromLTWH(
      body.left + body.width * (car.length > 2 ? 0.33 : 0.35),
      body.top + body.height * 0.18,
      body.width * (car.length > 2 ? 0.31 : 0.34),
      body.height * 0.64,
    );
    final cabinRRect = RRect.fromRectAndRadius(cabin, Radius.circular(body.height * 0.16));

    final cabinFrame = Paint()
      ..shader = LinearGradient(
        colors: [Colors.black.withOpacity(0.72), Colors.black.withOpacity(0.42)],
      ).createShader(cabin);
    canvas.drawRRect(cabinRRect, cabinFrame);

    final glassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.lightBlueAccent.withOpacity(0.86),
          const Color(0xFF0D47A1).withOpacity(0.78),
          Colors.black.withOpacity(0.62),
        ],
      ).createShader(cabin.deflate(body.height * 0.06));
    canvas.drawRRect(
      RRect.fromRectAndRadius(cabin.deflate(body.height * 0.06), Radius.circular(body.height * 0.11)),
      glassPaint,
    );

    final shine = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withOpacity(0.45), Colors.transparent],
      ).createShader(cabin);
    final shinePath = Path()
      ..moveTo(cabin.left + cabin.width * 0.12, cabin.top + cabin.height * 0.12)
      ..lineTo(cabin.left + cabin.width * 0.48, cabin.top + cabin.height * 0.12)
      ..lineTo(cabin.left + cabin.width * 0.20, cabin.bottom - cabin.height * 0.12)
      ..lineTo(cabin.left + cabin.width * 0.02, cabin.bottom - cabin.height * 0.12)
      ..close();
    canvas.drawPath(shinePath, shine);

    final mirrorPaint = Paint()..color = car.darkColor.withOpacity(0.88);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cabin.right - body.width * 0.01, cabin.top - body.height * 0.08, body.width * 0.08, body.height * 0.12),
        Radius.circular(body.height * 0.04),
      ),
      mirrorPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cabin.right - body.width * 0.01, cabin.bottom - body.height * 0.04, body.width * 0.08, body.height * 0.12),
        Radius.circular(body.height * 0.04),
      ),
      mirrorPaint,
    );
  }

  void _paintLightsAndDetails(Canvas canvas, Rect body) {
    final headlight = Paint()
      ..color = Colors.white.withOpacity(0.96)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6);
    final headGlow = Paint()
      ..color = AppTheme.accent.withOpacity(0.16 + pulse * 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final tail = Paint()..color = (car.isTarget ? AppTheme.targetRed : Colors.redAccent).withOpacity(0.95);

    final topLamp = Rect.fromLTWH(body.right - body.width * 0.055, body.top + body.height * 0.18, body.width * 0.035, body.height * 0.18);
    final bottomLamp = Rect.fromLTWH(body.right - body.width * 0.055, body.bottom - body.height * 0.36, body.width * 0.035, body.height * 0.18);
    canvas.drawOval(topLamp.inflate(3), headGlow);
    canvas.drawOval(bottomLamp.inflate(3), headGlow);
    canvas.drawRRect(RRect.fromRectAndRadius(topLamp, Radius.circular(body.height * 0.04)), headlight);
    canvas.drawRRect(RRect.fromRectAndRadius(bottomLamp, Radius.circular(body.height * 0.04)), headlight);

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(body.left + body.width * 0.018, body.top + body.height * 0.18, body.width * 0.028, body.height * 0.18), Radius.circular(body.height * 0.035)),
      tail,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(body.left + body.width * 0.018, body.bottom - body.height * 0.36, body.width * 0.028, body.height * 0.18), Radius.circular(body.height * 0.035)),
      tail,
    );

    final grille = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..strokeWidth = 1.0;
    for (int i = 0; i < 3; i++) {
      final y = body.top + body.height * (0.40 + i * 0.08);
      canvas.drawLine(Offset(body.right - body.width * 0.06, y), Offset(body.right - body.width * 0.025, y), grille);
    }
  }

  void _paintWheels(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final wheel = h * 0.22;
    final positions = [
      Offset(w * 0.20, h * 0.22),
      Offset(w * 0.20, h * 0.78),
      Offset(w * 0.79, h * 0.22),
      Offset(w * 0.79, h * 0.78),
    ];
    for (final center in positions) {
      _drawWheel(canvas, center, wheel);
    }
  }

  void _paintWheelArches(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final archPaint = Paint()..color = Colors.black.withOpacity(0.22);
    final archW = h * 0.34;
    final archH = h * 0.20;
    for (final center in [Offset(w * 0.20, h * 0.22), Offset(w * 0.20, h * 0.78), Offset(w * 0.79, h * 0.22), Offset(w * 0.79, h * 0.78)]) {
      canvas.drawOval(Rect.fromCenter(center: center, width: archW, height: archH), archPaint);
    }
  }

  void _drawWheel(Canvas canvas, Offset center, double diameter) {
    final tire = Paint()..color = const Color(0xFF101820);
    final tireEdge = Paint()
      ..color = const Color(0xFF3A4652)
      ..style = PaintingStyle.stroke
      ..strokeWidth = diameter * 0.12;
    canvas.drawCircle(center, diameter / 2, tire);
    canvas.drawCircle(center, diameter / 2 - diameter * 0.06, tireEdge);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(wheelRotation);

    final rim = Paint()
      ..shader = const RadialGradient(colors: [Color(0xFFE8EEF5), Color(0xFF7F8FA6)]).createShader(Rect.fromCircle(center: Offset.zero, radius: diameter * 0.28));
    canvas.drawCircle(Offset.zero, diameter * 0.28, rim);

    final spoke = Paint()
      ..color = const Color(0xFF1E272E)
      ..strokeWidth = diameter * 0.075
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 5; i++) {
      final angle = (math.pi * 2 / 5) * i;
      canvas.drawLine(Offset.zero, Offset(math.cos(angle), math.sin(angle)) * diameter * 0.24, spoke);
    }
    canvas.drawCircle(Offset.zero, diameter * 0.08, Paint()..color = const Color(0xFF101820));
    canvas.restore();
  }

  void _paintTargetDecal(Canvas canvas, Rect body) {
    final badgeRect = Rect.fromCircle(
      center: Offset(body.left + body.width * 0.15, body.center.dy),
      radius: body.height * 0.17,
    );
    final badge = Paint()
      ..shader = const RadialGradient(colors: [AppTheme.accent, Color(0xFFFFA502)]).createShader(badgeRect);
    canvas.drawCircle(badgeRect.center, badgeRect.width / 2, badge);
    canvas.drawCircle(
      badgeRect.center,
      badgeRect.width / 2,
      Paint()
        ..color = Colors.white.withOpacity(0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final textPainter = TextPainter(
      text: const TextSpan(text: '★', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, badgeRect.center - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  void _paintSelectedOutline(Canvas canvas, Rect body, double radius) {
    final outline = Paint()
      ..color = AppTheme.accent.withOpacity(0.55 + pulse * 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawRRect(RRect.fromRectAndRadius(body.inflate(2), Radius.circular(radius)), outline);
  }

  Color _lighten(Color color, double amount) {
    return Color.lerp(color, Colors.white, amount) ?? color;
  }

  @override
  bool shouldRepaint(covariant RealCarPainter oldDelegate) {
    return oldDelegate.car != car ||
        oldDelegate.wheelRotation != wheelRotation ||
        oldDelegate.selected != selected ||
        oldDelegate.dragging != dragging ||
        oldDelegate.pulse != pulse;
  }
}
