import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const SplashScreen({super.key, required this.onFinish});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _wheelController;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotate;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _wheelController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.elasticOut)), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
    ]).animate(_logoController);

    _logoRotate = Tween<double>(begin: -0.2, end: 0).animate(CurvedAnimation(parent: _logoController, curve: Curves.elasticOut));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _logoController, curve: const Interval(0.3, 1, curve: Curves.easeIn)));

    _logoController.forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) widget.onFinish();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _wheelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.background,
              AppTheme.surface,
              AppTheme.surfaceLight,
            ],
          ),
        ),
        child: Stack(
          children: [
            // animated background particles
            AnimatedBuilder(
              animation: _wheelController,
              builder: (_, __) => CustomPaint(
                size: Size.infinite,
                painter: _SplashBackgroundPainter(rotation: _wheelController.value * 2 * 3.1415),
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fade.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Transform.rotate(
                        angle: _logoRotate.value,
                        child: child,
                      ),
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo wheel
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.secondary],
                        ),
                        boxShadow: [
                          BoxShadow(color: AppTheme.primary.withOpacity(0.5), blurRadius: 30, spreadRadius: 5),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          RotationTransition(
                            turns: _wheelController,
                            child: Icon(Icons.settings, size: 90, color: Colors.white.withOpacity(0.9)),
                          ),
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.accent,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(Icons.directions_car, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.accent, AppTheme.secondary],
                      ).createShader(bounds),
                      child: const Text(
                        "WHEEL OUT",
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "PARKING PUZZLE MASTER",
                      style: TextStyle(
                        fontSize: 13,
                        letterSpacing: 6,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // loading indicator
                    SizedBox(
                      width: 200,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: const AlwaysStoppedAnimation(AppTheme.secondary),
                          minHeight: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashBackgroundPainter extends CustomPainter {
  final double rotation;
  _SplashBackgroundPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 5; i++) {
      double r = i * 120.0;
      canvas.drawCircle(center, r, paint);
    }

    // rotating dots orbit
    for (int i = 0; i < 8; i++) {
      double radiusOrbit = 100 + i * 45;
      double a = rotation * (0.5 + i * 0.1) + i * math.pi * 2 / 8;
      Offset finalP = Offset(
        center.dx + math.cos(a) * radiusOrbit,
        center.dy + math.sin(a) * radiusOrbit,
      );
      final dotPaint = Paint()..color = [AppTheme.primary, AppTheme.secondary, AppTheme.accent][i % 3].withOpacity(0.12);
      canvas.drawCircle(finalP, 5 + i * 1.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SplashBackgroundPainter oldDelegate) => oldDelegate.rotation != rotation;
}
