import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/player_profile.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_parking_background.dart';
import '../utils/sound_manager.dart';
import 'daily_challenges_screen.dart';
import 'car_collection_screen.dart';
import 'settings_screen.dart';

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
  late AnimationController _sceneController;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _shimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _sceneController = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
    _floatAnim = Tween<double>(begin: -10, end: 10).animate(CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _floatController.dispose();
    _shimmerController.dispose();
    _sceneController.dispose();
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
              // NEW: Dynamic 3D Animated Background (same as game)
              Positioned.fill(
                child: AnimatedParkingBackground(
                  // The landing screen is the game's 3D poster: keep the
                  // scene richer here, while gameplay stays minimal and focused.
                  showRoad: true,
                  intensity: 0.72,
                  child: const SizedBox.expand(),
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
                    'PRODUCTION GARAGE • PROFILE SAVE ENABLED',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.42),
                      fontSize: 10.5,
                      letterSpacing: 1.7,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Roboto',
                      fontFeatures: const [FontFeature.enable('kern')],
                    ),
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
                        Text(widget.profile.rankTitle, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 12, letterSpacing: 0.4, fontFamily: 'Roboto')),
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
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              SoundManager().toggleSound();
              SoundManager().playClick();
            },
            child: _HudChip(
              icon: SoundManager().soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              value: '',
              color: AppTheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    final width = MediaQuery.sizeOf(context).width;
    final titleSize = width < 360 ? 38.0 : width < 430 ? 44.0 : 50.0;
    final subtitleSpacing = width < 360 ? 2.6 : width < 430 ? 3.6 : 4.6;
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
                gradient: const RadialGradient(
                  center: Alignment(-0.35, -0.45),
                  radius: 0.95,
                  colors: [Color(0xFFB7AEFF), AppTheme.primary, Color(0xFF30268F)],
                  stops: [0.0, 0.46, 1.0],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.48), width: 2),
                boxShadow: [
                  BoxShadow(color: AppTheme.primary.withOpacity(0.5), blurRadius: 30, spreadRadius: 5),
                  BoxShadow(color: AppTheme.secondary.withOpacity(0.28 + math.sin(spin).abs() * 0.18), blurRadius: 46, spreadRadius: 4),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Offset silhouettes create a simple 3D extrusion for the
                  // badge without requiring a raster asset.
                  Transform.translate(
                    offset: const Offset(0, 7),
                    child: Icon(Icons.settings_rounded, size: 92, color: const Color(0xFF211A70).withOpacity(0.72)),
                  ),
                  Transform.rotate(angle: spin, child: Icon(Icons.settings_rounded, size: 92, color: Colors.white.withOpacity(0.20))),
                  Stack(
                    children: [
                      Transform.translate(offset: const Offset(0, 4), child: Icon(Icons.directions_car_rounded, size: 62, color: const Color(0xFF33259A).withOpacity(.8))),
                      const Icon(Icons.directions_car_rounded, size: 62, color: Colors.white),
                    ],
                  ),
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
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
            'WHEEL OUT',
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.2,
              color: Colors.white,
              fontFamily: 'Roboto',
              fontFeatures: [FontFeature.enable('kern')],
              shadows: [
                Shadow(color: AppTheme.primary, blurRadius: 18),
                Shadow(color: AppTheme.secondary, blurRadius: 26),
              ],
            ),
          ),
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
            style: TextStyle(
              letterSpacing: subtitleSpacing,
              fontSize: width < 360 ? 9.5 : 11,
              fontWeight: FontWeight.w900,
              fontFamily: 'Roboto',
              color: Colors.white.withOpacity(0.84),
              shadows: [Shadow(color: AppTheme.accent.withOpacity(0.35), blurRadius: 10)],
            ),
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
            onTap: () {
              SoundManager().playClick();
              widget.onPlay();
            },
            delay: 0,
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 380 ? 2 : 3;
              final gap = 10.0;
              final itemWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _AnimatedButton(
                  label: 'LEVELS',
                  icon: Icons.grid_view_rounded,
                  gradient: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
                  isOutlined: true,
                  onTap: () {
                    SoundManager().playClick();
                    widget.onLevels();
                  },
                  delay: 100,
                    ),
                  ),
              SizedBox(
                    width: itemWidth,
                    child: _AnimatedButton(
                  label: 'DAILY',
                  icon: Icons.today_rounded,
                  gradient: [AppTheme.accent.withOpacity(0.3), AppTheme.accent.withOpacity(0.1)],
                  isOutlined: true,
                  onTap: () {
                    SoundManager().playClick();
                    // Navigate to daily challenges
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DailyChallengesScreen(
                          onLevelSelected: (levelId) {
                            Navigator.pop(context);
                            widget.onPlay(); // This will be improved later
                          },
                          onBack: () => Navigator.pop(context),
                        ),
                      ),
                    );
                  },
                  delay: 160,
                    ),
                  ),
              SizedBox(
                    width: itemWidth,
                    child: _AnimatedButton(
                  label: 'PROFILE',
                  icon: Icons.badge_rounded,
                  gradient: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
                  isOutlined: true,
                  onTap: () {
                    SoundManager().playClick();
                    widget.onProfile();
                  },
                  delay: 160,
                    ),
                  ),
              SizedBox(
                    width: itemWidth,
                    child: _AnimatedButton(
                  label: 'CARS',
                  icon: Icons.directions_car_rounded,
                  gradient: [AppTheme.secondary.withOpacity(0.3), AppTheme.secondary.withOpacity(0.1)],
                  isOutlined: true,
                  onTap: () {
                    SoundManager().playClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CarCollectionScreen(onBack: () => Navigator.pop(context)),
                      ),
                    );
                  },
                  delay: 220,
                    ),
                  ),
              SizedBox(
                    width: itemWidth,
                    child: _AnimatedButton(
                  label: 'SETTINGS',
                  icon: Icons.settings_rounded,
                  gradient: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
                  isOutlined: true,
                  onTap: () {
                    SoundManager().playClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(onBack: () => Navigator.pop(context)),
                      ),
                    );
                  },
                  delay: 280,
                    ),
                  ),
                ],
              );
            },
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
      child: Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 4), Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontFamily: 'Roboto'))]),
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
    final compact = MediaQuery.sizeOf(context).width < 380;
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
          height: compact ? 56 : 62,
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
              Icon(widget.icon, color: Colors.white, size: compact ? 20 : 24),
              SizedBox(width: compact ? 5 : 8),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: compact ? 11.5 : 15, fontWeight: FontWeight.w900, letterSpacing: compact ? .65 : 1.15, color: Colors.white, fontFamily: 'Roboto'),
                ),
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


