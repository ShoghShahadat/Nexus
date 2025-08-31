import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';

/// A system that manages the application's lifecycle state.
///
/// --- RE-ARCHITECTED as an event-driven base System ---
/// This system doesn't need to run in the update loop or react to component
/// changes. It only reacts to events from the event bus.
class AppLifecycleSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    // Ensure the central world state entity exists.
    final rootEntity = world.entities.values.firstWhereOrNull(
        (e) => e.get<TagsComponent>()?.hasTag('root') ?? false);
    if (rootEntity != null && !rootEntity.has<AppLifecycleComponent>()) {
      rootEntity.add(AppLifecycleComponent(AppLifecycleStatus.resumed));
    }
    listen<AppLifecycleEvent>(_onLifecycleChange);
  }

  void _onLifecycleChange(AppLifecycleEvent event) {
    try {
      final rootEntity = world.entities.values
          .firstWhere((e) => e.get<TagsComponent>()?.hasTag('root') ?? false);
      rootEntity.add(AppLifecycleComponent(event.status));
    } catch (e) {
      print(
          '[AppLifecycleSystem] Error: Could not find the root entity to update lifecycle status.');
    }
  }
}
