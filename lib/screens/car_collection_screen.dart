import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/sound_manager.dart';
import '../widgets/animated_parking_background.dart';

class CarCollectionScreen extends StatefulWidget {
  final VoidCallback onBack;

  const CarCollectionScreen({super.key, required this.onBack});

  @override
  State<CarCollectionScreen> createState() => _CarCollectionScreenState();
}

class _CarCollectionScreenState extends State<CarCollectionScreen> {
  final List<CarSkin> cars = [
    CarSkin("Classic Red", AppTheme.targetRed, Icons.directions_car_rounded, 0, true),
    CarSkin("Night Rider", AppTheme.primary, Icons.electric_bolt_rounded, 25, false),
    CarSkin("Taxi Pro", AppTheme.accent, Icons.local_taxi_rounded, 40, false),
    CarSkin("Cyber Truck", AppTheme.secondary, Icons.fire_truck_rounded, 60, false),
    CarSkin("Police Cruiser", Colors.blue, Icons.local_police_rounded, 80, false),
    CarSkin("Sports Racer", Colors.deepOrange, Icons.sports_motorsports_rounded, 120, false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.background, AppTheme.surface],
          ),
        ),
        child: SafeArea(
          child: AnimatedParkingBackground(
            showRoad: true,
            intensity: 0.9,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: cars.length,
                    itemBuilder: (context, index) {
                      return _CarCard(car: cars[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              SoundManager().playClick();
              widget.onBack();
            },
            icon: const Icon(Icons.arrow_back_rounded),
            style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('CAR COLLECTION', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${cars.where((c) => c.unlocked).length}/${cars.length}', 
              style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class CarSkin {
  final String name;
  final Color color;
  final IconData icon;
  final int requiredStars;
  final bool unlocked;

  CarSkin(this.name, this.color, this.icon, this.requiredStars, this.unlocked);
}

class _CarCard extends StatelessWidget {
  final CarSkin car;

  const _CarCard({required this.car});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            car.color.withOpacity(car.unlocked ? 0.35 : 0.08),
            Colors.white.withOpacity(0.03),
          ],
        ),
        border: Border.all(color: car.color.withOpacity(car.unlocked ? 0.4 : 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            car.icon,
            size: 58,
            color: car.unlocked ? Colors.white : Colors.white24,
          ),
          const SizedBox(height: 16),
          Text(
            car.name,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: car.unlocked ? Colors.white : Colors.white38,
            ),
          ),
          const SizedBox(height: 4),
          if (!car.unlocked)
            Text(
              '${car.requiredStars} stars',
              style: const TextStyle(fontSize: 12, color: Colors.white38),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('OWNED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.accent)),
            ),
        ],
      ),
    );
  }
}