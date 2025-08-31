import 'dart:math';
import 'dart:ui';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/rendering/style_component.dart';
import 'package:nexus_particle_demo/features/metaball_scene/domain/components/blob_component.dart';

/// Assembles the initial entities for the realistic water droplet simulation.
/// موجودیت‌های اولیه را برای شبیه‌سازی واقع‌گرایانه قطرات آب مونتاژ می‌کند.
class MetaballSceneAssembler {
  final NexusWorld world;
  final Random _random = Random();

  MetaballSceneAssembler(this.world);

  List<Entity> assemble() {
    // --- RE-ARCHITECTED FOR REALISM ---
    // 1. The main 'pathEntity' is reintroduced. This single entity will be responsible
    //    for drawing the entire visual scene using the metaball algorithm.
    // 2. The individual 'blob' entities are now purely logical. They contain
    //    physics data (Position, Velocity) but are NOT drawable themselves.
    //    The MetaballSystem reads their data to generate the final visual path.
    //
    // --- بازمعماری برای واقع‌گرایی ---
    // ۱. 'pathEntity' اصلی دوباره معرفی می‌شود. این موجودیت تنها مسئول ترسیم کل
    //    صحنه بصری با استفاده از الگوریتم متابال خواهد بود.
    // ۲. موجودیت‌های 'blob' اکنون کاملاً منطقی هستند. آنها داده‌های فیزیکی
    //    (موقعیت، سرعت) را در خود دارند اما خودشان قابل ترسیم نیستند.
    //    MetaballSystem داده‌های آنها را برای تولید مسیر بصری نهایی می‌خواند.

    final screenInfo = world.rootEntity.get<ScreenInfoComponent>()!;
    final width = screenInfo.width;
    final height = screenInfo.height;

    // The single, drawable entity that will hold the final, combined path of all blobs.
    // موجودیت واحد و قابل ترسیمی که مسیر نهایی و ترکیب‌شده تمام قطره‌ها را نگه می‌دارد.
    final pathEntity = Entity()
      ..add(TagsComponent({'metaball_path'}))
      ..add(DrawableComponent())
      ..add(LayerComponent(1))
      ..add(TransformComponent(x: 0, y: 0))
      ..add(StyleComponent(
        color: const GradientColor(
          colors: [
            0xAAEAF2FF, // Light, semi-transparent blue/white for highlight
            0xAA87CEEB, // Medium, semi-transparent blue for the body
          ],
          stops: [0.0, 1.0],
          beginX: -0.7,
          beginY: -0.7,
          endX: 0.7,
          endY: 0.7,
        ),
        style: PaintingStyle.fill,
      ))
      ..add(ShapeComponent(const PathShape(commands: [])))
      ..add(LifecyclePolicyComponent(isPersistent: true));

    final blobs = List.generate(15, (index) {
      final radius =
          _random.nextDouble() * 20 + 5; // Smaller, more numerous droplets
      return Entity()
        // --- LOGICAL COMPONENTS ONLY ---
        ..add(BlobComponent(radius))
        ..add(PositionComponent(
          x: _random.nextDouble() * width,
          y: _random.nextDouble() * height,
        ))
        ..add(VelocityComponent(
          x: (_random.nextDouble() - 0.5) *
              20, // Slower initial horizontal drift
          y: _random.nextDouble() * 50 + 20, // Initial downward velocity
        ))
        ..add(LifecyclePolicyComponent(isPersistent: true));
    });

    return [pathEntity, ...blobs];
  }
}
