import 'package:flutter/material.dart';
import '../models/car.dart';
import '../models/level.dart';
import '../models/weather.dart';
import '../theme/app_theme.dart';

class LevelsRepository {
  static List<GameLevel> get allLevels {
    return [
      _level1(),
      _level2(),
      _level3(),
      _level4(),
      _level5(),
      _level6(),
      _level7(),
      _level8(),
      _level9(),
      _level10(),
      _level11(),
      _level12(),
      _level13(),
      _level14(),
      _level15(),
      _level16(),
      _level17(),
      _level18(),
      _level19(),
      _level20(),
      _level21(),
      _level22(),
      _level23(),
      _level24(),
      _level25(),
      _level26(),
      _level27(),
      _level28(),
      _level29(),
      _level30(),
      _level31(),
      _level32(),
      _level33(),
      _level34(),
      _level35(),
      _level36(),
      _level37(),
      _level38(),
      _level39(),
      _level40(),
      _level41(),
      _level42(),
      _level43(),
      _level44(),
      _level45(),
      _level46(),
      _level47(),
      _level48(),
      _level49(),
      _level50(),
      _level51(),
      _level52(),
      _level53(),
      _level54(),
      _level55(),
      _level56(),
      _level57(),
      _level58(),
      _level59(),
      _level60(),
      _level61(),
      _level62(),
      _level63(),
      _level64(),
      _level65(),
      _level66(),
      _level67(),
      _level68(),
      _level69(),
      _level70(),
      _level71(),
      _level72(),
      _level73(),
      _level74(),
      _level75(),
      // Procedurally curated chapters 76–200. Each chapter gets a stable
      // layout, increasing traffic density and difficulty.
      ...List.generate(125, (index) => _generatedLevel(index + 76)),
    ];
  }

  static int get totalLevels => allLevels.length;

  static Color _c(int index) => AppTheme.carColors[index % AppTheme.carColors.length];
  static Color _d(int index) => AppTheme.carColors[index % AppTheme.carColors.length].withOpacity(0.85);

  static GameLevel _generatedLevel(int id) {
    final difficulty = id <= 10 ? 1 : id <= 30 ? 2 : id <= 70 ? 3 : id <= 120 ? 4 : 5;
    final traffic = 4 + ((id - 76) % 7);
    final cars = <CarModel>[
      CarModel(id: 'target-$id', x: 0, y: 2, length: 2,
        orientation: CarOrientation.horizontal, isTarget: true,
        color: AppTheme.targetRed, darkColor: AppTheme.targetRedDark,
        carType: CarType.sports),
    ];
    // Fill lanes away from the exit row first; deterministic layouts make
    // every level reproducible and keep the difficulty progression predictable.
    var cursor = 0;
    for (var i = 0; i < traffic; i++) {
      final vertical = (i + id) % 2 == 0;
      final x = vertical ? (1 + ((i * 2 + id) % 5)) : (i % 2 == 0 ? 0 : 3);
      final y = vertical ? ((i * 3 + id) % 4) : ((i + id) % 6);
      final length = vertical ? 2 : (i % 3 == 0 ? 3 : 2);
      final cells = <String>{};
      for (final existing in cars) {
        for (final point in existing.occupiedCells()) {
          cells.add('${point.x},${point.y}');
        }
      }
      final fits = List.generate(length, (n) => vertical ? '${x},${y + n}' : '${x + n},${y}')
          .every((cell) => !cells.contains(cell) && (vertical ? y + length <= 6 : x + length <= 6));
      if (!fits || (vertical && x == 0)) {
        cursor++;
        continue;
      }
      final colorIndex = id + i + cursor;
      cars.add(CarModel(
        id: 'car-$id-$i', x: x, y: y, length: length,
        orientation: vertical ? CarOrientation.vertical : CarOrientation.horizontal,
        color: _c(colorIndex), darkColor: _d(colorIndex),
        carType: CarType.values[(colorIndex) % CarType.values.length],
      ));
      cursor++;
    }
    return GameLevel(
      id: id, name: 'Chapter ${((id - 1) ~/ 25) + 1} • Level $id',
      exitRow: 2, cars: cars, parMoves: 5 + difficulty * 3 + (id % 5), difficulty: difficulty,
    );
  }

