import 'package:nexus/src/core/component.dart';
import 'package:nexus/src/core/entity.dart';

/// A simple data component that holds a callback for tap events.
class ClickableComponent extends Component {
  final void Function(Entity entity) onTap;

  ClickableComponent(this.onTap);

  // Functions don't have a meaningful equality check, so we return an empty
  // list. This means any new instance of ClickableComponent will be considered
  // different, which is often the desired behavior for components with callbacks.
  @override
  List<Object?> get props => [];
}
