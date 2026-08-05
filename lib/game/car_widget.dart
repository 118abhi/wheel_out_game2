import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/car.dart';
import '../theme/app_theme.dart';

class CarWidget extends StatefulWidget {
  final CarModel car;
  final double cellSize;
  final double wheelRotation; // in radians
  final bool isDragging;
  final bool isSelected;

  const CarWidget({
    super.key,
    required this.car,
    required this.cellSize,
    this.wheelRotation = 0,
    this.isDragging = false,
    this.isSelected = false,
  });

  @override
  State<CarWidget> createState() => _CarWidgetState();
}

class _CarWidgetState extends State<CarWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;
    final cell = widget.cellSize;
    final width = car.isHorizontal ? cell * car.length : cell;
    final height = car.isHorizontal ? cell : cell * car.length;

    final isTarget = car.isTarget;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        final scale = (isTarget && !widget.isDragging) ? _pulseAnim.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cell * 0.22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(widget.isDragging ? 0.4 : 0.25),
              blurRadius: widget.isDragging ? 16 : 8,
              offset: Offset(0, widget.isDragging ? 8 : 4),
            ),
            if (widget.isSelected)
              BoxShadow(
                color: car.color.withOpacity(0.6),
                blurRadius: 12,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Stack(
          children: [
            // Car body with gradient
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(cell * 0.22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    car.color,
                    car.darkColor,
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.2,
                ),
              ),
            ),
            // Highlight
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(cell * 0.22),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.white.withOpacity(0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Window / cockpit
            _buildWindow(cell, isTarget, car.isHorizontal),
            // Doors lines
            if (car.length > 2) _buildDoorLines(cell, car.isHorizontal),
            // Headlights / taillights
            _buildLights(cell, car.isHorizontal, isTarget),
            // Wheels
            ..._buildWheels(cell, car.isHorizontal),
            // Target crown icon
            if (isTarget)
              Positioned(
                top: cell * 0.15,
                left: car.isHorizontal ? cell * 0.25 : cell * 0.18,
                child: Icon(
                  Icons.emoji_events,
                  size: cell * 0.32,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindow(double cell, bool isTarget, bool horizontal) {
    if (horizontal) {
      return Positioned(
        left: cell * 0.25,
        top: cell * 0.15,
        width: cell * (isTarget ? 1.1 : lengthFactor(cell) * 0.55),
        height: cell * 0.38,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            borderRadius: BorderRadius.circular(cell * 0.08),
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
          ),
          child: Container(
            margin: EdgeInsets.all(cell * 0.04),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.lightBlueAccent.withOpacity(0.9),
                  Colors.blue.shade900.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(cell * 0.05),
            ),
          ),
        ),
      );
    } else {
      return Positioned(
        left: cell * 0.15,
        top: cell * 0.25,
        width: cell * 0.38,
        height: cell * (isTarget ? 1.1 : lengthFactor(cell) * 0.55),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            borderRadius: BorderRadius.circular(cell * 0.08),
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
          ),
          child: Container(
            margin: EdgeInsets.all(cell * 0.04),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.lightBlueAccent.withOpacity(0.9),
                  Colors.blue.shade900.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(cell * 0.05),
            ),
          ),
        ),
      );
    }
  }

  double lengthFactor(double cell) => widget.car.length.toDouble();

  Widget _buildDoorLines(double cell, bool horiz) {
    return Positioned.fill(
      child: CustomPaint(
        painter: DoorLinePainter(
          isHorizontal: horiz,
          color: Colors.black.withOpacity(0.2),
        ),
      ),
    );
  }

  Widget _buildLights(double cell, bool horiz, bool isTarget) {
    if (horiz) {
      return Stack(
        children: [
          // Headlight right side
          Positioned(
            right: cell * 0.08,
            top: cell * 0.18,
            child: Container(
              width: cell * 0.12,
              height: cell * 0.14,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(cell * 0.04),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: cell * 0.08,
            bottom: cell * 0.18,
            child: Container(
              width: cell * 0.12,
              height: cell * 0.14,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(cell * 0.04),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
          // Tail light left
          Positioned(
            left: cell * 0.06,
            top: cell * 0.2,
            child: Container(
              width: cell * 0.08,
              height: cell * 0.12,
              decoration: BoxDecoration(
                color: isTarget ? Colors.red.shade700 : Colors.red.shade400,
                borderRadius: BorderRadius.circular(cell * 0.03),
              ),
            ),
          ),
          Positioned(
            left: cell * 0.06,
            bottom: cell * 0.2,
            child: Container(
              width: cell * 0.08,
              height: cell * 0.12,
              decoration: BoxDecoration(
                color: isTarget ? Colors.red.shade700 : Colors.red.shade400,
                borderRadius: BorderRadius.circular(cell * 0.03),
              ),
            ),
          ),
        ],
      );
    } else {
      return Stack(
        children: [
          Positioned(
            top: cell * 0.08,
            left: cell * 0.18,
            child: Container(
              width: cell * 0.14,
              height: cell * 0.12,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(cell * 0.04),
              ),
            ),
          ),
          Positioned(
            top: cell * 0.08,
            right: cell * 0.18,
            child: Container(
              width: cell * 0.14,
              height: cell * 0.12,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(cell * 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: cell * 0.06,
            left: cell * 0.2,
            child: Container(
              width: cell * 0.12,
              height: cell * 0.08,
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(cell * 0.03),
              ),
            ),
          ),
          Positioned(
            bottom: cell * 0.06,
            right: cell * 0.2,
            child: Container(
              width: cell * 0.12,
              height: cell * 0.08,
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(cell * 0.03),
              ),
            ),
          ),
        ],
      );
    }
  }

  List<Widget> _buildWheels(double cell, bool horiz) {
    final wheelSize = cell * 0.22;
    final rotation = widget.wheelRotation;

    Widget wheel(double left, double top) {
      return Positioned(
        left: left,
        top: top,
        child: Transform.rotate(
          angle: rotation,
          child: Container(
            width: wheelSize,
            height: wheelSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1E272E),
              border: Border.all(color: const Color(0xFF485460), width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: wheelSize * 0.55,
                  height: wheelSize * 0.55,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFD2DAE2),
                    border: Border.all(color: const Color(0xFF808E9B), width: 1),
                  ),
                ),
                // spokes
                CustomPaint(
                  size: Size(wheelSize * 0.7, wheelSize * 0.7),
                  painter: WheelSpokePainter(rotation: 0),
                ),
                Container(
                  width: wheelSize * 0.2,
                  height: wheelSize * 0.2,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF1E272E),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (horiz) {
      // horizontal car: 4 wheels, 2 per side (top/bottom) and front/back
      final carLen = widget.car.length.toDouble();
      return [
        wheel(cell * 0.3, -wheelSize * 0.35), // front top
        wheel(cell * 0.3, cell - wheelSize * 0.65), // front bottom
        wheel(cell * (carLen - 0.65), -wheelSize * 0.35), // rear top
        wheel(cell * (carLen - 0.65), cell - wheelSize * 0.65), // rear bottom
      ];
    } else {
      final carLen = widget.car.length.toDouble();
      return [
        wheel(-wheelSize * 0.35, cell * 0.3),
        wheel(cell - wheelSize * 0.65, cell * 0.3),
        wheel(-wheelSize * 0.35, cell * (carLen - 0.65)),
        wheel(cell - wheelSize * 0.65, cell * (carLen - 0.65)),
      ];
    }
  }
}

class DoorLinePainter extends CustomPainter {
  final bool isHorizontal;
  final Color color;
  DoorLinePainter({required this.isHorizontal, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    if (isHorizontal) {
      // vertical line in middle if length 3
      if (size.width > size.height * 2.2) {
        canvas.drawLine(
          Offset(size.width * 0.5, 0),
          Offset(size.width * 0.5, size.height),
          paint,
        );
        canvas.drawLine(
          Offset(size.width * 0.33, size.height * 0.15),
          Offset(size.width * 0.33, size.height * 0.85),
          paint..strokeWidth = 0.8,
        );
        canvas.drawLine(
          Offset(size.width * 0.66, size.height * 0.15),
          Offset(size.width * 0.66, size.height * 0.85),
          paint..strokeWidth = 0.8,
        );
      }
    } else {
      if (size.height > size.width * 2.2) {
        canvas.drawLine(
          Offset(0, size.height * 0.5),
          Offset(size.width, size.height * 0.5),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WheelSpokePainter extends CustomPainter {
  final double rotation;
  WheelSpokePainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFF1E272E)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 4; i++) {
      final angle = (math.pi * 2 / 4) * i;
      final dir = Offset(math.cos(angle), math.sin(angle)) * size.width * 0.35;
      canvas.drawLine(center, center + dir, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WheelSpokePainter oldDelegate) => oldDelegate.rotation != rotation;
}
