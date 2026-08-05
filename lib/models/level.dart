import 'car.dart';

class GameLevel {
  final int id;
  final String name;
  final int gridSize;
  final int exitRow; // row where red car needs to exit (right side)
  final List<CarModel> cars;
  final int parMoves;
  final int difficulty; // 1-5

  const GameLevel({
    required this.id,
    required this.name,
    this.gridSize = 6,
    required this.exitRow,
    required this.cars,
    this.parMoves = 10,
    this.difficulty = 1,
  });

  GameLevel clone() {
    return GameLevel(
      id: id,
      name: name,
      gridSize: gridSize,
      exitRow: exitRow,
      cars: cars.map((c) => c.clone()).toList(),
      parMoves: parMoves,
      difficulty: difficulty,
    );
  }
}

class GameState {
  final GameLevel level;
  final List<CarModel> cars;
  final int moves;
  final List<List<CarModel>> history;

  GameState({
    required this.level,
    required this.cars,
    this.moves = 0,
    this.history = const [],
  });

  GameState copyWith({
    List<CarModel>? cars,
    int? moves,
    List<List<CarModel>>? history,
  }) {
    return GameState(
      level: level,
      cars: cars ?? this.cars.map((c) => c.clone()).toList(),
      moves: moves ?? this.moves,
      history: history ?? this.history,
    );
  }

  List<List<bool>> occupiedGrid() {
    int size = level.gridSize;
    List<List<bool>> grid = List.generate(size, (_) => List.filled(size, false));
    for (var car in cars) {
      for (var p in car.occupiedCells()) {
        if (p.x >= 0 && p.x < size && p.y >= 0 && p.y < size) {
          grid[p.y][p.x] = true;
        }
      }
    }
    return grid;
  }

  bool canMove(CarModel car, int delta) {
    int size = level.gridSize;
    // build occupancy without this car
    List<List<bool>> grid = List.generate(size, (_) => List.filled(size, false));
    for (var c in cars) {
      if (c.id == car.id) continue;
      for (var p in c.occupiedCells()) {
        if (p.x >= 0 && p.x < size && p.y >= 0 && p.y < size) {
          grid[p.y][p.x] = true;
        }
      }
    }

    if (car.isHorizontal) {
      int newX = car.x + delta;
      if (newX < 0) return false;
      if (newX + car.length > size) {
        // allow target car to go out 1 beyond for win
        if (car.isTarget && newX + car.length == size + 1 && car.y == level.exitRow) {
          // need path clear to exit
          // check cells between old tail and new
          // only allow if delta positive and moving towards exit
          if (delta > 0) {
            // check intermediate cells within grid
            for (int x = car.x + car.length; x < size; x++) {
              if (grid[car.y][x]) return false;
            }
            return true;
          }
        }
        return false;
      }
      // check collisions
      if (delta > 0) {
        for (int i = 0; i < delta; i++) {
          int checkX = car.x + car.length + i;
          if (checkX < size && grid[car.y][checkX]) return false;
        }
      } else {
        for (int i = -1; i >= delta; i--) {
          int checkX = car.x + i;
          if (checkX >= 0 && grid[car.y][checkX]) return false;
        }
      }
    } else {
      int newY = car.y + delta;
      if (newY < 0 || newY + car.length > size) return false;
      if (delta > 0) {
        for (int i = 0; i < delta; i++) {
          int checkY = car.y + car.length + i;
          if (checkY < size && grid[checkY][car.x]) return false;
        }
      } else {
        for (int i = -1; i >= delta; i--) {
          int checkY = car.y + i;
          if (checkY >= 0 && grid[checkY][car.x]) return false;
        }
      }
    }
    return true;
  }

  int maxMoveInDirection(CarModel car, int dir) {
    // dir = 1 or -1
    int max = 0;
    while (true) {
      int next = max + dir;
      if (canMove(car, next)) {
        max = next;
      } else {
        break;
      }
      if (max.abs() > 6) break; // safety
    }
    return max;
  }

  bool isWin() {
    var target = cars.firstWhere((c) => c.isTarget);
    // target at exit => x = 4 for length 2 (so right edge at 6) => actually x==4 and y==exitRow means needs one more to exit? We consider win when x == 5 (outside) or x == 4 and next move to 5 clears.
    // Our canMove allows x+length == size+1 as win position. So win if target.x == size -1? Let's define win as target.x >= size-1 (5) for length 2 => its front beyond grid.
    if (target.isHorizontal && target.y == level.exitRow) {
      if (target.x + target.length > level.gridSize - 1) {
        // check if front is at or beyond gridSize
        if (target.x >= level.gridSize - target.length + 1) {
          // need to detect if it's fully out? Actually for animation: when x == 4 it sits at edge but we want win when x==5
          return target.x >= level.gridSize - 1; // for 6 grid and length 2, x>=4 means at edge, we will trigger exit animation when dragging out, but count as win when x==4 and trying to go to 5, we treat x>=4 + path clear as pre-win.
        }
      }
    }
    return false;
  }

  bool isSpecificallyWon() {
    // true win when target's x = gridSize -1 (fully aligned to exit) actually length 2 at x=4 is at exit edge, that's win enough
    var target = cars.firstWhere((c) => c.isTarget);
    return target.isHorizontal && target.y == level.exitRow && target.x == level.gridSize - target.length;
    // But we will trigger final exit animation from there.
  }

  bool isExited() {
    var target = cars.firstWhere((c) => c.isTarget);
    return target.x >= level.gridSize;
  }
}
