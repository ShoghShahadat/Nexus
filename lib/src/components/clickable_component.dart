import 'package:nexus/src/core/component.dart';
import 'package:nexus/src/core/entity.dart';

/// A simple data component that holds a callback for tap events.
///
/// This component doesn't contain any logic. It's used by the `WidgetComponent`
/// builder to connect an entity's tap action to a Flutter gesture-handling
/// widget like [GestureDetector] or [ElevatedButton].
class ClickableComponent extends Component {
  final void Function(Entity entity) onTap;

  ClickableComponent(this.onTap);
}
