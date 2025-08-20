import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:collection/collection.dart';
import 'package:get_it/get_it.dart';

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
// --- FIX: Import the renamed, example-specific collision system ---
// --- اصلاح: ایمپورت کردن سیستم برخورد تغییر نام یافته و مخصوص مثال ---
import 'systems/meteor_collision_system.dart';

final InMemoryStorageAdapter _debugStorage = InMemoryStorageAdapter();

class InMemoryStorageAdapter implements StorageAdapter {
  final Map<String, Map<String, dynamic>> _data = {};
  @override
  Future<void> init() async {}
  @override
  Future<Map<String, dynamic>?> load(String key) async =>
      _data[key.replaceFirst('nexus_', '')];
  @override
  Future<void> save(String key, Map<String, dynamic> data) async =>
      _data[key.replaceFirst('nexus_', '')] = data;
  @override
  Future<Map<String, Map<String, dynamic>>> loadAll() async => _data;
}

Future<void> isolateInitializer() async {
  final StorageAdapter storage = _debugStorage;
  await storage.init();
  if (!GetIt.I.isRegistered<StorageAdapter>()) {
    GetIt.I.registerSingleton<StorageAdapter>(storage);
  }
}

NexusWorld provideAttractorWorld() {
  final world = NexusWorld();
  world.addSystem(AnimationSystem());
  world.addSystem(PersistenceSystem());
  world.addSystem(ParticleExplosionSystem());
  world.addSystem(ComplexMovementSystem());
  world.addSystem(MeteorSpawnerSystem());
  world.addSystem(MeteorTargetingSystem());
  world.addSystem(MeteorBurnSystem());
  // --- FIX: Use the renamed MeteorCollisionSystem ---
  // --- اصلاح: استفاده از MeteorCollisionSystem تغییر نام یافته ---
  world.addSystem(MeteorCollisionSystem());
  world.addSystem(PointerSystem());
  world.addSystem(ParticleSpawningSystem());
  world.addSystem(ParticleLifecycleSystem());
  world.addSystem(PhysicsSystem());
  world.addSystem(AttractionSystem());

  final attractor = Entity();
  attractor.add(PersistenceComponent('attractor_state'));
  attractor.add(PositionComponent(x: 200, y: 300, width: 20, height: 20));
  attractor.add(AttractorComponent(strength: 1.0));
  attractor.add(TagsComponent({'attractor'}));
  world.addEntity(attractor);

  final spawner = Entity();
  spawner.add(SpawnerLinkComponent(targetTag: 'attractor'));
  spawner.add(ParticleSpawnerComponent(spawnRate: 200));
  world.addEntity(spawner);

  final root = Entity();
  root.add(CustomWidgetComponent(widgetType: 'particle_canvas'));
  root.add(TagsComponent({'root'}));
  world.addEntity(root);

  return world;
}

void main() {
  registerCoreComponents();
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
          isolateInitializer: isolateInitializer,
        ),
      ),
    );
  }
}
