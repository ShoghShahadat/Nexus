import 'package:nexus/nexus.dart';
import '../component_registration.dart';
import '../components/network_components.dart';
import '../systems/debug_system.dart';
import '../systems/network_system.dart';
import '../systems/player_control_system.dart';

// --- CLIENT WORLD PROVIDER ---
// This file now ONLY contains the logic for creating the CLIENT's world.
// All server-side logic, prefabs, and mock server dependencies have been removed
// to align with a true client-server architecture.

NexusWorld provideAttractorWorld() {
  // This function should be called once at the start of the app.
  registerCoreComponents();
  registerAllComponents();

  final world = NexusWorld();
  final serializer = BinaryWorldSerializer(BinaryComponentFactory.I);

  // --- CRITICAL FIX: Corrected the WebSocket server URL ---
  // The protocol is now 'wss' (WebSocket Secure) and the invalid port and fragment are removed.
  // This should match the address your Python server is running on.
  const serverUrl = 'wss://n8n.youapi.ir';

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
