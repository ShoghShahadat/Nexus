import 'dart:math';
import 'package:nexus/nexus.dart';
import 'package:collection/collection.dart';
import '../components/complex_movement_component.dart';
import '../components/meteor_component.dart';
import '../components/meteor_target_component.dart';
import '../systems/complex_movement_system.dart';
import '../systems/explosion_system.dart';
import '../systems/game_systems.dart';
import '../systems/meteor_burn_system.dart';
import '../systems/meteor_collision_system.dart';
import '../systems/meteor_spawner_system.dart';
import '../systems/meteor_targeting_system.dart';

/// Creates a prefab for a meteor entity with dynamic size.
/// یک prefab برای موجودیت شهاب‌سنگ با اندازه پویا ایجاد می‌کند.
Entity createMeteorPrefab(NexusWorld world) {
  final meteor = Entity();
  final random = Random();

  final root = world.entities.values
      .firstWhereOrNull((e) => e.get<TagsComponent>()?.hasTag('root') ?? false);
  final gameTime =
      root?.get<BlackboardComponent>()?.get<double>('game_time') ?? 0.0;

  // --- NEW: Calculate size based on game time ---
  // --- جدید: محاسبه اندازه بر اساس زمان بازی ---
  // Size starts at 25 and increases to a max of 50 over 60 seconds
  // اندازه از ۲۵ شروع شده و در طول ۶۰ ثانیه به حداکثر ۵۰ می‌رسد
  final size = (25 + (gameTime / 60.0) * 25).clamp(25.0, 50.0);

  // Note: These screen dimensions are now only for initial placement.
  const screenWidth = 400.0;
  const screenHeight = 800.0;
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
  meteor
      .add(PositionComponent(x: startX, y: startY, width: size, height: size));
  meteor.add(CollisionComponent(
      tag: 'meteor', radius: size / 2, collidesWith: {'attractor'}));
  meteor.add(MeteorComponent());
  meteor.add(TagsComponent({'meteor'}));
  final attractor = world.entities.values
      .firstWhereOrNull((e) => e.has<AttractorComponent>());
  if (attractor != null) {
    meteor.add(TargetingComponent(targetId: attractor.id));
  }
  return meteor;
}

/// Provides the fully configured NexusWorld for the attractor game.
NexusWorld provideAttractorWorld() {
  final world = NexusWorld();

  // Core Systems
  world.addSystem(AnimationSystem());
  world.addSystem(PersistenceSystem());
  world.addSystem(AdvancedInputSystem());
  world.addSystem(PhysicsSystem());
  world.addSystem(AttractionSystem());

  // Particle Systems
  world.addSystem(ParticleSpawningSystem());
  world.addSystem(ParticleLifecycleSystem());
  world.addSystem(ComplexMovementSystem());
  world.addSystem(ExplosionSystem());

  // Gameplay Systems
  world.addSystem(MeteorSpawnerSystem());
  world.addSystem(MeteorTargetingSystem());
  world.addSystem(MeteorBurnSystem());
  world.addSystem(MeteorCollisionSystem());
  world.addSystem(AttractorControlSystem());
  world.addSystem(GameOverSystem());
  world.addSystem(RestartSystem());
  // --- NEW: Add the progression system ---
  // --- جدید: افزودن سیستم پیشرفت بازی ---
  world.addSystem(GameProgressionSystem());

  // --- Entities ---
  final attractor = Entity();
  attractor.add(PersistenceComponent('attractor_state'));
  attractor.add(PositionComponent(x: 200, y: 600, width: 20, height: 20));
  attractor.add(AttractorComponent(strength: 1.0));
  attractor.add(TagsComponent({'attractor'}));
  attractor.add(HealthComponent(maxHealth: 100));
  attractor.add(VelocityComponent());
  attractor.add(InputFocusComponent());
  attractor.add(KeyboardInputComponent());
  world.addEntity(attractor);

  final particleSpawner = Entity();
  particleSpawner.add(SpawnerLinkComponent(targetTag: 'attractor'));
  particleSpawner.add(ParticleSpawnerComponent(spawnRate: 200));
  world.addEntity(particleSpawner);

  final meteorSpawner = Entity();
  meteorSpawner.add(TagsComponent({'meteor_spawner'}));
  meteorSpawner.add(SpawnerComponent(
    prefab: () => createMeteorPrefab(world),
    fireRate: 0.8,
    wantsToFire: true,
  ));
  world.addEntity(meteorSpawner);

  final root = Entity();
  root.add(CustomWidgetComponent(widgetType: 'particle_canvas'));
  root.add(TagsComponent({'root'}));
  // --- NEW: Add game_time to the blackboard ---
  // --- جدید: افزودن game_time به تخته سیاه ---
  root.add(BlackboardComponent(
      {'score': 0, 'is_game_over': false, 'game_time': 0.0}));
  world.addEntity(root);

  return world;
}
