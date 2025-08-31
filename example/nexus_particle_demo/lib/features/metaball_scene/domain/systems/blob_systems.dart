import 'dart:math';
import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus_particle_demo/features/metaball_scene/domain/components/blob_component.dart';
import 'package:nexus_particle_demo/features/metaball_scene/domain/entities/metaball_scene_assembler.dart';

// --- NEW PHYSICS SYSTEM FOR REALISTIC DROPLETS ---
/// A dedicated physics system for simulating water droplets.
/// It handles gravity, merging on collision, and recycling droplets.
class DropletPhysicsSystem extends System {
  final double gravity = 98.0;
  final Random _random = Random();

  @override
  bool matches(Entity entity) => entity.has<BlobComponent>();

  @override
  void run(double dt) {
    final blobs = world.entities.values.where(matches).toList();
    final screen = world.rootEntity.get<ScreenInfoComponent>()!;
    if (screen.width == 0) return;

    final entitiesToRemove = <EntityId>{};

    // 1. Apply physics (gravity, movement, wall collision)
    for (final entity in blobs) {
      final pos = entity.get<PositionComponent>()!;
      final vel = entity.get<VelocityComponent>()!;
      final blob = entity.get<BlobComponent>()!;

      vel.y += gravity * dt;

      if ((pos.x < blob.radius && vel.x < 0) ||
          (pos.x > screen.width - blob.radius && vel.x > 0)) {
        vel.x *= -0.5;
      }

      if (pos.y > screen.height + blob.radius) {
        pos.y = -blob.radius;
        pos.x = _random.nextDouble() * screen.width;
        vel.y = _random.nextDouble() * 50 + 20;
      }
    }

    // 2. Handle collisions and merging
    for (int i = 0; i < blobs.length; i++) {
      for (int j = i + 1; j < blobs.length; j++) {
        final entityA = blobs[i];
        final entityB = blobs[j];

        if (entitiesToRemove.contains(entityA.id) ||
            entitiesToRemove.contains(entityB.id)) continue;

        final posA = entityA.get<PositionComponent>()!;
        final blobA = entityA.get<BlobComponent>()!;
        final posB = entityB.get<PositionComponent>()!;
        final blobB = entityB.get<BlobComponent>()!;

        final dx = posA.x - posB.x;
        final dy = posA.y - posB.y;
        final distance = sqrt(dx * dx + dy * dy);

        if (distance < blobA.radius + blobB.radius) {
          final (larger, smaller) = blobA.radius > blobB.radius
              ? (entityA, entityB)
              : (entityB, entityA);
          final largerBlob = larger.get<BlobComponent>()!;
          final smallerBlob = smaller.get<BlobComponent>()!;

          final newRadius = sqrt(largerBlob.radius * largerBlob.radius +
              smallerBlob.radius * smallerBlob.radius);
          largerBlob.radius = newRadius;

          entitiesToRemove.add(smaller.id);
        }
      }
    }

    // 3. Remove merged entities
    if (entitiesToRemove.isNotEmpty) {
      Future.microtask(() {
        for (final id in entitiesToRemove) {
          world.removeEntity(id);
        }
      });
    }
  }

  @override
  void update(Entity entity, double dt) {
    // Logic is handled in run()
  }
}

// --- REWRITTEN AND CORRECTED METABALL SYSTEM ---
/// The core visual system that calculates the combined path of all metaballs.
class MetaballSystem extends System {
  @override
  bool matches(Entity entity) => false; // Operates on the whole scene

  @override
  void run(double dt) {
    final blobs =
        world.entities.values.where((e) => e.has<BlobComponent>()).toList();
    final pathEntity = world.entities.values.firstWhereOrNull(
        (e) => e.get<TagsComponent>()?.hasTag('metaball_path') ?? false);

    if (pathEntity == null || blobs.isEmpty) {
      // If there are no blobs, ensure the path is empty.
      pathEntity?.add(ShapeComponent(const PathShape(commands: [])));
      return;
    }
    ;

    final pathCommands = _generateSerializableMetaballPath(blobs);

    pathEntity.add(ShapeComponent(
        PathShape(commands: pathCommands, fillType: PathFillType.evenOdd)));
  }

  @override
  void update(Entity entity, double dt) {}

  /// --- FINAL FIX: Generates a complete and correct path for the metaball effect. ---
  List<PathCommand> _generateSerializableMetaballPath(List<Entity> blobs) {
    final pathCommands = <PathCommand>[];
    const int segments = 24; // Number of line segments to approximate a circle

    // 1. --- CRITICAL ADDITION: Add the circles themselves to the path ---
    for (final blobEntity in blobs) {
      final pos = blobEntity.get<PositionComponent>()!;
      final blob = blobEntity.get<BlobComponent>()!;

      final centerX = pos.x;
      final centerY = pos.y;
      final radius = blob.radius;

      // Start at the top of the circle
      pathCommands.add(MoveToCommand(centerX, centerY - radius));

      // Create the circle using line segments
      for (int i = 1; i <= segments; i++) {
        final angle = i * (2 * pi / segments);
        final x = centerX + radius * sin(angle);
        final y = centerY - radius * cos(angle);
        pathCommands.add(LineToCommand(x, y));
      }
      pathCommands.add(const CloseCommand());
    }

    // 2. Add the "bridge" polygons between close-enough circles
    for (int i = 0; i < blobs.length; i++) {
      for (int j = i + 1; j < blobs.length; j++) {
        final b1 = blobs[i];
        final b2 = blobs[j];

        final pos1 = b1.get<PositionComponent>()!;
        final blob1 = b1.get<BlobComponent>()!;
        final pos2 = b2.get<PositionComponent>()!;
        final blob2 = b2.get<BlobComponent>()!;

        final center1 = Offset(pos1.x, pos1.y);
        final r1 = blob1.radius;
        final center2 = Offset(pos2.x, pos2.y);
        final r2 = blob2.radius;

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

/// A system that runs only once to initialize the scene after screen dimensions are known.
class MetaballSceneSetupSystem extends System {
  bool _isInitialized = false;

  @override
  bool matches(Entity entity) => false;

  @override
  void run(double dt) {
    if (_isInitialized) return;
    final screenInfo = world.rootEntity.get<ScreenInfoComponent>();
    if (screenInfo != null && screenInfo.width > 0 && screenInfo.height > 0) {
      final assembler = MetaballSceneAssembler(world);
      final entities = assembler.assemble();
      for (final entity in entities) {
        world.addEntity(entity);
      }
      _isInitialized = true;
      Future.microtask(() => world.removeSystem(this));
    }
  }

  @override
  void update(Entity entity, double dt) {}
}
