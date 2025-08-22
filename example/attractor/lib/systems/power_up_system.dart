import 'package:nexus/nexus.dart';
import '../components/network_components.dart';
import '../components/power_up_component.dart';
import '../network/mock_server.dart';

/// A server-side system that manages the lifecycle of power-up effects.
class PowerUpSystem extends System {
  @override
  bool matches(Entity entity) {
    // This system acts on any entity that has a power-up active.
    return entity.has<PowerUpComponent>();
  }

  @override
  void onEntityAdded(Entity entity) {
    // When the component is first added, apply the effects.
    if (matches(entity)) {
      final powerUp = entity.get<PowerUpComponent>()!;
      // Check if this is the initial application of the power-up
      if ((powerUp.duration - 5.0).abs() < 0.01) {
        print(
            '[SERVER] Power-up activated for player ${entity.get<PlayerComponent>()?.sessionId}');
        final pos = entity.get<PositionComponent>();
        final collision = entity.get<CollisionComponent>();
        if (pos != null && collision != null) {
          pos.width *= 2;
          pos.height *= 2;
          collision.radius *= 2;
          entity.add(pos);
          entity.add(collision);
        }
      }
    }
  }

  @override
  void update(Entity entity, double dt) {
    final powerUp = entity.get<PowerUpComponent>()!;
    powerUp.duration -= dt;

    if (powerUp.duration <= 0) {
      // Power-up has expired.
      print(
          '[SERVER] Power-up expired for player ${entity.get<PlayerComponent>()?.sessionId}');

      // Reset player size and collision radius to normal.
      final pos = entity.get<PositionComponent>();
      final collision = entity.get<CollisionComponent>();
      if (pos != null && collision != null) {
        pos.width = MockServer.playerBaseSize;
        pos.height = MockServer.playerBaseSize;
        collision.radius = MockServer.playerBaseSize / 2;
        entity.add(pos);
        entity.add(collision);
      }

      // Remove the power-up component.
      entity.remove<PowerUpComponent>();
    } else {
      // Re-add the component to signal its internal state has changed.
      entity.add(powerUp);
    }
  }
}
