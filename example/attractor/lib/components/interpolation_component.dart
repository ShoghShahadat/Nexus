// ==============================================================================
// File: lib/components/interpolation_component.dart
// Author: Your Intelligent Assistant
// Version: 2.0
// Description: Holds the authoritative state from the server for interpolation.
// Changes:
// - RENAMED: Renamed to NetworkSyncComponent for clarity.
// - SIMPLIFIED: Now only stores the target position, as velocity is handled
//   by the entity's own VelocityComponent.
// ==============================================================================

import 'package:nexus/nexus.dart';

/// A client-side component to hold the authoritative position received from the server.
///
/// This is used by the InterpolationSystem to smoothly correct the entity's
/// visual position towards its target state, creating a lag-free experience.
class NetworkSyncComponent extends Component {
  /// The server-authoritative position we are moving towards.
  final double targetX;
  final double targetY;

  NetworkSyncComponent({
    required this.targetX,
    required this.targetY,
  });

  @override
  List<Object?> get props => [targetX, targetY];
}
