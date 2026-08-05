import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/wheel_painter.dart';
import 'models/level.dart';
import 'models/player_profile.dart';
import 'screens/game_screen.dart';
import 'screens/home_screen.dart';
import 'screens/level_select_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/wheel_reward_screen.dart';
import 'theme/app_theme.dart';
import 'utils/levels_data.dart';

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

enum AppScreen { splash, home, levels, game, reward, profile }

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> with TickerProviderStateMixin {
  AppScreen _current = AppScreen.splash;
  int _currentLevelId = 1;
  PlayerProfile _profile = PlayerProfile.fresh();
  late AnimationController _transitionController;
  late Animation<double> _fadeAnim;

  int get _totalLevels => LevelsRepository.totalLevels;

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _transitionController, curve: Curves.easeOut));
    _transitionController.forward();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final loaded = await PlayerProfile.load();
    if (!mounted) return;
    setState(() {
      _profile = loaded.copyWith(unlockedLevel: loaded.unlockedLevel.clamp(1, _totalLevels).toInt());
      _currentLevelId = _profile.unlockedLevel.clamp(1, _totalLevels).toInt();
    });
  }

  Future<void> _saveProfile() => _profile.save();

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  void _navigateTo(AppScreen screen) async {
    await _transitionController.reverse();
    if (!mounted) return;
    setState(() => _current = screen);
    _transitionController.forward();
  }

  GameLevel _getLevel(int id) {
    final levels = LevelsRepository.allLevels;
    return levels.firstWhere((level) => level.id == id, orElse: () => levels.first);
  }

  void _onLevelComplete(int stars, int moves) {
    setState(() {
      _profile = _profile.recordLevelComplete(
        levelId: _currentLevelId,
        stars: stars,
        moves: moves,
        totalLevels: _totalLevels,
      );
    });
    _saveProfile();
  }

  void _onHintUsed() {
    if (_profile.hints <= 0) return;
    setState(() => _profile = _profile.spendHint());
    _saveProfile();
  }

  void _onRewardClaimed(WheelSegment reward) {
    final isHint = reward.label.toLowerCase().contains('hint');
    setState(() {
      _profile = _profile.addReward(
        coinsWon: isHint ? 0 : reward.value,
        hintsWon: isHint ? reward.value : 0,
      );
    });
    _saveProfile();
    _navigateTo(AppScreen.game);
  }

  void _selectSkin(int skinIndex) {
    setState(() => _profile = _profile.copyWith(selectedSkin: skinIndex));
    _saveProfile();
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
          profile: _profile,
          totalLevels: _totalLevels,
          onPlay: () {
            setState(() => _currentLevelId = _profile.unlockedLevel.clamp(1, _totalLevels).toInt());
            _navigateTo(AppScreen.game);
          },
          onLevels: () => _navigateTo(AppScreen.levels),
          onProfile: () => _navigateTo(AppScreen.profile),
        );
      case AppScreen.levels:
        return LevelSelectScreen(
          unlockedLevel: _profile.unlockedLevel,
          levelStars: _profile.levelStars,
          onLevelSelected: (id) {
            setState(() => _currentLevelId = id);
            _navigateTo(AppScreen.game);
          },
          onBack: () => _navigateTo(AppScreen.home),
        );
      case AppScreen.game:
        return GameScreen(
          level: _getLevel(_currentLevelId),
          hints: _profile.hints,
          coins: _profile.coins,
          totalLevels: _totalLevels,
          selectedSkin: _profile.selectedSkin,
          onBack: () => _navigateTo(AppScreen.levels),
          onHintUsed: _onHintUsed,
          onNextLevel: (nextId) {
            if (nextId > _totalLevels) {
              _navigateTo(AppScreen.profile);
              return;
            }
            // Every 3 completed levels shows the reward wheel for a premium game loop.
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
          onRewardClaimed: _onRewardClaimed,
        );
      case AppScreen.profile:
        return ProfileScreen(
          profile: _profile,
          onBack: () => _navigateTo(AppScreen.home),
          onPlay: () {
            setState(() => _currentLevelId = _profile.unlockedLevel.clamp(1, _totalLevels).toInt());
            _navigateTo(AppScreen.game);
          },
          onSelectSkin: _selectSkin,
        );
    }
  }
}
