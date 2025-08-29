import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/flutter/rendering/nexus_painter.dart';

/// An IWidgetBuilder implementation that renders a CustomPaint widget.
/// It retrieves the render packet from the scene entity and passes it
/// to the NexusPainter for actual drawing.
class NexusCanvasBuilder implements IWidgetBuilder {
  final String sceneEntityTag;

  NexusCanvasBuilder({this.sceneEntityTag = 'nexus_scene'});

  @override
  Widget build(
    BuildContext context,
    FlutterRenderingSystem renderingSystem,
    EntityId
        entityId, // This builder is usually tied to a scene, not a specific entity
  ) {
    // Find the scene entity which holds the render packet.
    final sceneEntities = renderingSystem.getAllIdsWithTag(sceneEntityTag);
    if (sceneEntities.isEmpty) {
      return const SizedBox.shrink();
    }

    final sceneEntityId = sceneEntities.first;

    // Use an AnimatedBuilder to listen for changes to the scene entity's notifier.
    return AnimatedBuilder(
      animation: renderingSystem.getNotifier(sceneEntityId),
      builder: (context, child) {
        final packetComponent =
            renderingSystem.get<SceneRenderPacketComponent>(sceneEntityId);
        final renderPacket = packetComponent?.packet ?? const [];

        return CustomPaint(
          painter: NexusPainter(
            renderPacket: renderPacket,
            renderingSystem: renderingSystem,
          ),
          // Takes the full space available.
          size: Size.infinite,
        );
      },
    );
  }
}
