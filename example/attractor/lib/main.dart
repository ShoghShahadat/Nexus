import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/core/serialization/binary_component_factory.dart';

import 'components/complex_movement_component.dart';
import 'components/debug_info_component.dart';
import 'components/explosion_component.dart';
import 'components/health_orb_component.dart';
import 'components/meteor_component.dart';
import 'components/network_components.dart';
import 'components/particle_render_data_component.dart';
import 'events.dart';
import 'network/mock_server.dart';
import 'particle_painter.dart';
import 'world/world_provider.dart';

/// Registers all custom components for JSON serialization.
void registerAttractorJsonComponents() {
  final customComponents = <String, ComponentFactory>{
    'ExplodingParticleComponent': (json) =>
        ExplodingParticleComponent.fromJson(json),
    'ComplexMovementComponent': (json) =>
        ComplexMovementComponent.fromJson(json),
    'MeteorComponent': (json) => MeteorComponent.fromJson(json),
    'HealthOrbComponent': (json) => HealthOrbComponent.fromJson(json),
    'ParticleRenderDataComponent': (json) =>
        ParticleRenderDataComponent.fromJson(json),
    'DebugInfoComponent': (json) => DebugInfoComponent.fromJson(json),
  };
  ComponentFactoryRegistry.I.registerAll(customComponents);
}

/// Registers all components enabled for binary network serialization.
void registerNetworkComponents() {
  final factory = BinaryComponentFactory.I;
  factory.register(1, () => PositionComponent());
  factory.register(2, () => PlayerComponent());
  factory.register(
      3,
      () =>
          HealthComponent(maxHealth: 0)); // Max health is server-authoritative
  factory.register(4, () => VelocityComponent());
}

void main() {
  // Register components for both JSON (for persistence/hot reload)
  // and Binary (for networking) serialization.
  registerCoreComponents();
  registerAttractorJsonComponents();
  registerNetworkComponents();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final FlutterRenderingSystem renderingSystem;
  MockServer? _server;

  @override
  void initState() {
    super.initState();

    // The NexusManager is now static in NexusWidget for debug builds,
    // so we can reliably access the world and its services after a hot reload.
    // We start the server in a post-frame callback to ensure the world is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final world = (renderingSystem.manager as NexusSingleThreadManager).world;
      if (world != null) {
        _server = world.services.get<MockServer>();
        _server?.start();
      }
    });

    renderingSystem = FlutterRenderingSystem(
      builders: {
        'particle_canvas': (context, id, controller, manager, child) {
          // --- UI LOGIC FOR MULTIPLAYER ---

          final rootId = controller.getAllIdsWithTag('root').firstOrNull;
          if (rootId == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Get network status
          final networkState = controller.get<NetworkStateComponent>(rootId);

          // Get all players and find the local one
          final playerEntities = controller.getAllIdsWithTag('player');
          final localPlayerEntityId =
              controller.getAllIdsWithTag('controlled_player').firstOrNull;

          final allPlayerPositions = playerEntities
              .map((id) => controller.get<PositionComponent>(id))
              .where((p) => p != null)
              .map((p) => Offset(p!.x, p.y))
              .toList();

          final localPlayerPos = localPlayerEntityId != null
              ? controller.get<PositionComponent>(localPlayerEntityId)
              : null;
          final localPlayerHealth = localPlayerEntityId != null
              ? controller.get<HealthComponent>(localPlayerEntityId)
              : null;

          // Get other game objects
          final meteorPositions = controller
              .getAllIdsWithTag('meteor')
              .map((id) => controller.get<PositionComponent>(id))
              .where((p) => p != null)
              .map((p) => Offset(p!.x, p.y))
              .toList();

          final healthOrbPositions = controller
              .getAllIdsWithTag('health_orb')
              .map((id) => controller.get<PositionComponent>(id))
              .where((p) => p != null)
              .map((p) => Offset(p!.x, p.y))
              .toList();

          final debugInfo = controller.get<DebugInfoComponent>(rootId);
          final blackboard = controller.get<BlackboardComponent>(rootId);
          final score = blackboard?.get<num>('score') ?? 0;
          final isGameOver =
              localPlayerHealth != null && localPlayerHealth.currentHealth <= 0;

          return Column(
            children: [
              // --- NETWORK STATUS BAR ---
              if (networkState != null && !networkState.isConnected)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: networkState.isConnected
                      ? Colors.green.shade900
                      : Colors.red.shade900,
                  child: Center(
                    child: Text(
                      networkState.statusMessage,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Score: $score',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: Stack(
                  children: [
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: ParticlePainter(
                          meteorPositions: meteorPositions,
                          healthOrbPositions: healthOrbPositions,
                          allPlayerPositions: allPlayerPositions,
                          localPlayerPosition: localPlayerPos != null
                              ? Offset(localPlayerPos.x, localPlayerPos.y)
                              : null,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    if (isGameOver)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(16)),
                          child: const Text(
                              'GAME OVER\nWaiting for next round...',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(blurRadius: 10, color: Colors.black)
                                  ])),
                        ),
                      ),
                  ],
                ),
              ),
              if (debugInfo != null) _DebugInfoBar(debugInfo: debugInfo),
              if (localPlayerHealth != null)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: LinearProgressIndicator(
                    value: (localPlayerHealth.currentHealth /
                            localPlayerHealth.maxHealth)
                        .clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade700,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                    minHeight: 10,
                  ),
                ),
            ],
          );
        },
      },
    );
  }

  @override
  void dispose() {
    _server?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1a1a1a),
        appBar: AppBar(
          title: const Text('Nexus Attractor: Multiplayer Edition'),
          backgroundColor: Colors.grey.shade900,
          foregroundColor: Colors.white,
        ),
        body: NexusWidget(
          // Use the new multiplayer world provider
          worldProvider: provideAttractorWorld,
          renderingSystem: renderingSystem,
        ),
      ),
    );
  }
}

// Helper Widgets
class _DebugInfoBar extends StatelessWidget {
  const _DebugInfoBar({required this.debugInfo});
  final DebugInfoComponent debugInfo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.black.withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _DebugStat(label: 'FPS', value: debugInfo.fps.toStringAsFixed(1)),
          _DebugStat(
              label: 'Frame',
              value: '${debugInfo.frameTime.toStringAsFixed(2)} ms'),
          _DebugStat(
              label: 'Entities', value: debugInfo.entityCount.toString()),
          const _DebugStat(
              label: 'Mode', value: 'Online', valueColor: Colors.cyanAccent),
        ],
      ),
    );
  }
}

class _DebugStat extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _DebugStat({
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
              color: valueColor, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
