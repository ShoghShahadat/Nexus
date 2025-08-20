import 'package:bloc/bloc.dart';
import 'package:nexus/src/core/component.dart';

/// A special component that holds an instance of a BLoC or Cubit.
class BlocComponent<B extends BlocBase<S>, S> extends Component {
  /// The BLoC or Cubit instance that manages the state.
  final B bloc;

  /// A convenience getter to access the current state of the BLoC.
  S get state => bloc.state;

  BlocComponent(this.bloc);

  @override
  List<Object?> get props => [bloc];
}
