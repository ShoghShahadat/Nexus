import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus_example/counter_cubit.dart';

// --- Events & Custom Components for the example ---
class CounterUpdatedEvent {
  final int newValue;
  CounterUpdatedEvent(this.newValue);
}

class WarningTagComponent extends Component with SerializableComponent {
  WarningTagComponent();
  factory WarningTagComponent.fromJson(Map<String, dynamic> json) =>
      WarningTagComponent();
  @override
  Map<String, dynamic> toJson() => {};
  @override
  List<Object?> get props => [];
}

// --- NEW: Define Behavior Components ---
class MovableComponent extends Component with SerializableComponent {
  final double speed;
  MovableComponent(this.speed);
  factory MovableComponent.fromJson(Map<String, dynamic> json) =>
      MovableComponent(json['speed']);
  @override
  Map<String, dynamic> toJson() => {'speed': speed};
  @override
  List<Object?> get props => [speed];
}

class TalkativeComponent extends Component with SerializableComponent {
  final String sound;
  TalkativeComponent(this.sound);
  factory TalkativeComponent.fromJson(Map<String, dynamic> json) =>
      TalkativeComponent(json['sound']);
  @override
  Map<String, dynamic> toJson() => {'sound': sound};
  @override
  List<Object?> get props => [sound];
}

// --- NEW: Define Archetypes ---
final animalArchetype = Archetype([
  MovableComponent(5.0),
]);

final humanArchetype = Archetype([
  TalkativeComponent("Hello Nexus!"),
]);

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
  world.addSystem(RuleSystem());
  world.addSystem(ArchetypeSystem()); // NEW: Add the archetype system

  // 3. ایجاد موجودیت‌ها

  // موجودیت برای نمایشگر شمارنده
  final counterDisplay = Entity();
  counterDisplay
      .add(PositionComponent(x: 100, y: 150, width: 200, height: 100));
  counterDisplay.add(BlocComponent<CounterCubit, int>(cubit));
  counterDisplay.add(CounterStateComponent(cubit.state));
  counterDisplay.add(TagsComponent({'counter_display'}));
  counterDisplay.add(HistoryComponent(
    trackedComponents: {'CounterStateComponent'},
  ));

  // RuleComponent for simple warning tag
  counterDisplay.add(RuleComponent(
    triggers: {CounterUpdatedEvent},
    condition: (entity, event) {
      final counterEvent = event as CounterUpdatedEvent;
      final isWarning = counterEvent.newValue > 5;
      final hasWarningTag = entity.has<WarningTagComponent>();
      return isWarning != hasWarningTag;
    },
    actions: (entity, event) {
      final counterEvent = event as CounterUpdatedEvent;
      if (counterEvent.newValue > 5) {
        entity.add(WarningTagComponent());
      } else {
        entity.remove<WarningTagComponent>();
      }
    },
  ));

  // --- NEW: ArchetypeComponent for complex behaviors ---
  counterDisplay.add(ArchetypeComponent(
    triggers: {CounterUpdatedEvent}, // Also triggered by counter updates
    archetypes: [
      // Condition to become an "Animal"
      ConditionalArchetype(
        archetype: animalArchetype,
        condition: (entity, event) =>
            (event as CounterUpdatedEvent).newValue > 3,
      ),
      // Condition to become a "Human" (more specific animal)
      ConditionalArchetype(
        archetype: humanArchetype,
        condition: (entity, event) =>
            (event as CounterUpdatedEvent).newValue > 7,
      ),
    ],
  ));
  // --- END NEW ---

  world.addEntity(counterDisplay);

  // Buttons...
  final incrementButton = Entity();
  incrementButton.add(PositionComponent(x: 210, y: 320, width: 80, height: 50));
  incrementButton.add(ClickableComponent((_) => cubit.increment()));
  incrementButton.add(TagsComponent({'increment_button'}));
  world.addEntity(incrementButton);

  final decrementButton = Entity();
  decrementButton.add(PositionComponent(x: 110, y: 320, width: 80, height: 50));
  decrementButton.add(ClickableComponent((_) => cubit.decrement()));
  decrementButton.add(TagsComponent({'decrement_button'}));
  world.addEntity(decrementButton);

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
  ComponentFactoryRegistry.I.register(
      'WarningTagComponent', (json) => WarningTagComponent.fromJson(json));
  // --- NEW: Register behavior components ---
  ComponentFactoryRegistry.I
      .register('MovableComponent', (json) => MovableComponent.fromJson(json));
  ComponentFactoryRegistry.I.register(
      'TalkativeComponent', (json) => TalkativeComponent.fromJson(json));

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
          final hasWarning = controller.get<WarningTagComponent>(id) != null;
          // --- NEW: Check for behavior components ---
          final movable = controller.get<MovableComponent>(id);
          final talkative = controller.get<TalkativeComponent>(id);

          if (state == null) return const SizedBox.shrink();

          return Material(
            color: Colors.transparent,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${state.value}',
                    style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: hasWarning ? Colors.redAccent : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // --- NEW: Display active behaviors ---
                  if (movable != null)
                    Text("Behavior: Movable (Speed: ${movable.speed})"),
                  if (talkative != null)
                    Text("Behavior: Talkative (Says: '${talkative.sound}')"),
                ],
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
          isolateInitializer: () {
            ComponentFactoryRegistry.I.register('WarningTagComponent',
                (json) => WarningTagComponent.fromJson(json));
            // --- NEW: Register behavior components in isolate ---
            ComponentFactoryRegistry.I.register(
                'MovableComponent', (json) => MovableComponent.fromJson(json));
            ComponentFactoryRegistry.I.register('TalkativeComponent',
                (json) => TalkativeComponent.fromJson(json));
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
      world.eventBus.fire(CounterUpdatedEvent(state));
    }
  }
}
