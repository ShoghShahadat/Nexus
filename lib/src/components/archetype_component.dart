import 'package:nexus/nexus.dart';
import 'package:nexus/src/core/archetype.dart';

/// A single conditional archetype definition.
class ConditionalArchetype {
  final Archetype archetype;
  final bool Function(Entity entity, dynamic event) condition;

  ConditionalArchetype({required this.archetype, required this.condition});
}

/// A component that manages the conditional application and removal of archetypes.
/// This component is not serializable as it contains functions.
class ArchetypeComponent extends Component {
  /// A set of event types that will trigger the evaluation of the archetypes.
  final Set<Type> triggers;

  /// A list of conditional archetypes to be evaluated.
  final List<ConditionalArchetype> archetypes;

  /// A set to keep track of currently active archetypes.
  final Set<Archetype> activeArchetypes;

  ArchetypeComponent({
    required this.triggers,
    required this.archetypes,
  }) : activeArchetypes = {};

  // Functions and complex objects don't have a meaningful equality check.
  @override
  List<Object?> get props => [];
}
