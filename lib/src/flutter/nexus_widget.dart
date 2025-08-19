import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:nexus/src/core/nexus_world.dart';

/// A Flutter widget that hosts and runs a [NexusWorld].
///
/// This widget is the bridge between the Nexus ECS architecture and the Flutter
/// widget tree. It initializes a `Ticker` to drive the `NexusWorld`'s update
/// loop, ensuring that all systems are processed on each frame.
class NexusWidget extends StatefulWidget {
  /// The world instance that this widget will manage.
  final NexusWorld world;

  /// A builder function to create the UI that overlays the Nexus world.
  /// This UI can react to the state within the world.
  final Widget Function(BuildContext context, NexusWorld world) builder;

  const NexusWidget({
    super.key,
    required this.world,
    required this.builder,
  });

  @override
  State<NexusWidget> createState() => _NexusWidgetState();
}

class _NexusWidgetState extends State<NexusWidget>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  /// The callback executed for each animation frame.
  void _onTick(Duration elapsed) {
    final delta = elapsed - _lastElapsed;
    final dt = delta.inMicroseconds / Duration.microsecondsPerSecond;
    _lastElapsed = elapsed;

    // Update the world with the calculated delta time.
    // We also trigger a widget rebuild to ensure the UI reflects the new state.
    if (mounted) {
      setState(() {
        widget.world.update(dt);
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.world);
  }
}
