import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import '../components/network_components.dart';
import '../events.dart';

/// A project-specific system to handle P2P state synchronization.
/// It determines which client "owns" which data and relays component
/// updates to other clients accordingly.
class P2pSyncSystem extends System {
  @override
  bool matches(Entity entity) {
    // This system runs on any entity that has a position and might need syncing.
    return entity.has<PositionComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    // Find the local player to determine our role (host or client).
    final localPlayer = world.entities.values.firstWhereOrNull(
        (e) => e.get<PlayerComponent>()?.isLocalPlayer ?? false);
    if (localPlayer == null) return;

    final isHost = localPlayer.get<PlayerComponent>()!.isHost;
    final isOurPlayer = entity.id == localPlayer.id;
    final isMeteor = entity.get<TagsComponent>()?.hasTag('meteor') ?? false;

    // An entity's state should only be broadcast if it has changed.
    if (entity.dirtyComponents.isEmpty) return;

    // --- Data Ownership Rules ---
    // 1. Each client is the authority for their own player's state.
    // 2. The Host is the authority for all non-player objects (e.g., meteors).

    if (isOurPlayer) {
      // If it's our player, broadcast any changed binary components.
      for (final component in entity.dirtyComponents) {
        final compInstance = entity.getByType(component);
        if (compInstance is BinaryComponent) {
          world.eventBus
              .fire(RelayComponentStateEvent(entity.id, compInstance));
        }
      }
    } else if (isHost && isMeteor) {
      // If we are the host and this is a meteor, broadcast its changes.
      for (final component in entity.dirtyComponents) {
        final compInstance = entity.getByType(component);
        if (compInstance is BinaryComponent) {
          world.eventBus
              .fire(RelayComponentStateEvent(entity.id, compInstance));
        }
      }
    }
  }
}
