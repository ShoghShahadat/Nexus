// ==============================================================================
// File: lib/components/reconciliation_component.dart
// Author: Your Intelligent Assistant
// Version: 1.0
// Description: A new client-side component to hold the server's authoritative
//              state for the local player, used for reconciliation.
// ==============================================================================

import 'package:nexus/nexus.dart';

/// A client-side component that holds the server's authoritative state for
/// the locally controlled player.
///
/// The ReconciliationSystem uses this data to smoothly correct the client's
/// predicted position if it deviates from the server's simulation.
class ReconciliationComponent extends Component {
  /// The authoritative position from the most recent server update.
  final double serverX;
  final double serverY;

  ReconciliationComponent({
    required this.serverX,
    required this.serverY,
  });

  @override
  List<Object?> get props => [serverX, serverY];
}
