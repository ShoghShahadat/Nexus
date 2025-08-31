import 'dart:math';
import 'dart:ui';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/particle_component.dart';
import 'package:nexus/src/components/rendering/drawable_component.dart';
import 'package:nexus/src/components/rendering/layer_component.dart';
import 'package:nexus/src/components/rendering/shape_component.dart';
import 'package:nexus/src/components/rendering/style_component.dart';
import 'package:nexus/src/components/rendering/transform_component.dart';

/// A system dedicated to updating the visual representation of particles.
/// سیستمی که به به‌روزرسانی نمایش بصری ذرات اختصاص دارد.
///
/// It runs every frame to translate the logical state (Position, Age) of a particle
/// into the components needed for rendering (Transform, Style).
/// این سیستم هر فریم اجرا می‌شود تا وضعیت منطقی (موقعیت، عمر) یک ذره را
/// به کامپوننت‌های مورد نیاز برای رندر (تبدیل، استایل) ترجمه کند.
class ParticleVisualsSystem extends System {
  @override
  bool matches(Entity entity) {
    // It acts on any entity that is a particle and is drawable.
    // روی هر موجودیتی که یک ذره و قابل ترسیم باشد، عمل می‌کند.
    return entity.has<ParticleComponent>() && entity.has<DrawableComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final pos = entity.get<PositionComponent>()!;
    final particle = entity.get<ParticleComponent>()!;

    // 1. Update TransformComponent from PositionComponent
    // `TransformComponent` را از `PositionComponent` به‌روز می‌کند.
    entity.add(TransformComponent(x: pos.x, y: pos.y, scale: pos.scale));

    // 2. Update StyleComponent based on the particle's age (creates a fade-out effect)
    // `StyleComponent` را بر اساس عمر ذره به‌روز می‌کند (ایجاد افکت محو شدن).
    final progress = (particle.age / particle.maxAge).clamp(0.0, 1.0);
    final currentColor = Color.lerp(
      Color(particle.initialColorValue),
      Color(particle.finalColorValue),
      progress,
    )!;

    entity.add(StyleComponent(
      color: SolidColor(currentColor.value),
      style: PaintingStyle.fill,
    ));
  }
}

/// A project-specific spawner that creates particles with all necessary components.
/// یک تولیدکننده مخصوص پروژه که ذرات را با تمام کامپوننت‌های لازم ایجاد می‌کند.
class ProjectParticleSpawningSystem extends System {
  final Random _random = Random();

  @override
  bool matches(Entity entity) {
    return entity.has<ParticleSpawnerComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final spawner = entity.get<ParticleSpawnerComponent>()!;
    spawner.timeSinceLastSpawn += dt;

    final timePerSpawn = 1.0 / spawner.spawnRate;
    while (spawner.timeSinceLastSpawn > timePerSpawn) {
      spawner.timeSinceLastSpawn -= timePerSpawn;
      world.addEntity(_createParticle(entity));
    }
    entity.add(spawner); // Re-add to save the updated timeSinceLastSpawn
  }

  Entity _createParticle(Entity spawnerEntity) {
    final spawnerLink = spawnerEntity.get<SpawnerLinkComponent>();
    final targetEntity = world.entities.values.firstWhere(
        (e) => e.get<TagsComponent>()?.hasTag(spawnerLink!.targetTag) ?? false);
    final spawnPos = targetEntity.get<PositionComponent>()!;

    final entity = Entity();
    final angle = _random.nextDouble() * 2 * pi;
    final speed = _random.nextDouble() * 150 + 50;
    final size = _random.nextDouble() * 2.0 + 1.0;

    // --- LOGIC COMPONENTS ---
    entity.add(PositionComponent(
        x: spawnPos.x, y: spawnPos.y, width: size, height: size));
    entity.add(VelocityComponent(x: cos(angle) * speed, y: sin(angle) * speed));
    entity.add(ParticleComponent(
      maxAge: _random.nextDouble() * 2.0 + 1.5,
      initialColorValue: 0xFFFFFFFF,
      finalColorValue: 0x00FFFFFF, // Fade to transparent white
    ));
    entity.add(TagsComponent({'particle'}));
    entity.add(LifecyclePolicyComponent(
      destructionCondition: (e) =>
          (e.get<ParticleComponent>()?.age ?? 0) >=
          (e.get<ParticleComponent>()?.maxAge ?? 999),
    ));

    // --- RENDERING COMPONENTS (THE FIX) ---
    entity.add(DrawableComponent());
    entity.add(LayerComponent(1)); // Draw particles on layer 1
    entity.add(TransformComponent(x: spawnPos.x, y: spawnPos.y));
    entity.add(
        ShapeComponent(CircleShape(centerX: 0, centerY: 0, radius: size / 2)));
    entity.add(StyleComponent(
      color: const SolidColor(0xFFFFFFFF), // Initial color is white
      style: PaintingStyle.fill,
    ));

    return entity;
  }
}