  static GameLevel _level1() {
    return GameLevel(
      id: 1,
      name: "First Spin",
      exitRow: 2,
      parMoves: 5,
      difficulty: 1,
      cars: [
        CarModel(id: 'R', x: 0, y: 2, length: 2, orientation: CarOrientation.horizontal, isTarget: true, color: AppTheme.targetRed, darkColor: AppTheme.targetRedDark),
        CarModel(id: 'A', x: 3, y: 0, length: 3, orientation: CarOrientation.vertical, color: _c(0), darkColor: _d(0)),
        CarModel(id: 'B', x: 4, y: 2, length: 2, orientation: CarOrientation.vertical, color: _c(1), darkColor: _d(1)),
        CarModel(id: 'C', x: 0, y: 4, length: 2, orientation: CarOrientation.horizontal, color: _c(2), darkColor: _d(2)),
      ],
    );
  }

  static GameLevel _level2() {
    return GameLevel(
      id: 2,
      name: "Easy Out",
      exitRow: 2,
      parMoves: 6,
      difficulty: 1,
      cars: [
        CarModel(id: 'R', x: 1, y: 2, length: 2, orientation: CarOrientation.horizontal, isTarget: true, color: AppTheme.targetRed, darkColor: AppTheme.targetRedDark),
        CarModel(id: 'A', x: 0, y: 0, length: 2, orientation: CarOrientation.horizontal, color: _c(3), darkColor: _d(3)),
        CarModel(id: 'B', x: 3, y: 0, length: 3, orientation: CarOrientation.vertical, color: _c(4), darkColor: _d(4)),
        CarModel(id: 'C', x: 0, y: 3, length: 3, orientation: CarOrientation.horizontal, color: _c(5), darkColor: _d(5)),
        CarModel(id: 'D', x: 4, y: 3, length: 2, orientation: CarOrientation.vertical, color: _c(6), darkColor: _d(6)),
      ],
    );
  }

  static GameLevel _level3() {
    return GameLevel(
      id: 3,
      name: "Block Party",
      exitRow: 2,
      parMoves: 8,
      difficulty: 1,
      cars: [
        CarModel(id: 'R', x: 1, y: 2, length: 2, orientation: CarOrientation.horizontal, isTarget: true, color: AppTheme.targetRed, darkColor: AppTheme.targetRedDark),
        CarModel(id: 'A', x: 3, y: 1, length: 2, orientation: CarOrientation.vertical, color: _c(0), darkColor: _d(0)),
        CarModel(id: 'B', x: 4, y: 1, length: 3, orientation: CarOrientation.vertical, color: _c(1), darkColor: _d(1)),
        CarModel(id: 'C', x: 0, y: 0, length: 2, orientation: CarOrientation.horizontal, color: _c(2), darkColor: _d(2)),
        CarModel(id: 'D', x: 2, y: 4, length: 2, orientation: CarOrientation.horizontal, color: _c(3), darkColor: _d(3)),
        CarModel(id: 'E', x: 0, y: 5, length: 3, orientation: CarOrientation.horizontal, color: _c(4), darkColor: _d(4)),
      ],
    );
  }

  static GameLevel _level4() {
    return GameLevel(
      id: 4,
      name: "Narrow Escape",
      exitRow: 2,
      parMoves: 10,
      difficulty: 2,
      cars: [
        CarModel(id: 'R', x: 0, y: 2, length: 2, orientation: CarOrientation.horizontal, isTarget: true, color: AppTheme.targetRed, darkColor: AppTheme.targetRedDark),
        CarModel(id: 'A', x: 2, y: 0, length: 2, orientation: CarOrientation.vertical, color: _c(5), darkColor: _d(5)),
        CarModel(id: 'B', x: 3, y: 0, length: 2, orientation: CarOrientation.vertical, color: _c(6), darkColor: _d(6)),
        CarModel(id: 'C', x: 4, y: 0, length: 2, orientation: CarOrientation.vertical, color: _c(7), darkColor: _d(7)),
        CarModel(id: 'D', x: 0, y: 3, length: 3, orientation: CarOrientation.horizontal, color: _c(8), darkColor: _d(8)),
        CarModel(id: 'E', x: 3, y: 3, length: 3, orientation: CarOrientation.horizontal, color: _c(9), darkColor: _d(9)),
        CarModel(id: 'F', x: 5, y: 2, length: 2, orientation: CarOrientation.vertical, color: _c(0), darkColor: _d(0)),
      ],
    );
  }

