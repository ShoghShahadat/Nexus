import 'package:nexus/src/core/component.dart';
import 'package:nexus/src/core/entity.dart';

/// A component that provides lifecycle callbacks for an entity.
class LifecycleComponent extends Component {
  /// A callback that is executed when the entity is added to the world.
  final void Function(Entity entity)? onInit;

  /// A callback that is executed just before the entity is removed from the world.
  final void Function(Entity entity)? onDispose;

  LifecycleComponent({this.onInit, this.onDispose});

  // Functions don't have a meaningful equality check, so we return an empty
  // list to ensure any new instance is treated as a unique update.
  @override
  List<Object?> get props => [];
}
