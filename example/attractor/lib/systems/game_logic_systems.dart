// ==============================================================================
// File: lib/systems/game_logic_systems.dart
// Author: Your Intelligent Assistant
// Version: 2.0
// Description: Contains all game logic systems for the client-authoritative model.
// Changes:
// - REFINED COLLISION LOGIC: The 'GameRulesSystem' has been updated. Instead
//   of directly removing entities on collision, it now sets their health to 0.
//   This allows other systems (like MeteorBurnSystem) to handle the
//   destruction effects, leading to a cleaner, more decoupled design.
// ==============================================================================

import 'dart:math';
import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart' hide SpawnerComponent, LifecycleComponent;
import '../components/network_components.dart';
import '../components/score_component.dart';
import '../components/server_logic_components.dart';
import 'player_control_system.dart';

/// Client-side system that handles entity spawning.
class ClientSpawnerSystem extends System {
  @override
  bool matches(Entity entity) {
    return entity.has<SpawnerComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final spawner = entity.get<SpawnerComponent>()!;
    if (spawner.cooldown > 0) {
      spawner.cooldown -= dt;
    }

    final playerCount =
        world.entities.values.where((e) => e.has<PlayerComponent>()).length;
    final meteorCount = world.entities.values
        .where((e) => e.get<TagsComponent>()?.hasTag('meteor') ?? false)
        .length;
    final maxMeteors = playerCount * 10; // Allow more meteors

    if (meteorCount >= maxMeteors || playerCount == 0) {
      return;
    }

    final bool conditionMet = spawner.condition?.call() ?? true;

    if (spawner.cooldown <= 0 && conditionMet) {
      final newEntity = spawner.prefab();
      if (newEntity.allComponents.isNotEmpty) {
        world.addEntity(newEntity);
      }

      if (spawner.frequency > 0) {
        spawner.cooldown = 1.0 / spawner.frequency;
      } else {
        spawner.cooldown = double.maxFinite;
      }
    }
  }
}

/// Client-side system that manages meteor lifecycle: aging, shrinking, and speed increase.
class MeteorLifecycleSystem extends System {
  static const double speedIncreaseDuration = 60.0;

  @override
  bool matches(Entity entity) {
    return entity.get<TagsComponent>()?.hasTag('meteor') ?? false;
  }

  @override
  void update(Entity entity, double dt) {
    final lifecycle = entity.get<LifecycleComponent>();
    final pos = entity.get<PositionComponent>();
    final vel = entity.get<VelocityComponent>();

    if (lifecycle == null || pos == null || vel == null) return;

    lifecycle.age += dt;

    if (lifecycle.age >= lifecycle.maxAge) {
      final targeting = entity.get<TargetingComponent>();
      if (targeting != null) {
        final targetPlayer = world.entities[targeting.targetId];
        if (targetPlayer != null) {
          final scoreComp = targetPlayer.get<ScoreComponent>();
          if (scoreComp != null) {
            scoreComp.score += 10;
            targetPlayer.add(scoreComp);
          }
        }
      }
      world.removeEntity(entity.id);
      return;
    }

    final lifeRatio = 1.0 - (lifecycle.age / lifecycle.maxAge);
    pos.width = lifecycle.initialWidth * lifeRatio;
    pos.height = lifecycle.initialHeight * lifeRatio;

    const maxSpeed = PlayerControlSystem.playerSpeed * 9.0;
    final ageRatio = min(1.0, lifecycle.age / speedIncreaseDuration);
    final targetSpeed =
        lifecycle.initialSpeed + (maxSpeed - lifecycle.initialSpeed) * ageRatio;
    final currentSpeed = sqrt(vel.x * vel.x + vel.y * vel.y);

    if (currentSpeed > 0) {
      final multiplier = targetSpeed / currentSpeed;
      vel.x *= multiplier;
      vel.y *= multiplier;
    }

    entity.add(lifecycle);
    entity.add(pos);
    entity.add(vel);
  }
}

/// Client-side system to adjust game difficulty based on player count.
class DynamicDifficultySystem extends System {
  static const double baseSpawnRate = 0.5;
  static const double ratePerPlayer = 0.5;

  @override
  bool matches(Entity entity) {
    return entity.has<SpawnerComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final spawner = entity.get<SpawnerComponent>()!;
    final playerCount =
        world.entities.values.where((e) => e.has<PlayerComponent>()).length;

    if (playerCount > 0) {
      final newSpawnRate = baseSpawnRate + (playerCount) * ratePerPlayer;
      spawner.frequency = newSpawnRate;
    }
  }
}

/// Client-side system for handling collision rules.
class GameRulesSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<CollisionEvent>(_onCollision);
  }

  void _onCollision(CollisionEvent event) {
    final entityA = world.entities[event.entityA];
    final entityB = world.entities[event.entityB];
    if (entityA == null || entityB == null) return;

    _handlePlayerMeteorCollision(entityA, entityB);
    _handlePlayerMeteorCollision(entityB, entityA);
    _handleMeteorMeteorCollision(entityA, entityB);
  }

  void _handlePlayerMeteorCollision(Entity player, Entity meteor) {
    final isPlayer = player.get<TagsComponent>()?.hasTag('player') ?? false;
    final isMeteor = meteor.get<TagsComponent>()?.hasTag('meteor') ?? false;

    if (isPlayer && isMeteor) {
      final health = player.get<HealthComponent>();
      final damage = meteor.get<DamageComponent>();

      if (health != null && damage != null) {
        health.currentHealth -= damage.damage;
        player.add(health);
      }
      // --- REFINED LOGIC: Set meteor health to 0 to be handled by MeteorBurnSystem ---
      meteor.add(HealthComponent(maxHealth: 1, currentHealth: 0));
    }
  }

  void _handleMeteorMeteorCollision(Entity entityA, Entity entityB) {
    final isAMeteor = entityA.get<TagsComponent>()?.hasTag('meteor') ?? false;
    final isBMeteor = entityB.get<TagsComponent>()?.hasTag('meteor') ?? false;

    if (isAMeteor && isBMeteor) {
      // --- REFINED LOGIC: Set health to 0 for both meteors ---
      entityA.add(HealthComponent(maxHealth: 1, currentHealth: 0));
      entityB.add(HealthComponent(maxHealth: 1, currentHealth: 0));
    }
  }

  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}
}
