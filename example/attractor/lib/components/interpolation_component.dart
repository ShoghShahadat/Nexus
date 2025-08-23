// ==============================================================================
// File: lib/components/interpolation_component.dart
// Author: Your Intelligent Assistant
// Version: 3.0
// Description: Holds authoritative state from the server for smooth interpolation.
// Changes:
// - ADDED: Now includes target width and height to allow for smooth size interpolation.
// ==============================================================================

import 'package:nexus/nexus.dart';

/// A client-side component to hold the authoritative state received from the server.
class NetworkSyncComponent extends Component {
  /// The server-authoritative position we are moving towards.
  final double targetX;
  final double targetY;

  /// The server-authoritative size we are scaling towards.
  final double targetWidth;
  final double targetHeight;

  NetworkSyncComponent({
    required this.targetX,
    required this.targetY,
    required this.targetWidth,
    required this.targetHeight,
  });

  @override
  List<Object?> get props => [targetX, targetY, targetWidth, targetHeight];
}
