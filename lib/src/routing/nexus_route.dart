import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/nexus.dart';

/// A specialized [GoRoute] that handles the creation and rendering of a
/// self-contained Nexus scene running in a background isolate.
///
/// This class abstracts away the boilerplate of setting up a NexusWidget
/// for a specific route.
abstract class NexusRoute extends GoRoute {
  /// Creates a NexusRoute.
  ///
  /// - [path], [name], etc. are standard [GoRoute] parameters.
  /// - [worldProvider] is required to construct the NexusWorld for this scene.
  ///   This function runs in the background isolate.
  /// - [renderingSystemBuilder] is required to build the FlutterRenderingSystem
  ///   that will render the UI for this scene on the main thread.
  NexusRoute({
    required String path,
    required NexusWorld Function() worldProvider,
    required FlutterRenderingSystem Function(BuildContext context)
        renderingSystemBuilder,
    String? name,
    GlobalKey<NavigatorState>? parentNavigatorKey,
    GoRouterRedirect? redirect,
  }) : super(
          path: path,
          name: name,
          parentNavigatorKey: parentNavigatorKey,
          redirect: redirect,
          builder: (context, state) {
            // 1. Build the rendering system on the UI thread.
            final renderingSystem = renderingSystemBuilder(context);

            // 2. The NexusWidget will use the provider to create the world
            //    in its own isolate and connect it to the rendering system.
            return NexusWidget(
              worldProvider: worldProvider,
              renderingSystem: renderingSystem,
            );
          },
        );
}
