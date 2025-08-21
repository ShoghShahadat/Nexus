import 'package:nexus/src/components/position_component.dart';
import 'package:nexus/src/components/velocity_component.dart';
import 'package:nexus/src/core/entity.dart';
import 'package:nexus/src/core/system.dart';

/// سیستمی که سرعت را به موجودیت‌ها اعمال می‌کند تا حرکت ایجاد شود.
///
/// این سیستم به دنبال موجودیت‌هایی می‌گردد که هم [PositionComponent] و هم
/// [VelocityComponent] دارند. در هر فریم، موقعیت موجودیت را بر اساس
/// سرعت فعلی و زمان دلتا به‌روزرسانی می‌کند.

class PhysicsSystem extends System {
  @override
  bool matches(Entity entity) {
    return entity.has<PositionComponent>() && entity.has<VelocityComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final pos = entity.get<PositionComponent>()!;
    final vel = entity.get<VelocityComponent>()!;

    pos.x += vel.x * dt;
    pos.y += vel.y * dt;

    entity.add(pos);
  }
}
