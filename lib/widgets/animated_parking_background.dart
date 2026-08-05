import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AnimatedParkingBackground extends StatefulWidget {
  final Widget child;
  final bool showRoad;
  final double intensity;

  const AnimatedParkingBackground({
    super.key,
    required this.child,
    this.showRoad = true,
    this.intensity = 1,
  });

  @override
  State<AnimatedParkingBackground> createState() => _AnimatedParkingBackgroundState();
}

class _AnimatedParkingBackgroundState extends State<AnimatedParkingBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => CustomPaint(
              painter: ParkingWorldPainter(
                progress: _controller.value,
                showRoad: widget.showRoad,
                intensity: widget.intensity,
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class ParkingWorldPainter extends CustomPainter {
  final double progress;
  final bool showRoad;
  final double intensity;

  ParkingWorldPainter({required this.progress, required this.showRoad, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    _paintSkyGlow(canvas, size);
    _paintCity(canvas, size);
    if (showRoad) _paintRoad(canvas, size);
    _paintFloatingLights(canvas, size);
  }

  void _paintSkyGlow(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.65, -0.75),
        radius: 1.0,
        colors: [
          AppTheme.secondary.withOpacity(0.14 * intensity),
          AppTheme.primary.withOpacity(0.07 * intensity),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glow);
  }

  void _paintCity(Canvas canvas, Size size) {
    final baseY = size.height * 0.46;
    final farPaint = Paint()..color = const Color(0xFF0B1326).withOpacity(0.58 * intensity);
    final nearPaint = Paint()..color = const Color(0xFF08101F).withOpacity(0.72 * intensity);
    final windowPaint = Paint()..color = AppTheme.accent.withOpacity(0.16 * intensity);

    final rnd = math.Random(7);
    double x = -20;
    while (x < size.width + 30) {
      final width = 20 + rnd.nextDouble() * 34;
      final height = 42 + rnd.nextDouble() * 98;
      final rect = Rect.fromLTWH(x, baseY - height, width, height);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), farPaint);
      for (double wy = rect.top + 12; wy < rect.bottom - 6; wy += 16) {
        if (rnd.nextBool()) {
          canvas.drawRect(Rect.fromLTWH(rect.left + width * 0.2, wy, 3, 5), windowPaint);
          canvas.drawRect(Rect.fromLTWH(rect.right - width * 0.3, wy, 3, 5), windowPaint);
        }
      }
      x += width + 5;
    }

    final path = Path()
      ..moveTo(0, baseY + 24)
      ..lineTo(size.width * .12, baseY - 18)
      ..lineTo(size.width * .24, baseY + 16)
      ..lineTo(size.width * .42, baseY - 8)
      ..lineTo(size.width * .58, baseY + 22)
      ..lineTo(size.width * .75, baseY - 14)
      ..lineTo(size.width, baseY + 20)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, nearPaint);
  }

  void _paintRoad(Canvas canvas, Size size) {
    final top = size.height * 0.55;
    final roadPath = Path()
      ..moveTo(size.width * 0.06, size.height)
      ..lineTo(size.width * 0.37, top)
      ..lineTo(size.width * 0.63, top)
      ..lineTo(size.width * 0.94, size.height)
      ..close();

    final roadPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF253447), Color(0xFF111923)],
      ).createShader(Rect.fromLTWH(0, top, size.width, size.height - top));
    canvas.drawPath(roadPath, roadPaint);

    final edgePaint = Paint()
      ..color = Colors.white.withOpacity(0.13 * intensity)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(size.width * 0.06, size.height), Offset(size.width * 0.37, top), edgePaint);
    canvas.drawLine(Offset(size.width * 0.94, size.height), Offset(size.width * 0.63, top), edgePaint);

    final dashPaint = Paint()
      ..color = AppTheme.accent.withOpacity(0.42 * intensity)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 8; i++) {
      final t = ((i / 8) + progress) % 1.0;
      final y = top + (size.height - top) * t;
      final scale = 0.2 + t * 0.9;
      final centerX = size.width / 2;
      canvas.drawLine(Offset(centerX, y), Offset(centerX, y + 18 * scale), dashPaint..strokeWidth = 2 + 5 * scale);
    }
  }

  void _paintFloatingLights(Canvas canvas, Size size) {
    final colors = [AppTheme.primary, AppTheme.secondary, AppTheme.accent, AppTheme.targetRed];
    for (int i = 0; i < 18; i++) {
      final t = (progress + i * 0.071) % 1.0;
      final wave = math.sin((progress * math.pi * 2) + i);
      final x = (i * 47.0 + wave * 18) % size.width;
      final y = size.height * (0.08 + 0.44 * t);
      final radius = 1.8 + (i % 4) * 0.8;
      final paint = Paint()
        ..color = colors[i % colors.length].withOpacity((0.10 + 0.08 * math.sin(t * math.pi)) * intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParkingWorldPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.showRoad != showRoad || oldDelegate.intensity != intensity;
  }
}
