import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF6C5CE7);
  static const secondary = Color(0xFF00CEC9);
  static const accent = Color(0xFFFFE66D);
  static const danger = Color(0xFFFD79A8);
  static const targetRed = Color(0xFFFF4757);
  static const targetRedDark = Color(0xFFD63031);
  static const background = Color(0xFF1A1A2E);
  static const surface = Color(0xFF16213E);
  static const surfaceLight = Color(0xFF0F3460);
  static const woodLight = Color(0xFFE6CCB2);
  static const woodDark = Color(0xFFCC9E7A);
  static const asphalt = Color(0xFF2C3E50);
  static const lineWhite = Color(0xFFEAEAEA);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        background: background,
        error: danger,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.white70,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: primary.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
    );
  }

  static List<Color> carColors = [
    const Color(0xFF74B9FF),
    const Color(0xFF55EFC4),
    const Color(0xFFFFEAA7),
    const Color(0xFFA29BFE),
    const Color(0xFFFD79A8),
    const Color(0xFFFDCB6E),
    const Color(0xFF00B894),
    const Color(0xFF0984E3),
    const Color(0xFFE17055),
    const Color(0xFF00CEC9),
  ];
}
