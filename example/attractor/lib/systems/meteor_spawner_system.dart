import 'dart:math';
import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import '../components/meteor_component.dart';
import '../components/meteor_target_component.dart';

/// A system that periodically spawns meteors with varied behaviors.
class MeteorSpawnerSystem extends System {
  final Random _random = Random();
  double _timeSinceLastSpawn = 0;
  double _spawnInterval = 4.0;

  @override
  bool matches(Entity entity) {
    return entity.has<AttractorComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    _timeSinceLastSpawn += dt;

    if (_timeSinceLastSpawn >= _spawnInterval) {
      _timeSinceLastSpawn = 0;
      _spawnInterval = _random.nextDouble() * 3 + 2; // Next wave in 2-5 secs

      // --- NEW: Spawn a random number of meteors ---
      final meteorCount = _random.nextInt(3) + 1; // 1 to 3 meteors
      for (int i = 0; i < meteorCount; i++) {
        _createMeteor();
      }
    }
  }

  void _createMeteor() {
    final meteor = Entity();
    const screenWidth = 400.0;
    const screenHeight = 800.0;

    final startEdge = _random.nextInt(4);
    double startX, startY;
    switch (startEdge) {
      case 0:
        startX = _random.nextDouble() * screenWidth;
        startY = -50.0;
        break;
      case 1:
        startX = screenWidth + 50.0;
        startY = _random.nextDouble() * screenHeight;
        break;
      case 2:
        startX = _random.nextDouble() * screenWidth;
        startY = screenHeight + 50.0;
        break;
      default:
        startX = -50.0;
        startY = _random.nextDouble() * screenHeight;
        break;
    }

    meteor.add(PositionComponent(x: startX, y: startY, width: 25, height: 25));
    meteor.add(MeteorComponent());
    meteor.add(TagsComponent({'meteor'}));

    // --- NEW: Randomly decide the meteor's behavior ---
    if (_random.nextDouble() < 0.3) {
      // 30% chance to be a homing meteor
      final attractor = world.entities.values
          .firstWhereOrNull((e) => e.has<AttractorComponent>());
      if (attractor != null) {
        meteor.add(MeteorTargetComponent(targetId: attractor.id));
      }
    } else {
      // 70% chance to have a random trajectory
      meteor.add(MeteorTargetComponent(targetId: null));
    }

    world.addEntity(meteor);
  }
}