  static GameLevel _level5() {
    return GameLevel(
      id: 5,
      name: "Crossroads",
      exitRow: 2,
      parMoves: 12,
      difficulty: 2,
      cars: [
        CarModel(id: 'R', x: 0, y: 2, length: 2, orientation: CarOrientation.horizontal, isTarget: true, color: AppTheme.targetRed, darkColor: AppTheme.targetRedDark),
        CarModel(id: 'A', x: 2, y: 0, length: 3, orientation: CarOrientation.vertical, color: _c(1), darkColor: _d(1)),
        CarModel(id: 'B', x: 3, y: 0, length: 2, orientation: CarOrientation.horizontal, color: _c(2), darkColor: _d(2)),
        CarModel(id: 'C', x: 5, y: 0, length: 3, orientation: CarOrientation.vertical, color: _c(3), darkColor: _d(3)),
        CarModel(id: 'D', x: 0, y: 3, length: 2, orientation: CarOrientation.horizontal, color: _c(4), darkColor: _d(4)),
        CarModel(id: 'E', x: 2, y: 3, length: 3, orientation: CarOrientation.vertical, color: _c(5), darkColor: _d(5)),
        CarModel(id: 'F', x: 3, y: 4, length: 2, orientation: CarOrientation.horizontal, color: _c(6), darkColor: _d(6)),
      ],
    );
  }

  static GameLevel _level6() {
    return GameLevel(
      id: 6,
      name: "Wheel Lock",
      exitRow: 2,
      parMoves: 14,
      difficulty: 2,
      cars: [
        CarModel(id: 'R', x: 1, y: 2, length: 2, orientation: CarOrientation.horizontal, isTarget: true, color: AppTheme.targetRed, darkColor: AppTheme.targetRedDark),
        CarModel(id: 'A', x: 0, y: 0, length: 2, orientation: CarOrientation.horizontal, color: _c(7), darkColor: _d(7)),
        CarModel(id: 'B', x: 2, y: 0, length: 3, orientation: CarOrientation.vertical, color: _c(8), darkColor: _d(8)),
        CarModel(id: 'C', x: 3, y: 0, length: 2, orientation: CarOrientation.vertical, color: _c(9), darkColor: _d(9)),
        CarModel(id: 'D', x: 5, y: 0, length: 3, orientation: CarOrientation.vertical, color: _c(0), darkColor: _d(0)),
        CarModel(id: 'E', x: 3, y: 3, length: 2, orientation: CarOrientation.horizontal, color: _c(1), darkColor: _d(1)),
        CarModel(id: 'F', x: 0, y: 4, length: 2, orientation: CarOrientation.horizontal, color: _c(2), darkColor: _d(2)),
        CarModel(id: 'G', x: 4, y: 4, length: 2, orientation: CarOrientation.vertical, color: _c(3), darkColor: _d(3)),
      ],
    );
  }

