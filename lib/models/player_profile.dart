import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

class PlayerProfile {
  static const _storageKey = 'wheel_out_player_profile_v2';

  final String playerName;
  final int unlockedLevel;
  final int coins;
  final int hints;
  final Map<int, int> levelStars;
  final int totalMoves;
  final int totalWins;
  final int perfectWins;
  final int currentStreak;
  final int bestStreak;
  final int selectedSkin;
  final DateTime lastSavedAt;

  const PlayerProfile({
    this.playerName = 'Road Rookie',
    this.unlockedLevel = 1,
    this.coins = 120,
    this.hints = 3,
    this.levelStars = const {},
    this.totalMoves = 0,
    this.totalWins = 0,
    this.perfectWins = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.selectedSkin = 0,
    required this.lastSavedAt,
  });

  factory PlayerProfile.fresh() => PlayerProfile(lastSavedAt: DateTime.now());

  int get totalStars => levelStars.values.fold<int>(0, (sum, stars) => sum + stars);
  int get completedLevels => levelStars.values.where((stars) => stars > 0).length;
  int get garageLevel => math.max(1, (totalStars / 12).floor() + 1);
  double get averageMoves => totalWins == 0 ? 0 : totalMoves / totalWins;

  String get rankTitle {
    if (totalStars >= 150) return 'Parking Legend';
    if (totalStars >= 110) return 'Master Driver';
    if (totalStars >= 75) return 'City Pro';
    if (totalStars >= 40) return 'Garage Hero';
    if (totalStars >= 15) return 'Street Driver';
    return 'Road Rookie';
  }

  double progressToNextRank(int totalLevels) {
    final maxStars = totalLevels * 3;
    if (maxStars == 0) return 0;
    return (totalStars / maxStars).clamp(0, 1).toDouble();
  }

  PlayerProfile copyWith({
    String? playerName,
    int? unlockedLevel,
    int? coins,
    int? hints,
    Map<int, int>? levelStars,
    int? totalMoves,
    int? totalWins,
    int? perfectWins,
    int? currentStreak,
    int? bestStreak,
    int? selectedSkin,
    DateTime? lastSavedAt,
  }) {
    return PlayerProfile(
      playerName: playerName ?? this.playerName,
      unlockedLevel: unlockedLevel ?? this.unlockedLevel,
      coins: coins ?? this.coins,
      hints: hints ?? this.hints,
      levelStars: levelStars ?? Map<int, int>.from(this.levelStars),
      totalMoves: totalMoves ?? this.totalMoves,
      totalWins: totalWins ?? this.totalWins,
      perfectWins: perfectWins ?? this.perfectWins,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      selectedSkin: selectedSkin ?? this.selectedSkin,
      lastSavedAt: lastSavedAt ?? DateTime.now(),
    );
  }

  PlayerProfile recordLevelComplete({
    required int levelId,
    required int stars,
    required int moves,
    required int totalLevels,
  }) {
    final oldBest = levelStars[levelId] ?? 0;
    final newStars = math.max(oldBest, stars).clamp(1, 3).toInt();
    final newMap = Map<int, int>.from(levelStars)..[levelId] = newStars;
    final newUnlocked = levelId >= unlockedLevel ? math.min(totalLevels, levelId + 1) : unlockedLevel;
    final firstClearBonus = oldBest == 0 ? 20 : 0;
    final improvedBonus = newStars > oldBest ? (newStars - oldBest) * 18 : 0;
    final perfectBonus = stars == 3 ? 12 : 0;
    final newStreak = currentStreak + 1;

    return copyWith(
      unlockedLevel: newUnlocked,
      coins: coins + stars * 10 + firstClearBonus + improvedBonus + perfectBonus,
      hints: hints + (stars == 3 && newStreak % 4 == 0 ? 1 : 0),
      levelStars: newMap,
      totalMoves: totalMoves + moves,
      totalWins: totalWins + 1,
      perfectWins: perfectWins + (stars == 3 ? 1 : 0),
      currentStreak: newStreak,
      bestStreak: math.max(bestStreak, newStreak),
    );
  }

  PlayerProfile spendHint() => copyWith(hints: math.max(0, hints - 1));

  PlayerProfile spendCoins(int amount) => copyWith(coins: math.max(0, coins - amount));

  PlayerProfile addReward({int coinsWon = 0, int hintsWon = 0}) {
    return copyWith(coins: coins + coinsWon, hints: hints + hintsWon);
  }

  Map<String, dynamic> toJson() => {
        'playerName': playerName,
        'unlockedLevel': unlockedLevel,
        'coins': coins,
        'hints': hints,
        'levelStars': levelStars.map((key, value) => MapEntry(key.toString(), value)),
        'totalMoves': totalMoves,
        'totalWins': totalWins,
        'perfectWins': perfectWins,
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'selectedSkin': selectedSkin,
        'lastSavedAt': lastSavedAt.toIso8601String(),
      };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    final rawStars = (json['levelStars'] as Map?) ?? {};
    return PlayerProfile(
      playerName: json['playerName'] as String? ?? 'Road Rookie',
      unlockedLevel: (json['unlockedLevel'] as num?)?.toInt() ?? 1,
      coins: (json['coins'] as num?)?.toInt() ?? 120,
      hints: (json['hints'] as num?)?.toInt() ?? 3,
      levelStars: rawStars.map<int, int>((key, value) => MapEntry(int.tryParse('$key') ?? 0, (value as num?)?.toInt() ?? 0))..removeWhere((key, value) => key <= 0),
      totalMoves: (json['totalMoves'] as num?)?.toInt() ?? 0,
      totalWins: (json['totalWins'] as num?)?.toInt() ?? 0,
      perfectWins: (json['perfectWins'] as num?)?.toInt() ?? 0,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      bestStreak: (json['bestStreak'] as num?)?.toInt() ?? 0,
      selectedSkin: (json['selectedSkin'] as num?)?.toInt() ?? 0,
      lastSavedAt: DateTime.tryParse(json['lastSavedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  static Future<PlayerProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return PlayerProfile.fresh();
    try {
      return PlayerProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return PlayerProfile.fresh();
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(toJson()));
  }
}
