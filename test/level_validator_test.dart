import 'package:flutter_test/flutter_test.dart';

import 'package:wheel_out_game2/utils/level_validator.dart';
import 'package:wheel_out_game2/utils/levels_data.dart';

void main() {
  test('the complete 200-level campaign is solvable', () {
    final levels = LevelsRepository.allLevels;
    expect(levels.length, 200);

    final unsolved = <int>[];
    for (final level in levels) {
      if (!LevelValidator.isSolvable(level)) unsolved.add(level.id);
    }

    expect(unsolved, isEmpty,
        reason: 'Unsolvable level ids: ${unsolved.join(', ')}');
  });

  test('level ids are unique and sequential', () {
    final ids = LevelsRepository.allLevels.map((level) => level.id).toList();
    expect(ids, List<int>.generate(200, (index) => index + 1));
  });

  test('every level has one valid target car and a legal exit row', () {
    for (final level in LevelsRepository.allLevels) {
      final targets = level.cars.where((car) => car.isTarget).toList();
      expect(targets, hasLength(1), reason: 'Level ${level.id}');
      expect(targets.single.isHorizontal, isTrue,
          reason: 'Level ${level.id} target must be horizontal');
      expect(level.exitRow, inInclusiveRange(0, level.gridSize - 1),
          reason: 'Level ${level.id}');
    }
  });
}