  static GameLevel _level7() {
    return GameLevel(
      id: 7,
      name: "Tight Squeeze",
      exitRow: 2,
      parMoves: 15,
      difficulty: 3,
      cars: [
        CarModel(id: 'R', x: 0, y: 2, length: 2, orientation: CarOrientation.horizontal, isTarget: true, color: AppTheme.targetRed, darkColor: AppTheme.targetRedDark),
        CarModel(id: 'A', x: 2, y: 0, length: 2, orientation: CarOrientation.vertical, color: _c(4), darkColor: _d(4)),
        CarModel(id: 'B', x: 3, y: 0, length: 3, orientation: CarOrientation.horizontal, color: _c(5), darkColor: _d(5)),
        CarModel(id: 'C', x: 2, y: 3, length: 2, orientation: CarOrientation.vertical, color: _c(6), darkColor: _d(6)),
        CarModel(id: 'D', x: 3, y: 3, length: 3, orientation: CarOrientation.horizontal, color: _c(7), darkColor: _d(7)),
        CarModel(id: 'E', x: 0, y: 4, length: 2, orientation: CarOrientation.vertical, color: _c(8), darkColor: _d(8)),
        CarModel(id: 'F', x: 4, y: 4, length: 2, orientation: CarOrientation.vertical, color: _c(9), darkColor: _d(9)),
        CarModel(id: 'G', x: 5, y: 1, length: 3, orientation: CarOrientation.vertical, color: _c(0), darkColor: _d(0)),
      ],
    );
  }

  static GameLevel _level8() {
    return GameLevel(
      id: 8,
      name: "Parking Hell",
      exitRow: 2,
      parMoves: 18,
      difficulty: 3,
      cars: [
        CarModel(id: 'R', x: 0, y: 2, length: 2, orientation: CarOrientation.horizontal, isTarget: true, color: AppTheme.targetRed, darkColor: AppTheme.targetRedDark),
        CarModel(id: 'A', x: 2, y: 0, length: 2, orientation: CarOrientation.vertical, color: _c(1), darkColor: _d(1)),
        CarModel(id: 'B', x: 3, y: 0, length: 2, orientation: CarOrientation.horizontal, color: _c(2), darkColor: _d(2)),
        CarModel(id: 'C', x: 0, y: 3, length: 3, orientation: CarOrientation.horizontal, color: _c(3), darkColor: _d(3)),
        CarModel(id: 'D', x: 3, y: 2, length: 3, orientation: CarOrientation.vertical, color: _c(4), darkColor: _d(4)),
        CarModel(id: 'E', x: 4, y: 0, length: 2, orientation: CarOrientation.vertical, color: _c(5), darkColor: _d(5)),
        CarModel(id: 'F', x: 5, y: 2, length: 3, orientation: CarOrientation.vertical, color: _c(6), darkColor: _d(6)),
        CarModel(id: 'G', x: 1, y: 4, length: 2, orientation: CarOrientation.horizontal, color: _c(7), darkColor: _d(7)),
        CarModel(id: 'H', x: 3, y: 5, length: 2, orientation: CarOrientation.horizontal, color: _c(8), darkColor: _d(8)),
      ],
    );
  }

