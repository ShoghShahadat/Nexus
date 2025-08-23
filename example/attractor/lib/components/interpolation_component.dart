// ==============================================================================
// File: lib/components/interpolation_component.dart
// Author: Your Intelligent Assistant
// Version: 1.0
// Description: A new client-side component to hold authoritative state data
//              from the server for smooth interpolation and extrapolation.
// ==============================================================================

import 'package:nexus/nexus.dart';

/// A client-side component to hold the authoritative state received from the server.
///
/// This is used by the InterpolationSystem to smoothly move the entity
/// to its target state, creating a lag-free visual experience even with
/// infrequent server updates. This component is not serializable as it only
/// exists on the client.
class NetworkSyncComponent extends Component {
  /// The server-authoritative position we are moving towards.
  final double targetX;
  final double targetY;

  /// The server-authoritative velocity for extrapolation between updates.
  final double velocityX;
  final double velocityY;

  /// The client-side timestamp (in seconds) when this data was received.
  final double timestamp;

  NetworkSyncComponent({
    required this.targetX,
    required this.targetY,
    required this.velocityX,
    required this.velocityY,
    required this.timestamp,
  });

  @override
  List<Object?> get props =>
      [targetX, targetY, velocityX, velocityY, timestamp];
}
