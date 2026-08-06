import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  final AudioPlayer _bgPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _enginePlayer = AudioPlayer();

  bool _soundEnabled = true;
  bool _musicEnabled = true;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;

  Future<void> init() async {
    await _bgPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgPlayer.setVolume(0.35);
    await _sfxPlayer.setVolume(0.9);
    await _enginePlayer.setReleaseMode(ReleaseMode.loop);
    await _enginePlayer.setVolume(0.6);
  }

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
    if (!_soundEnabled) {
      _sfxPlayer.stop();
      _enginePlayer.stop();
    }
  }

  void toggleMusic() {
    _musicEnabled = !_musicEnabled;
    if (_musicEnabled) {
      playBackgroundMusic();
    } else {
      _bgPlayer.stop();
    }
  }

  // ==================== BACKGROUND MUSIC ====================
  Future<void> playBackgroundMusic() async {
    if (!_musicEnabled) return;
    try {
      await _bgPlayer.play(AssetSource('audio/ambient_city.mp3'));
    } catch (_) {
      // Fallback: play a soft hum if asset missing
    }
  }

  Future<void> stopBackgroundMusic() async {
    await _bgPlayer.stop();
  }

  // ==================== SFX ====================
  Future<void> playCarSlide() async {
    if (!_soundEnabled) return;
    try {
      await _sfxPlayer.play(AssetSource('audio/car_slide.mp3'));
    } catch (_) {}
  }

  Future<void> playCarMove() async {
    if (!_soundEnabled) return;
    try {
      await _sfxPlayer.play(AssetSource('audio/car_move.mp3'));
    } catch (_) {}
  }

  Future<void> playWin() async {
    if (!_soundEnabled) return;
    try {
      await _sfxPlayer.play(AssetSource('audio/win_chime.mp3'));
    } catch (_) {}
  }

  Future<void> playClick() async {
    if (!_soundEnabled) return;
    try {
      await _sfxPlayer.play(AssetSource('audio/click.mp3'));
    } catch (_) {}
  }

  Future<void> playHint() async {
    if (!_soundEnabled) return;
    try {
      await _sfxPlayer.play(AssetSource('audio/hint.mp3'));
    } catch (_) {}
  }

  Future<void> playCollision() async {
    if (!_soundEnabled) return;
    try {
      await _sfxPlayer.play(AssetSource('audio/collision.mp3'));
    } catch (_) {}
  }

  // ==================== ENGINE SOUND (DRAGGING) ====================
  Future<void> startEngineSound() async {
    if (!_soundEnabled) return;
    try {
      await _enginePlayer.play(AssetSource('audio/engine_idle.mp3'));
    } catch (_) {}
  }

  Future<void> stopEngineSound() async {
    await _enginePlayer.stop();
  }

  Future<void> setEnginePitch(double pitch) async {
    // Simulate pitch by volume change (audioplayers limitation)
    await _enginePlayer.setVolume((0.4 + pitch * 0.5).clamp(0.3, 0.95));
  }

  void dispose() {
    _bgPlayer.dispose();
    _sfxPlayer.dispose();
    _enginePlayer.dispose();
  }
}