import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onPlay;
  final VoidCallback onLevels;
  const HomeScreen({super.key, required this.onPlay, required this.onLevels});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _shimmerController;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _shimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _floatAnim = Tween<double>(begin: -10, end: 10).animate(CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _floatController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.background, AppTheme.surface, AppTheme.surfaceLight],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // background animated circles
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _floatController,
                  builder: (_, __) => CustomPaint(
                    painter: _HomeBackgroundPainter(value: _floatController.value),
                  ),
                ),
              ),
              // content
              Column(
                children: [
                  const Spacer(),
                  // logo with float
                  AnimatedBuilder(
                    animation: _floatAnim,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnim.value),
                        child: child,
                      );
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
                            boxShadow: [
                              BoxShadow(color: AppTheme.primary.withOpacity(0.5), blurRadius: 30, spreadRadius: 5),
                            ],
                          ),
                          child: const Icon(Icons.directions_car_rounded, size: 64, color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(colors: [AppTheme.primary, AppTheme.accent, AppTheme.secondary]).createShader(b),
                          child: const Text(
                            "WHEEL OUT",
                            style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Text(
                            "SLIDE • SPIN • ESCAPE",
                            style: TextStyle(letterSpacing: 4, fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        _AnimatedButton(
                          label: "PLAY NOW",
                          icon: Icons.play_arrow_rounded,
                          gradient: const [AppTheme.primary, AppTheme.secondary],
                          onTap: widget.onPlay,
                          delay: 0,
                        ),
                        const SizedBox(height: 16),
                        _AnimatedButton(
                          label: "LEVELS",
                          icon: Icons.grid_view_rounded,
                          gradient: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
                          isOutlined: true,
                          onTap: widget.onLevels,
                          delay: 100,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _StatChip(icon: Icons.star_rounded, label: "30 Levels"),
                            const SizedBox(width: 12),
                            _StatChip(icon: Icons.bolt_rounded, label: "Premium Animations"),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "Made with Flutter • For Android",
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11, letterSpacing: 1),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;
  final bool isOutlined;
  final int delay;
  const _AnimatedButton({required this.label, required this.icon, required this.gradient, required this.onTap, this.isOutlined = false, this.delay = 0});

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1, end: 0.95).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: 500 + widget.delay), () {
      if (mounted) {
        _ctrl.forward().then((_) => _ctrl.reverse());
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity,
          height: 62,
          decoration: BoxDecoration(
            gradient: widget.isOutlined ? null : LinearGradient(colors: widget.gradient),
            color: widget.isOutlined ? Colors.white.withOpacity(0.08) : null,
            borderRadius: BorderRadius.circular(18),
            border: widget.isOutlined ? Border.all(color: Colors.white.withOpacity(0.2), width: 1.2) : null,
            boxShadow: widget.isOutlined
                ? []
                : [
                    BoxShadow(color: widget.gradient.first.withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 8)),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Text(widget.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppTheme.accent),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7))),
      ]),
    );
  }
}

class _HomeBackgroundPainter extends CustomPainter {
  final double value;
  _HomeBackgroundPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.02);
    for (int i = 0; i < 6; i++) {
      double offset = (value * 20 - 10) * (i % 2 == 0 ? 1 : -1);
      canvas.drawCircle(Offset(size.width * (0.2 + i * 0.15), size.height * 0.3 + offset), 40 + i * 15, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HomeBackgroundPainter oldDelegate) => oldDelegate.value != value;
}
