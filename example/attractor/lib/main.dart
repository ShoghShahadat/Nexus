import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'systems/meteor_collision_system.dart';

// --- NEW: Player control system ---
// --- جدید: سیستم کنترل بازیکن ---
class AttractorControlSystem extends System {
  final double moveSpeed = 250.0;

  @override
  bool matches(Entity entity) {
    return entity.get<TagsComponent>()?.hasTag('attractor') ?? false;
  }

  @override
  void update(Entity entity, double dt) {
    final keyboard = entity.get<KeyboardInputComponent>();
    final vel = entity.get<VelocityComponent>()!;
    final pos = entity.get<PositionComponent>()!;

    vel.x = 0;
    vel.y = 0;

    if (keyboard != null) {
      if (keyboard.keysDown.contains(LogicalKeyboardKey.arrowLeft.keyId) ||
          keyboard.keysDown.contains(LogicalKeyboardKey.keyA.keyId)) {
        vel.x = -moveSpeed;
      }
      if (keyboard.keysDown.contains(LogicalKeyboardKey.arrowRight.keyId) ||
          keyboard.keysDown.contains(LogicalKeyboardKey.keyD.keyId)) {
        vel.x = moveSpeed;
      }
      if (keyboard.keysDown.contains(LogicalKeyboardKey.arrowUp.keyId) ||
          keyboard.keysDown.contains(LogicalKeyboardKey.keyW.keyId)) {
        vel.y = -moveSpeed;
      }
      if (keyboard.keysDown.contains(LogicalKeyboardKey.arrowDown.keyId) ||
          keyboard.keysDown.contains(LogicalKeyboardKey.keyS.keyId)) {
        vel.y = moveSpeed;
      }
    }

    // Keep the attractor within screen bounds.
    // جاذب را در محدوده صفحه نگه می‌دارد.
    if ((pos.x < 10 && vel.x < 0) || (pos.x > 390 && vel.x > 0)) {
      vel.x = 0;
    }
    if ((pos.y < 10 && vel.y < 0) || (pos.y > 790 && vel.y > 0)) {
      vel.y = 0;
    }

    entity.add(vel);
  }
}

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
  world.addSystem(MeteorCollisionSystem());
  // --- MODIFIED: Replace PointerSystem with keyboard controls ---
  // --- اصلاح شده: جایگزینی PointerSystem با کنترل‌های کیبورد ---
  world.addSystem(AdvancedInputSystem());
  world.addSystem(AttractorControlSystem());
  world.addSystem(ParticleSpawningSystem());
  world.addSystem(ParticleLifecycleSystem());
  world.addSystem(PhysicsSystem());
  world.addSystem(AttractionSystem());

  final attractor = Entity();
  attractor.add(PersistenceComponent('attractor_state'));
  attractor.add(PositionComponent(x: 200, y: 600, width: 20, height: 20));
  attractor.add(AttractorComponent(strength: 1.0));
  attractor.add(TagsComponent({'attractor'}));
  attractor.add(HealthComponent(maxHealth: 100));
  // --- NEW: Add components for movement and keyboard input ---
  // --- جدید: افزودن کامپوننت‌ها برای حرکت و ورودی کیبورد ---
  attractor.add(VelocityComponent());
  attractor.add(InputFocusComponent());
  attractor.add(KeyboardInputComponent());
  world.addEntity(attractor);

  final spawner = Entity();
  spawner.add(SpawnerLinkComponent(targetTag: 'attractor'));
  spawner.add(ParticleSpawnerComponent(spawnRate: 200));
  world.addEntity(spawner);

  final root = Entity();
  root.add(CustomWidgetComponent(widgetType: 'particle_canvas'));
  root.add(TagsComponent({'root'}));
  root.add(BlackboardComponent({'score': 0}));
  world.addEntity(root);

  return world;
}

void main() {
  registerCoreComponents();
  ComponentFactoryRegistry.I
      .register('HealthComponent', (json) => HealthComponent.fromJson(json));
  ComponentFactoryRegistry.I.register('ExplodingParticleComponent',
      (json) => ExplodingParticleComponent.fromJson(json));
  ComponentFactoryRegistry.I.register('ComplexMovementComponent',
      (json) => ComplexMovementComponent.fromJson(json));
  ComponentFactoryRegistry.I
      .register('MeteorComponent', (json) => MeteorComponent.fromJson(json));
  ComponentFactoryRegistry.I.register(
      'MeteorTargetComponent', (json) => MeteorTargetComponent.fromJson(json));
  // --- NEW: Register input components ---
  // --- جدید: ثبت کامپوننت‌های ورودی ---
  ComponentFactoryRegistry.I.register(
      'InputFocusComponent', (json) => InputFocusComponent.fromJson(json));
  ComponentFactoryRegistry.I.register('KeyboardInputComponent',
      (json) => KeyboardInputComponent.fromJson(json));
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
          final rootId = controller.getAllIdsWithTag('root').firstOrNull;

          if (attractorId == null || rootId == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final health = controller.get<HealthComponent>(attractorId);
          final blackboard = controller.get<BlackboardComponent>(rootId);
          final score = blackboard?.get<num>('score') ?? 0;
          final currentHealth = health?.currentHealth ?? 0;
          final maxHealth = health?.maxHealth ?? 100;
          final bool isGameOver = currentHealth <= 0;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Score: $score',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: ParticlePainter(
                          particleIds: particleIds,
                          meteorIds: isGameOver ? [] : meteorIds,
                          attractorId: attractorId,
                          controller: controller,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    if (isGameOver)
                      const Center(
                        child: Text(
                          'GAME OVER',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(blurRadius: 10, color: Colors.black)
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: LinearProgressIndicator(
                  value: (currentHealth / maxHealth).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade700,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                  minHeight: 10,
                ),
              ),
            ],
          );
        },
      },
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1a1a1a),
        appBar: AppBar(
          title: const Text('Nexus Attractor: Survival'),
          backgroundColor: Colors.grey.shade900,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: NexusWidget(
              worldProvider: provideAttractorWorld,
              renderingSystem: renderingSystem,
              isolateInitializer: isolateInitializer,
            ),
          ),
        ),
      ),
    );
  }
}
