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
    // The spawner itself needs a position to be a valid spawn point.
    // خودِ spawner برای اینکه یک نقطه ساخت معتبر باشد، به موقعیت نیاز دارد.
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

    // *** FIX: Only set the position if the prefab doesn't already have one. ***
    // This allows prefabs like health orbs to define their own random starting positions,
    // while prefabs like bullets will correctly inherit the spawner's position.
    // *** اصلاح: موقعیت فقط در صورتی تنظیم می‌شود که prefab از قبل آن را نداشته باشد. ***
    // این به prefabهایی مانند گوی‌های جان اجازه می‌دهد موقعیت تصادفی خود را تعیین کنند،
    // در حالی که prefabهایی مانند گلوله‌ها موقعیت spawner را به درستی به ارث می‌برند.
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
