import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/attractor_component.dart';
import 'package:nexus/src/events/pointer_events.dart';

/// A system that listens for pointer events from the UI and updates the
/// position of a designated entity (like the attractor).
class PointerSystem extends System {
  Entity? _trackedEntity;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    world.eventBus.on<PointerMoveEvent>(_onPointerMove);
    // Lazily find the entity later to ensure it has been added.
  }

  void _onPointerMove(PointerMoveEvent event) {
    _trackedEntity ??= world.entities.values
        .firstWhere((e) => e.has<AttractorComponent>(), orElse: () => Entity());

    if (_trackedEntity!.has<AttractorComponent>()) {
      final pos = _trackedEntity!.get<PositionComponent>()!;
      pos.x = event.x;
      pos.y = event.y;
      _trackedEntity!.add(pos);
    }
  }

  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}
}
