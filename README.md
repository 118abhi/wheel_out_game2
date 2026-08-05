# 🚗 Wheel Out - Perfect Parking Puzzle Game

**Premium Animated Wheel Out Game built with Flutter & Dart for Android**

A beautifully crafted, highly polished parking jam puzzle game featuring fluid Flutter animations, custom wheel physics, and 60 levels, profile progression, garage rewards.

![Wheel Out](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter)
![Android](https://img.shields.io/badge/Android-Compatible-3DDC84?logo=android)
![Animations](https://img.shields.io/badge/Animations-60FPS-FF6B6B)

---

## 🎮 Game Concept: Wheel Out!

**Objective:** Slide the blocking cars and **free the red wheel** out of the parking lot!

### Core Mechanics
- **6x6 Grid Puzzle** - Classic Rush Hour style
- **Horizontal & Vertical Cars** - Each can only move along its orientation
- **Red Target Car** - Must reach the right edge exit
- **Real Wheel Physics** - Wheels spin based on drag distance, tire smoke on exit!
- **Reward Wheel** - Spin the fortune wheel every 3 levels for coins & hints

---

## ✨ Premium Features & Flutter Animations

### 🎨 Visual Excellence
- **Realistic Custom Car Widget** with top-down body panels, cabin glass, mirrors, grille, headlights, taillights, wheel arches, and **4 rotating fitted wheels per car**
- **Wheel Rotation Physics** - `rotation = distance / wheelCircumference`
- **Premium Animated Front Page** with neon city skyline, moving traffic, perspective highway, floating particles, cinematic glow, and polished Roboto typography
- **Realistic Road/Parking Lot** with asphalt grit, curbs, cracks, puddle reflections, bay numbers, stop line, exit chevrons, and procedural texture (`CustomPainter`)
- **Grid with Parking Spot Markers** - Dashed L-corners
- **Particle Systems** - Confetti explosion on win, tire smoke on exit
- **Exit Glow** with pulsing arrow

### 🌊 Flutter Animation Magic Used
- **Implicit**: `AnimatedBuilder`, `Tween`, `CurvedAnimation`
- **Explicit**: `AnimationController` with `SingleTickerProviderStateMixin`, `TickerProviderStateMixin`
- **Physics**: `ElasticOut`, `easeInOutCubic`, `decelerate`, spring simulations
- **Hero-like Transitions**: Board scale-in with elastic, card stagger with `Interval`
- **Gesture Physics**: Pan drag with clamped movement, legal move guide lanes, parking sensor readout, shake animation when blocked (`sin` wave)
- **Reward Wheel**: Full custom `CustomPainter` wheel with `SweepGradient`, spinning with `easeOutCubic` deceleration
- **Confetti**: 120 particles with gravity, rotation, life cycle
- **Splash Screen**: Floating logo + orbiting dots background

### 🧩 Game Systems
- **60 Production Levels** - From "First Spin" to "Wheel Out Master"
  - Difficulty 1-5 stars with color coding
  - Par moves system, star rating
  - Deterministic generated challenge layouts from levels 9-60 with guaranteed escape backbones
- **Game State Management**
  - `GameState` with history stack for undo
  - Collision detection via occupancy grid
  - `canMove()` and `maxMoveInDirection()`
- **Hint System** - Finds blocking car and shows animated arrow + glow pulse
- **Pause/Pro Coach Overlay** - Resume, restart, objectives, star forecast, controls, and profile resource summary
- **Parking Sensor Feature** - Tap a car to show legal move lanes and forward/back movement counts
- **Win Animation** - Red car accelerates out with smoke, then confetti celebration

### 📱 Screens
1. **Splash** - Animated wheel logo, orbiting particles
2. **Home** - Floating card, shimmer buttons with scale feedback
3. **Level Select** - 3-column grid with stagger elastic animation, lock states
4. **Game** - Interactive board, progress bar, hint & reset
5. **Profile/Garage** - Saved driver stats, achievements, stars, coins, hints, and skins
6. **Wheel Reward** - Fortune wheel spin with 8 segments
7. **Win** - Confetti, star reveal, stats, next level

---

## 🛠 Tech Stack

- **Flutter 3.10+** & **Dart 3.2+**
- **shared_preferences** for offline profile/progress saves
- **Material 3** Dark Theme with custom colors
- **Android** - Kotlin MainActivity, Gradle 8.7, AGP 8.5.0, Java 17

---

## 📁 Project Structure

```
lib/
├── main.dart                  # App entry + navigator with fade transitions
├── theme/
│   └── app_theme.dart         # Colors, gradients, Material 3 theme
├── models/
│   ├── car.dart               # CarModel with orientation & cells
│   ├── level.dart             # GameLevel & GameState with logic
│   └── player_profile.dart    # Saved profile, rewards, skins, stats
├── utils/
│   └── levels_data.dart       # 60 levels repository
├── game/
│   ├── car_widget.dart        # Premium car visuals + wheel rotation
│   ├── game_board.dart        # Board logic, drag, exit, smoke
│   ├── wheel_painter.dart     # Reward wheel CustomPainter
│   └── particle_system.dart   # Confetti & smoke particles
└── screens/
    ├── splash_screen.dart
    ├── home_screen.dart
    ├── level_select_screen.dart
    ├── game_screen.dart
    ├── profile_screen.dart
    ├── win_screen.dart
    └── wheel_reward_screen.dart

android/ - Complete Android project ready for build
web/ - PWA ready with icons & manifest
```

---

## 🚀 How to Run

### Prerequisites
- Flutter SDK installed (https://flutter.dev)
- Android Studio / VS Code

### Steps
```bash
# Get dependencies
flutter pub get

# Run on Android device/emulator
flutter run

# Build APK
flutter build apk --release

# Build App Bundle for Play Store
flutter build appbundle --release

# Run on Web
flutter run -d chrome
```

### Controls
- **Drag cars** along their axis
- **Tap car** to select (glow effect)
- **Undo** with ↩️ button
- **Hint** shows blocking car with pulsing arrow
- **Exit** - When red car at edge, it auto drives out!

---

## 🎯 Level Design Philosophy

- Levels 1-3: Tutorial easy (par 5-8)
- Levels 4-8: Medium, introduce vertical blockers
- Levels 9-15: Hard, require planning
- Levels 16-30: Expert city levels
- Levels 31-45: Night run challenge levels
- Levels 46-60: Mastery tour with dense traffic and higher par targets

All levels tested to be solvable with our generation logic ensuring at least one path.

---

## 🎨 Animation Showcase Code Snippets

**Wheel Rotation:**
```dart
double dist = dragDistance.abs();
wheelRotation = dist / (wheelCircumference) * 2π
```

**Reward Wheel Spin:**
```dart
AnimationController(duration: 4s)
Tween(begin: 0, end: 5 full rotations + targetAngle)
CurvedAnimation(curve: easeOutCubic) // realistic deceleration
```

**Car Exit:**
```dart
Exit animation: easeInCubic from x=4 to x=8
Smoke particles spawn at exit with life decay
```

---

## 🏆 Why This is "Perfect"

- ✅ **60 FPS** smooth animations
- ✅ **Zero plugins** - pure Flutter performance
- ✅ **Production Ready** - 60 levels, profile saves, rewards, garage skins, achievements
- ✅ **Beautiful UI** - Glassmorphism, gradients, shadows, particles
- ✅ **Android Ready** - Full android/ folder, works with `flutter build apk`
- ✅ **Animated Like a Game** - Every interaction has feedback: scale, shake, pulse, glow
- ✅ **Wheel Theme** - Real spinning wheels on cars + fortune wheel mini-game

---

## 📄 License

MIT - Feel free to expand with sounds, more levels, and Play Store publishing!

Made with ❤️ and Flutter

# wheel_out_game2
