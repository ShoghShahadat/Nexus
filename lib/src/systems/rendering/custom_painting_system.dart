import 'package:flutter/foundation.dart';
import 'package:nexus/nexus.dart';

/// This system runs in the logic isolate. It queries for all drawable entities,
/// sorts them by layer, and generates a serializable "render packet".
/// This packet is then attached to a central scene entity to be sent to the UI thread.
class CustomPaintingSystem extends System {
  static const String _sceneEntityTag = 'nexus_scene';

  Entity? _sceneEntity;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    // Find or create the central scene entity.
    final existing = world.entities.values
        .where((e) => e.get<TagsComponent>()?.hasTag(_sceneEntityTag) ?? false);

    if (existing.isEmpty) {
      _sceneEntity = Entity();
      _sceneEntity!.add(TagsComponent({_sceneEntityTag}));
      _sceneEntity!.add(SceneRenderPacketComponent(const []));
      world.addEntity(_sceneEntity!);
    } else {
      _sceneEntity = existing.first;
    }
  }

  /// This method is not part of the standard update loop but can be called by it.
  /// It processes all drawable entities at once to generate the render packet.
  void run(double dt) {
    if (_sceneEntity == null) return;

    final entities =
        world.entities.values.where((e) => e.has<DrawableComponent>()).toList();

    // Sort by z-index (layer). Lower z-index is drawn first.
    entities.sort((a, b) {
      final layerA = a.get<LayerComponent>()?.zIndex ?? 0;
      final layerB = b.get<LayerComponent>()?.zIndex ?? 0;
      return layerA.compareTo(layerB);
    });

    final renderPacket = <Map<String, dynamic>>[];

    for (final entity in entities) {
      final shapeComp = entity.get<ShapeComponent>();
      final styleComp = entity.get<StyleComponent>();
      final transformComp = entity.get<TransformComponent>();
      final interactiveComp = entity.get<InteractiveComponent>();

      if (shapeComp == null || styleComp == null || transformComp == null) {
        continue;
      }

      // *** FIX & LOGGING: Only add shapes that actually have something to draw ***
      if (shapeComp.shape is PathShape &&
          (shapeComp.shape as PathShape).commands.isEmpty) {
        continue;
      }

      final command = <String, dynamic>{
        'entityId': entity.id,
        'shape': shapeComp.shape.toJson(),
        'style': styleComp.toJson(),
        'transform': transformComp.toJson(),
      };

      if (interactiveComp != null && interactiveComp.isHitTestable) {
        command['interactive'] = {
          // We don't serialize the event itself, just markers.
          // The UI thread will send back an event with the entityId and shape type.
          'onTap': interactiveComp.onTapEvent != null,
          'onDrag': interactiveComp.onDragUpdateEvent != null,
        };
      }

      renderPacket.add(command);
    }

    // *** LOGGING ADDED ***
    debugPrint(
        '[CustomPaintingSystem] 🟢 Generated render packet with ${renderPacket.length} drawable commands.');

    // Update the central scene entity with the new packet.
    // This will be picked up by the UI thread.
    _sceneEntity!.add(SceneRenderPacketComponent(renderPacket));
  }
}
