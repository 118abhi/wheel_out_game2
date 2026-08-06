import 'package:flutter/material.dart';
import '../models/level.dart';

class DailyChallenge {
  final int id;
  final String title;
  final String description;
  final int levelId;
  final int rewardCoins;
  final int rewardHints;
  final DateTime date;
  final bool isCompleted;

  const DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.levelId,
    required this.rewardCoins,
    required this.rewardHints,
    required this.date,
    this.isCompleted = false,
  });

  DailyChallenge copyWith({bool? isCompleted}) {
    return DailyChallenge(
      id: id,
      title: title,
      description: description,
      levelId: levelId,
      rewardCoins: rewardCoins,
      rewardHints: rewardHints,
      date: date,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class PowerUp {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final int cost;

  const PowerUp({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.cost,
  });
}

class PowerUpType {
  static const timeFreeze = PowerUp(
    id: 'time_freeze',
    name: 'Time Freeze',
    description: 'Pause all cars for 8 seconds',
    icon: Icons.pause_circle_filled_rounded,
    color: Color(0xFF00BCD4),
    cost: 15,
  );

  static const doubleMove = PowerUp(
    id: 'double_move',
    name: 'Double Move',
    description: 'Move two cars in one turn',
    icon: Icons.swap_horiz_rounded,
    color: Color(0xFF7C4DFF),
    cost: 20,
  );

  static const forcePush = PowerUp(
    id: 'force_push',
    name: 'Force Push',
    description: 'Push any blocking car away',
    icon: Icons.arrow_forward_rounded,
    color: Color(0xFFFF5722),
    cost: 25,
  );

  static const superHint = PowerUp(
    id: 'super_hint',
    name: 'Super Hint',
    description: 'Reveal the optimal solution path',
    icon: Icons.lightbulb_rounded,
    color: Color(0xFFFFC107),
    cost: 12,
  );

  static List<PowerUp> get all => [
        timeFreeze,
        doubleMove,
        forcePush,
        superHint,
      ];
}