// ==============================================================================
// File: lib/world/world_provider.dart
// Author: Your Intelligent Assistant
// Version: 12.0
// Description: Provides the configured NexusWorld for the client application.
// Changes:
// - ADDED: The new `ScoreComponent` is now added to the local player entity
//   on creation, enabling score tracking and synchronization.
// ==============================================================================

import 'package:nexus/nexus.dart' hide SpawnerComponent, LifecycleComponent;
import '../component_registration.dart';
import '../components/network_components.dart';
import '../components/score_component.dart'; // Import the new component
import '../components/server_logic_components.dart';
import '../systems/debug_system.dart';
import '../systems/game_logic_systems.dart';
import '../systems/interpolation_system.dart';
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

  world.addSystems([
    ResponsivenessSystem(),
    DebugSystem(),
    PlayerControlSystem(),
    InterpolationSystem(),
    ClientSpawnerSystem(),
    DynamicDifficultySystem(),
    MeteorLifecycleSystem(),
    ClientTargetingSystem(),
    PhysicsSystem(),
    CollisionSystem(),
    GameRulesSystem(),
    NetworkSystem(serializer, serverUrl: serverUrl),
  ]);

  final player = Entity()
    ..add(OwnedComponent())
    ..add(ControlledPlayerComponent())
    ..add(PlayerComponent(sessionId: 'local', isLocalPlayer: true))
    ..add(
        TagsComponent({'player', 'root'})) // Add 'root' tag for network system
    ..add(PositionComponent(x: 400, y: 500, width: 20, height: 20))
    ..add(VelocityComponent())
    ..add(HealthComponent(maxHealth: 100))
    ..add(ScoreComponent(score: 0)) // Add the new ScoreComponent
    ..add(LifecyclePolicyComponent(isPersistent: true));
  world.addEntity(player);

  world.rootEntity.addComponents([
    CustomWidgetComponent(widgetType: 'particle_canvas'),
    BlackboardComponent({'local_player_id': player.id}),
    NetworkStateComponent(),
    TagsComponent({'root'}),
  ]);

  return world;
}
