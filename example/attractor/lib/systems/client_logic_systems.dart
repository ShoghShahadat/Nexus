import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import '../components/meteor_component.dart';
import '../components/network_components.dart';
import '../events.dart';

/// Manages the game state (game over, reset) on the HOST client.
class ClientGameLogicSystem extends System {
  bool _isGameOver = false;
  double _gameOverTimer = 5.0;

  @override
  bool matches(Entity entity) {
    final localPlayer = world.entities.values.firstWhereOrNull(
        (e) => e.get<PlayerComponent>()?.isLocalPlayer ?? false);
    return (localPlayer?.get<PlayerComponent>()?.isHost ?? false) &&
        (entity.get<TagsComponent>()?.hasTag('root') ?? false);
  }

  @override
  void update(Entity entity, double dt) {
    final players =
        world.entities.values.where((e) => e.has<PlayerComponent>()).toList();
    if (players.isEmpty) {
      _isGameOver = false;
      return;
    }

    final alivePlayers = players
        .where((p) => (p.get<HealthComponent>()?.currentHealth ?? 0) > 0);

    if (alivePlayers.isEmpty && !_isGameOver) {
      print("[HOST] All players defeated! Resetting in 5 seconds...");
      _isGameOver = true;
      _gameOverTimer = 5.0;

      world.entities.values
          .firstWhereOrNull((e) => e.has<SpawnerComponent>())
          ?.get<SpawnerComponent>()
          ?.wantsToFire = false;

      // --- FIX: Broadcast a "GameOver" message to other clients ---
      world.eventBus.fire(RelayGameEvent('gameOver'));
    }

    if (_isGameOver) {
      _gameOverTimer -= dt;
      if (_gameOverTimer <= 0) {
        _resetGame(players);
      }
    }
  }

  void _resetGame(List<Entity> players) {
    print("[HOST] Resetting game for new round.");
    // --- FIX: Broadcast a "ResetGame" message to other clients ---
    world.eventBus.fire(RelayGameEvent('resetGame'));

    // The host executes the logic locally first
    _executeReset();
    _isGameOver = false;
  }

  void _executeReset() {
    // Remove all meteors
    // --- FIX: Correctly check for the 'meteor' tag. ---
    final meteors = world.entities.values
        .where((e) => e.get<TagsComponent>()?.hasTag('meteor') ?? false)
        .map((e) => e.id)
        .toList();
    for (final id in meteors) {
      world.removeEntity(id);
    }

    // Reset players
    final allPlayers =
        world.entities.values.where((e) => e.has<PlayerComponent>());
    for (final player in allPlayers) {
      player.add(HealthComponent(maxHealth: 100));
      player.add(PositionComponent(x: 400, y: 500, width: 20, height: 20));
      player.add(VelocityComponent());
    }

    // Reactivate spawner
    world.entities.values
        .firstWhereOrNull((e) => e.has<SpawnerComponent>())
        ?.get<SpawnerComponent>()
        ?.wantsToFire = true;
  }
}
