import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus_example/counter_cubit.dart';
import 'package:nexus_example/counter_module/counter_module.dart';
import 'package:nexus_example/counter_module/ui/button_painters.dart';
import 'package:nexus_example/counter_module/ui/morphing_painter.dart';

// --- World Provider ---
// This function will be executed in the background isolate.
// It sets up the data and logic, but no Flutter widgets.
NexusWorld provideNexusWorld() {
  final world = NexusWorld();

  // Register CounterCubit as a singleton service
  world.services.registerSingleton(CounterCubit());

  // --- Global Systems ---
  // FlutterRenderingSystem is no longer added here.
  world.addSystem(AnimationSystem());
  world.addSystem(PulsingWarningSystem());
  world.addSystem(MorphingSystem());
  world.addSystem(LifecycleSystem());

  // --- Load Feature Modules ---
  final counterModule = CounterModule();
  world.loadModule(counterModule);

  return world;
}

void main() {
  // Register all serializable components for the ComponentFactory.
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
        'counter_display': (context, id, controller) {
          final state = controller.get<CounterStateComponent>(id)!.value;
          final morph = controller.get<MorphingComponent>(id)!;
          final color = state >= 0 ? Colors.deepPurple : Colors.redAccent;
          return CustomPaint(
            painter: MorphingPainter(
                path: morph.currentPath, color: color, text: 'Count: $state'),
          );
        },
        'increment_button': (context, id, controller) {
          return ElevatedButton(
            onPressed: () {
              // Note: Input handling would require sending events to the isolate.
              // This is a more advanced topic. For now, this demonstrates rendering.
            },
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
          final shapePath = controller.get<ShapePathComponent>(id)!.path;
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
