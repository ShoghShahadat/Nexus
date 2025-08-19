import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:nexus/src/core/nexus_world.dart';

/// A Flutter widget that hosts and runs a [NexusWorld].
///
/// This widget is now much simpler. It only runs the high-frequency logic
/// loop via a `Ticker`. The UI rendering is handled reactively by the
/// `EntityWidgetBuilder`s created by the `FlutterRenderingSystem`, so this
/// widget no longer needs to listen for changes or call `setState`.
class NexusWidget extends StatefulWidget {
  final NexusWorld world;
  final Widget child;

  const NexusWidget({
    super.key,
    required this.world,
    required this.child,
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
    // The logic loop ticker. This runs at the screen's refresh rate.
    _ticker = createTicker(_onTick)..start();
  }

  /// The high-frequency callback for the logic loop.
  void _onTick(Duration elapsed) {
    final delta = elapsed - _lastElapsed;
    final dt = delta.inMicroseconds / Duration.microsecondsPerSecond;
    _lastElapsed = elapsed;

    // Update the world's logic without rebuilding this widget.
    if (mounted) {
      widget.world.update(dt);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The child is built only once. All subsequent updates are handled
    // by the reactive EntityWidgetBuilders within the child tree.
    return widget.child;
  }
}
