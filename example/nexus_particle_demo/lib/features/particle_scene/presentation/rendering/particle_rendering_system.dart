import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/events/pointer_events.dart';
import 'package:nexus/src/flutter/rendering/nexus_painter.dart';

/// The UI-side rendering system for the particle scene.
/// سیستم رندرینگ سمت UI برای صحنه ذرات.
class ParticleRenderingSystem extends FlutterRenderingSystem {
  @override
  Widget build(BuildContext context) {
    // Find the entity that holds the render packet from the logic isolate.
    // The CustomPaintingSystem automatically creates an entity with this tag.
    // موجودیتی را پیدا می‌کند که بسته رندر را از ایزولیت منطق نگهداری می‌کند.
    // CustomPaintingSystem به طور خودکار یک موجودیت با این تگ ایجاد می‌کند.
    final sceneEntityId = getAllIdsWithTag('nexus_scene').firstOrNull;

    if (manager == null || sceneEntityId == null) {
      // Show a loading indicator until the world is initialized.
      // تا زمان مقداردهی اولیه دنیا، یک نشانگر بارگذاری نمایش می‌دهد.
      return const Center(child: CircularProgressIndicator());
    }

    // Use an AnimatedBuilder to listen for new render packets.
    // از یک AnimatedBuilder برای گوش دادن به بسته‌های رندر جدید استفاده می‌کند.
    return AnimatedBuilder(
      animation: getNotifier(sceneEntityId),
      builder: (context, child) {
        final packetComponent = get<SceneRenderPacketComponent>(sceneEntityId);
        final renderPacket = packetComponent?.packet ?? const [];

        return GestureDetector(
          // Capture pointer movements and send them to the logic isolate.
          // حرکات اشاره‌گر را ثبت کرده و به ایزولیت منطق ارسال می‌کند.
          onPanUpdate: (details) {
            manager?.send(NexusPointerMoveEvent(
                details.localPosition.dx, details.localPosition.dy));
          },
          // The CustomPaint widget is extremely efficient for this task.
          // ویجت CustomPaint برای این کار بسیار کارآمد است.
          child: CustomPaint(
            painter: NexusPainter(
              renderPacket: renderPacket,
              renderingSystem: this,
            ),
            // Ensure the canvas takes up the entire available space.
            // اطمینان از اینکه بوم تمام فضای موجود را اشغال می‌کند.
            size: Size.infinite,
          ),
        );
      },
    );
  }
}
