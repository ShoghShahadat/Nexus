import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'particle_painter.dart';
import 'package:collection/collection.dart';

/// The entry point for the background isolate.
NexusWorld provideAttractorWorld() {
  final world = NexusWorld();

  world.addSystem(PointerSystem());
  world.addSystem(ParticleSpawningSystem());
  world.addSystem(ParticleLifecycleSystem());
  world.addSystem(PhysicsSystem());
  world.addSystem(AttractionSystem());

  final attractor = Entity();
  attractor.add(PositionComponent(x: 200, y: 300, width: 20, height: 20));
  attractor.add(AttractorComponent(strength: 1.0));
  attractor.add(TagsComponent({'attractor'}));
  world.addEntity(attractor);

  final spawner = Entity();
  // --- FIX: Removed PositionComponent from spawner ---
  // --- NEW: Link the spawner to the attractor's position ---
  spawner.add(SpawnerLinkComponent(targetTag: 'attractor'));
  spawner.add(SpawnerComponent(spawnRate: 200));
  world.addEntity(spawner);

  final root = Entity();
  root.add(CustomWidgetComponent(widgetType: 'particle_canvas'));
  root.add(TagsComponent({'root'}));
  world.addEntity(root);

  return world;
}

/// Main entry point for the Flutter app.
void main() {
  registerCoreComponents();
  // We need to register our new component for serialization
  ComponentFactoryRegistry.I.register(
      'SpawnerLinkComponent', (json) => SpawnerLinkComponent.fromJson(json));
  runApp(const MyApp());
}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final renderingSystem = FlutterRenderingSystem(
      builders: {
        'particle_canvas': (context, id, controller, manager, child) {
          final particleIds = controller.getAllIdsWithTag('particle');
          final attractorId =
              controller.getAllIdsWithTag('attractor').firstOrNull;

          if (attractorId == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RepaintBoundary(
            child: CustomPaint(
              painter: ParticlePainter(
                particleIds: particleIds,
                attractorId: attractorId,
                controller: controller,
              ),
              child: const SizedBox.expand(),
            ),
          );
        },
      },
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1a1a1a),
        appBar: AppBar(
          title: const Text('Nexus Attractor Example'),
          backgroundColor: Colors.grey.shade900,
          foregroundColor: Colors.white,
        ),
        body: NexusWidget(
          worldProvider: provideAttractorWorld,
          renderingSystem: renderingSystem,
        ),
      ),
    );
  }
}
