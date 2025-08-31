import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/attractor_component.dart';
import 'package:nexus/src/components/particle_spawner_component.dart';
import 'package:nexus/src/components/rendering/drawable_component.dart';
import 'package:nexus/src/components/rendering/layer_component.dart';
import 'package:nexus/src/components/rendering/shape_component.dart';
import 'package:nexus/src/components/rendering/style_component.dart';
import 'package:nexus/src/components/rendering/transform_component.dart';

/// Assembles the initial entities for the particle scene.
/// موجودیت‌های اولیه را برای صحنه ذرات مونتاژ می‌کند.
class ParticleSceneAssembler {
  final NexusWorld world;

  ParticleSceneAssembler(this.world);

  List<Entity> assemble() {
    return [
      _createAttractor(),
      _createParticleSpawner(),
    ];
  }

  /// Creates the central attractor entity that follows the pointer.
  /// موجودیت جاذب مرکزی را ایجاد می‌کند که از اشاره‌گر پیروی می‌کند.
  Entity _createAttractor() {
    final entity = Entity();
    // LOGIC
    entity.add(PositionComponent(x: 100, y: 100, width: 20, height: 20));
    entity.add(AttractorComponent(strength: 1.0));
    entity.add(TagsComponent({'attractor'}));
    entity.add(LifecyclePolicyComponent(isPersistent: true));

    // RENDERING (THE FIX)
    entity.add(DrawableComponent());
    entity.add(LayerComponent(2)); // Draw attractor on top of particles
    entity.add(TransformComponent(x: 100, y: 100));
    entity.add(ShapeComponent(CircleShape(centerX: 0, centerY: 0, radius: 10)));
    entity.add(StyleComponent(
      color: const SolidColor(0xFFFF0000), // Red color for attractor
      style: PaintingStyle.fill,
    ));
    return entity;
  }

  /// Creates the entity responsible for spawning particles.
  /// موجودیتی را ایجاد می‌کند که مسئول تولید ذرات است.
  Entity _createParticleSpawner() {
    final entity = Entity();
    // This entity is purely logical and has no visual representation.
    // این موجودیت کاملاً منطقی است و نمایش بصری ندارد.
    entity.add(PositionComponent(x: 100, y: 100));
    entity.add(ParticleSpawnerComponent(spawnRate: 70)); // 300 particles/sec
    entity.add(SpawnerLinkComponent(targetTag: 'attractor'));
    entity.add(LifecyclePolicyComponent(isPersistent: true));
    return entity;
  }
}
