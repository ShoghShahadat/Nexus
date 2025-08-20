import 'dart:math';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/spawner_component.dart';

/// سیستمی که موجودیت‌های ذره جدید را بر اساس یک SpawnerComponent تولید می‌کند.
class ParticleSpawningSystem extends System {
  final Random _random = Random();

  @override
  bool matches(Entity entity) {
    // این سیستم فقط روی یک موجودیت با SpawnerComponent عمل می‌کند.
    return entity.has<SpawnerComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final spawner = entity.get<SpawnerComponent>()!;
    spawner.timeSinceLastSpawn += dt;

    final timePerSpawn = 1.0 / spawner.spawnRate;
    while (spawner.timeSinceLastSpawn > timePerSpawn) {
      spawner.timeSinceLastSpawn -= timePerSpawn;
      world.addEntity(_createParticle(entity));
    }
    entity.add(spawner); // دوباره اضافه کردن برای ذخیره زمان به‌روزرسانی شده
  }

  Entity _createParticle(Entity spawnerEntity) {
    final entity = Entity();
    final angle = _random.nextDouble() * 2 * pi;
    // محدوده سرعت اولیه برای ذرات
    final speed = _random.nextDouble() * 150 + 50; // سرعت بین 50 تا 200

    final spawnerPos = spawnerEntity.get<PositionComponent>()!;

    // کاهش اندازه ذرات برای نرمی بصری بیشتر
    entity.add(PositionComponent(
        x: spawnerPos.x,
        y: spawnerPos.y,
        width: 3,
        height: 3)); // اندازه ذرات به 3x3 کاهش یافت
    entity.add(VelocityComponent(x: cos(angle) * speed, y: sin(angle) * speed));
    entity.add(ParticleComponent(
      maxAge: _random.nextDouble() * 3 + 2, // عمر ذرات بین 2 تا 5 ثانیه
      initialColorValue: 0xFFFFFFFF,
      finalColorValue: 0xFF4A148C, // بنفش تیره
    ));
    entity.add(TagsComponent({'particle'}));
    return entity;
  }
}
