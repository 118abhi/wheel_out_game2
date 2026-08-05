import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/levels_data.dart';
import '../models/level.dart';

class LevelSelectScreen extends StatefulWidget {
  final int unlockedLevel;
  final Function(int) onLevelSelected;
  final VoidCallback onBack;
  const LevelSelectScreen({super.key, required this.unlockedLevel, required this.onLevelSelected, required this.onBack});

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
                    const Text("SELECT LEVEL", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: Row(children: [
                        const Icon(Icons.lock_open_rounded, size: 16, color: AppTheme.accent),
                        const SizedBox(width: 4),
                        Text("${widget.unlockedLevel}/30", style: const TextStyle(fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: levels.length,
                  itemBuilder: (context, index) {
                    bool locked = index + 1 > widget.unlockedLevel;
                    double delay = index * 0.03;
                    return AnimatedBuilder(
                      animation: _staggerController,
                      builder: (context, child) {
                        double animValue = CurvedAnimation(parent: _staggerController, curve: Interval(delay.clamp(0, 1), (delay + 0.4).clamp(0, 1), curve: Curves.elasticOut)).value;
                        return Transform.scale(scale: animValue, child: Opacity(opacity: animValue.clamp(0, 1), child: child));
                      },
                      child: _LevelCard(
                        level: levels[index],
                        locked: locked,
                        onTap: () => widget.onLevelSelected(levels[index].id),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatefulWidget {
  final GameLevel level;
  final bool locked;
  final VoidCallback onTap;
  const _LevelCard({required this.level, required this.locked, required this.onTap});

  @override
  State<_LevelCard> createState() => _LevelCardState();
}

class _LevelCardState extends State<_LevelCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _hover = false;

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
            borderRadius: BorderRadius.circular(16),
            gradient: widget.locked
                ? LinearGradient(colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)])
                : LinearGradient(colors: [_difficultyColor().withOpacity(0.8), _difficultyColor().withOpacity(0.5)]),
            border: Border.all(color: widget.locked ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.2), width: 1),
            boxShadow: widget.locked
                ? []
                : [BoxShadow(color: _difficultyColor().withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Stack(
            children: [
              // background pattern
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CustomPaint(painter: _CardPatternPainter()),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.locked)
                      Icon(Icons.lock_rounded, color: Colors.white.withOpacity(0.3), size: 28)
                    else
                      Text(
                        "${widget.level.id}",
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    const SizedBox(height: 4),
                    if (!widget.locked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          "${widget.level.difficulty}★",
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    if (widget.locked)
                      Text("LOCKED", style: TextStyle(fontSize: 10, letterSpacing: 1, color: Colors.white.withOpacity(0.3))),
                    const SizedBox(height: 4),
                    Text(
                      widget.locked ? "???" : widget.level.name,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(widget.locked ? 0.3 : 0.8)),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;
    // diagonal stripes
    for (double i = -size.height; i < size.width; i += 12) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
