import 'dart:async';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/rule_component.dart';

/// A system that processes [RuleComponent]s, creating a reactive rule engine.
///
/// It listens for events on the global event bus and triggers the evaluation
/// of rules that are registered for a given event type.
class RuleSystem extends System {
  // A map to efficiently find which entities are listening for which event types.
  final Map<Type, List<EntityId>> _eventSubscriptions = {};
  StreamSubscription? _eventBusSubscription;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    _buildSubscriptionMap();

    // Listen to all events on the bus.
    _eventBusSubscription = world.eventBus.on<dynamic>(_handleEvent);
  }

  /// Scans all entities and builds the map of event types to entity IDs.
  void _buildSubscriptionMap() {
    _eventSubscriptions.clear();
    for (final entity in world.entities.values) {
      if (entity.has<RuleComponent>()) {
        _registerEntityRules(entity);
      }
    }
  }

  /// Registers the rules for a single entity in the subscription map.
  void _registerEntityRules(Entity entity) {
    final rules = entity.get<RuleComponent>()!;
    for (final triggerType in rules.triggers) {
      _eventSubscriptions.putIfAbsent(triggerType, () => []).add(entity.id);
    }
  }

  /// Unregisters the rules for a single entity.
  void _unregisterEntityRules(Entity entity) {
    final rules = entity.get<RuleComponent>();
    if (rules == null) return;
    for (final triggerType in rules.triggers) {
      _eventSubscriptions[triggerType]?.remove(entity.id);
    }
  }

  /// The central event handler.
  void _handleEvent(dynamic event) {
    final eventType = event.runtimeType;

    // Find all entities subscribed to this event type.
    final interestedEntityIds = _eventSubscriptions[eventType];
    if (interestedEntityIds == null || interestedEntityIds.isEmpty) return;

    // Create a copy of the list to avoid concurrent modification issues
    // if an action modifies the entity list.
    for (final entityId in List<EntityId>.from(interestedEntityIds)) {
      final entity = world.entities[entityId];
      if (entity == null) continue;

      final rule = entity.get<RuleComponent>()!;
      // Evaluate the condition and execute actions if it passes.
      if (rule.condition(entity, event)) {
        rule.actions(entity, event);
      }
    }
  }

  @override
  bool matches(Entity entity) {
    // This system doesn't operate on entities in the update loop.
    // It's purely event-driven. However, we need to know when a
    // RuleComponent is added or removed to update our subscription map.
    return entity.has<RuleComponent>();
  }

  @override
  void onEntityAdded(Entity entity) {
    // A new entity with a rule was added, register it.
    _registerEntityRules(entity);
  }

  @override
  void onEntityRemoved(Entity entity) {
    // An entity with a rule was removed, unregister it.
    _unregisterEntityRules(entity);
  }

  @override
  void update(Entity entity, double dt) {
    // The main logic is handled by the event listener, not the update loop.
  }

  @override
  void onRemovedFromWorld() {
    _eventBusSubscription?.cancel();
    _eventSubscriptions.clear();
    super.onRemovedFromWorld();
  }
}
