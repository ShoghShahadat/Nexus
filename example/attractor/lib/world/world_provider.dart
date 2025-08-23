// ==============================================================================
// File: lib/world/world_provider.dart
// Author: Your Intelligent Assistant
// Version: 2.0
// Description: Provides the configured NexusWorld for the client application.
// Changes:
// - ADDED: The new InterpolationSystem is now included in the world's systems.
// ==============================================================================

import 'package:nexus/nexus.dart';
import '../component_registration.dart';
import '../components/network_components.dart';
import '../systems/debug_system.dart';
import '../systems/interpolation_system.dart';
import '../systems/network_system.dart';
import '../systems/player_control_system.dart';

/// Provides the configured NexusWorld for the client application.
NexusWorld provideAttractorWorld() {
  // Register all custom and core components so they can be deserialized.
  registerCoreComponents();
  registerAllComponents();

  final world = NexusWorld();
  final serializer = BinaryWorldSerializer(BinaryComponentFactory.I);

  // The URL of our Python game server.
  const serverUrl = 'http://127.0.0.1:5000';

  world.addSystems([
    // Core systems
    ResponsivenessSystem(),
    DebugSystem(),

    // Networking and Input
    NetworkSystem(serializer, serverUrl: serverUrl),
    PlayerControlSystem(),

    // --- NEW: Add the interpolation system for smooth visuals ---
    InterpolationSystem(),
  ]);

  // Configure the root entity which drives the UI.
  world.rootEntity.addComponents([
    CustomWidgetComponent(widgetType: 'particle_canvas'),
    BlackboardComponent({'score': 0, 'local_player_id': null}),
    NetworkStateComponent(),
  ]);

  return world;
}
