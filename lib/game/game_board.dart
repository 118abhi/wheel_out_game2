import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/car.dart';
import '../models/level.dart';
import '../theme/app_theme.dart';
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
  int dragStartCarPos = 0; // x or y
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.asphalt,
            AppTheme.asphalt.withOpacity(0.9),
            const Color(0xFF34495E),
          ],
        ),
      ),
      child: CustomPaint(
        size: Size(boardSize, boardSize),
        painter: AsphaltPainter(),
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
      left: boardSize - cellSize * 0.15,
      top: exitRow * cellSize,
      width: cellSize * 0.15,
      height: cellSize,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.4)],
          ),
          boxShadow: [
            BoxShadow(color: AppTheme.accent.withOpacity(0.6), blurRadius: 12, spreadRadius: 2),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_forward, color: AppTheme.accent, size: cellSize * 0.4),
            Container(height: 4, width: cellSize * 0.6, color: AppTheme.accent),
          ],
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
      double deltaCells = (dragCurrentPos - dragStartPos) / cellSize;
      int wholeDelta = deltaCells.round(); // for clamping visualization we use raw delta too
      // But we show fractional drag with clamping
      double rawOffset = dragCurrentPos - dragStartPos;
      // calculate max allowed in pixels
      int maxNeg = widget.gameState.maxMoveInDirection(car, -1);
      int maxPos = widget.gameState.maxMoveInDirection(car, 1);
      double minPx = maxNeg * cellSize.toDouble();
      double maxPx = maxPos * cellSize.toDouble();
      double clampedPx = rawOffset.clamp(minPx, maxPx);

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
            dragStartCarPos = car.isHorizontal ? car.x : car.y;
          });
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
            deltaCells = deltaCells.clamp(maxNeg, maxPos);
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

class AsphaltPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.04);
    final rand = math.Random(42);
    for (int i = 0; i < 80; i++) {
      double x = rand.nextDouble() * size.width;
      double y = rand.nextDouble() * size.height;
      double r = rand.nextDouble() * 1.5;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
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
      ..color = Colors.white.withOpacity(0.07)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= gridSize; i++) {
      double pos = i * cellSize;
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), linePaint);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), linePaint);
    }

    // parking spots dashed
    final dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // draw inner lot marks
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (x == gridSize - 1 && y == 2) continue; // exit
        // small L corners
        double l = cellSize * 0.12;
        double left = x * cellSize;
        double top = y * cellSize;

        // top-left
        canvas.drawLine(Offset(left, top + l), Offset(left, top), dashPaint);
        canvas.drawLine(Offset(left, top), Offset(left + l, top), dashPaint);
        // top-right
        canvas.drawLine(Offset(left + cellSize - l, top), Offset(left + cellSize, top), dashPaint);
        canvas.drawLine(Offset(left + cellSize, top), Offset(left + cellSize, top + l), dashPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
