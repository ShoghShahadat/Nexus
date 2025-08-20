import 'package:nexus/nexus.dart' hide SpawnerComponent;
import 'package:nexus/src/components/gameplay_components.dart';
import 'package:nexus/src/events/gameplay_events.dart';

/// A system that handles the spawning of new entities based on a `SpawnerComponent`.
/// سیستمی که تولید موجودیت‌های جدید را بر اساس `SpawnerComponent` مدیریت می‌کند.
class SpawnerSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    world.eventBus.on<FireEvent>(_onFire);
  }

  void _onFire(FireEvent event) {
    final entity = world.entities[event.spawnerId];
    if (entity == null) return;
    final spawner = entity.get<SpawnerComponent>();
    if (spawner != null && spawner.cooldown <= 0) {
      _spawn(entity, spawner);
    }
  }

  @override
  bool matches(Entity entity) {
    return entity.has<SpawnerComponent>() && entity.has<PositionComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final spawner = entity.get<SpawnerComponent>()!;

    if (spawner.cooldown > 0) {
      spawner.cooldown -= dt;
    }

    if (spawner.wantsToFire && spawner.cooldown <= 0) {
      _spawn(entity, spawner);
    }

    entity.add(spawner);
  }

  void _spawn(Entity spawnerEntity, SpawnerComponent spawner) {
    final newEntity = spawner.prefab();
    final spawnerPos = spawnerEntity.get<PositionComponent>()!;

    // If the new entity already has a position, update it. Otherwise, add one.
    // اگر موجودیت جدید از قبل کامپوننت موقعیت دارد، آن را به‌روز کن. در غیر این صورت، یکی اضافه کن.
    final newEntityPos =
        newEntity.get<PositionComponent>() ?? PositionComponent(x: 0, y: 0);
    newEntityPos.x = spawnerPos.x;
    newEntityPos.y = spawnerPos.y;
    newEntity.add(newEntityPos);

    world.addEntity(newEntity);
    spawner.cooldown = 1.0 / spawner.fireRate;
  }
}
