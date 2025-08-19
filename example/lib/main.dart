import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus_example/counter_cubit.dart';

// --- World Setup ---
NexusWorld setupWorld() {
  final world = NexusWorld();

  // 1. Systems
  final renderingSystem = FlutterRenderingSystem();
  final counterSystem = _CounterDisplaySystem();
  final animationSystem = AnimationSystem();
  final physicsSystem = PhysicsSystem(); // Add the new system

  world.addSystem(renderingSystem);
  world.addSystem(counterSystem);
  world.addSystem(animationSystem);
  world.addSystem(physicsSystem); // Add the new system

  // 2. Shared State
  final counterCubit = CounterCubit();

  // 3. Entities & Components
  final counterDisplayEntity = Entity();
  counterDisplayEntity
      .add(PositionComponent(x: 80, y: 250, width: 250, height: 100, scale: 0));
  counterDisplayEntity.add(BlocComponent<CounterCubit, int>(counterCubit));
  counterDisplayEntity.add(CounterStateComponent(counterCubit.state));
  counterDisplayEntity.add(WidgetComponent((context, entity) {
    final stateComponent = entity.get<CounterStateComponent>()!;
    final state = stateComponent.value;

    return Material(
      key: ValueKey(state),
      elevation: 4.0,
      borderRadius: BorderRadius.circular(12),
      color: state >= 0 ? Colors.deepPurple : Colors.redAccent,
      child: Center(
        child: Text(
          'Count: $state',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }));

  // Add an animation to make the counter "pop in" on start
  counterDisplayEntity.add(AnimationComponent(
    duration: const Duration(milliseconds: 600),
    curve: Curves.easeOutBack,
    onUpdate: (entity, value) {
      final pos = entity.get<PositionComponent>();
      if (pos != null) {
        pos.scale = value;
        entity.add(pos);
      }
    },
    // When the animation is complete, give the entity a downward velocity.
    onComplete: (entity) {
      entity.add(
          VelocityComponent(x: 0, y: 50)); // 50 pixels per second downwards
    },
  ));

  world.addEntity(counterDisplayEntity);

  // --- Button Entities ---
  final incrementButtonEntity = Entity();
  incrementButtonEntity
      .add(PositionComponent(x: 220, y: 370, width: 110, height: 50));
  incrementButtonEntity.add(WidgetComponent(
    (context, entity) => ElevatedButton(
      onPressed: counterCubit.increment,
      child: const Icon(Icons.add),
    ),
  ));
  world.addEntity(incrementButtonEntity);

  final decrementButtonEntity = Entity();
  decrementButtonEntity
      .add(PositionComponent(x: 80, y: 370, width: 110, height: 50));
  decrementButtonEntity.add(WidgetComponent(
    (context, entity) => ElevatedButton(
      onPressed: counterCubit.decrement,
      child: const Icon(Icons.remove),
    ),
  ));
  world.addEntity(decrementButtonEntity);

  return world;
}

void main() {
  runApp(MyApp(world: setupWorld()));
}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  final NexusWorld world;

  const MyApp({super.key, required this.world});

  @override
  Widget build(BuildContext context) {
    final renderingSystem =
        world.systems.firstWhere((s) => s is FlutterRenderingSystem)
            as FlutterRenderingSystem;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          title: const Text('Nexus Counter Example',
              style: TextStyle(color: Colors.white)),
        ),
        body: NexusWidget(
          world: world,
          child: renderingSystem.build(context),
        ),
      ),
    );
  }
}

/// The system that updates the counter's data component.
class _CounterDisplaySystem extends BlocSystem<CounterCubit, int> {
  @override
  void onStateChange(Entity entity, int state) {
    entity.add(CounterStateComponent(state));
  }
}
