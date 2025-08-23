// ==============================================================================
// File: lib/world/world_provider.dart
// Author: Your Intelligent Assistant
// Version: 8.0
// Description: Provides the configured NexusWorld for the client application.
// Changes:
// - FIX: Added the missing LifecyclePolicyComponent to the local player entity
//   to remove the console warnings during startup.
// ==============================================================================

import 'package:nexus/nexus.dart' hide SpawnerComponent, LifecycleComponent;
import '../component_registration.dart';
import '../components/network_components.dart';
import '../components/server_logic_components.dart';
import '../systems/debug_system.dart';
import '../systems/game_logic_systems.dart';
import '../systems/network_system.dart';
import '../systems/player_control_system.dart';
import '../systems/client_targeting_system.dart';

/// Provides the configured NexusWorld for the client application.
NexusWorld provideAttractorWorld() {
  registerCoreComponents();
  registerAllComponents();

  final world = NexusWorld();
  final serializer = BinaryWorldSerializer(BinaryComponentFactory.I);

  const serverUrl = 'ws://127.0.0.1:5000';

  // The client now runs the full simulation
  world.addSystems([
    // Core systems
    ResponsivenessSystem(),
    DebugSystem(),

    // Input and Player control
    PlayerControlSystem(),

    // All Game Logic now runs on the Client
    ClientSpawnerSystem(),
    DynamicDifficultySystem(),
    MeteorLifecycleSystem(),
    ClientTargetingSystem(),
    PhysicsSystem(),
    CollisionSystem(),
    GameRulesSystem(),

    // Networking
    NetworkSystem(serializer, serverUrl: serverUrl),
  ]);

  // Create the local player entity
  final player = Entity()
    ..add(OwnedComponent())
    ..add(ControlledPlayerComponent())
    ..add(TagsComponent({'player'}))
    ..add(PositionComponent(x: 400, y: 500, width: 20, height: 20))
    ..add(VelocityComponent())
    ..add(HealthComponent(maxHealth: 100))
    // --- FIX: Added LifecyclePolicyComponent to prevent warnings ---
    ..add(LifecyclePolicyComponent(isPersistent: true));
  world.addEntity(player);

  world.rootEntity.addComponents([
    CustomWidgetComponent(widgetType: 'particle_canvas'),
    BlackboardComponent({
      'score': 0,
      'local_player_id': player.id // Set local player ID immediately
    }),
    NetworkStateComponent(),
  ]);

  return world;
}
