import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import '../components/network_components.dart';
import '../network/mock_server.dart';

/// An event fired on the server world to reset the game state for a new round.
class ServerResetGameEvent {}

/// A system that runs ONLY on the server to manage the overall game state.
class ServerGameLogicSystem extends System {
  bool _isGameOver = false;
  double _gameOverTimer = 5.0;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<ServerResetGameEvent>((_) => _resetGame());
  }

  @override
  bool matches(Entity entity) {
    return entity.get<TagsComponent>()?.hasTag('root') ?? false;
  }

  @override
  void update(Entity entity, double dt) {
    final players =
        world.entities.values.where((e) => e.has<PlayerComponent>()).toList();

    if (players.isEmpty) {
      _isGameOver = false;
      return;
    }

    for (final player in players) {
      final health = player.get<HealthComponent>();
      if (health != null &&
          health.currentHealth <= 0 &&
          player.has<CollisionComponent>()) {
        print(
            '[SERVER] Player ${player.get<PlayerComponent>()!.sessionId} defeated.');
        player.remove<VelocityComponent>();
        player.remove<CollisionComponent>();
      }
    }

    final allPlayersDefeated = players
        .every((p) => (p.get<HealthComponent>()?.currentHealth ?? 1) <= 0);

    if (allPlayersDefeated && !_isGameOver) {
      print(
          '[SERVER] All players defeated! Game Over. Resetting in 5 seconds...');
      _isGameOver = true;
      _gameOverTimer = 5.0;
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
    final players =
        world.entities.values.where((e) => e.has<PlayerComponent>());
    for (final player in players) {
      final health = player.get<HealthComponent>();
      if (health != null) {
        player.add(HealthComponent(maxHealth: health.maxHealth));
      }

      final pos = player.get<PositionComponent>();
      if (pos != null) {
        pos.width = MockServer.playerBaseSize;
        pos.height = MockServer.playerBaseSize;
        player.add(pos);
      }

      player.add(VelocityComponent());
      player.add(CollisionComponent(
          tag: 'player',
          radius: MockServer.playerBaseSize / 2,
          collidesWith: {'meteor', 'health_orb'}));
    }

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

    final blackboard = world.rootEntity.get<BlackboardComponent>();
    if (blackboard != null) {
      blackboard.set('score', 0);
      blackboard.set('game_time', 0.0);
      world.rootEntity.add(blackboard);
    }
  }
}
