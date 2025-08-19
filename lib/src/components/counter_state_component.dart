import 'package:nexus/src/core/component.dart';

/// A simple data component that holds the current integer state of the counter.
///
/// This component is managed by the `_CounterDisplaySystem` and read by the
/// `WidgetComponent`'s builder to display the UI. It contains no logic.
class CounterStateComponent extends Component {
  final int value;

  CounterStateComponent(this.value);
}
