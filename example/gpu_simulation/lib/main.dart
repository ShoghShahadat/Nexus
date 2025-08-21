import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';

// --- NEW: Event for toggling the simulation ---
class ToggleSimulationEvent {}

// 1. Define the data structure for a single particle as a Component.
class ParticleComponent extends Component {
  final Vec2 position;
  final Vec2 velocity;

  ParticleComponent({required this.position, required this.velocity});

  @override
  List<Object?> get props => [position, velocity];
}

// A simple 2D vector class.
class Vec2 with EquatableMixin {
  double x, y;
  Vec2(this.x, this.y);

  @override
  List<Object?> get props => [x, y];
}

// 2. Create the GpuSystem by extending the base class.
class ParticleGpuSystem extends GpuSystem<ParticleComponent> {
  final int particleCount;

  ParticleGpuSystem({this.particleCount = 8000000});

  @override
  List<ParticleComponent> initializeData() {
    final random = Random();
    return List.generate(particleCount, (i) {
      return ParticleComponent(
        position: Vec2(
            random.nextDouble() * 2.0 - 1.0, random.nextDouble() * 2.0 - 1.0),
        velocity: Vec2(0, 0),
      );
    });
  }

  // 3. Write the logic for a SINGLE particle in Dart.
  @override
  void gpuLogic(ParticleComponent p, GpuKernelContext ctx) {
    // This is a placeholder. The actual transpiler would analyze this code.
    // This logic matches the pre-compiled shader in our Rust core.
    final dist =
        sqrt(p.position.x * p.position.x + p.position.y * p.position.y);

    if (dist > 0.01) {
      final perpDirX = -p.position.y / dist;
      final perpDirY = p.position.x / dist;

      final vortexStrength = 5.0;
      final vortexForce = vortexStrength / (dist + 0.1);
      p.velocity.x += perpDirX * vortexForce * ctx.deltaTime;
      p.velocity.y += perpDirY * vortexForce * ctx.deltaTime;
    }

    p.velocity.y -= 1.0 * ctx.deltaTime;
    p.position.x += p.velocity.x * ctx.deltaTime;
    p.position.y += p.velocity.y * ctx.deltaTime;
  }
}

/// A simple manager system to run the simulation and update the UI.
class SimulationManagerSystem extends System {
  late final ParticleGpuSystem _gpuSystem;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    _gpuSystem = world.systems.whereType<ParticleGpuSystem>().first;
    // --- FIX: Listen for the toggle event ---
    world.eventBus.on<ToggleSimulationEvent>(_onToggle);
  }

  void _onToggle(ToggleSimulationEvent event) {
    final root = world.rootEntity;
    final bb = root.get<BlackboardComponent>()!;
    bb.toggle('isRunning');
    root.add(bb);
  }

  @override
  bool matches(Entity entity) =>
      entity.get<TagsComponent>()?.hasTag('root') ?? false;

  @override
  void update(Entity entity, double dt) {
    final blackboard = entity.get<BlackboardComponent>()!;
    if (blackboard.get<bool>('isRunning') ?? false) {
      final gpuTime = _gpuSystem.compute(dt);
      blackboard.set('lastGpuTime', gpuTime);
      entity.add(blackboard);
    }
  }
}

void main() {
  // --- FIX: Register all core components before running the app ---
  registerCoreComponents();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  NexusWorld provideWorld() {
    final world = NexusWorld();
    world.addSystem(ParticleGpuSystem());
    world.addSystem(SimulationManagerSystem());

    world.rootEntity.add(CustomWidgetComponent(widgetType: 'main_view'));
    world.rootEntity.add(BlackboardComponent({
      'isRunning': false,
      'lastGpuTime': 0,
    }));

    return world;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('NexusCompute Final API')),
        body: NexusWidget(
          worldProvider: provideWorld,
          renderingSystem: FlutterRenderingSystem(
            builders: {
              'main_view': (context, id, controller, manager, child) {
                final blackboard = controller.get<BlackboardComponent>(id);
                final isRunning = blackboard?.get<bool>('isRunning') ?? false;
                final gpuTime = blackboard?.get<num>('lastGpuTime') ?? 0;

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Simulating 8,000,000 Particles',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 24),
                      if (gpuTime > 0)
                        Text(
                          'GPU Frame Time: $gpuTime µs',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          // --- FIX: Send an event instead of direct access ---
                          manager.send(ToggleSimulationEvent());
                        },
                        child: Text(
                            isRunning ? 'Stop Simulation' : 'Start Simulation'),
                      ),
                    ],
                  ),
                );
              },
            },
          ),
        ),
      ),
    );
  }
}
