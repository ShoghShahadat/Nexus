import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import '../components/network_components.dart';
import '../components/network_id_component.dart';
import '../events.dart';

/// A project-specific system to handle P2P state synchronization.
/// It determines which client "owns" which data and relays component
/// updates to other clients accordingly.
class P2pSyncSystem extends System {
  @override
  bool matches(Entity entity) {
    // This system runs on any entity that is part of the network.
    return entity.has<NetworkIdComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    // --- CRITICAL FIX: Only process entities that have actual changes. ---
    // --- اصلاح حیاتی: فقط موجودیت‌هایی پردازش می‌شوند که واقعاً تغییری داشته‌اند. ---
    if (entity.dirtyComponents.isEmpty) return;

    final localPlayer = world.entities.values.firstWhereOrNull(
        (e) => e.get<PlayerComponent>()?.isLocalPlayer ?? false);
    if (localPlayer == null) return;

    final networkIdComp = entity.get<NetworkIdComponent>()!;
    final isHost = localPlayer.get<PlayerComponent>()!.isHost;
    // --- FIX: Correctly identify the local player entity using its NetworkIdComponent ---
    final isOurPlayer = networkIdComp.networkId ==
        localPlayer.get<NetworkIdComponent>()!.networkId;
    final isMeteor = entity.get<TagsComponent>()?.hasTag('meteor') ?? false;

    // --- Data Ownership Rules ---
    // 1. Each client is the authority for their own player's state.
    // 2. The Host is the authority for all non-player objects (e.g., meteors).
    if (isOurPlayer || (isHost && isMeteor)) {
      // --- FIX: Iterate only over components that have changed this frame. ---
      for (final componentType in entity.dirtyComponents) {
        final compInstance = entity.getByType(componentType);
        if (compInstance is BinaryComponent) {
          world.eventBus.fire(
              RelayComponentStateEvent(networkIdComp.networkId, compInstance));
        }
      }
    }
  }
}
