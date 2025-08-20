import 'dart:math';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/spawner_component.dart';

/// A system that spawns new particle entities based on a SpawnerComponent.
class ParticleSpawningSystem extends System {
  final Random _random = Random();

  @override
  bool matches(Entity entity) {
    // This system only operates on a single entity with a SpawnerComponent.
    return entity.has<SpawnerComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final spawner = entity.get<SpawnerComponent>()!;
    spawner.timeSinceLastSpawn += dt;

    final timePerSpawn = 1.0 / spawner.spawnRate;
    while (spawner.timeSinceLastSpawn > timePerSpawn) {
      spawner.timeSinceLastSpawn -= timePerSpawn;
      world.addEntity(_createParticle(entity));
    }
    entity.add(spawner); // Re-add to save the updated time
  }

  Entity _createParticle(Entity spawnerEntity) {
    final entity = Entity();
    final angle = _random.nextDouble() * 2 * pi;
    final speed = _random.nextDouble() * 50 + 20;
    final spawnerPos = spawnerEntity.get<PositionComponent>()!;

    entity.add(PositionComponent(
        x: spawnerPos.x, y: spawnerPos.y, width: 5, height: 5));
    entity.add(VelocityComponent(x: cos(angle) * speed, y: sin(angle) * speed));
    entity.add(ParticleComponent(
      maxAge: _random.nextDouble() * 3 + 2, // Lives for 2-5 seconds
      initialColorValue: 0xFFFFFFFF,
      finalColorValue: 0xFF4A148C, // Deep purple
    ));
    entity.add(TagsComponent({'particle'}));
    return entity;
  }
}
