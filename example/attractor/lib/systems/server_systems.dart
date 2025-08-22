// === File: example/attractor/lib/systems/server_systems.dart (New) ===

import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import '../components/network_components.dart';

/// An event fired on the server world to reset the game state for a new round.
class ServerResetGameEvent {}

/// A system that runs ONLY on the server to manage the overall game state.
/// It checks for game-over conditions and triggers a global reset.
class ServerGameLogicSystem extends System {
  bool _isGameOver = false;
  double _gameOverTimer = 5.0; // 5 seconds until reset

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<ServerResetGameEvent>((_) => _resetGame());
  }

  @override
  bool matches(Entity entity) {
    // This system runs once per frame, tied to the server's root entity.
    return entity.get<TagsComponent>()?.hasTag('root') ?? false;
  }

  @override
  void update(Entity entity, double dt) {
    final players =
        world.entities.values.where((e) => e.has<PlayerComponent>()).toList();

    // If there are no players, do nothing.
    if (players.isEmpty) {
      _isGameOver = false;
      return;
    }

    // Check if all players are defeated.
    final allPlayersDefeated = players
        .every((p) => (p.get<HealthComponent>()?.currentHealth ?? 1) <= 0);

    if (allPlayersDefeated && !_isGameOver) {
      print('[SERVER] All players defeated! Game Over.');
      _isGameOver = true;
      _gameOverTimer = 5.0; // Reset countdown
      entity.get<BlackboardComponent>()?.set('is_game_over', true);
    }

    if (_isGameOver) {
      _gameOverTimer -= dt;
      if (_gameOverTimer <= 0) {
        print('[SERVER] Resetting game for new round.');
        world.eventBus.fire(ServerResetGameEvent());
        _isGameOver = false;
        entity.get<BlackboardComponent>()?.set('is_game_over', false);
      }
    }
  }

  void _resetGame() {
    // Reset all players' health.
    final players =
        world.entities.values.where((e) => e.has<PlayerComponent>());
    for (final player in players) {
      final health = player.get<HealthComponent>();
      if (health != null) {
        player.add(HealthComponent(maxHealth: health.maxHealth));
      }
    }

    // Remove all meteors and health orbs.
    final entitiesToRemove = world.entities.values
        .where((e) {
          final tags = e.get<TagsComponent>();
          return tags != null &&
              (tags.hasTag('meteor') || tags.hasTag('health_orb'));
        })
        .map((e) => e.id)
        .toList();

    for (final id in entitiesToRemove) {
      world.removeEntity(id);
    }

    // Reset score
    world.rootEntity.get<BlackboardComponent>()?.set('score', 0);
  }
}
