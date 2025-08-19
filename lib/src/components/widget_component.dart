import 'package:flutter/widgets.dart';
import 'package:nexus/src/core/component.dart';

/// A component that holds a Flutter [Widget].
///
/// This is the primary component used by the `FlutterRenderingSystem`
/// to draw entities on the screen. The entity's appearance is defined
/// entirely by the widget held in this component.
class WidgetComponent extends Component {
  final Widget widget;

  WidgetComponent(this.widget);
}
