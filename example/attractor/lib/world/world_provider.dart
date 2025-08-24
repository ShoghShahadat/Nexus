// ==============================================================================
// File: lib/world/world_provider.dart
// Author: Your Intelligent Assistant
// Version: 5.0
// Description: Provides the fully configured NexusWorld for the attractor game.
// Changes:
// - DYNAMIC DIFFICULTY: Re-implemented the original logic in 'createMeteorPrefab'.
//   Meteors now spawn from random screen edges with speed and size that
//   increase over game time, restoring the progressive challenge.
// ==============================================================================

import 'dart:math';
import 'package:attractor_example/components/server_logic_components.dart';
import 'package:attractor_example/systems/client_targeting_system.dart';
import 'package:attractor_example/systems/game_logic_systems.dart';
import 'package:nexus/nexus.dart' hide SpawnerComponent, LifecycleComponent;
import '../component_registration.dart';
import '../components/attractor_component.dart' hide AttractorComponent;
import '../components/camera_component.dart';
import '../components/health_orb_component.dart';
import '../components/meteor_component.dart';
import '../components/network_components.dart';
import '../components/particle_render_data_component.dart';
import '../components/score_component.dart';
import '../systems/attractor_system.dart';
import '../systems/debug_system.dart';
import '../systems/game_state_systems.dart';
import '../systems/healing_system.dart';
import '../systems/health_orb_system.dart';
import '../systems/interpolation_system.dart';
import '../systems/meteor_burn_system.dart';
import '../systems/network_system.dart';
import '../systems/player_control_system.dart';
import '../systems/player_spawning_system.dart';
import '../systems/reconciliation_system.dart';

Entity createMeteorPrefab(NexusWorld world) {
  final meteor = Entity();
  final random = Random();
  final screenInfo = world.rootEntity.get<ScreenInfoComponent>()!;
  final player =
      world.entities.values.firstWhere((e) => e.has<PlayerComponent>());

  // --- DYNAMIC DIFFICULTY LOGIC RESTORED ---
  final gameTime =
      world.rootEntity.get<BlackboardComponent>()?.get<double>('game_time') ??
          0.0;
  final size = (25 + (gameTime / 60.0) * 25).clamp(25.0, 50.0);
  final speed = (150 + (gameTime / 60.0) * 250).clamp(150.0, 400.0);

  final startEdge = random.nextInt(4);
  double startX, startY;

  switch (startEdge) {
    case 0: // Top
      startX = random.nextDouble() * screenInfo.width;
      startY = -50.0;
      break;
    case 1: // Right
      startX = screenInfo.width + 50.0;
      startY = random.nextDouble() * screenInfo.height;
      break;
    case 2: // Bottom
      startX = random.nextDouble() * screenInfo.width;
      startY = screenInfo.height + 50.0;
      break;
    default: // Left
      startX = -50.0;
      startY = random.nextDouble() * screenInfo.height;
      break;
  }
  // --- END OF DYNAMIC DIFFICULTY LOGIC ---

  meteor.addComponents([
    PositionComponent(x: startX, y: startY, width: size, height: size),
    CollisionComponent(
        tag: 'meteor', radius: size / 2, collidesWith: {'player', 'meteor'}),
    MeteorComponent(),
    TagsComponent({'meteor'}),
    HealthComponent(maxHealth: 20),
    VelocityComponent(), // Velocity will be set by TargetingSystem
    DamageComponent(25),
    TargetingComponent(targetId: player.id, turnSpeed: 2.0),
    LifecyclePolicyComponent(
      destructionCondition: (e) {
        final pos = e.get<PositionComponent>()!;
        return pos.y > screenInfo.height + 100 ||
            pos.y < -100 ||
            pos.x > screenInfo.width + 100 ||
            pos.x < -100;
      },
    ),
    // Add lifecycle to handle aging and speed increase
    LifecycleComponent(
        maxAge: 15.0, // Give meteors a 15-second lifespan
        initialSpeed: speed,
        initialWidth: size,
        initialHeight: size),
  ]);
  return meteor;
}

