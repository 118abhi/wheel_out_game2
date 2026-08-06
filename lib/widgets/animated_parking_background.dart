import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/weather.dart';

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
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
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
              painter: ThreeDAnimatedParkingPainter(
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

class ThreeDAnimatedParkingPainter extends CustomPainter {
  final double progress;
  final bool showRoad;
  final double intensity;
  final WeatherType? weatherType;

  ThreeDAnimatedParkingPainter({
    required this.progress,
    required this.showRoad,
    required this.intensity,
    this.weatherType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintSkyAndHorizon(canvas, size);
    _paint3DCityBackground(canvas, size);
    _paint3DParkingLot(canvas, size);
    if (showRoad) _paint3DAnimatedRoad(canvas, size);
    _paintFloatingNeonLights(canvas, size);
    _paintMovingCars(canvas, size);
    _paintLightBeams(canvas, size);
    _paintDynamicFog(canvas, size);
    _paintLightRain(canvas, size);

    // Weather-based effects
    if (weatherType == WeatherType.rain || weatherType == WeatherType.storm) {
      _paintHeavyRain(canvas, size);
    }
    if (weatherType == WeatherType.storm) {
      _paintLightning(canvas, size);
    }
    if (weatherType == WeatherType.fog) {
      _paintDynamicFog(canvas, size);
    }

    // Enhanced dynamic effects
    if (intensity > 0.6) {
      _paintHeavyRain(canvas, size);
    }
    if (intensity > 0.75) {
      _paintLightning(canvas, size);
    }
    _paintWindParticles(canvas, size);
  }

  void _paintSkyAndHorizon(Canvas canvas, Size size) {
    // Deep cinematic 3D night sky
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0A0F1F),
          const Color(0xFF121B32),
          const Color(0xFF1A253F),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, skyPaint);

    // Horizon glow
    final horizon = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, 0.3),
        radius: 1.2,
        colors: [
          AppTheme.primary.withOpacity(0.18 * intensity),
          AppTheme.secondary.withOpacity(0.08 * intensity),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, horizon);
  }

  void _paint3DCityBackground(Canvas canvas, Size size) {
    final vanishingY = size.height * 0.38;
    final rand = math.Random(42);

    // Far distant buildings (strong 3D perspective)
    final farPaint = Paint()..color = const Color(0xFF0B1326).withOpacity(0.75 * intensity);
    final farWindow = Paint()..color = AppTheme.accent.withOpacity(0.12 * intensity);

    for (int layer = 0; layer < 3; layer++) {
      double x = -30 + layer * 18;
      while (x < size.width + 80) {
        final w = 22 + rand.nextDouble() * 36;
        final h = 60 + rand.nextDouble() * 110;
        final perspective = 1 - (layer * 0.18);

        final rect = Rect.fromLTWH(
          x,
          vanishingY - h * perspective,
          w * perspective,
          h * perspective,
        );

        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(2 * perspective)),
          farPaint,
        );

        // Windows
        if (layer < 2) {
          for (double wy = rect.top + 14; wy < rect.bottom - 8; wy += 18) {
            if (rand.nextDouble() > 0.35) {
              canvas.drawRect(
                Rect.fromLTWH(rect.left + w * 0.22 * perspective, wy, 3.5, 5.5),
                farWindow,
              );
              canvas.drawRect(
                Rect.fromLTWH(rect.right - w * 0.32 * perspective, wy, 3.5, 5.5),
                farWindow,
              );
            }
          }
        }
        x += w * perspective + 12;
      }
    }

    // Mid layer buildings
    final midPaint = Paint()..color = const Color(0xFF08101F).withOpacity(0.85 * intensity);
    double mx = 10;
    while (mx < size.width) {
      final w = 38 + rand.nextDouble() * 48;
      final h = 95 + rand.nextDouble() * 75;
      final rect = Rect.fromLTWH(mx, vanishingY - h, w, h);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), midPaint);

      // Windows
      final winPaint = Paint()..color = AppTheme.accent.withOpacity(0.18 * intensity);
      for (double wy = rect.top + 18; wy < rect.bottom - 10; wy += 17) {
        if (rand.nextBool()) {
          canvas.drawRect(Rect.fromLTWH(rect.left + 8, wy, 4, 6), winPaint);
          canvas.drawRect(Rect.fromLTWH(rect.right - 12, wy, 4, 6), winPaint);
        }
      }
      mx += w + 18;
    }
  }

  void _paint3DParkingLot(Canvas canvas, Size size) {
    final lotTop = size.height * 0.48;
    final lotBottom = size.height;

    // 3D perspective parking lot floor
    final floorPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1E2A3C),
          const Color(0xFF16202F),
          const Color(0xFF0F161F),
        ],
      ).createShader(Rect.fromLTWH(0, lotTop, size.width, lotBottom - lotTop));
    canvas.drawRect(Rect.fromLTWH(0, lotTop, size.width, lotBottom - lotTop), floorPaint);

    // 3D perspective parking lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.14 * intensity)
      ..strokeWidth = 1.6;

    final spacing = size.width / 9;
    for (int i = 0; i < 10; i++) {
      final x = spacing * i;
      final topOffset = (i - 4.5).abs() * 0.9;
      canvas.drawLine(
        Offset(x, lotTop + topOffset),
        Offset(x * 0.6 + size.width * 0.2, lotBottom),
        linePaint,
      );
    }

    // Parking bay markings
    final bayPaint = Paint()
      ..color = Colors.white.withOpacity(0.09 * intensity)
      ..strokeWidth = 1.2;
    for (int i = 0; i < 8; i++) {
      final x = spacing * (i + 0.5);
      canvas.drawLine(Offset(x, lotTop + 18), Offset(x, lotTop + 55), bayPaint);
    }
  }

  void _paint3DAnimatedRoad(Canvas canvas, Size size) {
    final roadTop = size.height * 0.55;
    final roadBottom = size.height;

    final roadPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF253447),
          const Color(0xFF1A2435),
          const Color(0xFF111923),
        ],
      ).createShader(Rect.fromLTWH(0, roadTop, size.width, roadBottom - roadTop));

    final roadPath = Path()
      ..moveTo(size.width * 0.12, roadBottom)
      ..lineTo(size.width * 0.35, roadTop)
      ..lineTo(size.width * 0.65, roadTop)
      ..lineTo(size.width * 0.88, roadBottom)
      ..close();
    canvas.drawPath(roadPath, roadPaint);

    // Road edges
    final edgePaint = Paint()
      ..color = Colors.white.withOpacity(0.2 * intensity)
      ..strokeWidth = 2.5;
    canvas.drawLine(Offset(size.width * 0.12, roadBottom), Offset(size.width * 0.35, roadTop), edgePaint);
    canvas.drawLine(Offset(size.width * 0.88, roadBottom), Offset(size.width * 0.65, roadTop), edgePaint);

    // Animated dashed center line (3D perspective)
    final dashPaint = Paint()
      ..color = AppTheme.accent.withOpacity(0.6 * intensity)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 9; i++) {
      final t = ((i / 9.0) + progress * 1.2) % 1.0;
      final y = roadTop + (roadBottom - roadTop) * t;
      final scale = 0.3 + t * 1.4;
      final centerX = size.width / 2 + (math.sin(t * math.pi * 1.8) * 8);
      canvas.drawLine(
        Offset(centerX - 3 * scale, y),
        Offset(centerX + 3 * scale, y + 22 * scale),
        dashPaint..strokeWidth = 2.8 + 4 * scale,
      );
    }
  }

  void _paintFloatingNeonLights(Canvas canvas, Size size) {
    final colors = [
      AppTheme.primary,
      AppTheme.secondary,
      AppTheme.accent,
      AppTheme.targetRed,
      const Color(0xFF00E5FF),
    ];

    for (int i = 0; i < 26; i++) {
      final t = (progress + i * 0.037) % 1.0;
      final wave = math.sin(progress * math.pi * 1.8 + i * 0.7) * 22;
      final x = (i * 31.0 + wave) % size.width;
      final y = size.height * (0.06 + 0.36 * t * (1 + math.sin(i) * 0.2));

      final radius = 2.2 + (i % 5) * 0.9;
      final opacity = (0.09 + 0.11 * math.sin(t * math.pi * 2)) * intensity;

      final paint = Paint()
        ..color = colors[i % colors.length].withOpacity(opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
      canvas.drawCircle(Offset(x, y), radius, paint);

      // Small glow core
      final core = Paint()
        ..color = colors[i % colors.length].withOpacity(opacity * 1.8);
      canvas.drawCircle(Offset(x, y), radius * 0.4, core);
    }
  }

  void _paintMovingCars(Canvas canvas, Size size) {
    final rand = math.Random(99);
    final carPaint = Paint()..color = Colors.white.withOpacity(0.18 * intensity);

    for (int i = 0; i < 5; i++) {
      final t = ((progress * 0.6 + i * 0.19) % 1.0);
      final x = size.width * (0.15 + t * 0.75);
      final y = size.height * (0.59 + (i % 3) * 0.035);

      final carWidth = 14.0 + (i % 2) * 4;
      final carHeight = 7.0;

      // Tiny 3D moving cars in distance
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: carWidth, height: carHeight),
          const Radius.circular(2),
        ),
        carPaint,
      );

      // Headlight
      canvas.drawCircle(
        Offset(x + carWidth * 0.45, y),
        1.8,
        Paint()..color = AppTheme.accent.withOpacity(0.6 * intensity),
      );
    }
  }

  void _paintLightBeams(Canvas canvas, Size size) {
    final beamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.accent.withOpacity(0.06 * intensity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.6));

    for (int i = 0; i < 4; i++) {
      final t = (progress + i * 0.25) % 1.0;
      final x = size.width * (0.2 + i * 0.18 + math.sin(t * math.pi) * 0.03);
      final path = Path()
        ..moveTo(x - 18, 0)
        ..lineTo(x + 18, 0)
        ..lineTo(x + 70, size.height * 0.52)
        ..lineTo(x - 70, size.height * 0.52)
        ..close();
      canvas.drawPath(path, beamPaint);
    }
  }

  // === NEW DYNAMIC EFFECTS ===

  void _paintDynamicFog(Canvas canvas, Size size) {
    final fogPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.035 * intensity),
          Colors.transparent,
          Colors.white.withOpacity(0.025 * intensity),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Offset.zero & size);

    final fogOffset = math.sin(progress * math.pi * 1.3) * 30;

    canvas.save();
    canvas.translate(fogOffset * 0.6, 0);
    canvas.drawRect(Offset.zero & size, fogPaint);
    canvas.restore();

    // Second fog layer
    final fogPaint2 = Paint()
      ..color = Colors.white.withOpacity(0.02 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.3 + math.sin(progress * 1.8) * 40, size.height * 0.6),
        width: size.width * 1.1,
        height: size.height * 0.55,
      ),
      fogPaint2,
    );
  }

  void _paintLightRain(Canvas canvas, Size size) {
    final rainPaint = Paint()
      ..color = Colors.white.withOpacity(0.06 * intensity)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final rainSpeed = 1.6;
    final dropCount = 48;

    for (int i = 0; i < dropCount; i++) {
      final phase = (progress * rainSpeed + i * 0.019) % 1.0;
      final x = ((i * 23) % size.width) + (math.sin(i) * 8);
      final y = size.height * phase * 1.1 - 40;

      if (y > 0 && y < size.height) {
        final length = 8 + (i % 3) * 4;
        final alpha = 0.05 + (1 - phase) * 0.09;

        canvas.drawLine(
          Offset(x, y),
          Offset(x + 1.5, y + length),
          rainPaint..color = Colors.white.withOpacity(alpha * intensity),
        );
      }
    }
  }

  // ==================== NEW DYNAMIC EFFECTS ====================

  void _paintHeavyRain(Canvas canvas, Size size) {
    final rainPaint = Paint()
      ..color = Colors.white.withOpacity(0.12 * intensity)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final wind = math.sin(progress * 3.5) * 12;
    final rainSpeed = 2.8;
    final dropCount = 85;

    for (int i = 0; i < dropCount; i++) {
      final phase = (progress * rainSpeed + i * 0.012) % 1.0;
      final x = ((i * 17.3) % size.width) + wind * (i % 5 - 2) * 0.3;
      final y = size.height * phase * 1.15 - 60;

      if (y > 0 && y < size.height * 0.98) {
        final length = 12 + (i % 5) * 5;
        final alpha = 0.08 + (1 - phase) * 0.18;

        canvas.drawLine(
          Offset(x, y),
          Offset(x + wind * 0.08, y + length),
          rainPaint..color = Colors.white.withOpacity(alpha * intensity),
        );
      }
    }
  }

  void _paintLightning(Canvas canvas, Size size) {
    // Occasional lightning flash
    final flash = (math.sin(progress * 18) * math.sin(progress * 7)).abs();
    if (flash > 0.88) {
      final lightningPaint = Paint()
        ..color = Colors.white.withOpacity(0.35 * intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

      // Main flash
      canvas.drawRect(Offset.zero & size, lightningPaint);

      // Lightning bolt
      final boltPaint = Paint()
        ..color = Colors.white.withOpacity(0.75)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;

      final boltPath = Path();
      final startX = size.width * 0.35 + math.sin(progress * 40) * 30;
      boltPath.moveTo(startX, 0);

      for (int i = 1; i < 6; i++) {
        final y = size.height * (i / 6);
        final x = startX + (i.isEven ? 35 : -28) + math.sin(i + progress * 20) * 12;
        boltPath.lineTo(x, y);
      }
      canvas.drawPath(boltPath, boltPaint);
    }
  }

  void _paintWindParticles(Canvas canvas, Size size) {
    final windPaint = Paint()
      ..color = AppTheme.secondary.withOpacity(0.08 * intensity)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final windStrength = math.sin(progress * 2.2) * 40;

    for (int i = 0; i < 22; i++) {
      final t = (progress * 1.4 + i * 0.047) % 1.0;
      final x = (i * 41 + windStrength) % size.width;
      final y = size.height * (0.12 + t * 0.72);

      canvas.drawLine(
        Offset(x, y),
        Offset(x + 18 + math.sin(i) * 6, y + 2),
        windPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ThreeDAnimatedParkingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.showRoad != showRoad ||
        oldDelegate.intensity != intensity;
  }
}
