import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus_example/counter_cubit.dart';
import 'package:nexus_example/counter_module.dart';

// --- World Setup ---
NexusWorld setupWorld() {
  final world = NexusWorld();

  // --- Global Systems ---
  // These systems are application-wide and not specific to any feature.
  world.addSystem(FlutterRenderingSystem());
  world.addSystem(AnimationSystem());
  world.addSystem(PhysicsSystem());
  world.addSystem(LifecycleSystem());
  world.addSystem(PulsingWarningSystem()); // Add our new custom system

  // --- Shared State / Services ---
  final counterCubit = CounterCubit();

  // --- Load Feature Modules ---
  // The application is now composed by loading isolated modules.
  final counterModule = CounterModule();
  world.loadModule(counterModule);

  // --- Create Initial Entities ---
  // The module itself is responsible for creating its own entities.
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
        body: NexusWidget(
          world: world,
          child: renderingSystem.build(context),
        ),
      ),
    );
  }
}
