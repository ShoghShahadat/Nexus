import 'dart:math';
import 'package:nexus/nexus.dart';
import '../component_registration.dart';
import '../components/health_orb_component.dart';
import '../components/meteor_component.dart';
import '../components/network_components.dart';
import '../network/mock_server.dart';
import '../systems/debug_system.dart';
import '../systems/health_orb_system.dart';
import '../systems/healing_system.dart';
import '../systems/meteor_burn_system.dart';
import '../systems/network_system.dart';
import '../systems/player_control_system.dart';
import '../systems/server_systems.dart';

Entity createHealthOrbPrefab(NexusWorld world) {
  final orb = Entity();
  final random = Random();
  final screenInfo = world.rootEntity.get<ScreenInfoComponent>();
  final screenWidth = screenInfo?.width ?? 800.0;
  final screenHeight = screenInfo?.height ?? 600.0;
  final x = random.nextDouble() * (screenWidth - 40) + 20;
  final y = random.nextDouble() * (screenHeight - 40) + 20;
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

Entity createMeteorPrefab(NexusWorld world) {
  final meteor = Entity();
  final random = Random();
  final root = world.rootEntity;
  final gameTime =
      root.get<BlackboardComponent>()?.get<double>('game_time') ?? 0.0;
  final size = (25 + (gameTime / 30.0) * 25).clamp(25.0, 50.0);

  // --- FIX: Meteor speed is now 5x player speed ---
  final speed = MockServer.playerMoveSpeed * 5;

  final startEdge = random.nextInt(4);
  double startX, startY;
  final screenInfo = root.get<ScreenInfoComponent>();
  final screenWidth = screenInfo?.width ?? 800.0;
  final screenHeight = screenInfo?.height ?? 600.0;
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
    // --- FIX: Meteors now collide with each other ---
    CollisionComponent(
        tag: 'meteor', radius: size / 2, collidesWith: {'player', 'meteor'}),
    MeteorComponent(),
    TagsComponent({'meteor'}),
    HealthComponent(maxHealth: 20),
    VelocityComponent(),
    DamageComponent(25),
    LifecyclePolicyComponent(
      destructionCondition: (e) {
        final pos = e.get<PositionComponent>();
        if (pos == null) return true;
        return pos.y >
            (world.rootEntity.get<ScreenInfoComponent>()?.height ?? 600) + 100;
      },
    ),
  ]);

  final players =
      world.entities.values.where((e) => e.has<PlayerComponent>()).toList();
  if (players.isNotEmpty) {
    final targetPlayer = players[random.nextInt(players.length)];
    final targetPos = targetPlayer.get<PositionComponent>();
    if (targetPos != null) {
      meteor.add(TargetingComponent(targetId: targetPlayer.id, turnSpeed: 1.0));
      final vel = meteor.get<VelocityComponent>()!;
      final pos = meteor.get<PositionComponent>()!;
      final angle = atan2(targetPos.y - pos.y, targetPos.x - pos.x);
      vel.x = cos(angle) * speed;
      vel.y = sin(angle) * speed;
      meteor.add(vel);
    }
  }
  return meteor;
}

// --- SERVER WORLD PROVIDER ---

NexusWorld provideServerWorld() {
  registerCoreComponents();
  registerAllComponents();

  final world = NexusWorld();
  world.addSystems([
    GarbageCollectorSystem(),
    PhysicsSystem(),
    SpawnerSystem(),
    TargetingSystem(),
    CollisionSystem(),
    DamageSystem(),
    MeteorBurnSystem(),
    HealthOrbSystem(),
    HealingSystem(),
    ServerGameLogicSystem(),
  ]);

  world.rootEntity.addComponents([
    ScreenInfoComponent(
        width: 800, height: 600, orientation: ScreenOrientation.landscape),
    BlackboardComponent({'score': 0, 'is_game_over': false, 'game_time': 0.0}),
  ]);

  world.addEntity(Entity()
    ..add(TagsComponent({'meteor_spawner'}))
    ..add(LifecyclePolicyComponent(isPersistent: true))
    ..add(PositionComponent())
    ..add(SpawnerComponent(
        prefab: () => createMeteorPrefab(world),
        frequency: const Frequency.perSecond(2.0),
        wantsToFire: true)));

  world.addEntity(Entity()
    ..add(TagsComponent({'health_orb_spawner'}))
    ..add(LifecyclePolicyComponent(isPersistent: true))
    ..add(PositionComponent())
    ..add(SpawnerComponent(
        prefab: () => createHealthOrbPrefab(world),
        frequency: Frequency.every(const Duration(seconds: 15)),
        wantsToFire: true)));

  return world;
}

// --- CLIENT WORLD PROVIDER ---

NexusWorld provideAttractorWorld() {
  registerCoreComponents();
  registerAllComponents();

  final world = NexusWorld();
  final serializer = BinaryWorldSerializer(BinaryComponentFactory.I);

  final server = MockServer(provideServerWorld, serializer);
  world.services.registerSingleton<MockServer>(server);

  world.addSystems([
    ResponsivenessSystem(),
    DebugSystem(),
    NetworkSystem(serializer),
    PlayerControlSystem(),
  ]);

  world.rootEntity.addComponents([
    CustomWidgetComponent(widgetType: 'particle_canvas'),
    BlackboardComponent({'score': 0, 'local_player_id': null}),
    NetworkStateComponent(),
  ]);

  return world;
}
