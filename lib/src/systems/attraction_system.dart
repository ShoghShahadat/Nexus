import 'dart:math';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/attractor_component.dart';

/// سیستمی که یک کشش گرانشی را از یک موجودیت جاذب
/// به تمام موجودیت‌های دیگر با سرعت اعمال می‌کند.
class AttractionSystem extends System {
  Entity? _attractor;

  // یک تابع کمکی برای یافتن جاذب بدون ایجاد خطاهای نوع.
  void _findAttractor() {
    try {
      _attractor =
          world.entities.values.firstWhere((e) => e.has<AttractorComponent>());
    } catch (e) {
      _attractor = null;
    }
  }

  @override
  bool matches(Entity entity) {
    // این سیستم روی هر موجودیت متحرکی که خودش جاذب نباشد، عمل می‌کند.
    return entity.has<PositionComponent>() &&
        entity.has<VelocityComponent>() &&
        !entity.has<AttractorComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    // جاذب را در اولین اجرا پیدا کن اگر هنوز پیدا نشده است.
    _attractor ??= world.entities.values
        .firstWhere((e) => e.has<AttractorComponent>(), orElse: () => Entity());
    if (_attractor!.id == entity.id || !_attractor!.has<AttractorComponent>()) {
      return;
    }

    final pos = entity.get<PositionComponent>()!;
    final vel = entity.get<VelocityComponent>()!;
    final attractorPos = _attractor!.get<PositionComponent>()!;
    final attractorComp = _attractor!.get<AttractorComponent>()!;

    final dx = attractorPos.x - pos.x;
    final dy = attractorPos.y - pos.y;
    final distSq = dx * dx + dy * dy;

    if (distSq < 25) return; // از نیروهای شدید در فاصله نزدیک جلوگیری می‌کند.

    // افزایش قدرت جاذبه برای کشش بیشتر ذرات
    final force =
        attractorComp.strength * 50000 / distSq; // افزایش ضریب 1000 به 50000
    final angle = atan2(dy, dx);

    // اعمال شتاب
    vel.x += cos(angle) * force * dt;
    vel.y += sin(angle) * force * dt;

    entity.add(vel);
  }
}
