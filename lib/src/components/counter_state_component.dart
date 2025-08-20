import 'package:nexus/src/core/component.dart';

/// A simple data component that holds the current integer state of the counter.
class CounterStateComponent extends Component {
  final int value;

  CounterStateComponent(this.value);

  @override
  List<Object?> get props => [value];
}
