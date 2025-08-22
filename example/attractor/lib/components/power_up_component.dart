import 'package:nexus/nexus.dart';

/// A server-side component to track the duration of a power-up effect.
/// This component is not binary-serializable as it only exists on the server.
class PowerUpComponent extends Component {
  /// The remaining duration of the power-up in seconds.
  double duration;

  PowerUpComponent({this.duration = 5.0});

  @override
  List<Object?> get props => [duration];
}
