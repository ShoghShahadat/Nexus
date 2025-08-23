import 'package:attractor_example/components/network_components.dart';
import 'package:nexus/nexus.dart';
import '../component_registration.dart';
import '../systems/client_logic_systems.dart';
import '../systems/client_spawner_system.dart';
import '../systems/debug_system.dart';
import '../systems/network_system.dart';
import '../systems/p2p_sync_system.dart';
import '../systems/player_control_system.dart';

NexusWorld provideAttractorWorld() {
  registerCoreComponents();
  registerAllComponents();

  final world = NexusWorld();
  final serializer = BinaryWorldSerializer(BinaryComponentFactory.I);
  const serverUrl = 'ws://127.0.0.1:5000';

  world.addSystems([
    // Core & UI Systems
    ResponsivenessSystem(),
    DebugSystem(),
    PlayerControlSystem(),
    NetworkSystem(serializer, serverUrl: serverUrl),

    // P2P Game Logic Systems (run on all clients)
    PhysicsSystem(),
    P2pSyncSystem(),
    CollisionSystem(),
    DamageSystem(),
    TargetingSystem(),

    // Host-Only Systems
    ClientGameLogicSystem(),
    ClientSpawnerSystem(),
  ]);

  // --- CLEANUP: The LifecyclePolicyComponent is now added automatically by createSpawner. ---
  // --- پاکسازی: کامپوننت LifecyclePolicy اکنون به صورت خودکار توسط createSpawner اضافه می‌شود. ---
  world.createSpawner(
    prefab: () => Entity(),
    frequency: Frequency.perSecond(1.5),
    tag: 'meteor_spawner',
  );

  world.rootEntity.addComponents([
    CustomWidgetComponent(widgetType: 'particle_canvas'),
    BlackboardComponent({'score': 0, 'local_player_id': null}),
    NetworkStateComponent(),
  ]);

  return world;
}
