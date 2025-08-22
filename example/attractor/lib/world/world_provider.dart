import 'dart:math';
import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/core/serialization/binary_component_factory.dart'; // <-- CRITICAL FIX: Added missing import
import 'package:nexus/src/core/serialization/binary_world_serializer.dart';
import '../components/debug_info_component.dart';
import '../components/health_orb_component.dart';
import '../components/meteor_component.dart';
import '../components/network_components.dart';
import '../components/particle_render_data_component.dart';
import '../network/mock_server.dart';
import '../systems/debug_system.dart';
import '../systems/health_orb_system.dart';
import '../systems/healing_system.dart';
import '../systems/meteor_burn_system.dart';
import '../systems/network_system.dart';
import '../systems/player_control_system.dart';

// Prefabs remain largely the same, as they define the components.
// The server will be responsible for creating these entities.

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
        tag: 'health_orb', radius: 6, collidesWith: {'attractor'}),
    LifecyclePolicyComponent(
      destructionCondition: (e) => e.get<HealthComponent>()!.currentHealth <= 0,
    ),
  ]);
  return orb;
}

Entity createMeteorPrefab(NexusWorld world) {
  final meteor = Entity();
  final random = Random();
  final root = world.rootEntity;
  final gameTime =
      root.get<BlackboardComponent>()?.get<double>('game_time') ?? 0.0;
  final size = (25 + (gameTime / 60.0) * 25).clamp(25.0, 50.0);
  final speed = ((150 + (gameTime / 60.0) * 250).clamp(150.0, 400.0)) * 5;
  final startEdge = random.nextInt(4);
  double startX, startY;
  final screenInfo = root.get<ScreenInfoComponent>();
  final screenWidth = screenInfo?.width ?? 400.0;
  final screenHeight = screenInfo?.height ?? 800.0;
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
    DamageComponent(25),
    LifecyclePolicyComponent(
      destructionCondition: (e) {
        final pos = e.get<PositionComponent>()!;
        final health = e.get<HealthComponent>()?.currentHealth ?? 1;
        final currentScreenInfo = world.rootEntity.get<ScreenInfoComponent>()!;
        final currentWidth = currentScreenInfo.width;
        final currentHeight = currentScreenInfo.height;
        return health <= 0 ||
            pos.y > currentHeight + 50 ||
            pos.y < -50 ||
            pos.x > currentWidth + 50 ||
            pos.x < -50;
      },
    ),
  ]);
  final attractor = world.entities.values
      .firstWhereOrNull((e) => e.has<AttractorComponent>());
  if (attractor != null) {
    meteor.add(TargetingComponent(targetId: attractor.id, turnSpeed: 2.0));
  }
  return meteor;
}

/// Provides the fully configured NexusWorld for the MULTIPLAYER attractor game.
NexusWorld provideAttractorWorld() {
  final world = NexusWorld();
  final serializer = BinaryWorldSerializer(BinaryComponentFactory.I);

  // --- Start the Mock Server ---
  // In a real app, this would not be here. The client would just connect.
  final server = MockServer(world, serializer);
  world.services.registerSingleton<MockServer>(server);

  // --- MODIFIED: Systems are now client-focused ---
  world.addSystems([
    // Core Systems
    GarbageCollectorSystem(),
    PhysicsSystem(),
    ResponsivenessSystem(),
    DebugSystem(),

    // Client-Side Gameplay Logic & Network
    NetworkSystem('ws://localhost:8080', serializer),
    PlayerControlSystem(),

    // These systems now run on the server, but we keep them on the client
    // for visual effects and predictions if needed. For this example,
    // they will mostly be dormant as the server is the source of truth.
    SpawnerSystem(),
    TargetingSystem(),
    CollisionSystem(),
    DamageSystem(),
    MeteorBurnSystem(),
    HealthOrbSystem(),
    HealingSystem(),
  ]);

  // The client no longer creates the player entity. The server will send it.
  // We create a "local player" marker entity.
  final localPlayer = Entity();
  localPlayer.add(ControlledPlayerComponent());
  world.addEntity(localPlayer);

  // --- MODIFIED: Root entity setup for multiplayer ---
  world.rootEntity.addComponents([
    CustomWidgetComponent(widgetType: 'particle_canvas'),
    BlackboardComponent({'score': 0, 'is_game_over': false, 'game_time': 0.0}),
    ParticleRenderDataComponent([]), // This will be unused for now
    DebugInfoComponent(),
    NetworkStateComponent(), // To display connection status
  ]);

  return world;
}
