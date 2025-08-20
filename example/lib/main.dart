import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus_example/counter_cubit.dart';
import 'package:nexus_example/counter_module/counter_module.dart';
import 'package:nexus_example/counter_module/ui/button_painters.dart';
import 'package:nexus_example/counter_module/ui/morphing_painter.dart';
import 'package:nexus_example/counter_module/utils/shape_utils.dart';

// --- World Provider ---
// This function will be executed in the background isolate.
// It sets up the data and logic, but no Flutter widgets.
NexusWorld provideNexusWorld() {
  final world = NexusWorld();

  // Register CounterCubit as a singleton service
  world.services.registerSingleton(CounterCubit());

  // --- Global Systems ---
  world.addSystem(AnimationSystem());
  world.addSystem(PulsingWarningSystem());
  world.addSystem(MorphingSystem());
  world.addSystem(LifecycleSystem());
  world.addSystem(InputSystem());

  // --- Load Feature Modules ---
  final counterModule = CounterModule();
  world.loadModule(counterModule);

  return world;
}

void main() {
  // Register all serializable components from the core framework.
  // This is crucial for communication between isolates.
  registerCoreComponents();

  runApp(const MyApp());
}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- UI Setup ---
    // This happens on the main thread.
    // We define how entities are rendered based on their tags.
    final renderingSystem = FlutterRenderingSystem(
      builders: {
        'counter_display': (context, id, controller, manager) {
          final stateComp = controller.get<CounterStateComponent>(id);
          final morph = controller.get<MorphingLogicComponent>(id);
          final pos = controller.get<PositionComponent>(id);
          final anim = controller.get<AnimationProgressComponent>(id);

          if (stateComp == null || morph == null || pos == null) {
            return const SizedBox.shrink();
          }

          final state = stateComp.value;
          final color = state >= 0 ? Colors.deepPurple : Colors.redAccent;

          final startPath = getPolygonPath(
              Size(pos.width, pos.height), morph.initialSides,
              cornerRadius: 12.0);
          final endPath = getPolygonPath(
              Size(pos.width, pos.height), morph.targetSides,
              cornerRadius: 12.0);

          // If animation is running, use its progress. Otherwise, it's complete (1.0).
          final progress = anim?.progress ?? 1.0;

          return CustomPaint(
            painter: MorphingPainter(
              startPath: startPath,
              endPath: endPath,
              progress: progress,
              color: color,
              text: 'Count: $state',
            ),
          );
        },
        'increment_button': (context, id, controller, manager) {
          return ElevatedButton(
            onPressed: () {
              // Send a tap event to the logic isolate.
              manager.send(EntityTapEvent(id));
            },
            child: const Icon(Icons.add),
          );
        },
        'decrement_button': (context, id, controller, manager) {
          return ElevatedButton(
            onPressed: () {
              // Send a tap event to the logic isolate.
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

          final path = getPolygonPath(Size(pos.width, pos.height), shape.sides);

          return GestureDetector(
            onTap: () {
              // Send a tap event to the logic isolate.
              manager.send(EntityTapEvent(id));
            },
            child: Container(
              color: Colors.transparent,
              child: CustomPaint(
                  size: Size(pos.width, pos.height),
                  painter: ShapeButtonPainter(path: path)),
            ),
          );
        },
      },
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          title: const Text('Nexus Isolate Example',
              style: TextStyle(color: Colors.white)),
        ),
        body: NexusWidget(
          worldProvider: provideNexusWorld,
          renderingSystem: renderingSystem,
        ),
      ),
    );
  }
}
