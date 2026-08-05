import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../models/level.dart';
import '../models/car.dart';
import '../game/game_board.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_parking_background.dart';
import 'win_screen.dart';

class GameScreen extends StatefulWidget {
  final GameLevel level;
  final int hints;
  final int coins;
  final int totalLevels;
  final int selectedSkin;
  final VoidCallback onBack;
  final VoidCallback onHintUsed;
  final Function(int nextLevelId) onNextLevel;
  final Function(int stars, int moves) onLevelComplete;

  const GameScreen({
    super.key,
    required this.level,
    required this.hints,
    required this.coins,
    required this.totalLevels,
    required this.selectedSkin,
    required this.onBack,
    required this.onHintUsed,
    required this.onNextLevel,
    required this.onLevelComplete,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GameState _gameState;
  late GameState _initialState;
  late AnimationController _hintController;
  late Animation<double> _hintPulse;
  bool _showWin = false;
  late int _hintCount;
  bool _showingHint = false;
  CarModel? _hintCar;
  int? _hintDelta;

  late AnimationController _boardScaleController;
  late Animation<double> _boardScale;

  @override
  void initState() {
    super.initState();
    _gameState = GameState(level: widget.level, cars: _levelCars());
    _initialState = _gameState.copyWith();
    _hintCount = widget.hints;

    _hintController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _hintPulse = Tween<double>(begin: 0.9, end: 1.1).animate(CurvedAnimation(parent: _hintController, curve: Curves.easeInOut));

    _boardScaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _boardScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.05).chain(CurveTween(curve: Curves.easeOut)), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 40),
    ]).animate(_boardScaleController);
    _boardScaleController.forward();
  }

  @override
  void didUpdateWidget(covariant GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level.id != widget.level.id || oldWidget.selectedSkin != widget.selectedSkin) {
      setState(() {
        _gameState = GameState(level: widget.level, cars: _levelCars());
        _initialState = _gameState.copyWith();
        _hintCount = widget.hints;
        _showWin = false;
      });
      _boardScaleController.forward(from: 0);
    } else if (oldWidget.hints != widget.hints) {
      setState(() => _hintCount = widget.hints);
    }
  }

  List<CarModel> _levelCars() => widget.level.cars.map(_applySelectedSkin).toList();

  CarModel _applySelectedSkin(CarModel car) {
    if (!car.isTarget) return car.clone();
    final skins = [
      (AppTheme.targetRed, AppTheme.targetRedDark),
      (AppTheme.primary, const Color(0xFF3B2DB7)),
      (AppTheme.accent, const Color(0xFFE1A600)),
      (AppTheme.secondary, const Color(0xFF008B88)),
    ];
    final skin = skins[widget.selectedSkin % skins.length];
    return CarModel(
      id: car.id,
      x: car.x,
      y: car.y,
      length: car.length,
      orientation: car.orientation,
      isTarget: true,
      color: skin.$1,
      darkColor: skin.$2,
    )..animX = car.animX
     ..animY = car.animY;
  }

  @override
  void dispose() {
    _hintController.dispose();
    _boardScaleController.dispose();
    super.dispose();
  }

  void _onCarMoved(CarModel newCar, double _) {
    // update state
    List<CarModel> newCars = _gameState.cars.map((c) => c.id == newCar.id ? newCar : c.clone()).toList();
    List<List<CarModel>> newHistory = [..._gameState.history, _gameState.cars.map((c) => c.clone()).toList()];
    setState(() {
      _gameState = _gameState.copyWith(cars: newCars, moves: _gameState.moves + 1, history: newHistory);
      _showingHint = false;
    });
    HapticFeedback.selectionClick();

    if (_gameState.isSpecificallyWon()) {
      // slight delay before win show to allow exit anim? Actually GameBoard will trigger onWin when exiting
    }
  }

  void _onWin() {
    if (_showWin) return;
    int stars = 1;
    if (_gameState.moves <= widget.level.parMoves) stars = 3;
    else if (_gameState.moves <= widget.level.parMoves + 4) stars = 2;

    HapticFeedback.heavyImpact();
    widget.onLevelComplete(stars, _gameState.moves);
    setState(() => _showWin = true);
  }

  void _undo() {
    if (_gameState.history.isEmpty) return;
    var prev = _gameState.history.last;
    var newHist = List<List<CarModel>>.from(_gameState.history)..removeLast();
    setState(() {
      _gameState = _gameState.copyWith(cars: prev.map((c) => c.clone()).toList(), moves: math.max(0, _gameState.moves - 1), history: newHist);
    });
  }

  void _reset() {
    setState(() {
      _gameState = GameState(level: widget.level, cars: _initialState.cars.map((c) => c.clone()).toList(), moves: 0, history: []);
      _showingHint = false;
    });
    _boardScaleController.forward(from: 0);
  }

  void _showHint() {
    if (_hintCount <= 0 || _showingHint) return;
    // simple hint: find a car that is blocking target's path and can move
    var target = _gameState.cars.firstWhere((c) => c.isTarget);
    var grid = _gameState.occupiedGrid();
    // find blocking car in same row between target and exit
    for (int x = target.x + target.length; x < _gameState.level.gridSize; x++) {
      if (grid[target.y][x]) {
        // find which car occupies x,target.y
        for (var car in _gameState.cars) {
          if (car.isTarget) continue;
          for (var p in car.occupiedCells()) {
            if (p.x == x && p.y == target.y) {
              // try to move it away
              int maxNeg = _gameState.maxMoveInDirection(car, -1);
              int maxPos = _gameState.maxMoveInDirection(car, 1);
              if (maxNeg != 0 || maxPos != 0) {
                setState(() {
                  _hintCar = car;
                  _hintDelta = maxNeg != 0 ? maxNeg : maxPos;
                  _showingHint = true;
                  _hintCount--;
                });
                widget.onHintUsed();
                HapticFeedback.lightImpact();
                return;
              }
            }
          }
        }
      }
    }
    // fallback: random movable car
    for (var car in _gameState.cars) {
      if (car.isTarget) continue;
      int maxNeg = _gameState.maxMoveInDirection(car, -1);
      int maxPos = _gameState.maxMoveInDirection(car, 1);
      if (maxNeg != 0 || maxPos != 0) {
        setState(() {
          _hintCar = car;
          _hintDelta = maxNeg != 0 ? maxNeg : maxPos;
          _showingHint = true;
          _hintCount--;
        });
        widget.onHintUsed();
        HapticFeedback.lightImpact();
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            showRoad: false,
            intensity: 0.45,
            child: Stack(
              children: [
              Column(
                children: [
                  // top bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: widget.onBack,
                          icon: const Icon(Icons.arrow_back_rounded),
                          style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("LEVEL ${widget.level.id} • ${widget.level.name.toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.flag_rounded, size: 14, color: Colors.white.withOpacity(0.5)),
                                  const SizedBox(width: 4),
                                  Text("Par ${widget.level.parMoves}", style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5))),
                                  const SizedBox(width: 12),
                                  Icon(Icons.directions_car_rounded, size: 14, color: Colors.white.withOpacity(0.5)),
                                  const SizedBox(width: 4),
                                  Text("${_gameState.moves} moves", style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7))),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _MiniWallet(icon: Icons.toll_rounded, value: '${widget.coins}', color: AppTheme.accent),
                        const SizedBox(width: 6),
                        IconButton(onPressed: _undo, icon: const Icon(Icons.undo_rounded), style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.08))),
                        const SizedBox(width: 6),
                        IconButton(onPressed: _reset, icon: const Icon(Icons.refresh_rounded), style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.08))),
                      ],
                    ),
                  ),
                  // progress bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (widget.level.parMoves > 0) ? (_gameState.moves / (widget.level.parMoves * 1.8)).clamp(0, 1).toDouble() : 0,
                        backgroundColor: Colors.white.withOpacity(0.08),
                        valueColor: AlwaysStoppedAnimation(_gameState.moves <= widget.level.parMoves ? AppTheme.secondary : _gameState.moves <= widget.level.parMoves + 5 ? AppTheme.accent : AppTheme.danger),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  _buildMissionStrip(),
                  const SizedBox(height: 8),
                  // board area
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: ScaleTransition(
                          scale: _boardScale,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              GameBoardWidget(
                                gameState: _gameState,
                                onCarMoved: _onCarMoved,
                                onWin: _onWin,
                                onCarSelected: (_) => setState(() => _showingHint = false),
                              ),
                              if (_showingHint && _hintCar != null)
                                _buildHintOverlay(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // bottom controls
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: _BottomButton(
                            label: "HINT ($_hintCount)",
                            icon: Icons.lightbulb_rounded,
                            color: AppTheme.accent,
                            onTap: _showHint,
                            enabled: _hintCount > 0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _BottomButton(
                            label: "EXIT WHEEL",
                            icon: Icons.exit_to_app_rounded,
                            color: AppTheme.primary,
                            onTap: () {
                              // try to force exit if possible
                              var target = _gameState.cars.firstWhere((c) => c.isTarget);
                              if (target.x == _gameState.level.gridSize - target.length) {
                                _onWin();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_showWin)
                WinScreen(
                  levelId: widget.level.id,
                  totalLevels: widget.totalLevels,
                  moves: _gameState.moves,
                  par: widget.level.parMoves,
                  isPerfect: _gameState.moves <= widget.level.parMoves,
                  onNext: () {
                    setState(() => _showWin = false);
                    widget.onNextLevel(widget.level.id + 1);
                  },
                  onMenu: widget.onBack,
                  onReplay: () {
                    setState(() => _showWin = false);
                    _reset();
                  },
                ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildMissionStrip() {
    final movesLeft = math.max(0, widget.level.parMoves - _gameState.moves);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.065),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.09)),
        ),
        child: Row(
          children: [
            const Icon(Icons.route_rounded, color: AppTheme.secondary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                movesLeft > 0 ? 'Mission: clear the exit in $movesLeft moves for 3 stars' : 'Mission: finish the escape and protect your streak',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.70), fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.cloud_rounded, color: Colors.white.withOpacity(0.45), size: 16),
            const SizedBox(width: 4),
            Text('Night lot', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.48))),
          ],
        ),
      ),
    );
  }

  Widget _buildHintOverlay() {
    if (_hintCar == null) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _hintPulse,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black.withOpacity(0.2),
              ),
              child: CustomPaint(
                painter: _HintPainter(
                  hintCar: _hintCar!,
                  delta: _hintDelta ?? 1,
                  gridSize: widget.level.gridSize,
                  pulse: _hintPulse.value,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MiniWallet extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _MiniWallet({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
        ],
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;
  const _BottomButton({required this.label, required this.icon, required this.color, required this.onTap, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HintPainter extends CustomPainter {
  final CarModel hintCar;
  final int delta;
  final int gridSize;
  final double pulse;
  _HintPainter({required this.hintCar, required this.delta, required this.gridSize, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    double cellSize = size.width / gridSize;
    double left = hintCar.x * cellSize;
    double top = hintCar.y * cellSize;
    double width = hintCar.isHorizontal ? cellSize * hintCar.length : cellSize;
    double height = hintCar.isHorizontal ? cellSize : cellSize * hintCar.length;

    final paint = Paint()
      ..color = AppTheme.accent.withOpacity(0.7 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final glowPaint = Paint()
      ..color = AppTheme.accent.withOpacity(0.25 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    RRect rrect = RRect.fromRectAndRadius(Rect.fromLTWH(left, top, width, height), Radius.circular(cellSize * 0.22));

    canvas.drawRRect(rrect, glowPaint);
    canvas.drawRRect(rrect, paint);

    // arrow
    final arrowPaint = Paint()..color = AppTheme.accent;
    double arrowX, arrowY;
    if (hintCar.isHorizontal) {
      arrowX = delta > 0 ? left + width + 6 : left - 18;
      arrowY = top + height / 2;
      Path path = Path();
      if (delta > 0) {
        path.moveTo(arrowX, arrowY);
        path.lineTo(arrowX + 12, arrowY - 7);
        path.lineTo(arrowX + 12, arrowY + 7);
      } else {
        path.moveTo(arrowX, arrowY);
        path.lineTo(arrowX - 12, arrowY - 7);
        path.lineTo(arrowX - 12, arrowY + 7);
      }
      path.close();
      canvas.drawPath(path, arrowPaint);
    } else {
      arrowX = left + width / 2;
      arrowY = delta > 0 ? top + height + 6 : top - 18;
      Path path = Path();
      if (delta > 0) {
        path.moveTo(arrowX, arrowY);
        path.lineTo(arrowX - 7, arrowY + 12);
        path.lineTo(arrowX + 7, arrowY + 12);
      } else {
        path.moveTo(arrowX, arrowY);
        path.lineTo(arrowX - 7, arrowY - 12);
        path.lineTo(arrowX + 7, arrowY - 12);
      }
      path.close();
      canvas.drawPath(path, arrowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HintPainter oldDelegate) => oldDelegate.pulse != pulse;
}