  // Production tour: deterministic generated levels with hand-tuned names, par targets, and seeds for 9-60.
  static GameLevel _level9() => _genLevel(9, "Spin Cycle", 20, 3, seed: 9);
  static GameLevel _level10() => _genLevel(10, "Drift Zone", 22, 3, seed: 10);
  static GameLevel _level11() => _genLevel(11, "Turbo Trap", 25, 4, seed: 11);
  static GameLevel _level12() => _genLevel(12, "Clutch Control", 28, 4, seed: 12);
  static GameLevel _level13() => _genLevel(13, "Axle Break", 30, 4, seed: 13);
  static GameLevel _level14() => _genLevel(14, "Oversteer", 32, 4, seed: 14);
  static GameLevel _level15() => _genLevel(15, "Burnout", 35, 5, seed: 15);
  static GameLevel _level16() => _genLevel(16, "Final Lap", 38, 5, seed: 16);
  static GameLevel _level17() => _genLevel(17, "Nitro", 20, 3, seed: 17);
  static GameLevel _level18() => _genLevel(18, "Redline", 24, 4, seed: 18);
  static GameLevel _level19() => _genLevel(19, "Pit Stop", 26, 4, seed: 19);
  static GameLevel _level20() => _genLevel(20, "Championship", 30, 5, seed: 20);
  static GameLevel _level21() => _genLevel(21, "Ghost Car", 32, 5, seed: 21);
  static GameLevel _level22() => _genLevel(22, "Legends", 34, 5, seed: 22);
  static GameLevel _level23() => _genLevel(23, "Formula", 36, 5, seed: 23);
  static GameLevel _level24() => _genLevel(24, "Monaco", 38, 5, seed: 24);
  static GameLevel _level25() => _genLevel(25, "Daytona", 40, 5, seed: 25);
  static GameLevel _level26() => _genLevel(26, "Le Mans", 42, 5, seed: 26);
  static GameLevel _level27() => _genLevel(27, "Silverstone", 45, 5, seed: 27);
  static GameLevel _level28() => _genLevel(28, "Suzuka", 48, 5, seed: 28);
  static GameLevel _level29() => _genLevel(29, "Ultimate", 50, 5, seed: 29);
  static GameLevel _level30() => _genLevel(30, "Wheel Out Master", 55, 5, seed: 30);
  static GameLevel _level31() => _genLevel(31, "Rainy Avenue", 28, 3, seed: 31);
  static GameLevel _level32() => _genLevel(32, "Metro Gridlock", 30, 4, seed: 32);
  static GameLevel _level33() => _genLevel(33, "Taxi Stand", 31, 4, seed: 33);
  static GameLevel _level34() => _genLevel(34, "Neon Crossing", 32, 4, seed: 34);
  static GameLevel _level35() => _genLevel(35, "Underground Lot", 33, 4, seed: 35);
  static GameLevel _level36() => _genLevel(36, "Harbor Exit", 34, 4, seed: 36);
  static GameLevel _level37() => _genLevel(37, "Midnight Jam", 35, 4, seed: 37);
  static GameLevel _level38() => _genLevel(38, "Express Lane", 36, 4, seed: 38);
  static GameLevel _level39() => _genLevel(39, "Stacked Garage", 37, 4, seed: 39);
  static GameLevel _level40() => _genLevel(40, "Rush Hour Pro", 38, 5, seed: 40);
  static GameLevel _level41() => _genLevel(41, "Service Road", 39, 5, seed: 41);
  static GameLevel _level42() => _genLevel(42, "Airport Pickup", 40, 5, seed: 42);
  static GameLevel _level43() => _genLevel(43, "Foggy Ramp", 41, 5, seed: 43);
  static GameLevel _level44() => _genLevel(44, "Double Parked", 42, 5, seed: 44);
  static GameLevel _level45() => _genLevel(45, "Police Escort", 43, 5, seed: 45);
  static GameLevel _level46() => _genLevel(46, "Legend Street", 44, 5, seed: 46);
  static GameLevel _level47() => _genLevel(47, "Canyon Lot", 45, 5, seed: 47);
  static GameLevel _level48() => _genLevel(48, "Storm Drain", 46, 5, seed: 48);
  static GameLevel _level49() => _genLevel(49, "VIP Garage", 47, 5, seed: 49);
  static GameLevel _level50() => _genLevel(50, "Impossible Turn", 48, 5, seed: 50);
  static GameLevel _level51() => _genLevel(51, "Warehouse Maze", 49, 5, seed: 51);
  static GameLevel _level52() => _genLevel(52, "Highway Merge", 50, 5, seed: 52);
  static GameLevel _level53() => _genLevel(53, "Final Checkpoint", 51, 5, seed: 53);
  static GameLevel _level54() => _genLevel(54, "Carbon Alley", 52, 5, seed: 54);
  static GameLevel _level55() => _genLevel(55, "Elite Convoy", 53, 5, seed: 55);
  static GameLevel _level56() => _genLevel(56, "Overnight Shift", 54, 5, seed: 56);
  static GameLevel _level57() => _genLevel(57, "No Margin", 55, 5, seed: 57);
  static GameLevel _level58() => _genLevel(58, "Super Speedway", 56, 5, seed: 58);
  static GameLevel _level59() => _genLevel(59, "The Last Gate", 58, 5, seed: 59);
  static GameLevel _level60() => _genLevel(60, "World Champion", 60, 5, seed: 60);

