import 'package:nexus/src/core/component.dart';
import 'package:nexus/src/core/entity.dart';

/// A component that makes an entity interactive.
///
/// It holds a callback function that is executed by the `InputSystem`
/// when a user tap is detected within the entity's bounds (defined by its
/// `PositionComponent`).
class ClickableComponent extends Component {
  final void Function(Entity entity) onTap;

  ClickableComponent(this.onTap);
}
