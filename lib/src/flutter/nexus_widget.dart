import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:nexus/nexus.dart';

/// A Flutter widget that hosts and runs a NexusWorld.
class NexusWidget extends StatefulWidget {
  final NexusWorld Function() worldProvider;
  final FlutterRenderingSystem renderingSystem;
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
  late final NexusManager _manager;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _manager = NexusSingleThreadManager();
    } else {
      _manager = NexusIsolateManager();
    }

    widget.renderingSystem.setManager(_manager);

    _manager.spawn(
      widget.worldProvider,
      isolateInitializer: widget.isolateInitializer,
    );
    _manager.renderPacketStream
        .listen(widget.renderingSystem.updateFromPackets);
  }

  @override
  void dispose() {
    _manager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: (event) {
        final NexusPointerMoveEvent pointerEvent = NexusPointerMoveEvent(
            event.localPosition.dx, event.localPosition.dy);
        _manager.send(pointerEvent);
      },
      // --- FIX: The AnimatedBuilder now correctly listens to the main rendering system ---
      // This ensures that when new entities are added or removed (structural changes),
      // the entire widget tree is rebuilt to reflect those changes.
      // Granular updates are handled by AnimatedBuilders inside the rendering system.
      child: AnimatedBuilder(
        animation: widget.renderingSystem,
        builder: (context, child) {
          return widget.renderingSystem.build(context);
        },
      ),
    );
  }
}
