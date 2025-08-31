import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/nexus.dart';

/// A specialized [GoRoute] that automatically wraps your scene's widget
/// with its own self-contained [NexusScope].
///
/// This is perfect for a multi-scene application where each route manages
/// its own isolated Nexus world.
abstract class NexusRoute extends GoRoute {
  NexusRoute({
    required super.path,
    required NexusWorld Function() worldProvider,
    required Widget Function(BuildContext context) sceneBuilder,
    super.name,
    super.parentNavigatorKey,
    super.redirect,
  }) : super(
          builder: (context, state) {
            // This route creates its own NexusScope, making it a self-contained
            // scene with its own logic world.
            return NexusScope(
              // A unique key is crucial to ensure Flutter replaces the scope
              // correctly when navigating between different Nexus scenes.
              key: ValueKey('NexusScope_${path}'),
              worldProvider: worldProvider,
              child: sceneBuilder(context),
            );
          },
        );
}
