import 'dart:math';
import 'dart:ui';
import 'package:nexus/nexus.dart';
// *** FIX: Import the rendering components directly to access SolidColor ***
// *** اصلاح: ایمپورت مستقیم کامپوننت‌های رندرینگ برای دسترسی به SolidColor ***
import 'package:nexus/src/components/rendering/style_component.dart';
import 'package:nexus_particle_demo/features/metaball_scene/domain/components/blob_component.dart';

/// Assembles the initial entities for the metaball scene.
/// موجودیت‌های اولیه را برای صحنه متابال مونتاژ می‌کند.
class MetaballSceneAssembler {
  final NexusWorld world;
  final Random _random = Random();

  MetaballSceneAssembler(this.world);

  List<Entity> assemble() {
    final screenInfo = world.rootEntity.get<ScreenInfoComponent>()!;
    final width = screenInfo.width;
    final height = screenInfo.height;

    // The main entity that will hold the final, combined path of all blobs.
    // موجودیت اصلی که مسیر نهایی و ترکیب‌شده تمام قطره‌ها را نگه می‌دارد.
    final pathEntity = Entity()
      ..add(TagsComponent({'metaball_path'}))
      ..add(DrawableComponent())
      ..add(LayerComponent(1))
      ..add(TransformComponent(x: 0, y: 0))
      ..add(StyleComponent(
        color: const SolidColor(0xFF9922FF),
        style: PaintingStyle.fill,
      ))
      ..add(ShapeComponent(const PathShape(commands: [])))
      ..add(LifecyclePolicyComponent(isPersistent: true));

    final blobs = List.generate(8, (index) {
      final radius = _random.nextDouble() * 40 + 40;
      return Entity()
        ..add(BlobComponent(radius))
        ..add(PositionComponent(
          x: _random.nextDouble() * width,
          y: _random.nextDouble() * height,
          width: radius * 2,
          height: radius * 2,
        ))
        ..add(VelocityComponent(
          x: (_random.nextDouble() - 0.5) * 150,
          y: (_random.nextDouble() - 0.5) * 150,
        ))
        ..add(LifecyclePolicyComponent(isPersistent: true));
    });

    return [pathEntity, ...blobs];
  }
}
