import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';

import 'components/complex_movement_component.dart';
import 'components/explosion_component.dart';
import 'components/health_orb_component.dart';
import 'components/meteor_component.dart';
import 'events.dart';
import 'particle_painter.dart';
import 'world/world_provider.dart';
import 'components/gpu_particle_render_component.dart'; // Import the new component

/// A dedicated function to register all custom components for this example.
void registerAttractorComponents() {
  final customComponents = <String, ComponentFactory>{
    'HealthComponent': (json) => HealthComponent.fromJson(json),
    'ExplodingParticleComponent': (json) =>
        ExplodingParticleComponent.fromJson(json),
    'ComplexMovementComponent': (json) =>
        ComplexMovementComponent.fromJson(json),
    'MeteorComponent': (json) => MeteorComponent.fromJson(json),
    'HealthOrbComponent': (json) => HealthOrbComponent.fromJson(json),
    'InputFocusComponent': (json) => InputFocusComponent.fromJson(json),
    'KeyboardInputComponent': (json) => KeyboardInputComponent.fromJson(json),
    'CollisionComponent': (json) => CollisionComponent.fromJson(json),
    'DamageComponent': (json) => DamageComponent.fromJson(json),
    'TargetingComponent': (json) => TargetingComponent.fromJson(json),
    // Register the new GPU render component
    'GpuParticleRenderComponent': (json) =>
        GpuParticleRenderComponent.fromJson(json),
  };
  ComponentFactoryRegistry.I.registerAll(customComponents);
}

void main() {
  // Register core library components
  registerCoreComponents();
  // Register components specific to this example
  registerAttractorComponents();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final FlutterRenderingSystem renderingSystem;

  @override
  void initState() {
    super.initState();
    renderingSystem = FlutterRenderingSystem(
      builders: {
        'particle_canvas': (context, id, controller, manager, child) {
          final attractorId =
              controller.getAllIdsWithTag('attractor').firstOrNull;
          final rootId = controller.getAllIdsWithTag('root').firstOrNull;

          if (attractorId == null || rootId == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final blackboard = controller.get<BlackboardComponent>(rootId);
          final health = controller.get<HealthComponent>(attractorId);
          // Get the particle data directly from the new component on the root entity
          final gpuRenderData =
              controller.get<GpuParticleRenderComponent>(rootId);

          final score = blackboard?.get<num>('score') ?? 0;
          final currentHealth = health?.currentHealth ?? 0;
          final maxHealth = health?.maxHealth ?? 100;
          final isGameOver = blackboard?.get<bool>('is_game_over') ?? false;
          final countdown = blackboard?.get<double>('restart_countdown') ?? 0.0;

          return Column(
            children: [
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
                          // Pass the raw GPU data to the painter
                          gpuParticleData: gpuRenderData?.particleData,
                          meteorIds: controller.getAllIdsWithTag('meteor'),
                          attractorId: attractorId,
                          healthOrbIds:
                              controller.getAllIdsWithTag('health_orb'),
                          controller: controller,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    if (isGameOver)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('GAME OVER',
                                style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                          blurRadius: 10, color: Colors.black)
                                    ])),
                            const SizedBox(height: 20),
                            if (countdown > 0)
                              Text('Restarting in ${countdown.ceil()}...',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 20)),
                            if (countdown <= 0)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.greenAccent,
                                    foregroundColor: Colors.black),
                                onPressed: () {
                                  manager.send(RestartGameEvent());
                                },
                                child: const Text('Start Again'),
                              )
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: LinearProgressIndicator(
                  value: (currentHealth / maxHealth).clamp(0.0, 1.0),
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
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1a1a1a),
        appBar: AppBar(
          title: const Text('Nexus Attractor: GPU Edition'),
          backgroundColor: Colors.grey.shade900,
          foregroundColor: Colors.white,
        ),
        body: NexusWidget(
          worldProvider: provideAttractorWorld,
          renderingSystem: renderingSystem,
        ),
      ),
    );
  }
}
