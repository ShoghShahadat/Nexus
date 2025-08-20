import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nexus/nexus.dart';

// A simple painter to render our game entities as circles.
// یک نقاش ساده برای رندر کردن موجودیت‌های بازی به شکل دایره.
class GamePainter extends CustomPainter {
  final FlutterRenderingSystem controller;

  GamePainter({required this.controller});

  @override
  void paint(Canvas canvas, Size size) {
    final playerPaint = Paint()..color = Colors.blue;
    final enemyPaint = Paint()..color = Colors.red;
    final bulletPaint = Paint()..color = Colors.yellow;

    // Draw all entities based on their tags.
    // تمام موجودیت‌ها را بر اساس تگ‌هایشان رسم می‌کند.
    for (final entityId in controller.getAllIdsWithTag('player')) {
      final pos = controller.get<PositionComponent>(entityId);
      if (pos != null) {
        canvas.drawCircle(Offset(pos.x, pos.y), 15, playerPaint);
      }
    }
    for (final entityId in controller.getAllIdsWithTag('enemy')) {
      final pos = controller.get<PositionComponent>(entityId);
      if (pos != null) {
        canvas.drawCircle(Offset(pos.x, pos.y), 12, enemyPaint);
      }
    }
    for (final entityId in controller.getAllIdsWithTag('bullet')) {
      final pos = controller.get<PositionComponent>(entityId);
      if (pos != null) {
        canvas.drawCircle(Offset(pos.x, pos.y), 4, bulletPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// A simple system to control the player's spaceship.
// یک سیستم ساده برای کنترل سفینه بازیکن.
class PlayerControlSystem extends System {
  final double moveSpeed = 200.0;

  @override
  bool matches(Entity entity) {
    return entity.has<TagsComponent>() &&
        entity.get<TagsComponent>()!.hasTag('player');
  }

  @override
  void update(Entity entity, double dt) {
    final keyboard = entity.get<KeyboardInputComponent>();
    final vel = entity.get<VelocityComponent>()!;

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

      final spawner = entity.get<SpawnerComponent>()!;
      if (keyboard.keysDown.contains(LogicalKeyboardKey.space.keyId)) {
        spawner.wantsToFire = true;
      } else {
        spawner.wantsToFire = false;
      }
      entity.add(spawner);
    }

    entity.add(vel);
  }
}

// A system to make enemies spawn and move downwards.
// سیستمی برای تولید دشمنان و حرکت آن‌ها به سمت پایین.
class EnemyAISystem extends System {
  @override
  bool matches(Entity entity) {
    return entity.has<TagsComponent>() &&
        entity.get<TagsComponent>()!.hasTag('enemy');
  }

  @override
  void update(Entity entity, double dt) {
    final pos = entity.get<PositionComponent>()!;
    // Remove enemies that go off-screen.
    // دشمنانی که از صفحه خارج می‌شوند را حذف می‌کند.
    if (pos.y > 850) {
      world.removeEntity(entity.id);
    }
  }
}

/// The main entry point for our game world.
/// نقطه ورود اصلی برای دنیای بازی ما.
NexusWorld provideSpaceShooterWorld() {
  final world = NexusWorld();

  // Add all the systems we've built.
  // تمام سیستم‌هایی که ساخته‌ایم را اضافه می‌کند.
  world.addSystem(PhysicsSystem());
  world.addSystem(AdvancedInputSystem());
  world.addSystem(SpawnerSystem());
  world.addSystem(CollisionSystem());
  world.addSystem(DamageSystem());
  world.addSystem(PlayerControlSystem());
  world.addSystem(EnemyAISystem());

  // --- Prefabs ---
  // A function that creates a bullet entity.
  // تابعی که یک موجودیت تیر ایجاد می‌کند.
  Entity createBulletPrefab() {
    final bullet = Entity();
    bullet.add(TagsComponent({'bullet'}));
    bullet.add(VelocityComponent(y: -400)); // Moves upwards
    bullet.add(
        CollisionComponent(tag: 'bullet', radius: 4, collidesWith: {'enemy'}));
    bullet.add(DamageComponent(10));
    // Bullets will be positioned by the SpawnerSystem.
    // موقعیت تیرها توسط SpawnerSystem تعیین خواهد شد.
    return bullet;
  }

  // A function that creates an enemy entity.
  // تابعی که یک موجودیت دشمن ایجاد می‌کند.
  Entity createEnemyPrefab() {
    final random = Random();
    final enemy = Entity();
    enemy.add(TagsComponent({'enemy'}));
    enemy.add(PositionComponent(x: random.nextDouble() * 400, y: -20));
    enemy.add(VelocityComponent(y: 100)); // Moves downwards
    enemy.add(CollisionComponent(
        tag: 'enemy', radius: 12, collidesWith: {'bullet', 'player'}));
    enemy.add(HealthComponent(maxHealth: 20));
    enemy.add(DamageComponent(25));
    return enemy;
  }

  // --- Game Entities ---
  // Create the player entity.
  // موجودیت بازیکن را ایجاد می‌کند.
  final player = Entity();
  player.add(TagsComponent({'player'}));
  player.add(PositionComponent(x: 200, y: 700));
  player.add(VelocityComponent());
  player.add(InputFocusComponent()); // This entity will receive keyboard input.
  player.add(KeyboardInputComponent());
  player.add(
      CollisionComponent(tag: 'player', radius: 15, collidesWith: {'enemy'}));
  player.add(HealthComponent(maxHealth: 100));
  player.add(SpawnerComponent(
    prefab: createBulletPrefab,
    fireRate: 5, // 5 shots per second
  ));
  world.addEntity(player);

  // Create an entity that spawns enemies periodically.
  // موجودیتی ایجاد می‌کند که به صورت دوره‌ای دشمن تولید می‌کند.
  final enemySpawner = Entity();
  enemySpawner.add(SpawnerComponent(
    prefab: createEnemyPrefab,
    fireRate: 0.8, // Spawns an enemy every 1.25 seconds
    wantsToFire: true, // Continuously spawns
  ));
  // This spawner is off-screen and doesn't need a position.
  // این spawner خارج از صفحه است و نیازی به موقعیت ندارد.
  world.addEntity(enemySpawner);

  // The root entity for rendering.
  // موجودیت ریشه برای رندرینگ.
  final root = Entity();
  root.add(CustomWidgetComponent(widgetType: 'game_canvas'));
  root.add(TagsComponent({'root'}));
  world.addEntity(root);

  return world;
}

void main() {
  // Register all serializable components that our game uses.
  // تمام کامپوننت‌های سریالایزبل که بازی ما استفاده می‌کند را ثبت می‌کند.
  registerCoreComponents();
  ComponentFactoryRegistry.I.register(
      'TargetingComponent', (json) => TargetingComponent.fromJson(json));
  ComponentFactoryRegistry.I.register(
      'CollisionComponent', (json) => CollisionComponent.fromJson(json));
  ComponentFactoryRegistry.I
      .register('HealthComponent', (json) => HealthComponent.fromJson(json));
  ComponentFactoryRegistry.I
      .register('DamageComponent', (json) => DamageComponent.fromJson(json));
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
        'game_canvas': (context, id, controller, manager, child) {
          // The CustomPaint widget will do all the rendering for us.
          // ویجت CustomPaint تمام رندرینگ را برای ما انجام خواهد داد.
          return RepaintBoundary(
            child: CustomPaint(
              painter: GamePainter(controller: controller),
              child: const SizedBox.expand(),
            ),
          );
        },
      },
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Nexus Space Shooter'),
          backgroundColor: Colors.grey.shade900,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: AspectRatio(
            aspectRatio: 9 / 16, // Typical mobile aspect ratio
            child: NexusWidget(
              worldProvider: provideSpaceShooterWorld,
              renderingSystem: renderingSystem,
            ),
          ),
        ),
      ),
    );
  }
}
