import 'dart:math';
import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import '../components/meteor_component.dart';
import '../components/network_components.dart';
import '../events.dart';

/// A system that runs ONLY on the host client to spawn and broadcast meteors.
class ClientSpawnerSystem extends System {
  final Random _random = Random();

  @override
  bool matches(Entity entity) {
    // This system runs on the spawner entity, but only if the local player is the host.
    final localPlayer = world.entities.values.firstWhereOrNull(
        (e) => e.get<PlayerComponent>()?.isLocalPlayer ?? false);
    return (localPlayer?.get<PlayerComponent>()?.isHost ?? false) &&
        entity.has<SpawnerComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final spawner = entity.get<SpawnerComponent>()!;
    if (!spawner.wantsToFire) return;

    spawner.cooldown -= dt;
    if (spawner.cooldown <= 0) {
      spawner.cooldown = 1.0 / spawner.frequency.eventsPerSecond;
      _spawnMeteor();
    }
    entity.add(spawner);
  }

  void _spawnMeteor() {
    final meteor = Entity();
    final meteorNetworkId = meteor.id; // Use the local ID as the network ID

    final components = [
      PositionComponent(
          x: _random.nextDouble() * 800, y: -50, width: 30, height: 30),
      VelocityComponent(
          x: _random.nextDouble() * 100 - 50,
          y: _random.nextDouble() * 100 + 150),
      TagsComponent({'meteor'}),
      MeteorComponent(),
      DamageComponent(25),
      CollisionComponent(tag: 'meteor', radius: 15, collidesWith: {'player'}),
      // --- FIX: Corrected typo from 'turn_speed' to 'turnSpeed'. ---
      TargetingComponent(turnSpeed: 1.5),
      // Ensure it gets cleaned up if it goes off-screen
      LifecyclePolicyComponent(destructionCondition: (e) {
        final pos = e.get<PositionComponent>();
        return pos != null && (pos.y > 1000 || pos.x < -100 || pos.x > 900);
      })
    ];

    // Add all components to the entity
    meteor.addComponents(components);

    // Add the entity to the host's world
    world.addEntity(meteor);

    // Broadcast the creation of this new entity to other clients
    world.eventBus.fire(RelayNewEntityEvent(
      meteorNetworkId,
      components.whereType<BinaryComponent>().toList(),
    ));
  }
}
