import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus_example/counter_cubit.dart';

// --- World Setup ---
NexusWorld setupWorld() {
  final world = NexusWorld();

  // 1. Systems
  // InputSystem is no longer needed for this UI logic.
  final renderingSystem = FlutterRenderingSystem();
  final counterSystem = _CounterDisplaySystem();

  world.addSystem(renderingSystem);
  world.addSystem(counterSystem);

  // 2. Shared State
  final counterCubit = CounterCubit();

  // 3. Entities & Components
  final counterDisplayEntity = Entity();
  counterDisplayEntity
      .add(PositionComponent(x: 80, y: 250, width: 250, height: 100));
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
  world.addEntity(counterDisplayEntity);

  // --- Button Entities (Refactored) ---

  // For widgets like ElevatedButton, it's more direct and reliable to use
  // the built-in `onPressed` callback. This avoids gesture conflicts.
  // Therefore, ClickableComponent and InputSystem are removed from this flow.

  final incrementButtonEntity = Entity();
  incrementButtonEntity
      .add(PositionComponent(x: 220, y: 370, width: 110, height: 50));
  incrementButtonEntity.add(WidgetComponent(
    (context, entity) => ElevatedButton(
      // Directly call the cubit method from the button's callback.
      onPressed: counterCubit.increment,
      child: const Icon(Icons.add),
    ),
  ));
  // ClickableComponent is no longer needed.
  world.addEntity(incrementButtonEntity);

  final decrementButtonEntity = Entity();
  decrementButtonEntity
      .add(PositionComponent(x: 80, y: 370, width: 110, height: 50));
  decrementButtonEntity.add(WidgetComponent(
    (context, entity) => ElevatedButton(
      // Directly call the cubit method from the button's callback.
      onPressed: counterCubit.decrement,
      child: const Icon(Icons.remove),
    ),
  ));
  // ClickableComponent is no longer needed.
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
        // The GestureDetector is no longer needed as the buttons handle their own taps.
        body: NexusWidget(
          world: world,
          child: renderingSystem.build(context),
        ),
      ),
    );
  }
}

/// The system now has a single, clear responsibility:
/// Listen to the BLoC and update the data component.
class _CounterDisplaySystem extends BlocSystem<CounterCubit, int> {
  @override
  void onStateChange(Entity entity, int state) {
    entity.add(CounterStateComponent(state));
  }
}
