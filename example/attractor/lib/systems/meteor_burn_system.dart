import 'dart:math';
import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import '../components/meteor_component.dart';

/// A system that handles the burning, shrinking, and particle shedding of meteors.
/// It now uses the standard HealthComponent to manage the meteor's lifespan and destruction.
/// سیستمی که سوختن، کوچک شدن و پخش ذرات شهاب‌سنگ‌ها را مدیریت می‌کند.
/// اکنون از HealthComponent استاندارد برای مدیریت طول عمر و نابودی شهاب‌سنگ استفاده می‌کند.
class MeteorBurnSystem extends System {
  final Random _random = Random();

  @override
  bool matches(Entity entity) {
    // This system now operates on meteors that have health.
    // این سیستم اکنون روی شهاب‌سنگ‌هایی که جان دارند عمل می‌کند.
    return entity.has<MeteorComponent>() && entity.has<HealthComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final health = entity.get<HealthComponent>()!;
    final pos = entity.get<PositionComponent>()!;

    // Check for death first (e.g., from a collision).
    // ابتدا مرگ را بررسی می‌کنیم (مثلاً در اثر برخورد).
    if (health.currentHealth <= 0) {
      _explodeAndDie(entity, pos);
      return;
    }

    // If not dead, burn over time. 5 second lifespan means losing 20% health per second.
    // اگر نمرده است، به مرور زمان می‌سوزد. عمر ۵ ثانیه‌ای یعنی از دست دادن ۲۰٪ جان در هر ثانیه.
    final damagePerSecond = health.maxHealth / 5.0;
    final newHealth = health.currentHealth - (damagePerSecond * dt);

    if (newHealth <= 0) {
      _explodeAndDie(entity, pos);
    } else {
      // Update health and shrink the meteor visually.
      // جان را به‌روز کرده و شهاب‌سنگ را از نظر بصری کوچک می‌کنیم.
      entity.add(HealthComponent(
          maxHealth: health.maxHealth, currentHealth: newHealth));

      final healthRatio = newHealth / health.maxHealth;
      pos.width = 25 * healthRatio;
      pos.height = 25 * healthRatio;
      entity.add(pos);

      if (_random.nextDouble() < 0.5) {
        _createDebrisParticle(pos);
      }
    }
  }

  void _explodeAndDie(Entity entity, PositionComponent pos) {
    final rootEntity = world.entities.values.firstWhereOrNull(
        (e) => e.get<TagsComponent>()?.hasTag('root') ?? false);

    if (rootEntity != null) {
      final blackboard = rootEntity.get<BlackboardComponent>()!;
      if (!(blackboard.get<bool>('is_game_over') ?? false)) {
        blackboard.increment('score', 5);
        rootEntity.add(blackboard);
      }
    }

    for (int i = 0; i < 20; i++) {
      _createDebrisParticle(pos);
    }
    world.removeEntity(entity.id);
  }

  void _createDebrisParticle(PositionComponent meteorPos) {
    final debris = Entity();
    final angle = _random.nextDouble() * 2 * pi;
    final speed = _random.nextDouble() * 70 + 10;

    debris.add(PositionComponent(
      x: meteorPos.x + (_random.nextDouble() - 0.5) * meteorPos.width,
      y: meteorPos.y + (_random.nextDouble() - 0.5) * meteorPos.width,
      width: 2,
      height: 2,
    ));
    debris.add(VelocityComponent(x: cos(angle) * speed, y: sin(angle) * speed));
    debris.add(ParticleComponent(
      maxAge: _random.nextDouble() * 1.5 + 0.5,
      initialColorValue: 0xFFFFE082,
      finalColorValue: 0xFF757575,
    ));
    debris.add(TagsComponent({'particle'}));
    world.addEntity(debris);
  }
}
