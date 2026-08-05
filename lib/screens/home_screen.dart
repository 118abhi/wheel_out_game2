import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/player_profile.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_parking_background.dart';

class HomeScreen extends StatefulWidget {
  final PlayerProfile profile;
  final int totalLevels;
  final VoidCallback onPlay;
  final VoidCallback onLevels;
  final VoidCallback onProfile;

  const HomeScreen({
    super.key,
    required this.profile,
    required this.totalLevels,
    required this.onPlay,
    required this.onLevels,
    required this.onProfile,
  });

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
          child: AnimatedParkingBackground(
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _floatController,
                    builder: (_, __) => CustomPaint(
                      painter: _HomeBackgroundPainter(value: _floatController.value),
                    ),
                  ),
                ),
                Column(
                  children: [
                    _buildProfileHud(),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _floatAnim,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _floatAnim.value),
                          child: child,
                        );
                      },
                      child: _buildLogo(),
                    ),
                    const Spacer(),
                    _buildActionPanel(),
                    const SizedBox(height: 18),
                    Text(
                      'Flutter production build • Profile save enabled',
                      style: TextStyle(color: Colors.white.withOpacity(0.34), fontSize: 11, letterSpacing: 1),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHud() {
    final progress = widget.totalLevels == 0 ? 0.0 : (widget.profile.unlockedLevel / widget.totalLevels).clamp(0, 1).toDouble();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onProfile,
            child: Hero(
              tag: 'profile-avatar',
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: Colors.white.withOpacity(0.08),
                  border: Border.all(color: Colors.white.withOpacity(0.14)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.profile.rankTitle, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 12)),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 82,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 5,
                              backgroundColor: Colors.white.withOpacity(0.08),
                              valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          _HudChip(icon: Icons.toll_rounded, value: '${widget.profile.coins}', color: AppTheme.accent),
          const SizedBox(width: 8),
          _HudChip(icon: Icons.lightbulb_rounded, value: '${widget.profile.hints}', color: AppTheme.secondary),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            final spin = _shimmerController.value * math.pi * 2;
            return Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
                boxShadow: [
                  BoxShadow(color: AppTheme.primary.withOpacity(0.5), blurRadius: 30, spreadRadius: 5),
                  BoxShadow(color: AppTheme.secondary.withOpacity(0.28 + math.sin(spin).abs() * 0.18), blurRadius: 46, spreadRadius: 4),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(angle: spin, child: Icon(Icons.settings_rounded, size: 92, color: Colors.white.withOpacity(0.18))),
                  const Icon(Icons.directions_car_rounded, size: 62, color: Colors.white),
                  Positioned(
                    bottom: 20,
                    child: Container(width: 58, height: 5, decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(20))),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(colors: [AppTheme.primary, AppTheme.accent, AppTheme.secondary]).createShader(bounds),
          child: const Text(
            'WHEEL OUT',
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
            'SLIDE • SPIN • ESCAPE',
            style: TextStyle(letterSpacing: 4, fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.8)),
          ),
        ),
      ],
    );
  }

  Widget _buildActionPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          _AnimatedButton(
            label: 'PLAY LEVEL ${widget.profile.unlockedLevel}',
            icon: Icons.play_arrow_rounded,
            gradient: const [AppTheme.primary, AppTheme.secondary],
            onTap: widget.onPlay,
            delay: 0,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _AnimatedButton(
                  label: 'LEVELS',
                  icon: Icons.grid_view_rounded,
                  gradient: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
                  isOutlined: true,
                  onTap: widget.onLevels,
                  delay: 100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AnimatedButton(
                  label: 'PROFILE',
                  icon: Icons.badge_rounded,
                  gradient: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
                  isOutlined: true,
                  onTap: widget.onProfile,
                  delay: 160,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatChip(icon: Icons.star_rounded, label: '${widget.totalLevels} Levels'),
              const SizedBox(width: 10),
              _StatChip(icon: Icons.emoji_events_rounded, label: '${widget.profile.totalStars} Stars'),
              const SizedBox(width: 10),
              const _StatChip(icon: Icons.bolt_rounded, label: 'Real Feel'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _HudChip({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 4), Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900))]),
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
        _ctrl.forward().then((_) => mounted ? _ctrl.reverse() : null);
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
            boxShadow: widget.isOutlined ? [] : [BoxShadow(color: widget.gradient.first.withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 8))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Flexible(
                child: Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: Colors.white)),
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
    final paint = Paint()..color = Colors.white.withOpacity(0.025);
    for (int i = 0; i < 6; i++) {
      final offset = (value * 20 - 10) * (i % 2 == 0 ? 1 : -1);
      canvas.drawCircle(Offset(size.width * (0.2 + i * 0.15), size.height * 0.3 + offset), 40 + i * 15, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HomeBackgroundPainter oldDelegate) => oldDelegate.value != value;
}
