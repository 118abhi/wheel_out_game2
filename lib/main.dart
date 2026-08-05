import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/level_select_screen.dart';
import 'screens/game_screen.dart';
import 'screens/wheel_reward_screen.dart';
import 'utils/levels_data.dart';
import 'models/level.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const WheelOutApp());
}

class WheelOutApp extends StatelessWidget {
  const WheelOutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wheel Out - Parking Puzzle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppNavigator(),
    );
  }
}

enum AppScreen { splash, home, levels, game, reward }

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> with TickerProviderStateMixin {
  AppScreen _current = AppScreen.splash;
  int _currentLevelId = 1;
  int _unlockedLevel = 1;
  int _coins = 0;
  int _hints = 3;
  Map<int, int> _levelStars = {}; // levelId -> stars
  late AnimationController _transitionController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _transitionController, curve: Curves.easeOut));
    _transitionController.forward();
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  void _navigateTo(AppScreen screen) async {
    await _transitionController.reverse();
    setState(() => _current = screen);
    _transitionController.forward();
  }

  GameLevel _getLevel(int id) {
    var levels = LevelsRepository.allLevels;
    return levels.firstWhere((l) => l.id == id, orElse: () => levels.first);
  }

  void _onLevelComplete(int stars) {
    setState(() {
      _levelStars[_currentLevelId] = math.max(_levelStars[_currentLevelId] ?? 0, stars);
      if (_currentLevelId >= _unlockedLevel && _currentLevelId < 30) {
        _unlockedLevel = _currentLevelId + 1;
      }
      _coins += stars * 10 + (_currentLevelId <= 3 ? 5 : 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: _buildCurrentScreen(),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_current) {
      case AppScreen.splash:
        return SplashScreen(onFinish: () => _navigateTo(AppScreen.home));
      case AppScreen.home:
        return HomeScreen(
          onPlay: () {
            setState(() => _currentLevelId = _unlockedLevel.clamp(1, 30));
            _navigateTo(AppScreen.game);
          },
          onLevels: () => _navigateTo(AppScreen.levels),
        );
      case AppScreen.levels:
        return LevelSelectScreen(
          unlockedLevel: _unlockedLevel,
          onLevelSelected: (id) {
            setState(() => _currentLevelId = id);
            _navigateTo(AppScreen.game);
          },
          onBack: () => _navigateTo(AppScreen.home),
        );
      case AppScreen.game:
        return GameScreen(
          level: _getLevel(_currentLevelId),
          onBack: () => _navigateTo(AppScreen.levels),
          onNextLevel: (nextId) {
            if (nextId > 30) {
              _navigateTo(AppScreen.home);
              return;
            }
            // every 3 levels show reward wheel
            if (nextId % 3 == 1 && nextId != 1) {
              setState(() => _currentLevelId = nextId);
              _navigateTo(AppScreen.reward);
            } else {
              setState(() => _currentLevelId = nextId);
              _navigateTo(AppScreen.game);
            }
          },
          onLevelComplete: _onLevelComplete,
        );
      case AppScreen.reward:
        return WheelRewardScreen(
          spinResult: math.Random().nextInt(8),
          onRewardClaimed: () {
            setState(() {
              _coins += 50 + math.Random().nextInt(100);
              _hints += 1 + math.Random().nextInt(2);
            });
            _navigateTo(AppScreen.game);
          },
        );
    }
  }
}
