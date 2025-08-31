import 'package:nexus/nexus.dart';

/// A system that manages the aging and immediate disposal of particle entities.
/// It increments the `age` property on each frame and removes the entity as soon
/// as its `maxAge` is reached, preventing any delay from the GarbageCollectorSystem.
class ParticleLifecycleSystem extends UpdateSystem {
  @override
  bool matches(Entity entity) {
    return entity.has<ParticleComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final particle = entity.get<ParticleComponent>()!;

    // Increment the particle's age.
    particle.age += dt;

    // --- CRITICAL FIX: Immediate Removal Logic ---
    // Check if the particle has expired.
    if (particle.age >= particle.maxAge) {
      // If so, remove it from the world immediately in the next microtask.
      // This is much more efficient than waiting for the periodic GarbageCollectorSystem.
      Future.microtask(() => world.removeEntity(entity.id));
    } else {
      // If not expired, re-add the component to notify listeners of the age change.
      entity.add(particle);
    }
  }
}
