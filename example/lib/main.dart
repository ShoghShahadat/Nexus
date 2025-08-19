import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus_example/counter_cubit.dart';
import 'package:nexus_example/counter_module.dart';

// --- World Setup ---
NexusWorld setupWorld() {
  final world = NexusWorld();

  // --- Global Systems ---
  world.addSystem(FlutterRenderingSystem());
  world.addSystem(AnimationSystem());
  world.addSystem(PulsingWarningSystem());
  world.addSystem(MorphingSystem());
  // The central InputSystem is no longer needed.

  // --- Shared State / Services ---
  final counterCubit = CounterCubit();

  // --- Load Feature Modules ---
  final counterModule = CounterModule();
  world.loadModule(counterModule);

  // --- Create Initial Entities ---
  counterModule.createEntities(world, counterCubit);

  return world;
}

void main() {
  runApp(MyApp(world: setupWorld()));
}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  final NexusWorld world;

  const MyApp({super.key, required this.world});

  @override
  Widget build(BuildContext context) {
    final renderingSystem =
        world.systems.firstWhere((s) => s is FlutterRenderingSystem)
            as FlutterRenderingSystem;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          title: const Text('Nexus Counter Example',
              style: TextStyle(color: Colors.white)),
        ),
        // The root Listener is removed. Input is now handled by individual widgets.
        body: NexusWidget(
          world: world,
          child: renderingSystem.build(context),
        ),
      ),
    );
  }
}
