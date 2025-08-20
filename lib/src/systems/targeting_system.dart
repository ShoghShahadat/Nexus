import 'dart:math';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/gameplay_components.dart';

/// A system that steers entities with a `TargetingComponent` towards their target.
/// سیستمی که موجودیت‌های دارای `TargetingComponent` را به سمت هدفشان هدایت می‌کند.
class TargetingSystem extends System {
  @override
  bool matches(Entity entity) {
    return entity.has<TargetingComponent>() &&
        entity.has<VelocityComponent>() &&
        entity.has<PositionComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final targeting = entity.get<TargetingComponent>()!;
    final vel = entity.get<VelocityComponent>()!;
    final pos = entity.get<PositionComponent>()!;

    final targetEntity = world.entities[targeting.targetId];
    if (targetEntity == null) {
      // Target is gone, remove the component so we stop trying.
      // هدف از بین رفته است، کامپوننت را حذف می‌کنیم تا تلاش متوقف شود.
      entity.remove<TargetingComponent>();
      return;
    }

    final targetPos = targetEntity.get<PositionComponent>();
    if (targetPos == null) return;

    // Calculate the desired direction
    // جهت مطلوب را محاسبه می‌کند
    final desiredAngle = atan2(targetPos.y - pos.y, targetPos.x - pos.x);

    // Calculate the current direction
    // جهت فعلی را محاسبه می‌کند
    final currentAngle = atan2(vel.y, vel.x);

    // Find the shortest angle to turn
    // کوتاه‌ترین زاویه برای چرخش را پیدا می‌کند
    var angleDiff = desiredAngle - currentAngle;
    while (angleDiff > pi) angleDiff -= 2 * pi;
    while (angleDiff < -pi) angleDiff += 2 * pi;

    // Clamp the turn speed
    // سرعت چرخش را محدود می‌کند
    final turnAmount =
        angleDiff.clamp(-targeting.turnSpeed * dt, targeting.turnSpeed * dt);
    final newAngle = currentAngle + turnAmount;

    // Keep the current speed, but change the direction
    // سرعت فعلی را حفظ کرده، اما جهت را تغییر می‌دهد
    final speed = sqrt(vel.x * vel.x + vel.y * vel.y);
    vel.x = cos(newAngle) * speed;
    vel.y = sin(newAngle) * speed;

    entity.add(vel);
  }
}