  static GameLevel _genLevel(int id, String name, int par, int diff, {required int seed, int gridSize = 6, Weather? weather}) {
    // Deterministic level factory with a guaranteed escape backbone:
    // the red wheel always has 1-3 movable vertical blockers in the exit lane,
    // while extra traffic fills the garage without occupying the blockers' routes.
    final rnd = _PseudoRandom(seed * 9973);
    final int size = gridSize;
    const int exitRow = 2;
    final cars = <CarModel>[];
    final occupied = <String>{};
    final reserved = <String>{};

    String key(int x, int y) => '$x,$y';

    void reserveColumn(int x) {
      for (int y = 0; y < size; y++) {
        reserved.add(key(x, y));
      }
    }

    bool place(CarModel car, {bool ignoreReserved = false}) {
      for (final point in car.occupiedCells()) {
        if (point.x < 0 || point.x >= size || point.y < 0 || point.y >= size) return false;
        final cell = key(point.x, point.y);
        if (occupied.contains(cell)) return false;
        if (!ignoreReserved && reserved.contains(cell)) return false;
      }
      cars.add(car);
      for (final point in car.occupiedCells()) {
        occupied.add(key(point.x, point.y));
      }
      return true;
    }

    final targetX = rnd.nextInt(2);
    place(
      CarModel(
        id: 'R',
        x: targetX,
        y: exitRow,
        length: 2,
        orientation: CarOrientation.horizontal,
        isTarget: true,
        color: AppTheme.targetRed,
        darkColor: AppTheme.targetRedDark,
        carType: CarType.sports,
      ),
      ignoreReserved: true,
    );

    final blockerColumns = <int>{(targetX + 2).clamp(2, 4).toInt(), 5};
    if (diff >= 5) blockerColumns.add(4);
    int blockerIndex = 0;
    for (final column in blockerColumns) {
      reserveColumn(column);
      final downMover = blockerIndex.isEven;
      place(
        CarModel(
          id: 'B$blockerIndex',
          x: column,
          y: downMover ? 1 : 2,
          length: 2,
          orientation: CarOrientation.vertical,
          color: _c(seed + blockerIndex),
          darkColor: _d(seed + blockerIndex),
        ),
        ignoreReserved: true,
      );
      blockerIndex++;
    }

    // Keep a cinematic exit tunnel clear except for the designed blockers.
    for (int x = targetX + 2; x < size; x++) {
      reserved.add(key(x, exitRow));
    }

    final desiredTraffic = (6 + diff * 2 + rnd.nextInt(3)).clamp(8, 15).toInt();
    int attempts = 0;
    int idx = 0;
    while (cars.length < desiredTraffic && attempts < 280) {
      attempts++;
      final horiz = rnd.nextBool();
      final len = rnd.nextInt(5) == 0 ? 3 : 2;
      final x = rnd.nextInt(size - (horiz ? len : 1) + 1);
      final y = rnd.nextInt(size - (horiz ? 1 : len) + 1);

      // Never create another permanent blocker in the red car exit row.
      if (horiz && y == exitRow && x + len > targetX + 1) continue;

      // Assign varied car types
      final carTypes = CarType.values;
      final carType = carTypes[(idx + seed) % carTypes.length];

      final car = CarModel(
        id: 'C$idx',
        x: x,
        y: y,
        length: len,
        orientation: horiz ? CarOrientation.horizontal : CarOrientation.vertical,
        color: _c(idx + seed + 4),
        darkColor: _d(idx + seed + 4),
        carType: carType,
      );

      if (place(car)) idx++;
    }

    return GameLevel(
      id: id, 
      name: name, 
      exitRow: exitRow, 
      cars: cars, 
      parMoves: par, 
      difficulty: diff,
      weather: weather ?? Weather.clear,
    );
  }
}
class _PseudoRandom {
  int _seed;
  _PseudoRandom(this._seed);
  int nextInt(int max) {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return _seed % max;
  }
  bool nextBool() => nextInt(2) == 0;
}
