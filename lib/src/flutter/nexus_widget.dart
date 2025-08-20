import 'package:flutter/widgets.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/events/pointer_events.dart';

/// A Flutter widget that hosts and runs a NexusWorld in a background isolate.
///
/// This widget manages the lifecycle of the NexusIsolateManager and connects
/// it to the FlutterRenderingSystem to build the UI reactively.
class NexusWidget extends StatefulWidget {
  final NexusWorld Function() worldProvider;
  final FlutterRenderingSystem renderingSystem;
  // FIX: Added initializer for custom component registration.
  final void Function()? isolateInitializer;

  const NexusWidget({
    super.key,
    required this.worldProvider,
    required this.renderingSystem,
    this.isolateInitializer,
  });

  @override
  State<NexusWidget> createState() => _NexusWidgetState();
}

class _NexusWidgetState extends State<NexusWidget> {
  late final NexusIsolateManager _isolateManager;

  @override
  void initState() {
    super.initState();
    _isolateManager = NexusIsolateManager();
    widget.renderingSystem.setManager(_isolateManager);
    // FIX: Pass the initializer to the spawn method.
    _isolateManager.spawn(
      widget.worldProvider,
      isolateInitializer: widget.isolateInitializer,
    );
    _isolateManager.renderPacketStream
        .listen(widget.renderingSystem.updateFromPackets);
  }

  @override
  void dispose() {
    _isolateManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: (event) {
        final NexusPointerMoveEvent pointerEvent = NexusPointerMoveEvent(
            event.localPosition.dx, event.localPosition.dy);
        _isolateManager.send(pointerEvent);
      },
      child: AnimatedBuilder(
        animation: widget.renderingSystem,
        builder: (context, child) {
          return widget.renderingSystem.build(context);
        },
      ),
    );
  }
}
