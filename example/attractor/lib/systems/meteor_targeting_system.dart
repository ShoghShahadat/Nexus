import 'dart:math';
import 'package:nexus/nexus.dart';
import '../components/meteor_component.dart';
import '../components/meteor_target_component.dart';

/// A system that calculates the initial velocity for a newly spawned meteor
/// based on its target component.
class MeteorTargetingSystem extends System {
  final Random _random = Random();

  @override
  bool matches(Entity entity) {
    // This system runs exactly once on a meteor that has a target but no velocity yet.
    return entity.has<MeteorComponent>() &&
        entity.has<MeteorTargetComponent>() &&
        !entity.has<VelocityComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final pos = entity.get<PositionComponent>()!;
    final target = entity.get<MeteorTargetComponent>()!;

    double targetX, targetY;

    // If the meteor has a specific target (the attractor)
    if (target.targetId != null) {
      final targetEntity = world.entities[target.targetId!];
      if (targetEntity != null) {
        final targetPos = targetEntity.get<PositionComponent>()!;
        targetX = targetPos.x;
        targetY = targetPos.y;
      } else {
        // Target disappeared, fall back to random.
        targetX = _random.nextDouble() * 400;
        targetY = _random.nextDouble() * 800;
      }
    } else {
      // If the meteor has a random trajectory
      const screenWidth = 400.0;
      const screenHeight = 800.0;
      targetX = screenWidth / 2 + (_random.nextDouble() - 0.5) * 200;
      targetY = screenHeight / 2 + (_random.nextDouble() - 0.5) * 400;
    }

    final angle = atan2(targetY - pos.y, targetX - pos.x);
    final speed = _random.nextDouble() * 100 + 150; // Speed between 150-250

    // Add the velocity to "launch" the meteor.
    entity.add(VelocityComponent(x: cos(angle) * speed, y: sin(angle) * speed));
  }
}
