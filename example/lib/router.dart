import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus_example/counter_cubit.dart';
import 'package:nexus_example/counter_module/counter_module.dart';

/// Defines the routes for the application using go_router.
final router = GoRouter(
  initialLocation: '/counter',
  routes: [
    // This is a Nexus-powered screen.
    CounterSceneRoute(path: '/counter'),

    // This could be a regular, non-Nexus screen.
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

/// Defines the Counter screen as a self-contained Nexus Scene.
class CounterSceneRoute extends NexusRoute {
  CounterSceneRoute({required super.path})
      : super(
          // The builder now returns a Scaffold, providing the necessary app structure.
          builder: (context, state) {
            // Create the world specifically for this route instance.
            final world = _buildCounterWorld();

            // Find the rendering system to build the UI.
            final renderingSystem = world.systems.firstWhere(
                    (s) => s is FlutterRenderingSystem,
                    orElse: () => throw Exception(
                        'NexusRoute requires a FlutterRenderingSystem to be present in the world.'))
                as FlutterRenderingSystem;

            // The NexusWidget is now the body of the Scaffold.
            return Scaffold(
              appBar: AppBar(
                title: const Text('Nexus Counter Example'),
                backgroundColor: Colors.deepPurple,
                titleTextStyle:
                    const TextStyle(color: Colors.white, fontSize: 20),
              ),
              body: NexusWidget(
                world: world,
                child: renderingSystem.build(context),
              ),
            );
          },
        );

  /// Helper method to encapsulate world creation logic.
  static NexusWorld _buildCounterWorld() {
    final world = NexusWorld();

    // Register services needed for this scene.
    world.services.registerSingleton(CounterCubit());

    // Add global systems.
    world.addSystem(FlutterRenderingSystem());
    world.addSystem(AnimationSystem());
    world.addSystem(PulsingWarningSystem());
    world.addSystem(MorphingSystem());
    world.addSystem(LifecycleSystem());

    // Load feature modules for this scene.
    world.loadModule(CounterModule());

    return world;
  }
}

/// A simple, standard Flutter widget for a non-Nexus route.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(
        child: Text('This is a regular Flutter page.'),
      ),
    );
  }
}
