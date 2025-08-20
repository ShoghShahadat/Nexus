import 'dart:math';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/attractor_component.dart';

/// A physics system that applies a gravitational pull from an attractor
/// entity to all other entities with velocity.
class AttractionSystem extends System {
  Entity? _attractor;

  // A helper to find the attractor without causing type errors.
  void _findAttractor() {
    try {
      _attractor =
          world.entities.values.firstWhere((e) => e.has<AttractorComponent>());
    } catch (e) {
      _attractor = null;
    }
  }

  @override
  bool matches(Entity entity) {
    // This system acts on any movable entity that is NOT the attractor itself.
    return entity.has<PositionComponent>() &&
        entity.has<VelocityComponent>() &&
        !entity.has<AttractorComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    // Find the attractor on the first run if it's not found yet.
    _attractor ??= world.entities.values
        .firstWhere((e) => e.has<AttractorComponent>(), orElse: () => Entity());
    if (_attractor!.id == entity.id || !_attractor!.has<AttractorComponent>())
      return;

    final pos = entity.get<PositionComponent>()!;
    final vel = entity.get<VelocityComponent>()!;
    final attractorPos = _attractor!.get<PositionComponent>()!;
    final attractorComp = _attractor!.get<AttractorComponent>()!;

    final dx = attractorPos.x - pos.x;
    final dy = attractorPos.y - pos.y;
    final distSq = dx * dx + dy * dy;

    if (distSq < 25) return; // Avoid extreme forces up close

    final force = attractorComp.strength * 1000 / distSq;
    final angle = atan2(dy, dx);

    // Apply acceleration
    vel.x += cos(angle) * force * dt;
    vel.y += sin(angle) * force * dt;

    entity.add(vel);
  }
}
