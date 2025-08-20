import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/nexus.dart';

/// A specialized [GoRoute] that handles the creation and rendering of a
/// self-contained [NexusWorld] for a specific screen or "scene".
///
/// This class elegantly bridges `go_router`'s navigation with Nexus's ECS
/// architecture. It abstracts away the boilerplate of setting up a NexusWidget
/// for a route.
abstract class NexusRoute extends GoRoute {
  /// Creates a NexusRoute.
  ///
  /// - [path], [name], etc. are standard [GoRoute] parameters.
  /// - [worldBuilder] is required to construct the specific [NexusWorld] for this scene.
  /// - [sceneBuilder] is an optional wrapper for the final [NexusWidget]. Use this
  ///   to add widgets like [Scaffold], [AppBar], etc., around your Nexus scene.
  NexusRoute({
    required String path,
    required NexusWorld Function(BuildContext context, GoRouterState state)
        worldBuilder,
    Widget Function(
            BuildContext context, GoRouterState state, Widget nexusWidget)?
        sceneBuilder,
    String? name,
    GlobalKey<NavigatorState>? parentNavigatorKey,
    GoRouterRedirect? redirect,
  }) : super(
          path: path,
          name: name,
          parentNavigatorKey: parentNavigatorKey,
          redirect: redirect,
          builder: (context, state) {
            // 1. Build the world using the provided factory.
            final world = worldBuilder(context, state);

            // 2. Find the essential rendering system.
            final renderingSystem = world.systems.firstWhere(
                    (s) => s is FlutterRenderingSystem,
                    orElse: () => throw Exception(
                        'NexusRoute requires a FlutterRenderingSystem to be present in the world.'))
                as FlutterRenderingSystem;

            // 3. Build the core Nexus widget.
            final nexusWidget = NexusWidget(
              world: world,
              child: renderingSystem.build(context),
            );

            // 4. If a sceneBuilder is provided, use it to wrap the NexusWidget.
            if (sceneBuilder != null) {
              return sceneBuilder(context, state, nexusWidget);
            }

            // 5. Otherwise, return the NexusWidget directly.
            return nexusWidget;
          },
        );
}
