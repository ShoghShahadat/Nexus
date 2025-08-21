import 'package:flutter/services.dart';
import 'package:nexus/nexus.dart';
import 'package:collection/collection.dart';
import 'package:nexus/src/core/utils/frequency.dart';
import '../events.dart';
import '../world/world_provider.dart'; // For the prefab function

/// A system to control the attractor's movement via keyboard.
class AttractorControlSystem extends System {
  final double moveSpeed = 250.0;
  bool _initialPositionSet = false;

  @override
  bool matches(Entity entity) {
    return entity.get<TagsComponent>()?.hasTag('attractor') ?? false;
  }

  @override
  void update(Entity entity, double dt) {
    final root = world.entities.values.firstWhereOrNull(
        (e) => e.get<TagsComponent>()?.hasTag('root') ?? false);
    final screenInfo = root?.get<ScreenInfoComponent>();
    final screenWidth = screenInfo?.width ?? 400.0;
    final screenHeight = screenInfo?.height ?? 800.0;

    final pos = entity.get<PositionComponent>()!;

    if (!_initialPositionSet && screenInfo != null) {
      pos.x = screenWidth / 2;
      pos.y = screenHeight * 0.8;
      entity.add(pos);
      _initialPositionSet = true;
    }

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
    }

    final nextX = pos.x + vel.x * dt;
    final nextY = pos.y + vel.y * dt;

    const padding = 10.0;
    if ((nextX < padding && vel.x < 0) ||
        (nextX > screenWidth - padding && vel.x > 0)) {
      vel.x = 0;
    }
    if ((nextY < padding && vel.y < 0) ||
        (nextY > screenHeight - padding && vel.y > 0)) {
      vel.y = 0;
    }

    entity.add(vel);
  }
}

/// A system to manage the game over state.
class GameOverSystem extends System {
  @override
  bool matches(Entity entity) {
    return entity.get<TagsComponent>()?.hasTag('root') ?? false;
  }

  @override
  void update(Entity entity, double dt) {
    final blackboard = entity.get<BlackboardComponent>()!;
    final isGameOver = blackboard.get<bool>('is_game_over') ?? false;

    if (isGameOver) {
      double countdown = blackboard.get<double>('restart_countdown') ?? 5.0;
      if (countdown > 0) {
        countdown -= dt;
        blackboard.set('restart_countdown', countdown);
        entity.add(blackboard);
      }
      return;
    }

    final attractor = world.entities.values.firstWhereOrNull(
        (e) => e.get<TagsComponent>()?.hasTag('attractor') ?? false);
    if (attractor == null) return;

    final health = attractor.get<HealthComponent>();
    if (health != null && health.currentHealth <= 0) {
      blackboard.set('is_game_over', true);
      blackboard.set('restart_countdown', 5.0);
      entity.add(blackboard);

      attractor.remove<InputFocusComponent>();
      attractor.remove<KeyboardInputComponent>();
      attractor.add(VelocityComponent(x: 0, y: 0));

      final meteorSpawner = world.entities.values.firstWhereOrNull(
          (e) => e.get<TagsComponent>()?.hasTag('meteor_spawner') ?? false);
      meteorSpawner?.remove<SpawnerComponent>();
    }
  }
}

/// A system to handle the game restart logic.
class RestartSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    world.eventBus.on<RestartGameEvent>(_onRestart);
  }

  void _onRestart(RestartGameEvent event) {
    final attractor = world.entities.values.firstWhereOrNull(
        (e) => e.get<TagsComponent>()?.hasTag('attractor') ?? false);
    final root = world.entities.values.firstWhereOrNull(
        (e) => e.get<TagsComponent>()?.hasTag('root') ?? false);
    final meteorSpawner = world.entities.values.firstWhereOrNull(
        (e) => e.get<TagsComponent>()?.hasTag('meteor_spawner') ?? false);

    if (attractor != null) {
      attractor.add(HealthComponent(maxHealth: 100));
      attractor.add(InputFocusComponent());
      attractor.add(KeyboardInputComponent());
    }

    if (root != null) {
      root.add(BlackboardComponent(
          {'score': 0, 'is_game_over': false, 'game_time': 0.0}));
    }

    if (meteorSpawner != null && !meteorSpawner.has<SpawnerComponent>()) {
      meteorSpawner.add(SpawnerComponent(
        prefab: () => createMeteorPrefab(world),
        frequency: const Frequency.perSecond(0.8),
        wantsToFire: true,
      ));
    }
  }

  @override
  bool matches(Entity entity) => false; // Event-driven
  @override
  void update(Entity entity, double dt) {}
}

/// A system to manage game progression and difficulty.
class GameProgressionSystem extends System {
  @override
  bool matches(Entity entity) {
    return entity.get<TagsComponent>()?.hasTag('root') ?? false;
  }

  @override
  void update(Entity entity, double dt) {
    final blackboard = entity.get<BlackboardComponent>()!;
    if (blackboard.get<bool>('is_game_over') ?? false) return;

    final gameTime = (blackboard.get<double>('game_time') ?? 0.0) + dt;
    blackboard.set('game_time', gameTime);
    entity.add(blackboard);

    final meteorSpawner = world.entities.values.firstWhereOrNull(
        (e) => e.get<TagsComponent>()?.hasTag('meteor_spawner') ?? false);
    if (meteorSpawner != null) {
      final spawner = meteorSpawner.get<SpawnerComponent>();
      if (spawner != null) {
        // Starts at 0.8 and increases to a max of 4 per second over 60 seconds
        final newEventsPerSecond =
            (0.8 + (gameTime / 60.0) * 3.2).clamp(0.8, 4.0);
        // --- FIX: Update the Frequency object instead of the old fireRate ---
        spawner.frequency = Frequency.perSecond(newEventsPerSecond);
        meteorSpawner.add(spawner);
      }
    }
  }
}
