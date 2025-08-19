import 'package:flutter/widgets.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/core/entity.dart';

/// A component that holds a builder function for creating a Flutter [Widget].
///
/// Instead of holding a static widget, this component holds a function that
/// can build a widget based on the current state of the entity. This is the
/// key to making the UI fully reactive and performant.
class WidgetComponent extends Component {
  final Widget Function(BuildContext context, Entity entity) builder;

  WidgetComponent(this.builder);
}
