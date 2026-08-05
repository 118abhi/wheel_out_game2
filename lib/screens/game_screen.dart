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
  bool _showPause = false;
  late int _hintCount;
  bool _showingHint = false;
  CarModel? _hintCar;
  CarModel? _selectedCar;
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
        _showPause = false;
        _selectedCar = null;
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
      _selectedCar = newCar;
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
      _selectedCar = null;
    });
  }

  void _reset() {
    setState(() {
      _gameState = GameState(level: widget.level, cars: _initialState.cars.map((c) => c.clone()).toList(), moves: 0, history: []);
      _selectedCar = null;
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
                        const SizedBox(width: 6),
                        IconButton(
                          onPressed: () => setState(() => _showPause = true),
                          icon: const Icon(Icons.pause_rounded),
                          style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.08)),
                        ),
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
                                onCarSelected: (car) => setState(() {
                                  _selectedCar = car;
                                  _showingHint = false;
                                }),
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
              if (_showPause)
                _PauseOverlay(
                  level: widget.level,
                  moves: _gameState.moves,
                  hints: _hintCount,
                  coins: widget.coins,
                  selectedCar: _selectedCar,
                  onResume: () => setState(() => _showPause = false),
                  onRestart: () {
                    setState(() => _showPause = false);
                    _reset();
                  },
                  onLevelSelect: widget.onBack,
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
    final selected = _selectedCar;
    final sensorText = selected == null
        ? 'Tap a car for parking sensors'
        : 'Sensor ${selected.id}: ${_gameState.maxMoveInDirection(selected, -1).abs()} back • ${_gameState.maxMoveInDirection(selected, 1).abs()} forward';
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
            Icon(Icons.sensors_rounded, color: Colors.white.withOpacity(0.45), size: 16),
            const SizedBox(width: 4),
            Flexible(
              child: Text(sensorText, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.52))),
            ),
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

class _PauseOverlay extends StatelessWidget {
  final GameLevel level;
  final int moves;
  final int hints;
  final int coins;
  final CarModel? selectedCar;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onLevelSelect;

  const _PauseOverlay({
    required this.level,
    required this.moves,
    required this.hints,
    required this.coins,
    required this.selectedCar,
    required this.onResume,
    required this.onRestart,
    required this.onLevelSelect,
  });

  @override
  Widget build(BuildContext context) {
    final starForecast = moves <= level.parMoves ? 3 : moves <= level.parMoves + 4 ? 2 : 1;
    return Positioned.fill(
      child: Material(
        color: Colors.black.withOpacity(0.76),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppTheme.surface, AppTheme.surfaceLight]),
                  border: Border.all(color: Colors.white.withOpacity(0.14)),
                  boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.28), blurRadius: 30, offset: const Offset(0, 14))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.secondary])),
                          child: const Icon(Icons.pause_rounded, color: Colors.white, size: 34),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('GAME PAUSED', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.white)),
                              Text('Level ${level.id} • ${level.name}', style: TextStyle(color: Colors.white.withOpacity(0.58), fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(child: _PauseStat(icon: Icons.directions_car_rounded, label: 'Moves', value: '$moves', color: AppTheme.secondary)),
                        const SizedBox(width: 10),
                        Expanded(child: _PauseStat(icon: Icons.star_rounded, label: 'Forecast', value: '$starForecast★', color: AppTheme.accent)),
                        const SizedBox(width: 10),
                        Expanded(child: _PauseStat(icon: Icons.lightbulb_rounded, label: 'Hints', value: '$hints', color: AppTheme.danger)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _PauseSection(
                      title: 'Live Objectives',
                      items: [
                        _PauseItem(icon: Icons.exit_to_app_rounded, text: 'Free the target car through the glowing exit gate.', done: false),
                        _PauseItem(icon: Icons.speed_rounded, text: 'Beat par ${level.parMoves} for 3 stars. Current forecast: $starForecast stars.', done: moves <= level.parMoves),
                        _PauseItem(icon: Icons.sensors_rounded, text: selectedCar == null ? 'Tap any car to enable parking sensor move guides.' : 'Selected ${selectedCar!.id}: guide lanes show legal movement cells.', done: selectedCar != null),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _PauseSection(
                      title: 'Pro Controls',
                      items: const [
                        _PauseItem(icon: Icons.swipe_rounded, text: 'Drag vehicles only along their natural direction.', done: true),
                        _PauseItem(icon: Icons.undo_rounded, text: 'Use undo for safe experimentation.', done: true),
                        _PauseItem(icon: Icons.toll_rounded, text: 'Coins and hints are saved in your driver profile.', done: true),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(child: _PauseButton(label: 'LEVELS', icon: Icons.grid_view_rounded, onTap: onLevelSelect, secondary: true)),
                        const SizedBox(width: 10),
                        Expanded(child: _PauseButton(label: 'RESTART', icon: Icons.refresh_rounded, onTap: onRestart, secondary: true)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _PauseButton(label: 'RESUME DRIVE', icon: Icons.play_arrow_rounded, onTap: onResume),
                    const SizedBox(height: 10),
                    Center(child: Text('$coins coins available', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.45)))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PauseStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _PauseStat({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.25))),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w900)),
        Text(label.toUpperCase(), style: TextStyle(fontSize: 9, letterSpacing: 0.8, color: Colors.white.withOpacity(0.48))),
      ]),
    );
  }
}

class _PauseSection extends StatelessWidget {
  final String title;
  final List<_PauseItem> items;

  const _PauseSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.055), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.08))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppTheme.accent)),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(item.done ? Icons.check_circle_rounded : item.icon, color: item.done ? AppTheme.secondary : Colors.white54, size: 18),
                    const SizedBox(width: 9),
                    Expanded(child: Text(item.text, style: TextStyle(fontSize: 12, height: 1.25, color: Colors.white.withOpacity(0.68)))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _PauseItem {
  final IconData icon;
  final String text;
  final bool done;

  const _PauseItem({required this.icon, required this.text, required this.done});
}

class _PauseButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool secondary;

  const _PauseButton({required this.label, required this.icon, required this.onTap, this.secondary = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: secondary ? null : const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
          color: secondary ? Colors.white.withOpacity(0.08) : null,
          borderRadius: BorderRadius.circular(15),
          border: secondary ? Border.all(color: Colors.white.withOpacity(0.14)) : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 7),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
        ]),
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
