import 'package:nexus/src/components/position_component.dart';
import 'package:nexus/src/components/velocity_component.dart';
import 'package:nexus/src/core/entity.dart';
import 'package:nexus/src/core/system.dart';

/// A system that applies velocity to entities to create movement.
///
/// This system looks for entities that have both a [PositionComponent] and a
/// [VelocityComponent]. In each frame, it updates the entity's position
/// based on its current velocity and the delta time.
class PhysicsSystem extends System {
  @override
  bool matches(Entity entity) {
    return entity.has<PositionComponent>() && entity.has<VelocityComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    // ما می‌توانیم با اطمینان از '!' استفاده کنیم زیرا 'matches' تضمین می‌کند که این کامپوننت‌ها وجود دارند.
    final pos = entity.get<PositionComponent>()!;
    final vel = entity.get<VelocityComponent>()!;

    // به‌روزرسانی موقعیت بر اساس سرعت و دلتا تایم.
    pos.x += vel.x * dt;
    pos.y += vel.y * dt;

    // --- حذف منطق مرزی که باعث توقف ذرات می‌شود ---
    // این منطق باعث می‌شد ذرات در y=500 متوقف شوند و شاید از دید خارج شوند.
    // برای شبیه‌سازی کیهانی، بهتر است اجازه دهیم ذرات آزادانه حرکت کنند.
    // اگر نیاز به مرز دارید، می‌توانید یک سیستم جداگانه برای آن ایجاد کنید
    // که ذرات را حذف کند یا آن‌ها را به داخل صفحه برگرداند،
    // اما نه با حذف VelocityComponent به صورت دائمی.
    /*
    if (pos.y > 500) {
      pos.y = 500; // Clamp the position to the boundary line.
      entity.remove<VelocityComponent>(); // Stop all future movement.
    }
    */

    // کامپوننت را دوباره اضافه کنید تا سیستم رندرینگ از تغییر مطلع شود.
    entity.add(pos);
  }
}