Entity createHealthOrbPrefab(NexusWorld world) {
  final orb = Entity();
  final random = Random();
  final screenInfo = world.rootEntity.get<ScreenInfoComponent>()!;
  final x = random.nextDouble() * (screenInfo.width - 40) + 20;
  final y = random.nextDouble() * (screenInfo.height - 40) + 20;
  orb.addComponents([
    PositionComponent(x: x, y: y, width: 12, height: 12),
    HealthOrbComponent(),
    TagsComponent({'health_orb'}),
    HealthComponent(maxHealth: 100),
    CollisionComponent(tag: 'health_orb', radius: 6, collidesWith: {'player'}),
    LifecyclePolicyComponent(
      destructionCondition: (e) =>
          (e.get<HealthComponent>()?.currentHealth ?? 0) <= 0,
    ),
  ]);
  return orb;
}

NexusWorld provideAttractorWorld() {
  registerCoreComponents();
  registerAllComponents();

  final world = NexusWorld();
  final serializer = BinaryWorldSerializer(BinaryComponentFactory.I);
  const serverUrl = 'ws://n8n.youapi.ir';

  world.addSystems([
    // Core & UI
    ResponsivenessSystem(),
    DebugSystem(),
    InterpolationSystem(),
    ReconciliationSystem(),

    // Player Control & Spawning
    PlayerSpawningSystem(),
    PlayerControlSystem(),

    // --- GAMEPLAY SYSTEMS ---
    AttractorSystem(),
    ClientTargetingSystem(),
    MeteorBurnSystem(),
    HealthOrbSystem(),
    HealingSystem(),
    ClientSpawnerSystem(),
    GameRulesSystem(),
    MeteorLifecycleSystem(),
    DynamicDifficultySystem(),

    // Game State
    GameProgressionSystem(),
    GameOverSystem(),
    RestartSystem(),

    // Core Physics & Networking
    PhysicsSystem(),
    CollisionSystem(),
    DamageSystem(),
    NetworkSystem(serializer, serverUrl: serverUrl),
  ]);

  // Player Entity (Attractor)
  final player = Entity()
    ..add(OwnedComponent())
    ..add(ControlledPlayerComponent())
    ..add(CameraComponent())
    ..add(PlayerComponent(sessionId: 'local', isLocalPlayer: true))
    ..add(AttractorComponent(strength: 1.0))
    ..add(TagsComponent({'player'}))
    ..add(PositionComponent(x: 0, y: 0, width: 20, height: 20))
    ..add(VelocityComponent())
    ..add(HealthComponent(maxHealth: 100))
    ..add(ScoreComponent(score: 0))
    ..add(LifecyclePolicyComponent(isPersistent: true));
  world.addEntity(player);

  // Spawner Entities
  world.addEntity(Entity()
    ..add(TagsComponent({'meteor_spawner'}))
    ..add(SpawnerComponent(
      prefab: () => createMeteorPrefab(world),
      frequency: 1.5,
    ))
    ..add(LifecyclePolicyComponent(isPersistent: true)));

  world.addEntity(Entity()
    ..add(TagsComponent({'health_orb_spawner'}))
    ..add(SpawnerComponent(
      prefab: () => createHealthOrbPrefab(world),
      frequency: 0.1,
    ))
    ..add(LifecyclePolicyComponent(isPersistent: true)));

  // Root Entity
  world.rootEntity.addComponents([
    CustomWidgetComponent(widgetType: 'particle_canvas'),
    BlackboardComponent(
        {'local_player_id': player.id, 'game_time': 0.0}), // Add game_time
    NetworkStateComponent(),
    TagsComponent({'root'}),
    ParticleRenderDataComponent([]),
  ]);

  return world;
}
