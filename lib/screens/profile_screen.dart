import 'package:flutter/material.dart';

import '../models/player_profile.dart';
import '../theme/app_theme.dart';
import '../utils/levels_data.dart';
import '../widgets/animated_parking_background.dart';

class ProfileScreen extends StatefulWidget {
  final PlayerProfile profile;
  final VoidCallback onBack;
  final VoidCallback onPlay;
  final Function(int skinIndex) onSelectSkin;

  const ProfileScreen({
    super.key,
    required this.profile,
    required this.onBack,
    required this.onPlay,
    required this.onSelectSkin,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalLevels = LevelsRepository.totalLevels;
    final profile = widget.profile;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.background, AppTheme.surface, AppTheme.surfaceLight],
          ),
        ),
        child: SafeArea(
          child: AnimatedParkingBackground(
            intensity: 0.75,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(profile, totalLevels)),
                SliverToBoxAdapter(child: _buildQuickStats(profile)),
                SliverToBoxAdapter(child: _buildGarage(profile)),
                SliverToBoxAdapter(child: _buildAchievements(profile, totalLevels)),
                SliverToBoxAdapter(child: _buildProductionPanel()),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(PlayerProfile profile, int totalLevels) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: FadeTransition(
        opacity: _controller,
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.10)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('DRIVER PROFILE', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
                _CurrencyChip(icon: Icons.toll_rounded, value: '${profile.coins}', color: AppTheme.accent),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(colors: [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.05)]),
                border: Border.all(color: Colors.white.withOpacity(0.16)),
                boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.16), blurRadius: 28, offset: const Offset(0, 14))],
              ),
              child: Row(
                children: [
                  Hero(
                    tag: 'profile-avatar',
                    child: Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
                        boxShadow: [BoxShadow(color: AppTheme.secondary.withOpacity(0.35), blurRadius: 20)],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.person_rounded, color: Colors.white, size: 44),
                          Positioned(
                            right: 5,
                            bottom: 5,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                              child: Text('${profile.garageLevel}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.playerName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(profile.rankTitle, style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: profile.progressToNextRank(totalLevels),
                            minHeight: 8,
                            backgroundColor: Colors.white.withOpacity(0.08),
                            valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('${profile.totalStars}/${totalLevels * 3} stars collected', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.55))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(PlayerProfile profile) {
    final average = profile.averageMoves == 0 ? '--' : profile.averageMoves.toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.85,
        children: [
          _ProfileStat(icon: Icons.flag_rounded, label: 'Unlocked', value: '${profile.unlockedLevel}/${LevelsRepository.totalLevels}', color: AppTheme.secondary),
          _ProfileStat(icon: Icons.star_rounded, label: 'Stars', value: '${profile.totalStars}', color: AppTheme.accent),
          _ProfileStat(icon: Icons.local_fire_department_rounded, label: 'Best Streak', value: '${profile.bestStreak}', color: AppTheme.danger),
          _ProfileStat(icon: Icons.speed_rounded, label: 'Avg Moves', value: average, color: AppTheme.primary),
        ],
      ),
    );
  }

  Widget _buildGarage(PlayerProfile profile) {
    final skins = [
      _SkinData('Classic Red', AppTheme.targetRed, Icons.directions_car_rounded, 0),
      _SkinData('Night Rider', AppTheme.primary, Icons.electric_bolt_rounded, 18),
      _SkinData('Taxi Pro', AppTheme.accent, Icons.local_taxi_rounded, 36),
      _SkinData('Cyber Truck', AppTheme.secondary, Icons.fire_truck_rounded, 72),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('GARAGE SKINS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 10),
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: skins.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final skin = skins[index];
                final unlocked = profile.totalStars >= skin.requiredStars;
                final selected = profile.selectedSkin == index;
                return GestureDetector(
                  onTap: unlocked ? () => widget.onSelectSkin(index) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 132,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(colors: [skin.color.withOpacity(unlocked ? 0.45 : 0.12), Colors.white.withOpacity(0.05)]),
                      border: Border.all(color: selected ? AppTheme.accent : Colors.white.withOpacity(0.12), width: selected ? 2 : 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(skin.icon, color: unlocked ? Colors.white : Colors.white24, size: 32),
                            const Spacer(),
                            Icon(selected ? Icons.check_circle_rounded : unlocked ? Icons.lock_open_rounded : Icons.lock_rounded, color: selected ? AppTheme.accent : Colors.white38, size: 18),
                          ],
                        ),
                        const Spacer(),
                        Text(skin.name, style: TextStyle(fontWeight: FontWeight.w900, color: unlocked ? Colors.white : Colors.white38)),
                        const SizedBox(height: 4),
                        Text(unlocked ? 'Ready to drive' : '${skin.requiredStars} stars', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(unlocked ? 0.62 : 0.35))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements(PlayerProfile profile, int totalLevels) {
    final achievements = [
      _AchievementData('First Escape', 'Clear your first level', profile.completedLevels >= 1, Icons.rocket_launch_rounded),
      _AchievementData('Perfect Driver', 'Win 5 perfect levels', profile.perfectWins >= 5, Icons.workspace_premium_rounded),
      _AchievementData('Collector', 'Collect 60 stars', profile.totalStars >= 60, Icons.stars_rounded),
      _AchievementData('World Tour', 'Unlock all levels', profile.unlockedLevel >= totalLevels, Icons.public_rounded),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ACHIEVEMENTS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 10),
          ...achievements.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(item.unlocked ? 0.10 : 0.045),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: item.unlocked ? AppTheme.accent.withOpacity(0.35) : Colors.white.withOpacity(0.07)),
                ),
                child: Row(
                  children: [
                    Icon(item.icon, color: item.unlocked ? AppTheme.accent : Colors.white24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                          Text(item.description, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
                        ],
                      ),
                    ),
                    Icon(item.unlocked ? Icons.verified_rounded : Icons.radio_button_unchecked_rounded, color: item.unlocked ? AppTheme.secondary : Colors.white24),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildProductionPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
          boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.28), blurRadius: 24, offset: const Offset(0, 12))],
        ),
        child: Row(
          children: [
            const Icon(Icons.sports_esports_rounded, color: Colors.white, size: 36),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Production Mode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                  SizedBox(height: 4),
                  Text('60 levels, profile saves, garage skins, rewards, missions and cinematic parking visuals.', style: TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            IconButton(
              onPressed: widget.onPlay,
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.18)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _CurrencyChip({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.16), borderRadius: BorderRadius.circular(99), border: Border.all(color: color.withOpacity(0.35))),
      child: Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 5), Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900))]),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ProfileStat({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.075),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: color.withOpacity(0.18), shape: BoxShape.circle),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                Text(label.toUpperCase(), style: TextStyle(fontSize: 10, letterSpacing: 1, color: Colors.white.withOpacity(0.48))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkinData {
  final String name;
  final Color color;
  final IconData icon;
  final int requiredStars;

  const _SkinData(this.name, this.color, this.icon, this.requiredStars);
}

class _AchievementData {
  final String title;
  final String description;
  final bool unlocked;
  final IconData icon;

  const _AchievementData(this.title, this.description, this.unlocked, this.icon);
}
