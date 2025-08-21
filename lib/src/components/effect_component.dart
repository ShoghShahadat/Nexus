import 'package:nexus/nexus.dart';

/// A logic-only component that defines a conditional, temporary effect to be
/// applied to an entity.
///
/// An effect is a collection of components (defined in an Archetype) that
/// can be added and removed from an entity in response to events or after a
/// certain duration.
class EffectComponent extends Component {
  /// The archetype containing the components to be applied when the effect is active.
  final Archetype archetype;

  /// The type of event that triggers the evaluation of this effect.
  final Type triggerEvent;

  /// An optional condition that must be met for the effect to be applied.
  /// Receives the entity and the triggering event.
  final bool Function(Entity entity, dynamic event)? condition;

  /// An optional duration for the effect. If set, the effect will be automatically
  /// removed after this duration.
  final Duration? duration;

  /// An optional event type that will cause the effect to be removed prematurely.
  final Type? removeOnEvent;

  /// A flag to track if the effect's archetype is currently applied.
  /// This is managed internally by the EffectSystem.
  bool isApplied;

  EffectComponent({
    required this.archetype,
    required this.triggerEvent,
    this.condition,
    this.duration,
    this.removeOnEvent,
    this.isApplied = false,
  });

  // This component contains functions and is not intended for value-based equality.
  @override
  List<Object?> get props =>
      [archetype, triggerEvent, condition, duration, removeOnEvent, isApplied];
}
