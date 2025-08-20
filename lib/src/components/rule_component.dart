import 'package:nexus/nexus.dart';

/// Defines a conditional action to be executed on an entity in response to specific events.
/// This component is the core of the reactive rule engine.
///
/// Note: This component is not serializable because it contains functions.
/// It should be defined and added within the logic isolate.
class RuleComponent extends Component {
  /// A set of event types that will trigger the evaluation of this rule's condition.
  final Set<Type> triggers;

  /// A function that evaluates whether the actions should be executed.
  /// It receives the entity this component is attached to, and the event that triggered it.
  /// It must return `true` for the actions to run.
  final bool Function(Entity entity, dynamic event) condition;

  /// A function that executes the desired logic when the condition is met.
  /// It receives the entity and the triggering event.
  final void Function(Entity entity, dynamic event) actions;

  RuleComponent({
    required this.triggers,
    required this.condition,
    required this.actions,
  });

  // Functions don't have a meaningful equality check.
  @override
  List<Object?> get props => [];
}
