import 'dart:math';
import 'package:collection/collection.dart'; // Import for firstWhereOrNull
import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/attractor_component.dart';

/// سیستمی که یک کشش گرانشی را از یک موجودیت جاذب
/// به تمام موجودیت‌های دیگر با سرعت اعمال می‌کند.
class AttractionSystem extends System {
  @override
  bool matches(Entity entity) {
    // این سیستم روی هر موجودیت متحرکی که خودش جاذب نباشد، عمل می‌کند.
    return entity.has<PositionComponent>() &&
        entity.has<VelocityComponent>() &&
        !entity.has<AttractorComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    // --- FIX: Race condition fixed by finding the attractor on every frame ---
    // به جای کش کردن، هر بار جاذب را پیدا می‌کنیم تا از بروز خطا جلوگیری شود.
    final attractor = world.entities.values
        .firstWhereOrNull((e) => e.has<AttractorComponent>());

    // اگر جاذب هنوز وجود ندارد، هیچ کاری انجام نده.
    if (attractor == null) {
      return;
    }

    final pos = entity.get<PositionComponent>()!;
    final vel = entity.get<VelocityComponent>()!;
    final attractorPos = attractor.get<PositionComponent>()!;
    final attractorComp = attractor.get<AttractorComponent>()!;

    final dx = attractorPos.x - pos.x;
    final dy = attractorPos.y - pos.y;
    final distSq = dx * dx + dy * dy;

    // از نیروهای بسیار شدید در فاصله نزدیک جلوگیری می‌کند تا شبیه‌سازی پایدار بماند.
    if (distSq < 25) return;

    // محاسبه نیروی جاذبه بر اساس قانون عکس مربع فاصله.
    final force = attractorComp.strength * 30000 / distSq;
    final angle = atan2(dy, dx);

    // اعمال شتاب به سرعت موجودیت.
    vel.x += cos(angle) * force * dt;
    vel.y += sin(angle) * force * dt;

    // کامپوننت سرعت را دوباره اضافه می‌کنیم تا سیستم از تغییر آن مطلع شود.
    entity.add(vel);
  }
}
