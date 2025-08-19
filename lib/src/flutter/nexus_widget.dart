import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:nexus/src/core/nexus_world.dart';

/// A Flutter widget that hosts and runs a [NexusWorld].
///
/// This widget separates the high-frequency logic loop (driven by a `Ticker`)
/// from the UI render loop (driven by a `ChangeNotifier`). This is a highly
/// performant approach that ensures the UI only rebuilds when necessary.
class NexusWidget extends StatefulWidget {
  final NexusWorld world;
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
    // The logic loop ticker. This runs at the screen's refresh rate.
    _ticker = createTicker(_onTick)..start();

    // The render loop listener. This only triggers a rebuild when notified.
    widget.world.worldNotifier.addListener(_onWorldChanged);
  }

  /// The high-frequency callback for the logic loop.
  void _onTick(Duration elapsed) {
    final delta = elapsed - _lastElapsed;
    final dt = delta.inMicroseconds / Duration.microsecondsPerSecond;
    _lastElapsed = elapsed;

    // Update the world's logic without rebuilding the widget.
    if (mounted) {
      widget.world.update(dt);
    }
  }

  /// The low-frequency callback for the render loop.
  void _onWorldChanged() {
    // A visual change has occurred in the world, so we call setState
    // to trigger a rebuild of the widget tree.
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    widget.world.worldNotifier.removeListener(_onWorldChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.world);
  }
}
