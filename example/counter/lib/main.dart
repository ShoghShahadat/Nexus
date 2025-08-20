import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus_example/counter_cubit.dart';

// --- NEW: Define a custom event for counter updates ---
class CounterUpdatedEvent {
  final int newValue;
  CounterUpdatedEvent(this.newValue);
}

// --- NEW: Define a simple component to tag the entity for UI changes ---
class WarningTagComponent extends Component with SerializableComponent {
  WarningTagComponent();

  factory WarningTagComponent.fromJson(Map<String, dynamic> json) =>
      WarningTagComponent();

  @override
  Map<String, dynamic> toJson() => {};

  @override
  List<Object?> get props => [];
}

/// تابع اصلی که NexusWorld را برای Isolate پس‌زمینه فراهم می‌کند.
NexusWorld provideCounterWorld() {
  final world = NexusWorld();

  // 1. ثبت سرویس‌ها
  final cubit = CounterCubit();
  world.services.registerSingleton(cubit);

  // 2. افزودن سیستم‌ها
  world.addSystem(CounterSystem());
  world.addSystem(InputSystem());
  world.addSystem(HistorySystem());
  world.addSystem(RuleSystem()); // NEW: Add the rule system

  // 3. ایجاد موجودیت‌ها

  // موجودیت برای نمایشگر شمارنده
  final counterDisplay = Entity();
  counterDisplay
      .add(PositionComponent(x: 100, y: 200, width: 200, height: 100));
  counterDisplay.add(BlocComponent<CounterCubit, int>(cubit));
  counterDisplay.add(CounterStateComponent(cubit.state));
  counterDisplay.add(TagsComponent({'counter_display'}));
  counterDisplay.add(HistoryComponent(
    trackedComponents: {'CounterStateComponent'},
  ));

  // --- NEW: Add the RuleComponent ---
  counterDisplay.add(RuleComponent(
    triggers: {CounterUpdatedEvent}, // Listen for our custom event
    condition: (entity, event) {
      // The condition checks the value from the event
      final counterEvent = event as CounterUpdatedEvent;
      final isWarning = counterEvent.newValue > 5;
      final hasWarningTag = entity.has<WarningTagComponent>();
      // Return true only if the state needs to change
      return isWarning != hasWarningTag;
    },
    actions: (entity, event) {
      final counterEvent = event as CounterUpdatedEvent;
      if (counterEvent.newValue > 5) {
        // Add a warning tag if value is high
        entity.add(WarningTagComponent());
        print("Rule Applied: Added WarningTagComponent");
      } else {
        // Remove the warning tag if value is low
        entity.remove<WarningTagComponent>();
        print("Rule Applied: Removed WarningTagComponent");
      }
    },
  ));
  // --- END NEW ---

  world.addEntity(counterDisplay);

  // موجودیت برای دکمه افزایش
  final incrementButton = Entity();
  incrementButton.add(PositionComponent(x: 210, y: 320, width: 80, height: 50));
  incrementButton.add(ClickableComponent((_) => cubit.increment()));
  incrementButton.add(TagsComponent({'increment_button'}));
  world.addEntity(incrementButton);

  // موجودیت برای دکمه کاهش
  final decrementButton = Entity();
  decrementButton.add(PositionComponent(x: 110, y: 320, width: 80, height: 50));
  decrementButton.add(ClickableComponent((_) => cubit.decrement()));
  decrementButton.add(TagsComponent({'decrement_button'}));
  world.addEntity(decrementButton);

  // دکمه‌های Undo/Redo
  final undoButton = Entity();
  undoButton.add(PositionComponent(x: 110, y: 380, width: 80, height: 50));
  undoButton.add(ClickableComponent(
      (_) => world.eventBus.fire(UndoEvent(counterDisplay.id))));
  undoButton.add(TagsComponent({'undo_button'}));
  world.addEntity(undoButton);

  final redoButton = Entity();
  redoButton.add(PositionComponent(x: 210, y: 380, width: 80, height: 50));
  redoButton.add(ClickableComponent(
      (_) => world.eventBus.fire(RedoEvent(counterDisplay.id))));
  redoButton.add(TagsComponent({'redo_button'}));
  world.addEntity(redoButton);

  return world;
}

/// نقطه شروع برنامه Flutter.
void main() {
  registerCoreComponents();
  // --- NEW: Register our new serializable component ---
  ComponentFactoryRegistry.I.register(
      'WarningTagComponent', (json) => WarningTagComponent.fromJson(json));
  runApp(const MyApp());
}

/// ویجت اصلی برنامه.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final renderingSystem = FlutterRenderingSystem(
      builders: {
        'counter_display': (context, id, controller, manager) {
          final state = controller.get<CounterStateComponent>(id);
          // --- NEW: Check for the warning tag ---
          final hasWarning = controller.get<WarningTagComponent>(id) != null;
          if (state == null) return const SizedBox.shrink();

          return Material(
            color: Colors.transparent,
            child: Center(
              child: Text(
                '${state.value}',
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  // Change color based on the warning tag
                  color: hasWarning ? Colors.redAccent : Colors.black,
                ),
              ),
            ),
          );
        },
        'increment_button': (context, id, controller, manager) {
          return ElevatedButton(
            onPressed: () => manager.send(EntityTapEvent(id)),
            child: const Icon(Icons.add),
          );
        },
        'decrement_button': (context, id, controller, manager) {
          return ElevatedButton(
            onPressed: () => manager.send(EntityTapEvent(id)),
            child: const Icon(Icons.remove),
          );
        },
        'undo_button': (context, id, controller, manager) {
          final counterId =
              controller.getAllIdsWithTag('counter_display').first;
          final history = controller.get<HistoryComponent>(counterId);
          final canUndo = history?.canUndo ?? false;

          return ElevatedButton(
            onPressed: canUndo ? () => manager.send(EntityTapEvent(id)) : null,
            child: const Icon(Icons.undo),
          );
        },
        'redo_button': (context, id, controller, manager) {
          final counterId =
              controller.getAllIdsWithTag('counter_display').first;
          final history = controller.get<HistoryComponent>(counterId);
          final canRedo = history?.canRedo ?? false;

          return ElevatedButton(
            onPressed: canRedo ? () => manager.send(EntityTapEvent(id)) : null,
            child: const Icon(Icons.redo),
          );
        },
      },
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Nexus Counter Example'),
        ),
        body: NexusWidget(
          worldProvider: provideCounterWorld,
          renderingSystem: renderingSystem,
          // --- NEW: Add initializer for the new component ---
          isolateInitializer: () {
            ComponentFactoryRegistry.I.register('WarningTagComponent',
                (json) => WarningTagComponent.fromJson(json));
          },
        ),
      ),
    );
  }
}

/// سیستمی که به تغییرات وضعیت در CounterCubit گوش می‌دهد.
class CounterSystem extends BlocSystem<CounterCubit, int> {
  @override
  void onStateChange(Entity entity, int state) {
    final currentState = entity.get<CounterStateComponent>();
    if (currentState == null || currentState.value != state) {
      entity.add(CounterStateComponent(state));
      // --- NEW: Fire a custom event when the counter changes ---
      world.eventBus.fire(CounterUpdatedEvent(state));
    }
  }
}
