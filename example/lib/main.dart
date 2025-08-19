import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus_example/counter_cubit.dart';

// --- World Setup ---
NexusWorld setupWorld() {
  final world = NexusWorld();

  // 1. Systems
  final renderingSystem = FlutterRenderingSystem();
  final inputSystem = InputSystem();
  final counterSystem = _CounterDisplaySystem();

  world.addSystem(renderingSystem);
  world.addSystem(inputSystem);
  world.addSystem(counterSystem);

  // 2. Shared State
  final counterCubit = CounterCubit();

  // 3. Entities & Components
  final counterDisplayEntity = Entity();
  // IMPORTANT: We connect the entity's change signal to the world's notifier.
  counterDisplayEntity.onComponentChanged = world.worldNotifier.notifyListeners;

  counterDisplayEntity
      .add(PositionComponent(x: 80, y: 250, width: 250, height: 100));
  counterDisplayEntity.add(WidgetComponent(const CircularProgressIndicator()));
  counterDisplayEntity.add(BlocComponent(counterCubit));
  world.addEntity(counterDisplayEntity);

  final incrementButtonEntity = Entity();
  incrementButtonEntity
      .add(PositionComponent(x: 220, y: 370, width: 110, height: 50));
  incrementButtonEntity.add(WidgetComponent(
    ElevatedButton(onPressed: () {}, child: const Icon(Icons.add)),
  ));
  incrementButtonEntity.add(ClickableComponent((entity) {
    counterCubit.increment();
  }));
  world.addEntity(incrementButtonEntity);

  final decrementButtonEntity = Entity();
  decrementButtonEntity
      .add(PositionComponent(x: 80, y: 370, width: 110, height: 50));
  decrementButtonEntity.add(WidgetComponent(
    ElevatedButton(onPressed: () {}, child: const Icon(Icons.remove)),
  ));
  decrementButtonEntity.add(ClickableComponent((entity) {
    counterCubit.decrement();
  }));
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
    final inputSystem =
        world.systems.firstWhere((s) => s is InputSystem) as InputSystem;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          title: const Text('Nexus Counter Example',
              style: TextStyle(color: Colors.white)),
        ),
        body: GestureDetector(
          onTapDown: inputSystem.handleTapDown,
          child: NexusWidget(
            world: world,
            builder: (context, world) {
              return renderingSystem.build(context);
            },
          ),
        ),
      ),
    );
  }
}

/// A custom system that listens to the CounterCubit's state and updates
/// the entity's WidgetComponent to display the new count.
class _CounterDisplaySystem extends BlocSystem {
  @override
  void onStateChange(Entity entity, dynamic state) {
    if (state is int) {
      // This `add` call will now trigger the `onComponentChanged` callback
      // on the entity, which in turn notifies the world, and finally,
      // the NexusWidget rebuilds the UI.
      entity.add(WidgetComponent(
        Material(
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
        ),
      ));
    }
  }
}
