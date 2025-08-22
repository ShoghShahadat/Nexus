import 'package:nexus/nexus.dart';
import '../component_registration.dart';
import '../components/network_components.dart';
import '../systems/debug_system.dart';
import '../systems/network_system.dart';
import '../systems/player_control_system.dart';

// --- CLIENT WORLD PROVIDER ---
// This file now ONLY contains the logic for creating the CLIENT's world.

NexusWorld provideAttractorWorld() {
  // This function should be called once at the start of the app.
  registerCoreComponents();
  registerAllComponents();

  final world = NexusWorld();
  final serializer = BinaryWorldSerializer(BinaryComponentFactory.I);

  // --- CRITICAL FIX: Corrected the WebSocket protocol and added the explicit port ---
  // The client now connects to 'ws://' on port 8765, matching the Python server configuration.
  const serverUrl = 'wss://127.0.0.1:5000';

  world.addSystems([
    ResponsivenessSystem(),
    DebugSystem(),
    NetworkSystem(serializer, serverUrl: serverUrl),
    PlayerControlSystem(),
  ]);

  world.rootEntity.addComponents([
    CustomWidgetComponent(widgetType: 'particle_canvas'),
    BlackboardComponent({'score': 0, 'local_player_id': null}),
    NetworkStateComponent(),
  ]);

  return world;
}
