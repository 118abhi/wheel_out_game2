import 'package:flutter/material.dart';

enum WeatherType {
  clear,
  rain,
  fog,
  night,
  storm,
}

class Weather {
  final WeatherType type;
  final String name;
  final IconData icon;
  final Color color;
  final double intensity; // 0.0 - 1.0

  const Weather({
    required this.type,
    required this.name,
    required this.icon,
    required this.color,
    this.intensity = 0.8,
  });

  static const clear = Weather(
    type: WeatherType.clear,
    name: "Clear",
    icon: Icons.wb_sunny_rounded,
    color: Color(0xFFFFD54F),
    intensity: 0.6,
  );

  static const rain = Weather(
    type: WeatherType.rain,
    name: "Rain",
    icon: Icons.umbrella_rounded,
    color: Color(0xFF5C6BC0),
    intensity: 0.9,
  );

  static const fog = Weather(
    type: WeatherType.fog,
    name: "Fog",
    icon: Icons.cloud_rounded,
    color: Color(0xFF90A4AE),
    intensity: 0.7,
  );

  static const night = Weather(
    type: WeatherType.night,
    name: "Night",
    icon: Icons.nightlight_round,
    color: Color(0xFF283593),
    intensity: 0.85,
  );

  static const storm = Weather(
    type: WeatherType.storm,
    name: "Storm",
    icon: Icons.thunderstorm_rounded,
    color: Color(0xFF37474F),
    intensity: 1.0,
  );

  static List<Weather> get all => [clear, rain, fog, night, storm];
}