class _PremiumHomeScenePainter extends CustomPainter {
  final double progress;
  final double floatValue;

  _PremiumHomeScenePainter({required this.progress, required this.floatValue});

  @override
  void paint(Canvas canvas, Size size) {
    _paintLuxurySky(canvas, size);
    _paintNeonCity(canvas, size);
    _paintPerspectiveRoad(canvas, size);
    _paintMovingTraffic(canvas, size);
    _paintForegroundGlow(canvas, size);
    _paintFloatingParticles(canvas, size);
  }

  void _paintLuxurySky(Canvas canvas, Size size) {
    final base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF070B1A), Color(0xFF101A33), Color(0xFF151133), Color(0xFF0B1020)],
        stops: [0.0, 0.42, 0.72, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);

    final sweep = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [
          AppTheme.primary.withOpacity(0.22),
          AppTheme.secondary.withOpacity(0.16),
          AppTheme.accent.withOpacity(0.10),
          AppTheme.primary.withOpacity(0.22),
        ],
        transform: GradientRotation(progress * math.pi * 2),
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.52, size.height * 0.30), radius: size.width * 0.9));
    canvas.drawCircle(Offset(size.width * 0.52, size.height * 0.30), size.width * 0.72, sweep);

    final moonPaint = Paint()
      ..shader = RadialGradient(colors: [Colors.white.withOpacity(0.70), AppTheme.secondary.withOpacity(0.18), Colors.transparent]).createShader(
        Rect.fromCircle(center: Offset(size.width * 0.82, size.height * 0.13), radius: size.width * 0.22),
      );
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.13), size.width * 0.20, moonPaint);
  }

  void _paintNeonCity(Canvas canvas, Size size) {
    final horizon = size.height * 0.43;
    final farPaint = Paint()..color = const Color(0xFF08101F).withOpacity(0.90);
    final nearPaint = Paint()..color = const Color(0xFF050913).withOpacity(0.96);
    final windowColors = [AppTheme.accent, AppTheme.secondary, Colors.white];

    final rnd = math.Random(11);
    double x = -20;
    int building = 0;
    while (x < size.width + 40) {
      final width = 20 + rnd.nextDouble() * 26;
      final height = 54 + rnd.nextDouble() * 120;
      final top = horizon - height;
      final rect = Rect.fromLTWH(x, top, width, height);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), building.isEven ? farPaint : nearPaint);

      final antenna = Paint()
        ..color = AppTheme.secondary.withOpacity(0.28)
        ..strokeWidth = 1;
      if (building % 4 == 0) {
        canvas.drawLine(Offset(rect.center.dx, rect.top), Offset(rect.center.dx, rect.top - 18), antenna);
        canvas.drawCircle(Offset(rect.center.dx, rect.top - 20), 2, Paint()..color = AppTheme.accent.withOpacity(0.7));
      }

      for (double wy = rect.top + 12; wy < rect.bottom - 8; wy += 14) {
        for (double wx = rect.left + 6; wx < rect.right - 4; wx += 10) {
          final twinkle = (math.sin(progress * math.pi * 2 + wx * 0.07 + wy * 0.03) + 1) / 2;
          if ((wx + wy).round() % 3 != 0) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(Rect.fromLTWH(wx, wy, 3.2, 5), const Radius.circular(1)),
              Paint()..color = windowColors[(building + wy.toInt()) % windowColors.length].withOpacity(0.08 + twinkle * 0.20),
            );
          }
        }
      }
      x += width + 5;
      building++;
    }

    final signRect = Rect.fromCenter(center: Offset(size.width * 0.20, horizon - 62), width: size.width * 0.28, height: 34);
    canvas.drawRRect(
      RRect.fromRectAndRadius(signRect, const Radius.circular(10)),
      Paint()..color = Colors.black.withOpacity(0.38),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(signRect, const Radius.circular(10)),
      Paint()
        ..color = AppTheme.accent.withOpacity(0.45 + math.sin(progress * math.pi * 2).abs() * 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    final tp = TextPainter(
      text: const TextSpan(
        text: 'VIP PARKING',
        style: TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.8, fontFamily: 'Roboto'),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, signRect.center - Offset(tp.width / 2, tp.height / 2));
  }

  void _paintPerspectiveRoad(Canvas canvas, Size size) {
    final horizon = size.height * 0.48;
    final road = Path()
      ..moveTo(size.width * 0.39, horizon)
      ..lineTo(size.width * 0.61, horizon)
      ..lineTo(size.width * 1.12, size.height)
      ..lineTo(size.width * -0.12, size.height)
      ..close();

    final roadPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF28384B), Color(0xFF111923), Color(0xFF060A10)],
      ).createShader(Rect.fromLTWH(0, horizon, size.width, size.height - horizon));
    canvas.drawPath(road, roadPaint);

    final shoulder = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 1.4;
    canvas.drawLine(Offset(size.width * 0.39, horizon), Offset(size.width * -0.10, size.height), shoulder);
    canvas.drawLine(Offset(size.width * 0.61, horizon), Offset(size.width * 1.10, size.height), shoulder);

    final neon = Paint()
      ..color = AppTheme.secondary.withOpacity(0.18)
      ..strokeWidth = 1.2;
    for (int i = 0; i < 8; i++) {
      final t = (i / 8 + progress) % 1;
      final y = horizon + (size.height - horizon) * math.pow(t, 1.65);
      final spread = (y - horizon) / (size.height - horizon);
      final left = size.width * (0.48 - spread * 0.30);
      final right = size.width * (0.52 + spread * 0.30);
      canvas.drawLine(Offset(left, y), Offset(right, y), neon..strokeWidth = 0.6 + spread * 2.2);
    }

    final dashPaint = Paint()
      ..color = AppTheme.accent.withOpacity(0.54)
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 7; i++) {
      final t = (i / 7 + progress * 1.25) % 1;
      final eased = math.pow(t, 1.55).toDouble();
      final y = horizon + (size.height - horizon) * eased;
      final len = 10 + eased * 32;
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, y + len),
        dashPaint..strokeWidth = 2 + eased * 5,
      );
    }
  }

  void _paintMovingTraffic(Canvas canvas, Size size) {
    _drawTrafficCar(canvas, size, lane: -1, phase: (progress * 1.2) % 1, color: AppTheme.targetRed);
    _drawTrafficCar(canvas, size, lane: 1, phase: (progress * 1.2 + 0.48) % 1, color: AppTheme.secondary);
    _drawTrafficCar(canvas, size, lane: -0.35, phase: (progress * 0.9 + 0.72) % 1, color: AppTheme.primary);
  }

  void _drawTrafficCar(Canvas canvas, Size size, {required double lane, required double phase, required Color color}) {
    final horizon = size.height * 0.48;
    final t = math.pow(phase, 1.9).toDouble();
    final y = horizon + (size.height - horizon) * t;
    final scale = 0.22 + t * 1.05;
    final x = size.width * (0.50 + lane * t * 0.26);
    final carW = 30 * scale;
    final carH = 15 * scale;
    final rect = Rect.fromCenter(center: Offset(x, y), width: carW, height: carH);
    final glow = Paint()
      ..color = color.withOpacity(0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(rect.inflate(8 * scale), glow);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(5 * scale)), Paint()..color = color.withOpacity(0.82));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x + carW * 0.08, y), width: carW * 0.32, height: carH * 0.58), Radius.circular(3 * scale)),
      Paint()..color = Colors.lightBlueAccent.withOpacity(0.55),
    );
    canvas.drawCircle(Offset(rect.left + carW * 0.22, rect.bottom), 2.4 * scale, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(rect.right - carW * 0.22, rect.bottom), 2.4 * scale, Paint()..color = Colors.black);
  }

  void _paintForegroundGlow(Canvas canvas, Size size) {
    final bottomGlow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Colors.black.withOpacity(0.58), Colors.transparent],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bottomGlow);

    final logoSpot = Paint()
      ..shader = RadialGradient(colors: [AppTheme.primary.withOpacity(0.18), Colors.transparent]).createShader(
        Rect.fromCircle(center: Offset(size.width / 2, size.height * 0.42), radius: size.width * 0.48),
      );
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.42), size.width * 0.46, logoSpot);
  }

  void _paintFloatingParticles(Canvas canvas, Size size) {
    final colors = [AppTheme.primary, AppTheme.secondary, AppTheme.accent, Colors.white];
    for (int i = 0; i < 32; i++) {
      final phase = (progress + i * 0.037) % 1;
      final x = (i * 41.0 + math.sin(progress * math.pi * 2 + i) * 18) % size.width;
      final y = size.height * (0.05 + phase * 0.55) + math.sin(floatValue * math.pi * 2 + i) * 9;
      final opacity = 0.05 + 0.13 * math.sin(phase * math.pi).abs();
      canvas.drawCircle(Offset(x, y), 1.2 + (i % 4) * 0.55, Paint()..color = colors[i % colors.length].withOpacity(opacity));
    }
  }

  @override
  bool shouldRepaint(covariant _PremiumHomeScenePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.floatValue != floatValue;
  }
}
