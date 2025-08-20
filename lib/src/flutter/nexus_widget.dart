import 'package:flutter/widgets.dart';
import 'package:nexus/nexus.dart';

/// A Flutter widget that hosts and runs a NexusWorld in a background isolate.
///
/// This widget manages the lifecycle of the NexusIsolateManager and connects
/// it to the FlutterRenderingSystem to build the UI reactively.
class NexusWidget extends StatefulWidget {
  final NexusWorld Function() worldProvider;
  final FlutterRenderingSystem renderingSystem;

  const NexusWidget({
    super.key,
    required this.worldProvider,
    required this.renderingSystem,
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
    // Provide the manager to the rendering system so it can be used by builders.
    widget.renderingSystem.setManager(_isolateManager);
    _isolateManager.spawn(widget.worldProvider);
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
    // AnimatedBuilder listens to the rendering system (which is a ChangeNotifier)
    // and rebuilds its child whenever the system calls notifyListeners().
    return AnimatedBuilder(
      animation: widget.renderingSystem,
      builder: (context, child) {
        return widget.renderingSystem.build(context);
      },
    );
  }
}
