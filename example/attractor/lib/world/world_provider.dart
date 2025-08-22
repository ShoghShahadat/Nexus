import 'dart:math';
import 'dart:typed_data';
import 'package:nexus/nexus.dart';
import 'package:collection/collection.dart';
import 'package:nexus/src/core/utils/frequency.dart';
import '../components/debug_info_component.dart';
import '../components/health_orb_component.dart';
import '../components/meteor_component.dart';
import '../systems/debug_system.dart';
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
        tag: 'health_orb', radius: 6, collidesWith: {'attractor'}),
    LifecyclePolicyComponent(
      destructionCondition: (e) => e.get<HealthComponent>()!.currentHealth <= 0,
    ),
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

/// Provides the fully configured NexusWorld for the attractor game.
NexusWorld provideAttractorWorld() {
  final world = NexusWorld();

  world.addSystems([
    GarbageCollectorSystem(),
    AnimationSystem(),
    AdvancedInputSystem(),
    PhysicsSystem(),
    ResponsivenessSystem(),
    ParticleLifecycleSystem(),

    AttractorGpuSystem(), // This now spawns 500 particles by default
    GpuBridgeSystem(),
    DebugSystem(),

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
        tag: 'attractor', radius: 20, collidesWith: {'meteor', 'health_orb'}),
    LifecyclePolicyComponent(isPersistent: true),
  ]);
  world.addEntity(attractor);

  final meteorSpawner = Entity();
  meteorSpawner.addComponents([
    TagsComponent({'meteor_spawner'}),
    PositionComponent(),
    SpawnerComponent(
      prefab: () => createMeteorPrefab(world),
      frequency: const Frequency.perSecond(0.8),
      wantsToFire: true,
      // --- CONFIGURATION FIX: Add condition to limit max meteors ---
      // This function will only allow a new meteor to spawn if the
      // current count is less than 10.
      // --- اصلاح پیکربندی: افزودن شرط برای محدود کردن حداکثر شهاب‌سنگ‌ها ---
      // این تابع فقط زمانی اجازه تولید شهاب‌سنگ جدید را می‌دهد که
      // تعداد فعلی کمتر از ۱۰ باشد.
      condition: () {
        final meteorCount = world.entities.values
            .where((e) => e.get<TagsComponent>()?.hasTag('meteor') ?? false)
            .length;
        return meteorCount < 10;
      },
    ),
    LifecyclePolicyComponent(isPersistent: true),
  ]);
  world.addEntity(meteorSpawner);

  final healthOrbSpawner = Entity();
  healthOrbSpawner.addComponents([
    TagsComponent({'health_orb_spawner'}),
    PositionComponent(),
    SpawnerComponent(
      prefab: () => createHealthOrbPrefab(world),
      frequency: Frequency.every(const Duration(seconds: 10)),
      wantsToFire: true,
      condition: () {
        final isGameOver = world.rootEntity
                .get<BlackboardComponent>()
                ?.get<bool>('is_game_over') ??
            false;
        return !isGameOver;
      },
    ),
    LifecyclePolicyComponent(isPersistent: true),
  ]);
  world.addEntity(healthOrbSpawner);

  world.rootEntity.addComponents([
    CustomWidgetComponent(widgetType: 'particle_canvas'),
    BlackboardComponent({'score': 0, 'is_game_over': false, 'game_time': 0.0}),
    GpuParticleRenderComponent(Float32List(0)),
    GpuUniformsComponent(),
    DebugInfoComponent(),
    GpuTimeComponent(0),
  ]);

  return world;
}
