import 'package:flutter/material.dart';

enum CarOrientation { horizontal, vertical }

enum CarType { sedan, suv, truck, police, sports, taxi, van, classic, electric, luxury }

class CarModel {
  final String id;
  final int x;
  final int y;
  final int length;
  final CarOrientation orientation;
  final bool isTarget;
  final Color color;
  final Color darkColor;
  final CarType carType;

  // runtime animated position
  double animX;
  double animY;

  CarModel({
    required this.id,
    required this.x,
    required this.y,
    required this.length,
    required this.orientation,
    this.isTarget = false,
    required this.color,
    required this.darkColor,
    this.carType = CarType.sedan,
  })  : animX = x.toDouble(),
        animY = y.toDouble();

  CarModel copyWith({int? x, int? y, double? animX, double? animY}) {
    return CarModel(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      length: length,
      orientation: orientation,
      isTarget: isTarget,
      color: color,
      darkColor: darkColor,
    )..animX = animX ?? this.animX
     ..animY = animY ?? this.animY;
  }

  bool get isHorizontal => orientation == CarOrientation.horizontal;

  // occupied cells
  List<Point> occupiedCells() {
    List<Point> cells = [];
    for (int i = 0; i < length; i++) {
      if (isHorizontal) {
        cells.add(Point(x + i, y));
      } else {
        cells.add(Point(x, y + i));
      }
    }
    return cells;
  }

  CarModel clone() {
    return CarModel(
      id: id,
      x: x,
      y: y,
      length: length,
      orientation: orientation,
      isTarget: isTarget,
      color: color,
      darkColor: darkColor,
    )..animX = animX
     ..animY = animY;
  }
}

class Point {
  final int x;
  final int y;
  Point(this.x, this.y);

  @override
  bool operator ==(Object other) => other is Point && other.x == x && other.y == y;
  @override
  int get hashCode => Object.hash(x, y);
}
