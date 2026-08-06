import 'package:flutter/material.dart';
import '../models/daily_challenge.dart';
import '../theme/app_theme.dart';
import '../utils/sound_manager.dart';
import '../widgets/animated_parking_background.dart';

class DailyChallengesScreen extends StatefulWidget {
  final Function(int levelId) onLevelSelected;
  final VoidCallback onBack;

  const DailyChallengesScreen({
    super.key,
    required this.onLevelSelected,
    required this.onBack,
  });

  @override
  State<DailyChallengesScreen> createState() => _DailyChallengesScreenState();
}

class _DailyChallengesScreenState extends State<DailyChallengesScreen> {
  List<DailyChallenge> challenges = [];

  @override
  void initState() {
    super.initState();
    _loadDailyChallenges();
  }

  void _loadDailyChallenges() {
    final now = DateTime.now();
    challenges = [
      DailyChallenge(
        id: 1,
        title: "Morning Rush",
        description: "Complete level 12 in under 18 moves",
        levelId: 12,
        rewardCoins: 80,
        rewardHints: 2,
        date: now,
      ),
      DailyChallenge(
        id: 2,
        title: "Precision Parking",
        description: "Finish level 25 with 3 stars",
        levelId: 25,
        rewardCoins: 120,
        rewardHints: 3,
        date: now,
      ),
      DailyChallenge(
        id: 3,
        title: "Night Escape",
        description: "Complete level 45 in under 25 moves",
        levelId: 45,
        rewardCoins: 150,
        rewardHints: 4,
        date: now,
      ),
    ];
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
            showRoad: true,
            intensity: 0.9,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: challenges.length,
                    itemBuilder: (context, index) {
                      final challenge = challenges[index];
                      return _ChallengeCard(
                        challenge: challenge,
                        onTap: () {
                          SoundManager().playClick();
                          widget.onLevelSelected(challenge.levelId);
                        },
                      );
                    },
                  ),
                ),
                _buildPowerUpsSection(),
                const SizedBox(height: 20),
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
            child: Text(
              'DAILY CHALLENGES',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '3/3',
              style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerUpsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'POWER-UPS',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 95,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: PowerUpType.all.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final powerUp = PowerUpType.all[index];
                return _PowerUpCard(powerUp: powerUp);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final DailyChallenge challenge;
  final VoidCallback onTap;

  const _ChallengeCard({required this.challenge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.08),
              Colors.white.withOpacity(0.03),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.today_rounded, color: AppTheme.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    challenge.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                if (challenge.isCompleted)
                  const Icon(Icons.check_circle_rounded, color: AppTheme.secondary, size: 26)
              ],
            ),
            const SizedBox(height: 12),
            Text(
              challenge.description,
              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.75)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _RewardChip(icon: Icons.toll_rounded, value: '+${challenge.rewardCoins}', color: AppTheme.accent),
                const SizedBox(width: 10),
                _RewardChip(icon: Icons.lightbulb_rounded, value: '+${challenge.rewardHints}', color: AppTheme.secondary),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'PLAY',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _RewardChip({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _PowerUpCard extends StatelessWidget {
  final PowerUp powerUp;

  const _PowerUpCard({required this.powerUp});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 115,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [powerUp.color.withOpacity(0.2), Colors.white.withOpacity(0.05)],
        ),
        border: Border.all(color: powerUp.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(powerUp.icon, color: powerUp.color, size: 28),
          const Spacer(),
          Text(powerUp.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
          const SizedBox(height: 2),
          Text('${powerUp.cost} coins', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6))),
        ],
      ),
    );
  }
}