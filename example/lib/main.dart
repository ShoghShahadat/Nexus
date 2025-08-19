import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus_example/counter_cubit.dart';

// --- World Setup ---
// We've moved the world creation logic into its own function for clarity.
NexusWorld setupWorld() {
  final world = NexusWorld();

  // 1. Systems
  // Systems are the brains of the application.
  final renderingSystem = FlutterRenderingSystem();
  final inputSystem = InputSystem();
  final counterSystem = _CounterDisplaySystem();

  world.addSystem(renderingSystem);
  world.addSystem(inputSystem);
  world.addSystem(counterSystem);

  // 2. Shared State
  // The CounterCubit is shared between multiple entities.
  final counterCubit = CounterCubit();

  // 3. Entities & Components
  // Each entity is a collection of data components.

  // The entity that displays the counter value.
  final counterDisplayEntity = Entity();
  counterDisplayEntity
      .add(PositionComponent(x: 80, y: 250, width: 250, height: 100));
  counterDisplayEntity.add(
      WidgetComponent(const CircularProgressIndicator())); // Initial widget
  counterDisplayEntity.add(BlocComponent(counterCubit)); // Links to the BLoC
  world.addEntity(counterDisplayEntity);

  // The entity for the "Increment" button.
  final incrementButtonEntity = Entity();
  incrementButtonEntity
      .add(PositionComponent(x: 220, y: 370, width: 110, height: 50));
  incrementButtonEntity.add(WidgetComponent(
    ElevatedButton(onPressed: () {}, child: const Icon(Icons.add)),
  ));
  incrementButtonEntity.add(ClickableComponent((entity) {
    // On tap, we find the cubit and call its method.
    counterCubit.increment();
  }));
  world.addEntity(incrementButtonEntity);

  // The entity for the "Decrement" button.
  final decrementButtonEntity = Entity();
  decrementButtonEntity
      .add(PositionComponent(x: 80, y: 370, width: 110, height: 50));
  decrementButtonEntity.add(WidgetComponent(
    ElevatedButton(onPressed: () {}, child: const Icon(Icons.remove)),
  ));
  decrementButtonEntity.add(ClickableComponent((entity) {
    // It interacts with the *same* cubit instance.
    counterCubit.decrement();
  }));
  world.addEntity(decrementButtonEntity);

  return world;
}

void main() {
  final world = setupWorld();
  runApp(MyApp(world: world));
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
      // --- FIX ---
      // The widget is simplified to a single Material widget.
      // Applying color and borderRadius directly to Material avoids layout
      // conflicts that can occur when nesting it with a decorated Container.
      entity.add(WidgetComponent(
        Material(
          key: ValueKey(state), // Add a key for better widget reconciliation
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
