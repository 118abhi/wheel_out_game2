import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../game/wheel_painter.dart';

class WheelRewardScreen extends StatefulWidget {
  final VoidCallback onRewardClaimed;
  final int spinResult;
  const WheelRewardScreen({super.key, required this.onRewardClaimed, required this.spinResult});

  @override
  State<WheelRewardScreen> createState() => _WheelRewardScreenState();
}

class _WheelRewardScreenState extends State<WheelRewardScreen> with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _scaleController;
  late Animation<double> _rotationAnim;
  late Animation<double> _scaleAnim;
  bool _isSpinning = true;
  bool _hasClaimed = false;

  final List<WheelSegment> segments = [
    WheelSegment(label: "+1 Hint", color: const Color(0xFF6C5CE7), value: 1),
    WheelSegment(label: "+50", color: const Color(0xFF00B894), value: 50),
    WheelSegment(label: "+2 Hints", color: const Color(0xFF0984E3), value: 2),
    WheelSegment(label: "+100", color: const Color(0xFFFDCB6E), value: 100),
    WheelSegment(label: "JACKPOT", color: const Color(0xFFFF4757), value: 500),
    WheelSegment(label: "+1 Hint", color: const Color(0xFF00CEC9), value: 1),
    WheelSegment(label: "+25", color: const Color(0xFFA29BFE), value: 25),
    WheelSegment(label: "+3 Hints", color: const Color(0xFFE17055), value: 3),
  ];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000));
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    // Calculate target rotation to land on desired segment
    // We want pointer at top. segments[0] at -90 deg etc.
    // Add multiple full rotations for effect
    int targetIndex = widget.spinResult % segments.length;
    double segmentAngle = 2 * math.pi / segments.length;
    // pointer is at top (-pi/2). To bring target to top, rotation needs to be...
    double targetRotation = (2 * math.pi * 5) + (2 * math.pi - targetIndex * segmentAngle - segmentAngle / 2);
    // add slight randomness within segment
    targetRotation += (math.Random().nextDouble() - 0.5) * segmentAngle * 0.6;

    _rotationAnim = Tween<double>(begin: 0, end: targetRotation).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.easeOutCubic),
    );

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.elasticOut)), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
    ]).animate(_scaleController);

    _spinController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isSpinning = false);
        _scaleController.forward();
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted && !_hasClaimed) {
            // auto claim after delay can be optional
          }
        });
      }
    });

    _spinController.forward();
  }

  @override
  void dispose() {
    _spinController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.background, AppTheme.surface, Color(0xFF1A1A2E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                _isSpinning ? "SPINNING..." : "YOU WON!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: _isSpinning ? Colors.white.withOpacity(0.8) : AppTheme.accent,
                  shadows: _isSpinning ? [] : [Shadow(color: AppTheme.accent.withOpacity(0.6), blurRadius: 20)],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isSpinning ? "Good luck!" : "Amazing spin!",
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
              const Spacer(),
              Stack(
                alignment: Alignment.center,
                children: [
                  // glow
                  Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppTheme.primary.withOpacity(0.25), blurRadius: 60, spreadRadius: 10),
                      ],
                    ),
                  ),
                  // wheel
                  AnimatedBuilder(
                    animation: _rotationAnim,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationAnim.value,
                        child: CustomPaint(
                          size: const Size(300, 300),
                          painter: RewardWheelPainter(rotation: 0, segments: segments),
                        ),
                      );
                    },
                  ),
                  // pointer
                  Positioned(
                    top: 0,
                    child: CustomPaint(
                      size: const Size(36, 44),
                      painter: SpinPointerPainter(),
                    ),
                  ),
                  // center tap to speed? ignore
                ],
              ),
              const Spacer(),
              if (!_isSpinning)
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: segments[widget.spinResult % segments.length].color,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: segments[widget.spinResult % segments.length].color.withOpacity(0.5), blurRadius: 20),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.card_giftcard_rounded, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              segments[widget.spinResult % segments.length].label,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () {
                          if (_hasClaimed) return;
                          setState(() => _hasClaimed = true);
                          widget.onRewardClaimed();
                        },
                        child: Container(
                          width: 220,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 8))],
                          ),
                          child: const Center(
                            child: Text("CLAIM REWARD", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1, color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    const CircularProgressIndicator(color: AppTheme.secondary),
                    const SizedBox(height: 16),
                    Text("Spinning the wheel of fortune...", style: TextStyle(color: Colors.white.withOpacity(0.5))),
                  ],
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
