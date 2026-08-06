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
    _paintDoorHandlesAndTrim(canvas, body);
    _paintCabinAndGlass(canvas, body);
    _paintVehicleSpecificDetails(canvas, body);
    _paintLightsAndDetails(canvas, body);
    _paintLicensePlates(canvas, body);
    if (car.isTarget) _paintTargetDecal(canvas, body);
    if (selected) _paintSelectedOutline(canvas, body, radius);
  }

  void _paintUnderGlow(Canvas canvas, Size size, Rect body) {
    // Soft shadow under car
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(dragging ? 0.42 : 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body.shift(Offset(0, size.height * 0.10)), Radius.circular(size.height * 0.24)),
      shadowPaint,
    );

    // Ground reflection
    final groundRef = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.black.withOpacity(0.12), Colors.transparent],
      ).createShader(Rect.fromLTWH(body.left, body.bottom + size.height * 0.02, body.width, size.height * 0.25));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(body.left, body.bottom + size.height * 0.02, body.width, size.height * 0.18), Radius.circular(size.height * 0.18)),
      groundRef,
    );

    if (car.isTarget || selected) {
      final glow = Paint()
        ..color = (car.isTarget ? AppTheme.accent : car.color).withOpacity(0.14 + pulse * 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
      canvas.drawRRect(RRect.fromRectAndRadius(body.inflate(size.height * 0.10), Radius.circular(size.height * 0.32)), glow);
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

    // Enhanced metallic paint with multiple layers
    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _lighten(car.color, 0.32),
          _lighten(car.color, 0.12),
          car.color,
          car.darkColor,
          _darken(car.color, 0.22),
        ],
        stops: const [0.0, 0.18, 0.42, 0.68, 1.0],
      ).createShader(body);
    canvas.drawPath(bodyPath, basePaint);

    // Metallic specular highlights
    final metalSpec = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.45),
          Colors.white.withOpacity(0.08),
          Colors.transparent,
          car.color.withOpacity(0.12),
        ],
        stops: const [0.0, 0.22, 0.55, 1.0],
      ).createShader(body);
    canvas.drawPath(bodyPath, metalSpec);

    final sidePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black.withOpacity(0.26)],
      ).createShader(body);
    canvas.drawPath(bodyPath, sidePaint);

    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withOpacity(0.42), Colors.white.withOpacity(0.09), Colors.transparent],
        stops: const [0.0, 0.34, 1.0],
      ).createShader(body);
    canvas.drawPath(bodyPath, highlightPaint);

    // Additional chrome edge
    final chromeEdge = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withOpacity(0.55), Colors.transparent],
      ).createShader(Rect.fromLTWH(body.left, body.top, body.width, body.height * 0.32));
    canvas.drawPath(bodyPath, chromeEdge);

    final border = Paint()
      ..color = Colors.white.withOpacity(0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(bodyPath, border);
  }

  Color _darken(Color color, double amount) {
    return Color.lerp(color, Colors.black, amount) ?? color;
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


  void _paintDoorHandlesAndTrim(Canvas canvas, Rect body) {
    final handlePaint = Paint()
      ..color = Colors.white.withOpacity(0.30)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final darkTrim = Paint()
      ..color = Colors.black.withOpacity(0.22)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final handleXs = car.length > 2
        ? [body.left + body.width * 0.38, body.left + body.width * 0.58]
        : [body.left + body.width * 0.50];
    for (final x in handleXs) {
      canvas.drawLine(Offset(x, body.top + body.height * 0.30), Offset(x + body.width * 0.04, body.top + body.height * 0.30), handlePaint);
      canvas.drawLine(Offset(x, body.bottom - body.height * 0.30), Offset(x + body.width * 0.04, body.bottom - body.height * 0.30), handlePaint);
    }

    canvas.drawLine(Offset(body.left + body.width * 0.05, body.center.dy), Offset(body.right - body.width * 0.05, body.center.dy), darkTrim);
    canvas.drawLine(Offset(body.left + body.width * 0.10, body.bottom - body.height * 0.15), Offset(body.right - body.width * 0.10, body.bottom - body.height * 0.15), darkTrim);
  }

  void _paintVehicleSpecificDetails(Canvas canvas, Rect body) {
    final type = car.carType;

    switch (type) {
      case CarType.suv:
        _paintSuvDetails(canvas, body);
        break;
      case CarType.truck:
        _paintVanOrTruckDetails(canvas, body, 2);
        break;
      case CarType.police:
        _paintPoliceDetails(canvas, body);
        break;
      case CarType.sports:
        _paintSportDetails(canvas, body);
        break;
      case CarType.taxi:
        _paintTaxiDetails(canvas, body);
        break;
      case CarType.sedan:
      default:
        _paintHatchbackDetails(canvas, body);
        break;
    }
  }

  void _paintVanOrTruckDetails(Canvas canvas, Rect body, int seed) {
    final railPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final cargoPaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    final cargo = Rect.fromLTWH(body.left + body.width * 0.17, body.top + body.height * 0.18, body.width * 0.20, body.height * 0.64);
    canvas.drawRRect(RRect.fromRectAndRadius(cargo, Radius.circular(body.height * 0.10)), cargoPaint);

    for (int i = 0; i < 3; i++) {
      final x = body.left + body.width * (0.25 + i * 0.16);
      canvas.drawLine(Offset(x, body.top + body.height * 0.18), Offset(x + body.width * 0.08, body.bottom - body.height * 0.18), railPaint);
    }

    if (seed.isEven) {
      final beacon = Paint()
        ..color = AppTheme.accent.withOpacity(0.92)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawCircle(Offset(body.left + body.width * 0.67, body.top + body.height * 0.18), body.height * 0.055, beacon);
    }
  }

  void _paintSportDetails(Canvas canvas, Rect body) {
    final stripe = Paint()
      ..shader = LinearGradient(colors: [Colors.white.withOpacity(0.40), Colors.white.withOpacity(0.05)]).createShader(body)
      ..strokeWidth = body.height * 0.055
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(body.left + body.width * 0.18, body.center.dy), Offset(body.right - body.width * 0.22, body.center.dy), stripe);

    final spoiler = Paint()..color = Colors.black.withOpacity(0.34);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(body.left + body.width * 0.045, body.top + body.height * 0.22, body.width * 0.035, body.height * 0.56), Radius.circular(body.height * 0.04)),
      spoiler,
    );
  }

  void _paintSuvDetails(Canvas canvas, Rect body) {
    final rail = Paint()
      ..color = Colors.black.withOpacity(0.32)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(body.left + body.width * 0.34, body.top + body.height * 0.14), Offset(body.left + body.width * 0.64, body.top + body.height * 0.14), rail);
    canvas.drawLine(Offset(body.left + body.width * 0.34, body.bottom - body.height * 0.14), Offset(body.left + body.width * 0.64, body.bottom - body.height * 0.14), rail);

    final step = Paint()..color = Colors.black.withOpacity(0.25);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(body.left + body.width * 0.28, body.bottom - body.height * 0.06, body.width * 0.42, body.height * 0.035), Radius.circular(4)), step);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(body.left + body.width * 0.28, body.top + body.height * 0.025, body.width * 0.42, body.height * 0.035), Radius.circular(4)), step);
  }

  void _paintHatchbackDetails(Canvas canvas, Rect body) {
    final roofPaint = Paint()..color = Colors.white.withOpacity(0.08);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(body.left + body.width * 0.38, body.top + body.height * 0.24, body.width * 0.18, body.height * 0.52), Radius.circular(body.height * 0.10)),
      roofPaint,
    );
    final rearGlass = Paint()
      ..shader = LinearGradient(colors: [Colors.lightBlueAccent.withOpacity(0.30), Colors.black.withOpacity(0.24)]).createShader(body);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(body.left + body.width * 0.21, body.top + body.height * 0.27, body.width * 0.08, body.height * 0.46), Radius.circular(body.height * 0.05)),
      rearGlass,
    );
  }

  // === NEW CAR VARIATIONS ===

  void _paintSuvDetails(Canvas canvas, Rect body) {
    // Roof rails
    final rail = Paint()
      ..color = Colors.black.withOpacity(0.38)
      ..strokeWidth = 1.8;
    canvas.drawLine(Offset(body.left + body.width * 0.32, body.top + body.height * 0.12), Offset(body.left + body.width * 0.68, body.top + body.height * 0.12), rail);
    canvas.drawLine(Offset(body.left + body.width * 0.32, body.bottom - body.height * 0.12), Offset(body.left + body.width * 0.68, body.bottom - body.height * 0.12), rail);

    // Side steps
    final step = Paint()..color = Colors.black.withOpacity(0.28);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(body.left + body.width * 0.26, body.bottom - body.height * 0.05, body.width * 0.48, body.height * 0.04), Radius.circular(2)), step);

    // SUV roof line
    final roof = Paint()..color = Colors.white.withOpacity(0.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(body.left + body.width * 0.34, body.top + body.height * 0.16, body.width * 0.32, body.height * 0.34), Radius.circular(body.height * 0.08)),
      roof,
    );
  }

  void _paintPoliceDetails(Canvas canvas, Rect body) {
    // Police light bar
    final lightbar = Paint()..color = Colors.blueAccent.withOpacity(0.9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(body.left + body.width * 0.26, body.top + body.height * 0.08, body.width * 0.48, body.height * 0.12), Radius.circular(2)),
      lightbar,
    );

    // Red + Blue flashing effect
    final red = Paint()..color = Colors.redAccent.withOpacity(0.85);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(body.left + body.width * 0.28, body.top + body.height * 0.10, body.width * 0.18, body.height * 0.08), Radius.circular(1)), red);

    final blue = Paint()..color = Colors.blue.withOpacity(0.85);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(body.left + body.width * 0.54, body.top + body.height * 0.10, body.width * 0.18, body.height * 0.08), Radius.circular(1)), blue);

    // "POLICE" text hint
    final textPainter = TextPainter(
      text: const TextSpan(text: 'POLICE', style: TextStyle(color: Colors.white, fontSize: 5.5, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(body.left + body.width * 0.35, body.top + body.height * 0.26));
  }

  void _paintTaxiDetails(Canvas canvas, Rect body) {
    // Taxi roof sign
    final sign = Paint()..color = Colors.yellowAccent.withOpacity(0.95);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(body.left + body.width * 0.38, body.top + body.height * 0.08, body.width * 0.24, body.height * 0.14), Radius.circular(2)),
      sign,
    );

    // "TAXI" text
    final tp = TextPainter(
      text: const TextSpan(text: 'TAXI', style: TextStyle(color: Colors.black, fontSize: 5.2, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(body.left + body.width * 0.395, body.top + body.height * 0.11));

    // Yellow stripe
    final stripe = Paint()..color = Colors.yellowAccent.withOpacity(0.6);
    canvas.drawLine(Offset(body.left + body.width * 0.1, body.center.dy), Offset(body.right - body.width * 0.1, body.center.dy), stripe);
  }

  void _paintLicensePlates(Canvas canvas, Rect body) {
    final platePaint = Paint()..color = const Color(0xFFEAEAEA).withOpacity(0.92);
    final front = Rect.fromLTWH(body.right - body.width * 0.036, body.center.dy - body.height * 0.11, body.width * 0.018, body.height * 0.22);
    final rear = Rect.fromLTWH(body.left + body.width * 0.018, body.center.dy - body.height * 0.10, body.width * 0.018, body.height * 0.20);
    canvas.drawRRect(RRect.fromRectAndRadius(front, Radius.circular(2)), platePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rear, Radius.circular(2)), platePaint..color = const Color(0xFFDDE6ED).withOpacity(0.82));
  }

  int get _styleSeed => car.id.codeUnits.fold<int>(car.length * 13, (sum, unit) => sum + unit);

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
        colors: [Colors.black.withOpacity(0.78), Colors.black.withOpacity(0.48)],
      ).createShader(cabin);
    canvas.drawRRect(cabinRRect, cabinFrame);

    final glassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.lightBlueAccent.withOpacity(0.92),
          const Color(0xFF0D47A1).withOpacity(0.82),
          Colors.black.withOpacity(0.68),
        ],
      ).createShader(cabin.deflate(body.height * 0.06));
    canvas.drawRRect(
      RRect.fromRectAndRadius(cabin.deflate(body.height * 0.06), Radius.circular(body.height * 0.11)),
      glassPaint,
    );

    // Glass reflection (realistic window)
    final glassShine = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white.withOpacity(0.65), Colors.white.withOpacity(0.15), Colors.transparent],
        stops: const [0.0, 0.28, 1.0],
      ).createShader(cabin.deflate(body.height * 0.06));
    canvas.drawRRect(
      RRect.fromRectAndRadius(cabin.deflate(body.height * 0.06), Radius.circular(body.height * 0.11)),
      glassShine,
    );

    final shine = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withOpacity(0.52), Colors.transparent],
      ).createShader(cabin);
    final shinePath = Path()
      ..moveTo(cabin.left + cabin.width * 0.12, cabin.top + cabin.height * 0.12)
      ..lineTo(cabin.left + cabin.width * 0.48, cabin.top + cabin.height * 0.12)
      ..lineTo(cabin.left + cabin.width * 0.20, cabin.bottom - cabin.height * 0.12)
      ..lineTo(cabin.left + cabin.width * 0.02, cabin.bottom - cabin.height * 0.12)
      ..close();
    canvas.drawPath(shinePath, shine);

    // Side mirrors
    final mirrorPaint = Paint()..color = car.darkColor.withOpacity(0.92);
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

    // Mirror chrome rim
    final mirrorChrome = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cabin.right - body.width * 0.005, cabin.top - body.height * 0.075, body.width * 0.08, body.height * 0.12),
        Radius.circular(body.height * 0.04),
      ),
      mirrorChrome,
    );
  }

  void _paintLightsAndDetails(Canvas canvas, Rect body) {
    // Headlight glows (realistic)
    final headGlow = Paint()
      ..color = AppTheme.accent.withOpacity(0.22 + pulse * 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    final headlight = Paint()
      ..color = Colors.white.withOpacity(0.98)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);

    final topLamp = Rect.fromLTWH(body.right - body.width * 0.055, body.top + body.height * 0.18, body.width * 0.035, body.height * 0.18);
    final bottomLamp = Rect.fromLTWH(body.right - body.width * 0.055, body.bottom - body.height * 0.36, body.width * 0.035, body.height * 0.18);

    // Headlight reflections
    canvas.drawOval(topLamp.inflate(7), headGlow);
    canvas.drawOval(bottomLamp.inflate(7), headGlow);
    canvas.drawRRect(RRect.fromRectAndRadius(topLamp, Radius.circular(body.height * 0.05)), headlight);
    canvas.drawRRect(RRect.fromRectAndRadius(bottomLamp, Radius.circular(body.height * 0.05)), headlight);

    // Headlight inner lens
    final lens = Paint()..color = const Color(0xFFCCE5FF).withOpacity(0.65);
    canvas.drawRRect(RRect.fromRectAndRadius(topLamp.deflate(1.5), Radius.circular(body.height * 0.03)), lens);
    canvas.drawRRect(RRect.fromRectAndRadius(bottomLamp.deflate(1.5), Radius.circular(body.height * 0.03)), lens);

    // Taillights
    final tail = Paint()..color = (car.isTarget ? AppTheme.targetRed : Colors.redAccent).withOpacity(0.96);
    final tailGlow = Paint()
      ..color = (car.isTarget ? AppTheme.targetRed : Colors.redAccent).withOpacity(0.38)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final rearTop = Rect.fromLTWH(body.left + body.width * 0.018, body.top + body.height * 0.18, body.width * 0.028, body.height * 0.18);
    final rearBottom = Rect.fromLTWH(body.left + body.width * 0.018, body.bottom - body.height * 0.36, body.width * 0.028, body.height * 0.18);
    canvas.drawOval(rearTop.inflate(4), tailGlow);
    canvas.drawOval(rearBottom.inflate(4), tailGlow);
    canvas.drawRRect(RRect.fromRectAndRadius(rearTop, Radius.circular(body.height * 0.04)), tail);
    canvas.drawRRect(RRect.fromRectAndRadius(rearBottom, Radius.circular(body.height * 0.04)), tail);

    // Grille
    final grille = Paint()
      ..color = Colors.black.withOpacity(0.42)
      ..strokeWidth = 1.2;
    for (int i = 0; i < 4; i++) {
      final y = body.top + body.height * (0.38 + i * 0.09);
      canvas.drawLine(Offset(body.right - body.width * 0.065, y), Offset(body.right - body.width * 0.022, y), grille);
    }

    // Fog lights / side detail
    final fog = Paint()..color = Colors.white.withOpacity(0.65);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(body.right - body.width * 0.055, body.center.dy - body.height * 0.05, body.width * 0.018, body.height * 0.10), Radius.circular(2)), fog);
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
    final tire = Paint()..color = const Color(0xFF0F141B);
    final tireEdge = Paint()
      ..color = const Color(0xFF2A3746)
      ..style = PaintingStyle.stroke
      ..strokeWidth = diameter * 0.13;
    canvas.drawCircle(center, diameter / 2, tire);
    canvas.drawCircle(center, diameter / 2 - diameter * 0.04, tireEdge);

    // Tire sidewall detail
    final sidewall = Paint()
      ..color = const Color(0xFF1A222D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = diameter * 0.055;
    canvas.drawCircle(center, diameter / 2 - diameter * 0.09, sidewall);

    // Realistic tire tread pattern
    final tread = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..strokeWidth = diameter * 0.028
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 12; i++) {
      final angle = wheelRotation + i * math.pi / 6;
      final start = center + Offset(math.cos(angle), math.sin(angle)) * diameter * 0.37;
      final end = center + Offset(math.cos(angle), math.sin(angle)) * diameter * 0.475;
      canvas.drawLine(start, end, tread);
    }
    // Sidewall grooves
    final groove = Paint()
      ..color = Colors.black.withOpacity(0.55)
      ..strokeWidth = diameter * 0.015;
    for (int i = 0; i < 6; i++) {
      final angle = wheelRotation * 0.6 + i * math.pi / 3;
      final start = center + Offset(math.cos(angle), math.sin(angle)) * diameter * 0.31;
      final end = center + Offset(math.cos(angle), math.sin(angle)) * diameter * 0.40;
      canvas.drawLine(start, end, groove);
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(wheelRotation);

    // Multi-layer realistic rim
    // Outer chrome rim
    final outerRim = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFFF0F4F8), const Color(0xFF9AA8B8), const Color(0xFF5F6B7A)],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: diameter * 0.33));
    canvas.drawCircle(Offset.zero, diameter * 0.33, outerRim);

    // Inner rim metallic
    final innerRim = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFFE8EEF5), const Color(0xFF6C7A8C), const Color(0xFF3B4754)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: diameter * 0.27));
    canvas.drawCircle(Offset.zero, diameter * 0.27, innerRim);

    // Rim highlight ring
    final rimHighlight = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white.withOpacity(0.65), Colors.transparent, Colors.black.withOpacity(0.25)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: diameter * 0.29));
    canvas.drawCircle(Offset.zero, diameter * 0.29, rimHighlight);

    // Wheel bolts (realistic)
    final boltPaint = Paint()..color = const Color(0xFF1E272E);
    for (int i = 0; i < 5; i++) {
      final angle = (math.pi * 2 / 5) * i + 0.3;
      final boltPos = Offset(math.cos(angle), math.sin(angle)) * diameter * 0.175;
      canvas.drawCircle(boltPos, diameter * 0.035, boltPaint);
      // bolt highlight
      canvas.drawCircle(boltPos + const Offset(-1.2, -1.2), diameter * 0.012, Paint()..color = Colors.white.withOpacity(0.6));
    }

    // Spokes (5 spoke sport design)
    final spoke = Paint()
      ..color = const Color(0xFF1E272E)
      ..strokeWidth = diameter * 0.065
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 5; i++) {
      final angle = (math.pi * 2 / 5) * i;
      canvas.drawLine(Offset.zero, Offset(math.cos(angle), math.sin(angle)) * diameter * 0.24, spoke);
    }

    // Center cap
    canvas.drawCircle(Offset.zero, diameter * 0.09, Paint()..color = const Color(0xFF0F141B));
    final capHighlight = Paint()
      ..shader = RadialGradient(colors: [Colors.white.withOpacity(0.5), Colors.transparent]).createShader(Rect.fromCircle(center: Offset.zero, radius: diameter * 0.09));
    canvas.drawCircle(Offset.zero, diameter * 0.09, capHighlight);

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
