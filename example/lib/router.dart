import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/nexus_router.dart';
import 'package:nexus_example/counter_cubit.dart';
import 'package:nexus_example/counter_module/counter_module.dart';
import 'package:nexus_example/counter_module/ui/button_painters.dart';
import 'package:nexus_example/counter_module/ui/morphing_painter.dart';
import 'package:nexus_example/counter_module/utils/shape_utils.dart';

/// Defines the routes for the application using go_router.
final router = GoRouter(
  initialLocation: '/counter',
  routes: [
    CounterSceneRoute(path: '/counter'),
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
          worldProvider: _provideCounterWorld,
          renderingSystemBuilder: (context) {
            return FlutterRenderingSystem(
              builders: {
                'counter_display': (context, id, controller, manager) {
                  final stateValue =
                      controller.get<CounterStateComponent>(id)?.value ?? 0;
                  final morphLogic = controller.get<MorphingLogicComponent>(id);
                  final pos = controller.get<PositionComponent>(id);
                  if (morphLogic == null || pos == null) {
                    return const SizedBox.shrink();
                  }

                  final path = getPolygonPath(
                      Size(pos.width, pos.height), morphLogic.targetSides,
                      cornerRadius: 12);
                  final color =
                      stateValue >= 0 ? Colors.deepPurple : Colors.redAccent;

                  return CustomPaint(
                    painter: MorphingPainter(
                        path: path, color: color, text: 'Count: $stateValue'),
                  );
                },
                'increment_button': (context, id, controller, manager) {
                  return ElevatedButton(
                    onPressed: () {
                      manager.send(EntityTapEvent(id));
                    },
                    child: const Icon(Icons.add),
                  );
                },
                'decrement_button': (context, id, controller, manager) {
                  return ElevatedButton(
                    onPressed: () {
                      manager.send(EntityTapEvent(id));
                    },
                    child: const Icon(Icons.remove),
                  );
                },
                'shape_button': (context, id, controller, manager) {
                  final shape = controller.get<ShapePathComponent>(id);
                  final pos = controller.get<PositionComponent>(id);
                  if (shape == null || pos == null) {
                    return const SizedBox.shrink();
                  }

                  final path =
                      getPolygonPath(Size(pos.width, pos.height), shape.sides);

                  return GestureDetector(
                    onTap: () {
                      manager.send(EntityTapEvent(id));
                    },
                    child: Container(
                      color: Colors.transparent,
                      child:
                          CustomPaint(painter: ShapeButtonPainter(path: path)),
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
    world.addSystem(ShapeSelectionSystem());
    world.addSystem(InputSystem()); // Add the input system here as well
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
