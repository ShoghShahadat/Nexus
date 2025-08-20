import 'package:nexus/src/components/position_component.dart';
import 'package:nexus/src/components/velocity_component.dart';
import 'package:nexus/src/core/entity.dart';
import 'package:nexus/src/core/system.dart';

/// سیستمی که سرعت را به موجودیت‌ها اعمال می‌کند تا حرکت ایجاد شود.
///
/// این سیستم به دنبال موجودیت‌هایی می‌گردد که هم [PositionComponent] و هم
/// [VelocityComponent] دارند. در هر فریم، موقعیت موجودیت را بر اساس
/// سرعت فعلی و زمان دلتا به‌روزرسانی می‌کند.
///
/// توجه: منطق حذف ذرات بر اساس خروج از محدوده حذف شده است تا
/// مدیریت چرخه حیات ذرات (حذف بر اساس سن) توسط ParticleLifecycleSystem
/// صورت گیرد، همانطور که کاربر درخواست کرده است.
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

    // به‌روزرسانی موقعیت بر اساس سرعت و زمان دلتا.
    pos.x += vel.x * dt;
    pos.y += vel.y * dt;

    // --- حذف منطق حذف ذرات خارج از محدوده ---
    // این بخش حذف شده است تا ذرات بر اساس سن خود (توسط ParticleLifecycleSystem)
    // از بین بروند، نه بر اساس خروج از مرزهای صفحه.
    /*
    const double boundsPadding = 100.0;
    if (pos.x < -boundsPadding ||
        pos.x > 400 + boundsPadding ||
        pos.y < -boundsPadding ||
        pos.y > 600 + boundsPadding) {
      Future.microtask(() => world.removeEntity(entity.id));
    } else {
      entity.add(pos);
    }
    */

    // کامپوننت را دوباره اضافه کنید تا سیستم رندرینگ از تغییر مطلع شود.
    // این خط باید همیشه وجود داشته باشد تا تغییرات موقعیت به UI ارسال شوند.
    entity.add(pos);
  }
}
