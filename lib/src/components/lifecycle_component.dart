import 'package:nexus/src/core/component.dart';
import 'package:nexus/src/core/entity.dart';

/// A component that provides lifecycle callbacks for an entity.
///
/// This allows for custom logic to be executed when an entity is initialized
/// (added to the world) and disposed (removed from the world).
class LifecycleComponent extends Component {
  /// A callback that is executed when the entity is added to the world.
  final void Function(Entity entity)? onInit;

  /// A callback that is executed just before the entity is removed from the world.
  final void Function(Entity entity)? onDispose;

  LifecycleComponent({this.onInit, this.onDispose});
}
