import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../game/particle_system.dart';
import '../utils/sound_manager.dart';

class WinScreen extends StatefulWidget {
  final int levelId;
  final int totalLevels;
  final int moves;
  final int par;
  final bool isPerfect;
  final VoidCallback onNext;
  final VoidCallback onMenu;
  final VoidCallback onReplay;
  const WinScreen({super.key, required this.levelId, required this.totalLevels, required this.moves, required this.par, required this.isPerfect, required this.onNext, required this.onMenu, required this.onReplay});

  @override
  State<WinScreen> createState() => _WinScreenState();
}

class _WinScreenState extends State<WinScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.elasticOut)), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
    ]).animate(_controller);
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.easeOut)));
    _slide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int stars = 1;
    if (widget.moves <= widget.par) stars = 3;
    else if (widget.moves <= widget.par + 5) stars = 2;

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: Stack(
        children: [
          // confetti
          const AnimatedConfetti(isActive: true),
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: ScaleTransition(
                  scale: _scale,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.surface, AppTheme.surfaceLight],
                      ),
                      border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.2),
                      boxShadow: [
                        BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 30, spreadRadius: 5),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // icon
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(colors: [AppTheme.accent, Color(0xFFFFA500)]),
                            boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.5), blurRadius: 20)],
                          ),
                          child: const Icon(Icons.emoji_events_rounded, size: 50, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        const Text("LEVEL COMPLETE!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.white)),
                        const SizedBox(height: 8),
                        Text("You freed the red wheel in ${widget.moves} moves!", style: TextStyle(color: Colors.white.withOpacity(0.6))),
                        const SizedBox(height: 8),
                        Text("+${stars * 10} coins • Profile XP saved", style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 12)),
                        const SizedBox(height: 20),
                        // stars
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (i) {
                            bool filled = i < stars;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: filled ? 1 : 0.3),
                                duration: Duration(milliseconds: 400 + i * 200),
                                curve: Curves.elasticOut,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: Icon(
                                      Icons.star_rounded,
                                      size: 42,
                                      color: filled ? AppTheme.accent : Colors.white.withOpacity(0.15),
                                      shadows: filled ? [Shadow(color: AppTheme.accent.withOpacity(0.6), blurRadius: 12)] : [],
                                    ),
                                  );
                                },
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 20),
                        // stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatBox(label: "Moves", value: "${widget.moves}"),
                            _StatBox(label: "Par", value: "${widget.par}"),
                            _StatBox(label: "Stars", value: "$stars/3"),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (widget.isPerfect)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.accent.withOpacity(0.4))),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bolt_rounded, color: AppTheme.accent, size: 18),
                                const SizedBox(width: 6),
                                const Text("PERFECT! You beat par!", style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),
                        // buttons
                        Row(
                          children: [
                            Expanded(
                              child: _ActionButton(
                                label: "MENU",
                                icon: Icons.home_rounded,
                                isSecondary: true,
                                onTap: widget.onMenu,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ActionButton(
                                label: "REPLAY",
                                icon: Icons.refresh_rounded,
                                isSecondary: true,
                                onTap: widget.onReplay,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: _ActionButton(
                            label: widget.levelId >= widget.totalLevels ? "FINISH TOUR" : "NEXT LEVEL",
                            icon: Icons.arrow_forward_rounded,
                            onTap: widget.onNext,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label.toUpperCase(), style: TextStyle(fontSize: 10, letterSpacing: 1, color: Colors.white.withOpacity(0.5))),
      ]),
    );
  }
}

class _PremiumActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  const _PremiumActionButton({required this.label, required this.icon, required this.onTap, this.isPrimary = false});

  @override
  State<_PremiumActionButton> createState() => _PremiumActionButtonState();
}

class _PremiumActionButtonState extends State<_PremiumActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 140));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap();
      },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.94).animate(_c),
        child: Container(
          height: widget.isPrimary ? 58 : 50,
          decoration: BoxDecoration(
            gradient: widget.isPrimary
                ? const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary])
                : null,
            color: widget.isPrimary ? null : Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(18),
            border: widget.isPrimary ? null : Border.all(color: Colors.white.withOpacity(0.16), width: 1.2),
            boxShadow: widget.isPrimary
                ? [BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 6))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: widget.isPrimary ? 23 : 19),
              const SizedBox(width: 9),
              Text(
                widget.label,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: widget.isPrimary ? 16 : 14,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
