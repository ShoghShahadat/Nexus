import 'dart:math';
import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import '../components/meteor_component.dart';
import '../components/meteor_target_component.dart';

/// A system that calculates the initial velocity for a newly spawned meteor
/// based on its target component.
class MeteorTargetingSystem extends System {
  final Random _random = Random();

  @override
  bool matches(Entity entity) {
    return entity.has<MeteorComponent>() &&
        entity.has<MeteorTargetComponent>() &&
        !entity.has<VelocityComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final pos = entity.get<PositionComponent>()!;
    final targetComp = entity.get<MeteorTargetComponent>()!;

    final targetEntity = world.entities[targetComp.targetId!];
    if (targetEntity == null) {
      world.removeEntity(entity.id);
      return;
    }

    final targetPos = targetEntity.get<PositionComponent>()!;
    final angle = atan2(targetPos.y - pos.y, targetPos.x - pos.x);

    // --- NEW: Calculate speed based on game time ---
    // --- جدید: محاسبه سرعت بر اساس زمان بازی ---
    final root = world.entities.values.firstWhereOrNull(
        (e) => e.get<TagsComponent>()?.hasTag('root') ?? false);
    final gameTime =
        root?.get<BlackboardComponent>()?.get<double>('game_time') ?? 0.0;

    // Speed starts at 150 and increases to a max of 400 over 60 seconds
    // سرعت از ۱۵۰ شروع شده و در طول ۶۰ ثانیه به حداکثر ۴۰۰ می‌رسد
    final speed = (150 + (gameTime / 60.0) * 250).clamp(150.0, 400.0);

    entity.add(VelocityComponent(x: cos(angle) * speed, y: sin(angle) * speed));
  }
}
