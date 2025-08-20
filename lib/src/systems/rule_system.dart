import 'dart:async';
import 'package:nexus/nexus.dart';

/// A system that processes [RuleComponent]s, creating a reactive rule engine.
///
/// It listens for events on the global event bus and triggers the evaluation
/// of rules that are registered for a given event type.
class RuleSystem extends System {
  final Map<Type, List<EntityId>> _eventSubscriptions = {};
  StreamSubscription? _eventBusSubscription;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    _buildSubscriptionMap();

    // Listen to all events on the bus. This requires the EventBus to allow
    // listening to the 'dynamic' type.
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

    final interestedEntityIds = _eventSubscriptions[eventType];
    if (interestedEntityIds == null || interestedEntityIds.isEmpty) return;

    for (final entityId in List<EntityId>.from(interestedEntityIds)) {
      final entity = world.entities[entityId];
      if (entity == null) continue;

      final rule = entity.get<RuleComponent>()!;
      if (rule.condition(entity, event)) {
        rule.actions(entity, event);
      }
    }
  }

  @override
  bool matches(Entity entity) {
    return entity.has<RuleComponent>();
  }

  @override
  void onEntityAdded(Entity entity) {
    _registerEntityRules(entity);
  }

  @override
  void onEntityRemoved(Entity entity) {
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
