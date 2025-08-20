import 'dart:math';
import 'package:flutter/animation.dart' show Curves;
import 'package:nexus/nexus.dart';
import '../components/explosion_component.dart';

/// A system that randomly selects particles to explode and manages their animation.
/// Note: The class was renamed from ParticleExplosionSystem to ExplosionSystem for consistency.
/// سیستمی که به صورت تصادفی ذرات را برای انفجار انتخاب کرده و انیمیشن آن‌ها را مدیریت می‌کند.
/// نکته: نام کلاس برای هماهنگی به ExplosionSystem تغییر یافت.
class ExplosionSystem extends System {
  final Random _random = Random();

  @override
  bool matches(Entity entity) {
    // This system is interested in any entity that is a particle.
    // این سیستم به هر موجودیتی که یک ذره باشد، علاقه‌مند است.
    return entity.has<ParticleComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    // Part 1: Handle particles that are already exploding.
    // بخش ۱: مدیریت ذراتی که در حال انفجار هستند.
    if (entity.has<ExplodingParticleComponent>()) {
      if (!entity.has<AnimationComponent>()) {
        entity.add(_createExplosionAnimation());
      }
      return;
    }

    // Part 2: Randomly select a new particle to explode.
    // بخش ۲: انتخاب تصادفی یک ذره جدید برای انفجار.
    // A small chance on every frame for any given particle.
    // یک شانس کوچک در هر فریم برای هر ذره.
    if (_random.nextDouble() < 0.01) {
      entity.add(ExplodingParticleComponent());
    }
  }

  /// Creates the animation for the explosion effect.
  /// انیمیشن مربوط به افکت انفجار را ایجاد می‌کند.
  AnimationComponent _createExplosionAnimation() {
    return AnimationComponent(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutQuad,
      onUpdate: (entity, value) {
        entity.add(ExplodingParticleComponent(progress: value));
        final pos = entity.get<PositionComponent>()!;
        pos.width = 3 + (value * 15);
        pos.height = pos.width;
        entity.add(pos);
      },
      onComplete: (entity) {
        world.removeEntity(entity.id);
      },
    );
  }
}
