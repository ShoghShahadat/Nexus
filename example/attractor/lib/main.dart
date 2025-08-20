import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:collection/collection.dart';

import 'particle_painter.dart';
import 'components/explosion_component.dart';
import 'components/complex_movement_component.dart';
import 'components/meteor_component.dart';
import 'components/meteor_target_component.dart';
import 'systems/explosion_system.dart';
import 'systems/complex_movement_system.dart';
import 'systems/meteor_spawner_system.dart';
import 'systems/meteor_burn_system.dart';
import 'systems/meteor_targeting_system.dart';
import 'systems/collision_system.dart';

/// The entry point for the background isolate.
NexusWorld provideAttractorWorld() {
  final world = NexusWorld();

  // Add all necessary systems to the world.
  world.addSystem(AnimationSystem());
  world.addSystem(ParticleExplosionSystem());
  world.addSystem(ComplexMovementSystem());
  world.addSystem(MeteorSpawnerSystem());
  world.addSystem(MeteorTargetingSystem()); // New system
  world.addSystem(MeteorBurnSystem());
  world.addSystem(CollisionSystem()); // New system
  world.addSystem(PointerSystem());
  world.addSystem(ParticleSpawningSystem());
  world.addSystem(ParticleLifecycleSystem());
  world.addSystem(PhysicsSystem());
  world.addSystem(AttractionSystem());

  // Create the central attractor entity.
  final attractor = Entity();
  attractor.add(PositionComponent(x: 200, y: 300, width: 20, height: 20));
  attractor.add(AttractorComponent(strength: 1.0));
  attractor.add(TagsComponent({'attractor'}));
  world.addEntity(attractor);

  // Create a spawner entity linked to the attractor's position.
  final spawner = Entity();
  spawner.add(SpawnerLinkComponent(targetTag: 'attractor'));
  spawner.add(SpawnerComponent(spawnRate: 200));
  world.addEntity(spawner);

  // Create a root entity for the UI to build the canvas.
  final root = Entity();
  root.add(CustomWidgetComponent(widgetType: 'particle_canvas'));
  root.add(TagsComponent({'root'}));
  world.addEntity(root);

  return world;
}

/// Main entry point for the Flutter app.
void main() {
  // Register all core components from the Nexus package.
  registerCoreComponents();

  // --- NEW: Register our custom local components for serialization ---
  ComponentFactoryRegistry.I.register('ExplodingParticleComponent',
      (json) => ExplodingParticleComponent.fromJson(json));
  ComponentFactoryRegistry.I.register('ComplexMovementComponent',
      (json) => ComplexMovementComponent.fromJson(json));
  ComponentFactoryRegistry.I
      .register('MeteorComponent', (json) => MeteorComponent.fromJson(json));
  ComponentFactoryRegistry.I.register(
      'MeteorTargetComponent', (json) => MeteorTargetComponent.fromJson(json));

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
          final meteorIds = controller.getAllIdsWithTag('meteor');
          final attractorId =
              controller.getAllIdsWithTag('attractor').firstOrNull;

          if (attractorId == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RepaintBoundary(
            child: CustomPaint(
              painter: ParticlePainter(
                particleIds: particleIds,
                meteorIds: meteorIds,
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
