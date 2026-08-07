import '../models/car.dart';
import '../models/level.dart';

/// Deterministic breadth-first validator for Rush-Hour layouts. It is kept
/// separate from the UI so level packs can be checked in tests or CI.
class LevelValidator {
  const LevelValidator._();

  static bool isSolvable(GameLevel level, {int maxStates = 50000}) {
    final start = level.cars.map((car) => car.isHorizontal ? car.x : car.y).join('|');
    final queue = <List<int>>[level.cars.map((car) => car.isHorizontal ? car.x : car.y).toList()];
    final visited = <String>{start};
    var checked = 0;

    while (queue.isNotEmpty && checked++ < maxStates) {
      final positions = queue.removeAt(0);
      final cars = <CarModel>[];
      for (var i = 0; i < level.cars.length; i++) {
        final original = level.cars[i];
        cars.add(CarModel(
          id: original.id,
          x: original.isHorizontal ? positions[i] : original.x,
          y: original.isHorizontal ? original.y : positions[i],
          length: original.length,
          orientation: original.orientation,
          isTarget: original.isTarget,
          color: original.color,
          darkColor: original.darkColor,
          carType: original.carType,
        ));
      }
      final state = GameState(level: level, cars: cars);
      if (state.isSpecificallyWon()) return true;

      for (var i = 0; i < cars.length; i++) {
        final car = cars[i];
        for (final delta in <int>[-1, 1]) {
          if (!state.canMove(car, delta)) continue;
          final next = List<int>.from(positions);
          next[i] += delta;
          final key = next.join('|');
          if (visited.add(key)) queue.add(next);
        }
      }
    }
    return false;
  }

  static String _key(int x, int y) => '$x,$y';
}
