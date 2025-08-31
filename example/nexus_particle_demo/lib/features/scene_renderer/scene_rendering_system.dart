import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/events/pointer_events.dart';
import 'package:nexus/src/flutter/rendering/nexus_painter.dart';

/// A generic rendering system for a custom painting scene.
/// یک سیستم رندرینگ عمومی برای یک صحنه نقاشی سفارشی.
///
/// This system renders a CustomPaint widget managed by a NexusPainter and
/// forwards pointer events back to the logic isolate.
/// این سیستم یک ویجت CustomPaint را که توسط NexusPainter مدیریت می‌شود، رندر کرده
/// و رویدادهای اشاره‌گر را به ایزولیت منطق ارسال می‌کند.
class SceneRenderingSystem extends FlutterRenderingSystem {
  final String sceneEntityTag;
  final Color backgroundColor;

  SceneRenderingSystem({
    this.sceneEntityTag = 'nexus_scene',
    this.backgroundColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    final sceneEntities = getAllIdsWithTag(sceneEntityTag);
    if (sceneEntities.isEmpty) {
      // *** LOGGING ADDED ***
      debugPrint(
          '[SceneRenderingSystem] 🟡 Build called, but scene entity not found yet. Showing loader.');
      return Container(
        color: backgroundColor,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      color: backgroundColor,
      child: Listener(
        onPointerMove: (event) {
          manager?.send(NexusPointerMoveEvent(
            event.localPosition.dx,
            event.localPosition.dy,
          ));
        },
        child: AnimatedBuilder(
          animation: this,
          builder: (context, child) {
            final sceneEntityId = sceneEntities.firstOrNull;
            if (sceneEntityId == null) {
              return const SizedBox.shrink();
            }

            return AnimatedBuilder(
              animation: getNotifier(sceneEntityId),
              builder: (context, child) {
                final packetComponent =
                    get<SceneRenderPacketComponent>(sceneEntityId);
                final renderPacket = packetComponent?.packet ?? const [];

                // *** LOGGING ADDED ***
                debugPrint(
                    '[SceneRenderingSystem] 🟢 Rebuilding CustomPaint. Passing ${renderPacket.length} commands to painter.');

                return CustomPaint(
                  painter: NexusPainter(
                    renderPacket: renderPacket,
                    renderingSystem: this,
                  ),
                  size: Size.infinite,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
