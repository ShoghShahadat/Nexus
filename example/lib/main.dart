import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus_example/counter_cubit.dart';
import 'package:nexus_example/counter_module/counter_module.dart';

// --- World Setup ---
NexusWorld setupWorld() {
  final world = NexusWorld();

  // Register CounterCubit as a singleton service
  world.services.registerSingleton(CounterCubit());

  // --- Global Systems ---
  world.addSystem(FlutterRenderingSystem());
  world.addSystem(AnimationSystem());
  world.addSystem(PulsingWarningSystem());
  world.addSystem(MorphingSystem());
  world.addSystem(LifecycleSystem());

  // --- Load Feature Modules ---
  // The module will now use the registered CounterCubit
  final counterModule = CounterModule();
  world.loadModule(counterModule);

  // --- Entity creation is now handled by the module's EntityProvider ---

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
