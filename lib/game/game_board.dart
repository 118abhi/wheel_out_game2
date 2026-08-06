import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/car.dart';
import '../models/level.dart';
import '../theme/app_theme.dart';
import '../utils/sound_manager.dart';
import 'car_widget.dart';
import 'particle_system.dart';

class GameBoardWidget extends StatefulWidget {
  final GameState gameState;
  final Function(CarModel newPos, double dragDistance) onCarMoved;
  final Function() onWin;
  final Function(CarModel) onCarSelected;

  const GameBoardWidget({
    super.key,
    required this.gameState,
    required this.onCarMoved,
    required this.onWin,
    required this.onCarSelected,
  });

  @override
  State<GameBoardWidget> createState() => _GameBoardWidgetState();
}

class _GameBoardWidgetState extends State<GameBoardWidget> with TickerProviderStateMixin {
  String? selectedCarId;
  String? draggingCarId;
  double dragStartPos = 0;
  double dragCurrentPos = 0;
  double wheelRotation = 0;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;
  String? _shakingCarId;

  late AnimationController _exitController;
  late Animation<double> _exitAnim;
  bool _isExiting = false;
  CarModel? _exitingCar;

  List<Particle> smokeParticles = [];
  late AnimationController _smokeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut));

    _exitController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _exitAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _exitController, curve: Curves.easeInOutCubic));

    _smokeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
    _smokeController.addListener(_updateSmoke);
  }

  void _updateSmoke() {
    if (!_isExiting) return;
    setState(() {
      // spawn smoke
      if (smokeParticles.length < 30 && math.Random().nextDouble() > 0.6) {
        smokeParticles.add(
          Particle(
            position: Offset(0, 0),
            velocity: Offset(- (math.Random().nextDouble() * 2 + 1), (math.Random().nextDouble() - 0.5) * 2),
            size: 4 + math.Random().nextDouble() * 10,
            color: Colors.grey.shade400,
            life: 1.0,
          ),
        );
      }
      for (var p in smokeParticles) {
        p.position += p.velocity;
        p.size += 0.3;
        p.life -= 0.02;
      }
      smokeParticles.removeWhere((p) => p.life <= 0);
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _exitController.dispose();
    _smokeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
    final double boardSize = math.min(constraints.maxWidth, constraints.maxHeight);
    final double cellSize = boardSize / widget.gameState.level.gridSize;

        return Container(
          width: boardSize,
          height: boardSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                _buildBoardBackground(cellSize, boardSize),
                _buildGridLines(cellSize, boardSize),
                _buildExit(cellSize, boardSize),
                if (selectedCarId != null && draggingCarId == null) _buildMoveGuide(cellSize),
                if (draggingCarId != null) _buildDragTrail(cellSize),
                // Cars
                ...widget.gameState.cars.map((car) => _buildCar(car, cellSize)),
                if (_isExiting && _exitingCar != null) _buildExitingCar(cellSize),
                if (_isExiting) _buildSmoke(cellSize),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBoardBackground(double cellSize, double boardSize) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: CustomPaint(
          size: Size(boardSize, boardSize),
          painter: ClassicRushHourBoardPainter(gridSize: widget.gameState.level.gridSize),
        ),
      ),
    );
  }

  Widget _buildGridLines(double cellSize, double boardSize) {
    return CustomPaint(
      size: Size(boardSize, boardSize),
      painter: GridPainter(cellSize: cellSize, gridSize: widget.gameState.level.gridSize),
    );
  }

  Widget _buildExit(double cellSize, double boardSize) {
    final exitRow = widget.gameState.level.exitRow;
    return Positioned(
      left: boardSize - cellSize * 0.28,
      top: exitRow * cellSize,
      width: cellSize * 0.28,
      height: cellSize,
      child: AnimatedBuilder(
        animation: _smokeController,
        builder: (_, __) => CustomPaint(
          painter: ExitGatePainter(pulse: _smokeController.value),
        ),
      ),
    );
  }

  CarModel? _findCar(String? id) {
    for (final item in widget.gameState.cars) {
      if (item.id == id) return item;
    }
    return null;
  }

  Widget _buildMoveGuide(double cellSize) {
    final car = _findCar(selectedCarId);
    if (car == null) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: MoveGuidePainter(
            car: car,
            cellSize: cellSize,
            negativeSteps: widget.gameState.maxMoveInDirection(car, -1).abs(),
            positiveSteps: widget.gameState.maxMoveInDirection(car, 1).abs(),
          ),
        ),
      ),
    );
  }

  Widget _buildDragTrail(double cellSize) {
    final car = _findCar(draggingCarId);
    if (car == null) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: DragTrailPainter(
            car: car,
            cellSize: cellSize,
            dragOffset: dragCurrentPos - dragStartPos,
          ),
        ),
      ),
    );
  }

  Widget _buildCar(CarModel car, double cellSize) {
    if (_isExiting && _exitingCar?.id == car.id) return const SizedBox.shrink();

    final isSelected = selectedCarId == car.id;
    final isDragging = draggingCarId == car.id;
    final isShaking = _shakingCarId == car.id;

    // animated position (for smooth drag)
    double animX = car.animX;
    double animY = car.animY;

    if (isDragging) {
      // Show fractional drag with hard clamping for a polished, physical feel.
      double rawOffset = dragCurrentPos - dragStartPos;
      // calculate max allowed in pixels
      int maxNeg = widget.gameState.maxMoveInDirection(car, -1);
      int maxPos = widget.gameState.maxMoveInDirection(car, 1);
      double minPx = maxNeg * cellSize.toDouble();
      double maxPx = maxPos * cellSize.toDouble();
      double clampedPx = rawOffset.clamp(minPx, maxPx).toDouble();

      if (car.isHorizontal) {
        animX = car.x + clampedPx / cellSize;
      } else {
        animY = car.y + clampedPx / cellSize;
      }
    }

    double left = animX * cellSize;
    double top = animY * cellSize;

    // shake offset
    double shakeOffset = 0;
    if (isShaking) {
      shakeOffset = math.sin(_shakeAnim.value * math.pi * 8) * 6 * (1 - _shakeAnim.value);
    }
    if (car.isHorizontal) {
      left += shakeOffset;
    } else {
      top += shakeOffset;
    }

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () {
          setState(() => selectedCarId = car.id);
          widget.onCarSelected(car);
        },
        onPanStart: (details) {
          setState(() {
            draggingCarId = car.id;
            selectedCarId = car.id;
            if (car.isHorizontal) {
              dragStartPos = details.globalPosition.dx;
            } else {
              dragStartPos = details.globalPosition.dy;
            }
            dragCurrentPos = dragStartPos;
          });
          SoundManager().startEngineSound();
          widget.onCarSelected(car);
        },
        onPanUpdate: (details) {
          if (draggingCarId != car.id) return;
          setState(() {
            if (car.isHorizontal) {
              dragCurrentPos = details.globalPosition.dx;
            } else {
              dragCurrentPos = details.globalPosition.dy;
            }
            // update wheel rotation based on drag distance
            double dist = (dragCurrentPos - dragStartPos).abs();
            wheelRotation = dist / (cellSize * 0.22 * math.pi) * 2 * math.pi;
          });
        },
        onPanEnd: (details) {
          if (draggingCarId != car.id) return;
          double deltaPx = dragCurrentPos - dragStartPos;
          int deltaCells = (deltaPx / cellSize).round();

          // check if drag was attempting to exit but blocked? For shake
          if (deltaCells == 0 && deltaPx.abs() > cellSize * 0.18) {
            // attempted move but blocked
            int dir = deltaPx > 0 ? 1 : -1;
            if (!widget.gameState.canMove(car, dir)) {
              _triggerShake(car.id);
            }
          }

          // try to move
          bool moved = false;
          if (deltaCells != 0) {
            // clamp to allowed range
            int maxNeg = widget.gameState.maxMoveInDirection(car, -1);
            int maxPos = widget.gameState.maxMoveInDirection(car, 1);
            deltaCells = deltaCells.clamp(maxNeg, maxPos).toInt();
            if (deltaCells != 0) {
              CarModel newCar = car.copyWith(
                x: car.isHorizontal ? car.x + deltaCells : car.x,
                y: car.isHorizontal ? car.y : car.y + deltaCells,
                animX: car.isHorizontal ? (car.x + deltaCells).toDouble() : car.animX,
                animY: car.isHorizontal ? car.animY : (car.y + deltaCells).toDouble(),
              );
              // check win condition for target car exiting
              if (newCar.isTarget && newCar.y == widget.gameState.level.exitRow) {
                // if moving out beyond
                if (newCar.x >= widget.gameState.level.gridSize - 1) {
                  // trigger exit animation
                  _triggerExit(newCar);
                  moved = true;
                } else if (newCar.x + newCar.length > widget.gameState.level.gridSize - 1 && widget.gameState.canMove(newCar, 1)) {
                  // at edge but can go one more -> actually allow exit in next drag? Instead check now if at winning pos and should exit
                  if (newCar.x == widget.gameState.level.gridSize - newCar.length) {
                    // This is winning position, auto exit after short delay
                    _triggerExit(newCar.copyWith(x: widget.gameState.level.gridSize));
                    moved = true;
                  } else {
                    widget.onCarMoved(newCar, deltaPx.abs());
                    moved = true;
                  }
                } else {
                  widget.onCarMoved(newCar, deltaPx.abs());
                  moved = true;
                }
              } else {
                widget.onCarMoved(newCar, deltaPx.abs());
                moved = true;
              }
            }
          }

          setState(() {
            draggingCarId = null;
            wheelRotation = 0;
            if (!moved) {
              // snap back animation already via anim values staying
            }
          });
          SoundManager().stopEngineSound();
          if (moved) {
            SoundManager().playCarSlide();
          }
        },
        child: CarWidget(
          car: car,
          cellSize: cellSize * 0.92,
          wheelRotation: isDragging ? wheelRotation : 0,
          isDragging: isDragging,
          isSelected: isSelected,
        ),
      ),
    );
  }

  void _triggerShake(String carId) {
    setState(() => _shakingCarId = carId);
    _shakeController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _shakingCarId = null);
    });
  }

  void _triggerExit(CarModel car) {
    setState(() {
      _isExiting = true;
      _exitingCar = car.copyWith(x: car.x, animX: car.x.toDouble());
      smokeParticles.clear();
    });
    _exitController.forward(from: 0).then((_) {
      widget.onWin();
    });
  }

  Widget _buildExitingCar(double cellSize) {
    return AnimatedBuilder(
      animation: _exitAnim,
      builder: (context, child) {
        double progress = _exitAnim.value;
        double eased = Curves.easeInCubic.transform(progress);
        double startX = (_exitingCar!.x - 1) * cellSize;
        double endX = (widget.gameState.level.gridSize + 2) * cellSize;
        double currentX = startX + (endX - startX) * eased;
        double currentY = _exitingCar!.y * cellSize + math.sin(progress * math.pi * 2) * 2; // slight wobble

        return Positioned(
          left: currentX,
          top: currentY,
          child: Opacity(
            opacity: 1 - progress * 0.3,
            child: CarWidget(
              car: _exitingCar!,
              cellSize: cellSize * 0.92,
              wheelRotation: progress * 20, // fast spin
              isDragging: false,
              isSelected: false,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSmoke(double cellSize) {
    if (smokeParticles.isEmpty) return const SizedBox.shrink();
    // Smoke originates near exit
    return Positioned.fill(
      child: CustomPaint(
        painter: TireSmokePainter(
          smokeParticles.map((p) {
            return Particle(
              position: Offset(
                (widget.gameState.level.gridSize * cellSize) - 20 + p.position.dx * 0.3,
                widget.gameState.level.exitRow * cellSize + cellSize / 2 + p.position.dy,
              ),
              velocity: p.velocity,
              size: p.size,
              color: p.color,
              life: p.life,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class ExitGatePainter extends CustomPainter {
  final double pulse;

  ExitGatePainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    // Classic Rush Hour exit glow
    final glow = Paint()
      ..color = AppTheme.accent.withOpacity(0.24 + math.sin(pulse * math.pi * 2).abs() * 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11);
    canvas.drawRect(Offset.zero & size, glow);

    // Metallic exit gate frame
    final gatePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.96),
          const Color(0xFFE8EEF5).withOpacity(0.6),
          Colors.white.withOpacity(0.28),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.width * 0.32)), gatePaint);

    // Classic chevrons (exit arrows)
    final chevron = Paint()
      ..color = AppTheme.accent.withOpacity(0.92)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final y = size.height * (0.22 + i * 0.26);
      final path = Path()
        ..moveTo(size.width * 0.18, y - size.height * 0.1)
        ..lineTo(size.width * 0.68, y)
        ..lineTo(size.width * 0.18, y + size.height * 0.1);
      canvas.drawPath(path, chevron);
    }

    // Side barrier lines (classic look)
    final barrier = Paint()
      ..color = const Color(0xFF0F1A28).withOpacity(0.75)
      ..strokeWidth = 1.8;
    canvas.drawLine(Offset(size.width * 0.06, 0), Offset(size.width * 0.06, size.height), barrier);
    canvas.drawLine(Offset(size.width * 0.94, 0), Offset(size.width * 0.94, size.height), barrier);

    // Exit label
    final label = TextPainter(
      text: const TextSpan(
        text: 'EXIT',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset(size.width / 2 - label.width / 2, size.height * 0.38));
  }

  @override
  bool shouldRepaint(covariant ExitGatePainter oldDelegate) => oldDelegate.pulse != pulse;
}

class ClassicRushHourBoardPainter extends CustomPainter {
  final int gridSize;
  ClassicRushHourBoardPainter({required this.gridSize});

  @override
  void paint(Canvas canvas, Size size) {
    final double cell = size.width / gridSize;
    final rand = math.Random(7);

    // Deep classic asphalt base
    final base = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF1F2A3A),
          const Color(0xFF2C3E50),
          const Color(0xFF1A2633),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);

    // Classic concrete border frame
    final borderPaint = Paint()
      ..color = const Color(0xFF455A6A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.18;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(cell * 0.3)),
      borderPaint,
    );

    // Inner concrete rim
    final innerBorder = Paint()
      ..color = const Color(0xFF334455)
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.08;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cell * 0.1, cell * 0.1, size.width - cell * 0.2, size.height - cell * 0.2),
        Radius.circular(cell * 0.22),
      ),
      innerBorder,
    );

    // Classic parking lot texture + wear
    final wearPaint = Paint()..color = Colors.black.withOpacity(0.13);
    for (int i = 0; i < 18; i++) {
      final cx = rand.nextDouble() * size.width;
      final cy = rand.nextDouble() * size.height;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: 18 + rand.nextDouble() * 52, height: 8 + rand.nextDouble() * 18),
        wearPaint,
      );
    }

    // Subtle asphalt grain
    final grain = Paint()..color = Colors.white.withOpacity(0.025);
    for (int i = 0; i < 240; i++) {
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 1.1, grain);
    }

    // Classic white road lines (Rush Hour style)
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.16)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    for (double y = cell * 0.5; y < size.height; y += cell * 1.05) {
      canvas.drawLine(Offset(cell * 0.15, y), Offset(cell * 0.48, y), linePaint);
      canvas.drawLine(Offset(size.width * 0.52, y), Offset(size.width * 0.85, y), linePaint);
    }

    // Yellow center divider line (classic rush hour feel)
    final yellowLine = Paint()
      ..color = AppTheme.accent.withOpacity(0.35)
      ..strokeWidth = 2.2;
    canvas.drawLine(Offset(cell * 0.5, cell * 1.1), Offset(cell * 0.5, size.height - cell * 1.1), yellowLine);

    // Parking bay dashed borders (perfect classic style)
    final bayBorder = Paint()
      ..color = Colors.white.withOpacity(0.26)
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.square;

    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (x == gridSize - 1 && y == 2) continue; // leave exit gap

        final left = x * cell;
        final top = y * cell;
        final m = cell * 0.18;

        // Top left corner
        canvas.drawLine(Offset(left, top), Offset(left, top + m), bayBorder);
        canvas.drawLine(Offset(left, top), Offset(left + m, top), bayBorder);

        // Top right corner
        canvas.drawLine(Offset(left + cell, top), Offset(left + cell - m, top), bayBorder);
        canvas.drawLine(Offset(left + cell, top), Offset(left + cell, top + m), bayBorder);

        // Bottom left
        canvas.drawLine(Offset(left, top + cell), Offset(left, top + cell - m), bayBorder);
        canvas.drawLine(Offset(left, top + cell), Offset(left + m, top + cell), bayBorder);

        // Bottom right
        canvas.drawLine(Offset(left + cell, top + cell), Offset(left + cell, top + cell - m), bayBorder);
        canvas.drawLine(Offset(left + cell, top + cell), Offset(left + cell - m, top + cell), bayBorder);
      }
    }

    // Parking bay labels (A1, B3, etc.)
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (x == gridSize - 1 && y == 2) continue;

        final bayText = TextPainter(
          text: TextSpan(
            text: '${String.fromCharCode(65 + y)}${x + 1}',
            style: TextStyle(
              fontSize: cell * 0.105,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.11),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        bayText.paint(canvas, Offset(x * cell + cell * 0.09, y * cell + cell * 0.78));
      }
    }

    // Exit zone highlight (Classic Rush Hour style)
    final exitRect = Rect.fromLTWH((gridSize - 1) * cell, 2 * cell, cell, cell);
    final exitGlow = Paint()
      ..color = AppTheme.accent.withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRect(exitRect.inflate(2), exitGlow);

    // Exit lane arrows
    final arrowPaint = Paint()
      ..color = AppTheme.accent.withOpacity(0.85)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final exitY = 2 * cell + cell * 0.5;
    for (int i = 0; i < 3; i++) {
      final ax = (gridSize - 0.72 + i * 0.23) * cell;
      final path = Path()
        ..moveTo(ax, exitY - cell * 0.13)
        ..lineTo(ax + cell * 0.16, exitY)
        ..lineTo(ax, exitY + cell * 0.13);
      canvas.drawPath(path, arrowPaint);
    }

    // Final polished border
    final outerFrame = Paint()
      ..color = Colors.white.withOpacity(0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(cell * 0.3)),
      outerFrame,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GridPainter extends CustomPainter {
  final double cellSize;
  final int gridSize;
  GridPainter({required this.cellSize, required this.gridSize});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Classic grid lines
    for (int i = 0; i <= gridSize; i++) {
      double pos = i * cellSize;
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), linePaint);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), linePaint);
    }

    // Classic Rush Hour parking lines + dashed borders
    final dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.22)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final thickBorder = Paint()
      ..color = Colors.white.withOpacity(0.16)
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke;

    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (x == gridSize - 1 && y == 2) continue; // exit gap

        double left = x * cellSize;
        double top = y * cellSize;
        double l = cellSize * 0.16;

        // Classic parking bay lines
        canvas.drawLine(Offset(left, top), Offset(left, top + l), dashPaint);
        canvas.drawLine(Offset(left, top), Offset(left + l, top), dashPaint);

        canvas.drawLine(Offset(left + cellSize, top), Offset(left + cellSize - l, top), dashPaint);
        canvas.drawLine(Offset(left + cellSize, top), Offset(left + cellSize, top + l), dashPaint);

        canvas.drawLine(Offset(left, top + cellSize), Offset(left + l, top + cellSize), dashPaint);
        canvas.drawLine(Offset(left, top + cellSize), Offset(left, top + cellSize - l), dashPaint);

        canvas.drawLine(Offset(left + cellSize, top + cellSize), Offset(left + cellSize - l, top + cellSize), dashPaint);
        canvas.drawLine(Offset(left + cellSize, top + cellSize), Offset(left + cellSize, top + cellSize - l), dashPaint);

        // Parking spot labels
        final bayText = TextPainter(
          text: TextSpan(
            text: '${String.fromCharCode(65 + y)}${x + 1}',
            style: TextStyle(fontSize: cellSize * 0.105, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.09)),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        bayText.paint(canvas, Offset(left + cellSize * 0.09, top + cellSize * 0.76));
      }
    }

    // Exit lane highlight (Classic Rush Hour style)
    final exitY = 2 * cellSize;
    final exitLane = Paint()
      ..color = AppTheme.accent.withOpacity(0.11)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH((gridSize - 1) * cellSize, exitY, cellSize, cellSize), exitLane);

    // Exit arrows
    final exitPaint = Paint()
      ..color = AppTheme.accent.withOpacity(0.75)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    final exitCenterY = exitY + cellSize / 2;
    for (int i = 0; i < 4; i++) {
      final x = cellSize * (gridSize - 0.78 + i * 0.18);
      final path = Path()
        ..moveTo(x, exitCenterY - cellSize * 0.12)
        ..lineTo(x + cellSize * 0.18, exitCenterY)
        ..lineTo(x, exitCenterY + cellSize * 0.12);
      canvas.drawPath(path, exitPaint);
    }

    // Stop line
    final stopPaint = Paint()
      ..color = Colors.white.withOpacity(0.24)
      ..strokeWidth = 2.2;
    canvas.drawLine(
      Offset(cellSize * (gridSize - 0.85), 2 * cellSize + cellSize * 0.18),
      Offset(cellSize * (gridSize - 0.85), 3 * cellSize - cellSize * 0.18),
      stopPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MoveGuidePainter extends CustomPainter {
  final CarModel car;
  final double cellSize;
  final int negativeSteps;
  final int positiveSteps;

  MoveGuidePainter({required this.car, required this.cellSize, required this.negativeSteps, required this.positiveSteps});

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = AppTheme.secondary.withOpacity(0.14)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = AppTheme.secondary.withOpacity(0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final arrowPaint = Paint()
      ..color = AppTheme.accent.withOpacity(0.85)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    void drawCell(int x, int y) {
      final rect = Rect.fromLTWH(x * cellSize + cellSize * 0.10, y * cellSize + cellSize * 0.10, cellSize * 0.80, cellSize * 0.80);
      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cellSize * 0.16));
      canvas.drawRRect(rrect, guidePaint);
      canvas.drawRRect(rrect, borderPaint);
    }

    if (car.isHorizontal) {
      for (int step = 1; step <= negativeSteps; step++) {
        drawCell(car.x - step, car.y);
      }
      for (int step = 1; step <= positiveSteps; step++) {
        drawCell(car.x + car.length - 1 + step, car.y);
      }
      _drawGuideArrow(canvas, Offset((car.x - negativeSteps + 0.35) * cellSize, (car.y + 0.5) * cellSize), false, arrowPaint);
      _drawGuideArrow(canvas, Offset((car.x + car.length + positiveSteps - 0.35) * cellSize, (car.y + 0.5) * cellSize), true, arrowPaint);
    } else {
      for (int step = 1; step <= negativeSteps; step++) {
        drawCell(car.x, car.y - step);
      }
      for (int step = 1; step <= positiveSteps; step++) {
        drawCell(car.x, car.y + car.length - 1 + step);
      }
      _drawGuideArrow(canvas, Offset((car.x + 0.5) * cellSize, (car.y - negativeSteps + 0.35) * cellSize), false, arrowPaint, vertical: true);
      _drawGuideArrow(canvas, Offset((car.x + 0.5) * cellSize, (car.y + car.length + positiveSteps - 0.35) * cellSize), true, arrowPaint, vertical: true);
    }
  }

  void _drawGuideArrow(Canvas canvas, Offset center, bool positive, Paint paint, {bool vertical = false}) {
    if ((positive ? positiveSteps : negativeSteps) <= 0) return;
    final size = cellSize * 0.12;
    final path = Path();
    if (!vertical) {
      final dir = positive ? 1 : -1;
      path.moveTo(center.dx - dir * size, center.dy - size);
      path.lineTo(center.dx + dir * size, center.dy);
      path.lineTo(center.dx - dir * size, center.dy + size);
    } else {
      final dir = positive ? 1 : -1;
      path.moveTo(center.dx - size, center.dy - dir * size);
      path.lineTo(center.dx, center.dy + dir * size);
      path.lineTo(center.dx + size, center.dy - dir * size);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant MoveGuidePainter oldDelegate) {
    return oldDelegate.car != car || oldDelegate.negativeSteps != negativeSteps || oldDelegate.positiveSteps != positiveSteps;
  }
}

