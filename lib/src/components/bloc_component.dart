import 'package:bloc/bloc.dart';
import 'package:nexus/src/core/component.dart';

/// A special component that holds an instance of a BLoC or Cubit.
///
/// This component acts as a bridge between the event-driven world of BLoC
/// and the data-driven world of Nexus ECS. It allows an entity to manage
/// complex state using a familiar BLoC pattern.
///
/// A `BlocSystem` will typically listen to the state changes of the [bloc]
/// and update other components on the same entity accordingly.
class BlocComponent<B extends BlocBase<S>, S> extends Component {
  /// The BLoC or Cubit instance that manages the state.
  final B bloc;

  BlocComponent(this.bloc);
}
