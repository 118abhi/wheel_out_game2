import 'package:flutter/material.dart';

import '../models/level.dart';
import '../theme/app_theme.dart';
import '../utils/levels_data.dart';
import '../widgets/animated_parking_background.dart';

class LevelSelectScreen extends StatefulWidget {
  final int unlockedLevel;
  final Map<int, int> levelStars;
  final Function(int) onLevelSelected;
  final VoidCallback onBack;

  const LevelSelectScreen({
    super.key,
    required this.unlockedLevel,
    required this.levelStars,
    required this.onLevelSelected,
    required this.onBack,
  });

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> with TickerProviderStateMixin {
  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final levels = LevelsRepository.allLevels;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.background, AppTheme.surface],
          ),
        ),
        child: SafeArea(
          child: AnimatedParkingBackground(
            showRoad: true,
            intensity: 0.88,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: widget.onBack,
                        icon: const Icon(Icons.arrow_back_rounded),
                        style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1)),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(child: Text('SELECT LEVEL', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: Row(children: [
                          const Icon(Icons.lock_open_rounded, size: 16, color: AppTheme.accent),
                          const SizedBox(width: 4),
                          Text('${widget.unlockedLevel}/${levels.length}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ],
                  ),
                ),
                _buildChapterStrip(levels.length),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.90,
                    ),
                    itemCount: levels.length,
                    itemBuilder: (context, index) {
                      final level = levels[index];
                      final locked = level.id > widget.unlockedLevel;
                      final delay = (index % 18) * 0.025;
                      return AnimatedBuilder(
                        animation: _staggerController,
                        builder: (context, child) {
                          final animValue = CurvedAnimation(parent: _staggerController, curve: Interval(delay.clamp(0, 1).toDouble(), (delay + 0.45).clamp(0, 1).toDouble(), curve: Curves.elasticOut)).value;
                          return Transform.scale(scale: animValue, child: Opacity(opacity: animValue.clamp(0, 1).toDouble(), child: child));
                        },
                        child: _LevelCard(
                          level: level,
                          stars: widget.levelStars[level.id] ?? 0,
                          locked: locked,
                          onTap: () => widget.onLevelSelected(level.id),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChapterStrip(int totalLevels) {
    final chapters = [
      ('Training', '1-15', AppTheme.secondary),
      ('Downtown', '16-30', AppTheme.primary),
      ('Night Run', '31-45', AppTheme.danger),
      ('Mastery', '46-$totalLevels', AppTheme.accent),
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final chapter = chapters[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: chapter.$3.withOpacity(0.14),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: chapter.$3.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Icon(Icons.map_rounded, color: chapter.$3, size: 16),
                const SizedBox(width: 6),
                Text('${chapter.$1} ${chapter.$2}', style: TextStyle(color: Colors.white.withOpacity(0.82), fontWeight: FontWeight.w800, fontSize: 12)),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: chapters.length,
      ),
    );
  }
}

class _LevelCard extends StatefulWidget {
  final GameLevel level;
  final int stars;
  final bool locked;
  final VoidCallback onTap;

  const _LevelCard({required this.level, required this.stars, required this.locked, required this.onTap});

  @override
  State<_LevelCard> createState() => _LevelCardState();
}

class _LevelCardState extends State<_LevelCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (!widget.locked) _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        if (!widget.locked) widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 0.92).animate(_controller),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: widget.locked
                ? LinearGradient(colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)])
                : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_difficultyColor().withOpacity(0.82), _difficultyColor().withOpacity(0.42)]),
            border: Border.all(color: widget.locked ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.2), width: 1),
            boxShadow: widget.locked ? [] : [BoxShadow(color: _difficultyColor().withOpacity(0.28), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: CustomPaint(painter: _CardPatternPainter()),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Icon(_chapterIcon(), color: Colors.white.withOpacity(widget.locked ? 0.12 : 0.42), size: 18),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.locked)
                        Icon(Icons.lock_rounded, color: Colors.white.withOpacity(0.3), size: 28)
                      else
                        Text('${widget.level.id}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(height: 5),
                      if (!widget.locked) _buildStars(),
                      if (widget.locked) Text('LOCKED', style: TextStyle(fontSize: 10, letterSpacing: 1, color: Colors.white.withOpacity(0.3))),
                      const SizedBox(height: 5),
                      Text(
                        widget.locked ? '???' : widget.level.name,
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(widget.locked ? 0.3 : 0.84)),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      if (!widget.locked)
                        Text('D${widget.level.difficulty} • Par ${widget.level.parMoves}', style: TextStyle(fontSize: 8, color: Colors.white.withOpacity(0.5))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final filled = index < widget.stars;
        return Icon(Icons.star_rounded, size: 13, color: filled ? AppTheme.accent : Colors.white.withOpacity(0.24));
      }),
    );
  }

  IconData _chapterIcon() {
    if (widget.level.id >= 46) return Icons.military_tech_rounded;
    if (widget.level.id >= 31) return Icons.dark_mode_rounded;
    if (widget.level.id >= 16) return Icons.location_city_rounded;
    return Icons.school_rounded;
  }

  Color _difficultyColor() {
    switch (widget.level.difficulty) {
      case 1:
        return const Color(0xFF00B894);
      case 2:
        return const Color(0xFF0984E3);
      case 3:
        return const Color(0xFFFDCB6E);
      case 4:
        return const Color(0xFFE17055);
      case 5:
        return const Color(0xFFD63031);
      default:
        return AppTheme.primary;
    }
  }
}

class _CardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stripe = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;
    for (double i = -size.height; i < size.width; i += 12) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), stripe);
    }

    final glow = Paint()
      ..shader = RadialGradient(colors: [Colors.white.withOpacity(0.14), Colors.transparent]).createShader(Rect.fromCircle(center: Offset(size.width * 0.18, size.height * 0.12), radius: size.width));
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
