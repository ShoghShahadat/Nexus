import 'dart:math';
import 'package:attractor_example/components/server_logic_components.dart'
    show OwnedComponent;
import 'package:nexus/nexus.dart';
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

Entity createMeteorPrefab(NexusWorld world) {
  final meteor = Entity();
  final random = Random();
  final screenInfo = world.rootEntity.get<ScreenInfoComponent>()!;
  final startX = random.nextDouble() * screenInfo.width;
  meteor.addComponents([
    PositionComponent(x: startX, y: -50, width: 25, height: 25),
    CollisionComponent(tag: 'meteor', radius: 12.5, collidesWith: {'player'}),
    MeteorComponent(),
    TagsComponent({'meteor'}),
    HealthComponent(maxHealth: 20),
    VelocityComponent(y: 150 + random.nextDouble() * 150),
    DamageComponent(25),
    LifecyclePolicyComponent(
      destructionCondition: (e) =>
          (e.get<PositionComponent>()?.y ?? 0) > screenInfo.height + 50,
    ),
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
    // Player Control & Spawning
    PlayerSpawningSystem(),
    PlayerControlSystem(),
    // --- RESTORED GAMEPLAY SYSTEMS ---
    AttractorSystem(),
    MeteorBurnSystem(),
    HealthOrbSystem(),
    HealingSystem(),
    SpawnerSystem(), // The generic system that runs spawners
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

  // --- RESTORED SPAWNER ENTITIES ---
  world.addEntity(Entity()
    ..add(TagsComponent({'meteor_spawner'}))
    ..add(SpawnerComponent(
      prefab: () => createMeteorPrefab(world),
      frequency: const Frequency.perSecond(1.5),
      wantsToFire: true,
    ))
    ..add(LifecyclePolicyComponent(isPersistent: true)));

  world.addEntity(Entity()
    ..add(TagsComponent({'health_orb_spawner'}))
    ..add(SpawnerComponent(
      prefab: () => createHealthOrbPrefab(world),
      frequency: Frequency.every(const Duration(seconds: 10)),
      wantsToFire: true,
    ))
    ..add(LifecyclePolicyComponent(isPersistent: true)));

  // Root Entity
  world.rootEntity.addComponents([
    CustomWidgetComponent(widgetType: 'particle_canvas'),
    BlackboardComponent({'local_player_id': player.id}),
    NetworkStateComponent(),
    TagsComponent({'root'}),
    ParticleRenderDataComponent([]),
  ]);

  return world;
}
