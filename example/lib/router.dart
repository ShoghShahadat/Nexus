import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/nexus_router.dart';
import 'package:nexus_example/counter_cubit.dart';
import 'package:nexus_example/counter_module/counter_module.dart';
import 'package:nexus_example/counter_module/ui/button_painters.dart';
import 'package:nexus_example/counter_module/ui/morphing_painter.dart';

/// Defines the routes for the application using go_router.
final router = GoRouter(
  initialLocation: '/counter',
  routes: [
    // This is a Nexus-powered screen, now correctly implemented.
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
  CounterSceneRoute({required String path})
      : super(
          path: path,
          // 1. Provide the world provider function to run in the isolate.
          worldProvider: _provideCounterWorld,
          // 2. Provide the rendering system builder to run on the UI thread.
          renderingSystemBuilder: (context) {
            return FlutterRenderingSystem(
              builders: {
                'counter_display': (context, id, controller) {
                  final stateValue =
                      controller.get<CounterStateComponent>(id)?.value ?? 0;
                  final morph = controller.get<MorphingComponent>(id);
                  if (morph == null) return const SizedBox.shrink();

                  final color =
                      stateValue >= 0 ? Colors.deepPurple : Colors.redAccent;
                  return CustomPaint(
                    painter: MorphingPainter(
                        path: morph.currentPath,
                        color: color,
                        text: 'Count: $stateValue'),
                  );
                },
                'increment_button': (context, id, controller) {
                  return ElevatedButton(
                    onPressed: () {},
                    child: const Icon(Icons.add),
                  );
                },
                'decrement_button': (context, id, controller) {
                  return ElevatedButton(
                    onPressed: () {},
                    child: const Icon(Icons.remove),
                  );
                },
                'shape_button': (context, id, controller) {
                  final shapePath =
                      controller.get<ShapePathComponent>(id)?.path;
                  if (shapePath == null) return const SizedBox.shrink();
                  return GestureDetector(
                    onTap: () {},
                    child: Container(
                      color: Colors.transparent,
                      child: CustomPaint(
                          size: const Size(60, 60),
                          painter: ShapeButtonPainter(path: shapePath)),
                    ),
                  );
                },
              },
            );
          },
        );

  /// Helper method to create the world. Runs in the background.
  static NexusWorld _provideCounterWorld() {
    final world = NexusWorld();
    world.services.registerSingleton(CounterCubit());
    world.addSystem(AnimationSystem());
    world.addSystem(PulsingWarningSystem());
    world.addSystem(MorphingSystem());
    world.addSystem(LifecycleSystem());
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
