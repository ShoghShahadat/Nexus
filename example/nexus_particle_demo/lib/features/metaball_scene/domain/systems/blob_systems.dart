import 'dart:math';
import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus_particle_demo/features/metaball_scene/domain/components/blob_component.dart';

/// A system to synchronize the visual TransformComponent with the logical PositionComponent for each blob.
/// سیستمی برای همگام‌سازی TransformComponent بصری با PositionComponent منطقی برای هر قطره.
class BlobVisualsSystem extends System {
  @override
  bool matches(Entity entity) {
    return entity.has<BlobComponent>() &&
        entity.has<PositionComponent>() &&
        entity.has<TransformComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final pos = entity.get<PositionComponent>()!;
    // Update the transform to match the physical position.
    // تبدیل را برای مطابقت با موقعیت فیزیکی به‌روزرسانی می‌کند.
    entity
        .add(TransformComponent(x: pos.x, y: pos.y, scale: 1.0, rotation: 0.0));
  }
}

/// Moves the blobs around the screen and makes them bounce off the walls.
/// قطره‌ها را در صفحه حرکت می‌دهد و باعث می‌شود از دیوارها بازگردند.
class BlobMovementSystem extends System {
  @override
  bool matches(Entity entity) {
    return entity.has<BlobComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final pos = entity.get<PositionComponent>()!;
    final vel = entity.get<VelocityComponent>()!;
    final screen = world.rootEntity.get<ScreenInfoComponent>()!;

    if (pos.x < 0 || pos.x > screen.width) vel.x *= -1;
    if (pos.y < 0 || pos.y > screen.height) vel.y *= -1;
  }
}

/// The core system that calculates the combined path of all metaballs.
/// سیستم اصلی که مسیر ترکیب‌شده تمام متابال‌ها را محاسبه می‌کند.
class MetaballSystem extends System {
  @override
  bool matches(Entity entity) => false; // Operates on the whole scene

  @override
  void run(double dt) {
    final blobs =
        world.entities.values.where((e) => e.has<BlobComponent>()).toList();

    final pathEntity = world.entities.values.firstWhereOrNull(
        (e) => e.get<TagsComponent>()?.hasTag('metaball_path') ?? false);

    if (pathEntity == null || blobs.length < 2) return;

    final path = _generateMetaballPath(blobs);
    pathEntity.add(ShapeComponent(
        PathShape(commands: path, fillType: PathFillType.evenOdd)));
  }

  @override
  void update(Entity entity, double dt) {}

  /// Generates the path commands for the metaball effect.
  /// دستورات مسیر را برای افکت متابال تولید می‌کند.
  List<PathCommand> _generateMetaballPath(List<Entity> blobs) {
    final pathCommands = <PathCommand>[];
    final blobData = blobs.map((e) {
      final pos = e.get<PositionComponent>()!;
      final blob = e.get<BlobComponent>()!;
      return {'x': pos.x, 'y': pos.y, 'r': blob.radius};
    }).toList();

    for (int i = 0; i < blobData.length; i++) {
      for (int j = i + 1; j < blobData.length; j++) {
        final b1 = blobData[i];
        final b2 = blobData[j];

        final center1 = Offset(b1['x']!, b1['y']!);
        final center2 = Offset(b2['x']!, b2['y']!);
        final r1 = b1['r']!;
        final r2 = b2['r']!;
        final d = (center2 - center1).distance;

        if (d > r1 + r2 || d <= (r1 - r2).abs()) {
          continue;
        }

        final angle1 = acos((r1 * r1 + d * d - r2 * r2) / (2 * r1 * d));
        final angle2 = acos((r2 * r2 + d * d - r1 * r1) / (2 * r2 * d));

        final centerAngle =
            atan2(center2.dy - center1.dy, center2.dx - center1.dx);

        final p1 = Offset(center1.dx + r1 * cos(centerAngle + angle1),
            center1.dy + r1 * sin(centerAngle + angle1));
        final p2 = Offset(center1.dx + r1 * cos(centerAngle - angle1),
            center1.dy + r1 * sin(centerAngle - angle1));
        final p3 = Offset(center2.dx + r2 * cos(centerAngle + pi - angle2),
            center2.dy + r2 * sin(centerAngle + pi - angle2));
        final p4 = Offset(center2.dx + r2 * cos(centerAngle - pi + angle2),
            center2.dy + r2 * sin(centerAngle - pi + angle2));

        pathCommands.add(MoveToCommand(p1.dx, p1.dy));
        pathCommands.add(LineToCommand(p3.dx, p3.dy));
        pathCommands.add(LineToCommand(p4.dx, p4.dy));
        pathCommands.add(LineToCommand(p2.dx, p2.dy));
        pathCommands.add(const CloseCommand());
      }
    }

    return pathCommands;
  }
}
