import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:nexus/nexus.dart';

/// A Flutter widget that hosts and runs a NexusWorld.
class NexusWidget extends StatefulWidget {
  final NexusWorld Function() worldProvider;
  final FlutterRenderingSystem renderingSystem;
  final Future<void> Function()? isolateInitializer;
  // --- NEW: Added RootIsolateToken ---
  final RootIsolateToken? rootIsolateToken;

  const NexusWidget({
    super.key,
    required this.worldProvider,
    required this.renderingSystem,
    this.isolateInitializer,
    this.rootIsolateToken,
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
      rootIsolateToken: widget.rootIsolateToken, // Pass the token
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
      child: AnimatedBuilder(
        animation: widget.renderingSystem,
        builder: (context, child) {
          return widget.renderingSystem.build(context);
        },
      ),
    );
  }
}
