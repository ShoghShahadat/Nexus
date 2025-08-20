import 'dart:math';
import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/particle_spawner_component.dart';

/// A system that spawns new particle entities based on a ParticleSpawnerComponent.
/// سیستمی که موجودیت‌های ذره جدید را بر اساس یک ParticleSpawnerComponent تولید می‌کند.
class ParticleSpawningSystem extends System {
  final Random _random = Random();

  @override
  bool matches(Entity entity) {
    return entity.has<ParticleSpawnerComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final spawner = entity.get<ParticleSpawnerComponent>()!;
    spawner.timeSinceLastSpawn += dt;

    final timePerSpawn = 1.0 / spawner.spawnRate;
    while (spawner.timeSinceLastSpawn > timePerSpawn) {
      spawner.timeSinceLastSpawn -= timePerSpawn;
      world.addEntity(_createParticle(entity));
    }
    entity.add(spawner);
  }

  Entity _createParticle(Entity spawnerEntity) {
    final spawnerLink = spawnerEntity.get<SpawnerLinkComponent>();
    PositionComponent? spawnPos;

    if (spawnerLink != null) {
      final targetEntity = world.entities.values.firstWhereOrNull((e) =>
          e.get<TagsComponent>()?.hasTag(spawnerLink.targetTag) ?? false);
      spawnPos = targetEntity?.get<PositionComponent>();
    }
    spawnPos ??= spawnerEntity.get<PositionComponent>();

    if (spawnPos == null) return Entity();

    final entity = Entity();
    final angle = _random.nextDouble() * 2 * pi;
    final speed = _random.nextDouble() * 150 + 50;

    entity.add(
        PositionComponent(x: spawnPos.x, y: spawnPos.y, width: 3, height: 3));
    entity.add(VelocityComponent(x: cos(angle) * speed, y: sin(angle) * speed));
    entity.add(ParticleComponent(
      maxAge: _random.nextDouble() * 3 + 2,
      initialColorValue: 0xFFFFFFFF,
      finalColorValue: 0xFF4A148C,
    ));
    entity.add(TagsComponent({'particle'}));
    return entity;
  }
}