class DragTrailPainter extends CustomPainter {
  final CarModel car;
  final double cellSize;
  final double dragOffset;

  DragTrailPainter({required this.car, required this.cellSize, required this.dragOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final direction = dragOffset == 0 ? 1.0 : dragOffset.sign;
    final speed = (dragOffset.abs() / cellSize).clamp(0.0, 1.0).toDouble();
    final paint = Paint()
      ..shader = LinearGradient(
        begin: car.isHorizontal ? (direction > 0 ? Alignment.centerLeft : Alignment.centerRight) : Alignment.topCenter,
        end: car.isHorizontal ? (direction > 0 ? Alignment.centerRight : Alignment.centerLeft) : Alignment.bottomCenter,
        colors: [AppTheme.secondary.withOpacity(0.0), AppTheme.secondary.withOpacity(0.28 * speed)],
      ).createShader(Offset.zero & size)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final baseX = car.x * cellSize + (car.isHorizontal ? 0 : cellSize / 2);
    final baseY = car.y * cellSize + (car.isHorizontal ? cellSize / 2 : 0);
    for (int i = 0; i < 6; i++) {
      final offset = (i + 1) * cellSize * 0.18;
      if (car.isHorizontal) {
        final y = baseY + (i - 2.5) * 4;
        final start = Offset(baseX - direction * offset, y);
        final end = Offset(baseX - direction * (offset + 22 + speed * 32), y);
        canvas.drawLine(start, end, paint);
      } else {
        final x = baseX + (i - 2.5) * 4;
        final start = Offset(x, baseY - direction * offset);
        final end = Offset(x, baseY - direction * (offset + 22 + speed * 32));
        canvas.drawLine(start, end, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DragTrailPainter oldDelegate) => oldDelegate.dragOffset != dragOffset;
}
