import 'dart:math' as math;
import 'package:flutter/material.dart';

class Particle {
  Offset position;
  Offset velocity;
  double size;
  Color color;
  double life;
  double rotation;
  double rotationSpeed;

  Particle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.color,
    this.life = 1.0,
    this.rotation = 0,
    this.rotationSpeed = 0,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<Particle> particles;
  ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      if (p.life <= 0) continue;
      final paint = Paint()
        ..color = p.color.withOpacity(p.life)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(p.position.dx, p.position.dy);
      canvas.rotate(p.rotation);

      // draw as rectangle/circle/star randomly based on size
      if (p.size > 8) {
        // star shape
        final path = Path();
        for (int i = 0; i < 5; i++) {
          double angle = (i * math.pi * 2 / 5) - math.pi / 2;
          double r = i.isEven ? p.size : p.size * 0.5;
          double x = math.cos(angle) * r;
          double y = math.sin(angle) * r;
          if (i == 0) path.moveTo(x, y);
          else path.lineTo(x, y);
        }
        path.close();
        canvas.drawPath(path, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 1.6),
            Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) => true;
}

class TireSmokePainter extends CustomPainter {
  final List<Particle> particles;
  TireSmokePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()
        ..color = p.color.withOpacity(p.life * 0.6)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 0.3);
      canvas.drawCircle(p.position, p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant TireSmokePainter oldDelegate) => true;
}

class AnimatedConfetti extends StatefulWidget {
  final bool isActive;
  const AnimatedConfetti({super.key, required this.isActive});

  @override
  State<AnimatedConfetti> createState() => _AnimatedConfettiState();
}

class _AnimatedConfettiState extends State<AnimatedConfetti> with TickerProviderStateMixin {
  late AnimationController _controller;
  List<Particle> particles = [];
  final math.Random rnd = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..addListener(_update)
      ..repeat();
    _initParticles();
  }

  void _initParticles() {
    particles = List.generate(120, (i) {
      final angle = rnd.nextDouble() * math.pi * 2;
      final speed = 2 + rnd.nextDouble() * 8;
      return Particle(
        position: Offset(rnd.nextDouble() * 400, -20 - rnd.nextDouble() * 100),
        velocity: Offset(math.cos(angle) * speed * 0.3, math.sin(angle) * speed + 2),
        size: 4 + rnd.nextDouble() * 10,
        color: [const Color(0xFFFF4757), const Color(0xFFFFE66D), const Color(0xFF6C5CE7), const Color(0xFF00CEC9), Colors.white][rnd.nextInt(5)],
        rotation: rnd.nextDouble() * math.pi * 2,
        rotationSpeed: (rnd.nextDouble() - 0.5) * 0.3,
      );
    });
  }

  void _update() {
    if (!widget.isActive) return;
    for (var p in particles) {
      p.position += p.velocity;
      p.velocity += Offset(0, 0.15); // gravity
      p.rotation += p.rotationSpeed;
      p.life -= 0.008;
      if (p.life <= 0 || p.position.dy > 900) {
        p.position = Offset(rnd.nextDouble() * 400, -20);
        p.velocity = Offset((rnd.nextDouble() - 0.5) * 4, 2 + rnd.nextDouble() * 4);
        p.life = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        painter: ConfettiPainter(particles),
        size: Size.infinite,
      ),
    );
  }
}
