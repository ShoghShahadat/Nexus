import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/particle_component.dart'
    show ParticleComponent;

/// Manages the aging and disposal of particle entities.
class ParticleLifecycleSystem extends System {
  @override
  bool matches(Entity entity) {
    return entity.has<ParticleComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final particle = entity.get<ParticleComponent>()!;
    particle.age += dt;

    if (particle.age >= particle.maxAge) {
      // Use a post-frame callback to avoid concurrent modification issues.
      Future.microtask(() => world.removeEntity(entity.id));
    } else {
      // Re-add the component to notify the UI of the age change.
      entity.add(particle);
    }
  }
}
