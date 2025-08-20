import 'package:flutter/widgets.dart';
import 'package:nexus/src/core/component.dart';
import 'package:nexus/src/core/entity.dart';

/// A component that holds a builder function for creating a Flutter [Widget].
///
/// This component is treated as non-equatable because its main property is a
/// function reference, which doesn't support meaningful value-based comparison.
/// Any update to this component is assumed to be intentional and should
/// trigger a rebuild.
class WidgetComponent extends Component {
  final Widget Function(BuildContext context, Entity entity) builder;

  WidgetComponent(this.builder);

  // By returning an empty list, we ensure that any two instances of
  // WidgetComponent are considered unequal (unless they are the same instance),
  // forcing a rebuild which is the desired behavior for UI builders.
  @override
  List<Object?> get props => [];
}
