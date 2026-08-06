import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/sound_manager.dart';
import '../widgets/animated_parking_background.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const SettingsScreen({super.key, required this.onBack});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool soundEnabled = SoundManager().soundEnabled;
  bool musicEnabled = SoundManager().musicEnabled;
  double musicVolume = 0.6;
  double sfxVolume = 0.85;
  bool vibrationEnabled = true;
  bool reducedMotion = false;

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
            showRoad: true,
            intensity: 0.85,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildSection("Audio", [
                        _buildSwitchTile(
                          "Sound Effects",
                          Icons.volume_up_rounded,
                          soundEnabled,
                          (val) {
                            setState(() => soundEnabled = val);
                            SoundManager().toggleSound();
                          },
                        ),
                        _buildSwitchTile(
                          "Background Music",
                          Icons.music_note_rounded,
                          musicEnabled,
                          (val) {
                            setState(() => musicEnabled = val);
                            SoundManager().toggleMusic();
                          },
                        ),
                        _buildSliderTile("Music Volume", musicVolume, (val) {
                          setState(() => musicVolume = val);
                        }),
                        _buildSliderTile("SFX Volume", sfxVolume, (val) {
                          setState(() => sfxVolume = val);
                        }),
                      ]),
                      const SizedBox(height: 24),
                      _buildSection("Gameplay", [
                        _buildSwitchTile(
                          "Vibration",
                          Icons.vibration_rounded,
                          vibrationEnabled,
                          (val) => setState(() => vibrationEnabled = val),
                        ),
                        _buildSwitchTile(
                          "Reduced Motion",
                          Icons.accessibility_rounded,
                          reducedMotion,
                          (val) => setState(() => reducedMotion = val),
                        ),
                      ]),
                      const SizedBox(height: 24),
                      _buildSection("About", [
                        _buildInfoTile("Version", "1.0.0"),
                        _buildInfoTile("Levels", "75"),
                        _buildInfoTile("Cars", "6 Types"),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              SoundManager().playClick();
              widget.onBack();
            },
            icon: const Icon(Icons.arrow_back_rounded),
            style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('SETTINGS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.accent)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, IconData icon, bool value, Function(bool) onChanged) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.secondary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.accent,
      ),
    );
  }

  Widget _buildSliderTile(String title, double value, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Slider(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.accent,
            inactiveColor: Colors.white.withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return ListTile(
      title: Text(title),
      trailing: Text(value, style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700)),
    );
  }
}