import 'dart:math';
import 'dart:typed_data';
import 'package:nexus/nexus.dart';
import 'package:collection/collection.dart';
import 'package:nexus/src/core/utils/frequency.dart';
import '../components/health_orb_component.dart';
import '../components/meteor_component.dart';
import '../systems/game_systems.dart';
import '../systems/health_orb_system.dart';
import '../systems/healing_system.dart';
import '../systems/meteor_burn_system.dart';
import '../systems/attractor_gpu_system.dart';
import '../systems/gpu_bridge_system.dart';
import '../components/gpu_particle_render_component.dart';

// --- Prefab for Health Orbs ---
Entity createHealthOrbPrefab(NexusWorld world) {
  final orb = Entity();
  final random = Random();

  final screenInfo = world.rootEntity.get<ScreenInfoComponent>();
  final screenWidth = screenInfo?.width ?? 400.0;
  final screenHeight = screenInfo?.height ?? 800.0;

  final x = random.nextDouble() * (screenWidth - 40) + 20;
  final y = random.nextDouble() * (screenHeight - 40) + 20;

  orb.addComponents([
    PositionComponent(x: x, y: y, width: 12, height: 12),
    HealthOrbComponent(),
    TagsComponent({'health_orb'}),
    HealthComponent(maxHealth: 100),
    CollisionComponent(
        tag: 'health_orb', radius: 6, collidesWith: {'attractor'})
  ]);

  return orb;
}

/// Creates a prefab for a meteor entity.
Entity createMeteorPrefab(NexusWorld world) {
  final meteor = Entity();
  final random = Random();

  final root = world.rootEntity;
  final gameTime =
      root.get<BlackboardComponent>()?.get<double>('game_time') ?? 0.0;

  final screenInfo = root.get<ScreenInfoComponent>();
  final screenWidth = screenInfo?.width ?? 400.0;
  final screenHeight = screenInfo?.height ?? 800.0;

  final size = (25 + (gameTime / 60.0) * 25).clamp(25.0, 50.0);
  final speed = ((150 + (gameTime / 60.0) * 250).clamp(150.0, 400.0)) * 5;

  final startEdge = random.nextInt(4);
  double startX, startY;
  switch (startEdge) {
    case 0:
      startX = random.nextDouble() * screenWidth;
      startY = -50.0;
      break;
    case 1:
      startX = screenWidth + 50.0;
      startY = random.nextDouble() * screenHeight;
      break;
    case 2:
      startX = random.nextDouble() * screenWidth;
      startY = screenHeight + 50.0;
      break;
    default:
      startX = -50.0;
      startY = random.nextDouble() * screenHeight;
      break;
  }

  meteor.addComponents([
    PositionComponent(x: startX, y: startY, width: size, height: size),
    CollisionComponent(
        tag: 'meteor', radius: size / 2, collidesWith: {'attractor'}),
    MeteorComponent(),
    TagsComponent({'meteor'}),
    HealthComponent(maxHealth: 20),
    VelocityComponent(y: speed * 0.5),
    DamageComponent(25)
  ]);

  final attractor = world.entities.values
      .firstWhereOrNull((e) => e.has<AttractorComponent>());
  if (attractor != null) {
    meteor.add(TargetingComponent(targetId: attractor.id, turnSpeed: 2.0));
  }
  return meteor;
}

/// Provides the fully configured NexusWorld for the attractor game.
NexusWorld provideAttractorWorld() {
  final world = NexusWorld();

  world.addSystems([
    // --- NEW: GPU Systems ---
    AttractorGpuSystem(), // The new powerhouse for particle simulation
    GpuBridgeSystem(), // Manages communication between CPU and GPU

    // --- Core Systems (Still running on CPU) ---
    AnimationSystem(),
    AdvancedInputSystem(),
    PhysicsSystem(), // Still needed for meteors and the attractor
    ResponsivenessSystem(),

    // --- Gameplay Systems (Still running on CPU) ---
    SpawnerSystem(),
    TargetingSystem(),
    CollisionSystem(),
    DamageSystem(),
    MeteorBurnSystem(),
    AttractorControlSystem(),
    GameOverSystem(),
    RestartSystem(),
    GameProgressionSystem(),
    HealthOrbSystem(),
    HealingSystem(),
  ]);

  // --- Entities ---
  final attractor = Entity();
  attractor.addComponents([
    PersistenceComponent('attractor_state'),
    PositionComponent(width: 20, height: 20),
    AttractorComponent(strength: 1.0),
    TagsComponent({'attractor'}),
    HealthComponent(maxHealth: 100),
    DamageComponent(1000),
    VelocityComponent(),
    InputFocusComponent(),
    KeyboardInputComponent(),
    CollisionComponent(
        tag: 'attractor', radius: 20, collidesWith: {'meteor', 'health_orb'})
  ]);
  world.addEntity(attractor);

  // The particle spawner is no longer needed, as the GpuSystem initializes all particles at once.

  world.createSpawner(
    tag: 'meteor_spawner',
    prefab: () => createMeteorPrefab(world),
    frequency: const Frequency.perSecond(0.8),
  );

  world.createSpawner(
    tag: 'health_orb_spawner',
    prefab: () => createHealthOrbPrefab(world),
    frequency: Frequency.every(const Duration(seconds: 1)),
    condition: () {
      final isGameOver = world.rootEntity
              .get<BlackboardComponent>()
              ?.get<bool>('is_game_over') ??
          false;
      return !isGameOver;
    },
  );

  world.rootEntity.addComponents([
    CustomWidgetComponent(widgetType: 'particle_canvas'),
    BlackboardComponent({'score': 0, 'is_game_over': false, 'game_time': 0.0}),
    // Add the render component to the root entity to hold the GPU results
    GpuParticleRenderComponent(Float32List(0)),
    // Add the uniforms component for the GPU system
    GpuUniformsComponent(),
  ]);

  return world;
}
