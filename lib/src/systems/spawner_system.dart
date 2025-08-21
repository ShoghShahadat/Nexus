import 'package:nexus/nexus.dart' hide SpawnerComponent;
import 'package:nexus/src/components/gameplay_components.dart';
import 'package:nexus/src/core/utils/frequency.dart';
import 'package:nexus/src/events/gameplay_events.dart';

/// A system that handles the spawning of new entities based on a `SpawnerComponent`.
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

    // *** MODIFIED: Check the optional condition before deciding to fire. ***
    // *** اصلاح: شرط اختیاری را قبل از تصمیم به ساخت، بررسی می‌کند. ***
    final bool conditionMet = spawner.condition?.call() ?? true;

    if (spawner.wantsToFire && spawner.cooldown <= 0 && conditionMet) {
      _spawn(entity, spawner);
    }

    entity.add(spawner);
  }

  void _spawn(Entity spawnerEntity, SpawnerComponent spawner) {
    final newEntity = spawner.prefab();

    if (!newEntity.has<PositionComponent>()) {
      final spawnerPos = spawnerEntity.get<PositionComponent>()!;
      newEntity.add(PositionComponent(x: spawnerPos.x, y: spawnerPos.y));
    }

    world.addEntity(newEntity);

    if (spawner.frequency.eventsPerSecond > 0) {
      spawner.cooldown = 1.0 / spawner.frequency.eventsPerSecond;
    } else {
      spawner.cooldown = double.maxFinite;
    }
  }
}
