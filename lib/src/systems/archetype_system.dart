import 'dart:async';
import 'package:nexus/nexus.dart';

/// A system that processes [ArchetypeComponent]s to dynamically apply and
/// remove collections of components (Archetypes) based on conditions.
class ArchetypeSystem extends System {
  final Map<Type, List<EntityId>> _eventSubscriptions = {};
  StreamSubscription? _eventBusSubscription;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    _buildSubscriptionMap();
    _eventBusSubscription = world.eventBus.on<dynamic>(_handleEvent);
  }

  void _buildSubscriptionMap() {
    _eventSubscriptions.clear();
    for (final entity in world.entities.values) {
      if (entity.has<ArchetypeComponent>()) {
        _registerEntity(entity);
      }
    }
  }

  void _registerEntity(Entity entity) {
    final archetypeComp = entity.get<ArchetypeComponent>()!;
    for (final triggerType in archetypeComp.triggers) {
      _eventSubscriptions.putIfAbsent(triggerType, () => []).add(entity.id);
    }
  }

  void _unregisterEntity(Entity entity) {
    final archetypeComp = entity.get<ArchetypeComponent>();
    if (archetypeComp == null) return;
    for (final triggerType in archetypeComp.triggers) {
      _eventSubscriptions[triggerType]?.remove(entity.id);
    }
  }

  void _handleEvent(dynamic event) {
    final eventType = event.runtimeType;
    final interestedEntityIds = _eventSubscriptions[eventType];
    if (interestedEntityIds == null) return;

    for (final entityId in List<EntityId>.from(interestedEntityIds)) {
      final entity = world.entities[entityId];
      if (entity == null) continue;

      final archetypeComp = entity.get<ArchetypeComponent>()!;
      bool changed = false;

      for (final conditionalArchetype in archetypeComp.archetypes) {
        final archetype = conditionalArchetype.archetype;
        final isCurrentlyActive =
            archetypeComp.activeArchetypes.contains(archetype);
        final conditionResult = conditionalArchetype.condition(entity, event);

        if (conditionResult && !isCurrentlyActive) {
          // Condition met, archetype not active -> Apply it
          archetype.apply(entity);
          archetypeComp.activeArchetypes.add(archetype);
          changed = true;
          print(
              "ArchetypeSystem: Applied archetype ${archetype.runtimeType} to Entity ${entity.id}");
        } else if (!conditionResult && isCurrentlyActive) {
          // Condition not met, archetype is active -> Remove it
          for (final componentType in archetype.componentTypes) {
            // --- FIX: Use the new removeByType method ---
            entity.removeByType(componentType);
            // --- END FIX ---
          }
          archetypeComp.activeArchetypes.remove(archetype);
          changed = true;
          print(
              "ArchetypeSystem: Removed archetype ${archetype.runtimeType} from Entity ${entity.id}");
        }
      }

      if (changed) {
        // Re-add the component to save the state of activeArchetypes
        entity.add(archetypeComp);
      }
    }
  }

  @override
  bool matches(Entity entity) => entity.has<ArchetypeComponent>();

  @override
  void onEntityAdded(Entity entity) => _registerEntity(entity);

  @override
  void onEntityRemoved(Entity entity) => _unregisterEntity(entity);

  @override
  void update(Entity entity, double dt) {
    // Logic is event-driven
  }

  @override
  void onRemovedFromWorld() {
    _eventBusSubscription?.cancel();
    _eventSubscriptions.clear();
    super.onRemovedFromWorld();
  }
}
