import 'dart:async';

import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/effect_component.dart';

/// A system that manages the application and removal of temporary effects
/// on entities based on `EffectComponent` definitions.
class EffectSystem extends System {
  StreamSubscription? _eventBusSubscription;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    // Listen to all events on the bus to trigger effects.
    _eventBusSubscription = world.eventBus.on<dynamic>(_handleEvent);
  }

  void _handleEvent(dynamic event) {
    final eventType = event.runtimeType;
    final entities =
        world.entities.values.where((e) => e.has<EffectComponent>());

    for (final entity in entities) {
      final effect = entity.get<EffectComponent>()!;

      // Check for trigger event
      if (!effect.isApplied && effect.triggerEvent == eventType) {
        if (effect.condition == null || effect.condition!(entity, event)) {
          _applyEffect(entity, effect);
        }
      }

      // Check for removal event
      if (effect.isApplied && effect.removeOnEvent == eventType) {
        _removeEffect(entity, effect);
      }
    }
  }

  void _applyEffect(Entity entity, EffectComponent effect) {
    // Apply all components from the effect's archetype.
    effect.archetype.apply(entity);
    effect.isApplied = true;

    // If a duration is specified, set up a timer to remove the effect.
    if (effect.duration != null) {
      final timerTask = TimerTask(
        id: 'effect_${entity.id}_${effect.hashCode}',
        duration: effect.duration!.inSeconds.toDouble(),
        onCompleteEvent: _EffectTimerCompleteEvent(entity.id, effect),
      );

      // Add the timer task to the entity's TimerComponent, creating one if needed.
      final timerComponent = entity.get<TimerComponent>() ?? TimerComponent([]);
      timerComponent.tasks.add(timerTask);
      entity.add(timerComponent);
    }

    // Re-add the effect component to update its 'isApplied' state.
    entity.add(effect);
  }

  void _removeEffect(Entity entity, EffectComponent effect) {
    // Remove all components defined in the effect's archetype.
    for (final componentType in effect.archetype.componentTypes) {
      entity.removeByType(componentType);
    }
    effect.isApplied = false;

    // Re-add the effect component to update its state.
    entity.add(effect);
  }

  @override
  bool matches(Entity entity) {
    // This system also needs to listen for timer completion events.
    return entity.has<TimerComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    // The main logic is event-driven, but we need to check for timer completions.
    final timer = entity.get<TimerComponent>();
    if (timer == null) return;

    // Find and process effect completion events from the timer.
    final completedEffects = timer.tasks
        .where((task) =>
            task.onCompleteEvent is _EffectTimerCompleteEvent &&
            task.elapsedTime >= task.duration)
        .toList();

    for (final task in completedEffects) {
      final event = task.onCompleteEvent as _EffectTimerCompleteEvent;
      if (event.entityId == entity.id) {
        _removeEffect(entity, event.effect);
      }
    }
  }

  @override
  void onRemovedFromWorld() {
    _eventBusSubscription?.cancel();
    super.onRemovedFromWorld();
  }
}

/// Internal event used by the TimerSystem to signal effect completion.
class _EffectTimerCompleteEvent {
  final EntityId entityId;
  final EffectComponent effect;
  _EffectTimerCompleteEvent(this.entityId, this.effect);
}
