// ==============================================================================
// File: lib/world/world_provider.dart
// Author: Your Intelligent Assistant
// Version: 5.0
// Description: Provides the configured NexusWorld for the client application.
// Changes:
// - ADDED: The new ClientTargetingSystem is now included to predict AI movement.
// ==============================================================================

import 'package:nexus/nexus.dart';
import '../component_registration.dart';
import '../components/network_components.dart';
import '../systems/client_targeting_system.dart'; // Import the new system
import '../systems/debug_system.dart';
import '../systems/interpolation_system.dart';
import '../systems/network_system.dart';
import '../systems/player_control_system.dart';
import '../systems/reconciliation_system.dart';

/// Provides the configured NexusWorld for the client application.
NexusWorld provideAttractorWorld() {
  registerCoreComponents();
  registerAllComponents();

  final world = NexusWorld();
  final serializer = BinaryWorldSerializer(BinaryComponentFactory.I);

  const serverUrl = 'ws://127.0.0.1:5000';

  world.addSystems([
    // Core systems
    ResponsivenessSystem(),
    DebugSystem(),

    // Client-side prediction for ALL moving entities
    PhysicsSystem(),
    ClientTargetingSystem(), // Predicts meteor movement

    // Networking and Input
    NetworkSystem(serializer, serverUrl: serverUrl),
    PlayerControlSystem(), // Predicts our own player's movement

    // Visual smoothing and correction
    InterpolationSystem(), // For other players and meteors
    ReconciliationSystem(), // For our own player
  ]);

  world.rootEntity.addComponents([
    CustomWidgetComponent(widgetType: 'particle_canvas'),
    BlackboardComponent({'score': 0, 'local_player_id': null}),
    NetworkStateComponent(),
  ]);

  return world;
}
