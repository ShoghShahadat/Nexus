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
  counterDisplayEntity
      .add(PositionComponent(x: 80, y: 250, width: 250, height: 100));
  counterDisplayEntity.add(BlocComponent<CounterCubit, int>(counterCubit));
  // The entity starts with an initial state component.
  counterDisplayEntity.add(CounterStateComponent(counterCubit.state));
  counterDisplayEntity.add(WidgetComponent((context, entity) {
    // The builder now reads from the simple CounterStateComponent.
    // This is guaranteed to exist because the system adds it.
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

  // Buttons do not need to be reactive, so their widget is static.
  final incrementButtonEntity = Entity();
  incrementButtonEntity
      .add(PositionComponent(x: 220, y: 370, width: 110, height: 50));
  incrementButtonEntity.add(WidgetComponent(
    (context, entity) =>
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
    (context, entity) =>
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
            child: renderingSystem.build(context),
          ),
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
    // This `add` call updates the data, and the Entity's `add` method
    // correctly calls `notifyListeners` internally, triggering the
    // reactive UI update.
    entity.add(CounterStateComponent(state));
  }
}
