import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nexus/nexus.dart';
import 'package:collection/collection.dart';
import 'package:get_it/get_it.dart';

import 'components/complex_movement_component.dart';
import 'components/explosion_component.dart';
import 'components/meteor_component.dart';
import 'components/meteor_target_component.dart';
import 'events.dart';
// --- FIX: Import the correct, enhanced painter ---
// --- اصلاح: ایمپورت کردن نقاش صحیح و بهبود یافته ---
import 'particle_painter.dart';

import 'world/world_provider.dart';

void main() {
  registerCoreComponents();
  ComponentFactoryRegistry.I
      .register('HealthComponent', (json) => HealthComponent.fromJson(json));
  ComponentFactoryRegistry.I.register('ExplodingParticleComponent',
      (json) => ExplodingParticleComponent.fromJson(json));
  ComponentFactoryRegistry.I.register('ComplexMovementComponent',
      (json) => ComplexMovementComponent.fromJson(json));
  ComponentFactoryRegistry.I
      .register('MeteorComponent', (json) => MeteorComponent.fromJson(json));
  ComponentFactoryRegistry.I.register(
      'MeteorTargetComponent', (json) => MeteorTargetComponent.fromJson(json));
  ComponentFactoryRegistry.I.register(
      'InputFocusComponent', (json) => InputFocusComponent.fromJson(json));
  ComponentFactoryRegistry.I.register('KeyboardInputComponent',
      (json) => KeyboardInputComponent.fromJson(json));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final renderingSystem = FlutterRenderingSystem(
      builders: {
        'particle_canvas': (context, id, controller, manager, child) {
          final particleIds = controller.getAllIdsWithTag('particle');
          final meteorIds = controller.getAllIdsWithTag('meteor');
          final attractorId =
              controller.getAllIdsWithTag('attractor').firstOrNull;
          final rootId = controller.getAllIdsWithTag('root').firstOrNull;

          if (attractorId == null || rootId == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final blackboard = controller.get<BlackboardComponent>(rootId);
          final health = controller.get<HealthComponent>(attractorId);

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
                        // --- FIX: Use the correct painter ---
                        // --- اصلاح: استفاده از نقاش صحیح ---
                        painter: ParticlePainter(
                          particleIds: particleIds,
                          meteorIds: meteorIds,
                          attractorId: attractorId,
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

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1a1a1a),
        appBar: AppBar(
          title: const Text('Nexus Attractor: Survival'),
          backgroundColor: Colors.grey.shade900,
          foregroundColor: Colors.white,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return NexusWidget(
              worldProvider: () {
                final world = provideAttractorWorld();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  world.eventBus.fire(ScreenResizeEvent(
                      constraints.maxWidth, constraints.maxHeight));
                });
                return world;
              },
              renderingSystem: renderingSystem,
            );
          },
        ),
      ),
    );
  }
}
