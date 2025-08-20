import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus_example/counter_cubit.dart';

/// تابع اصلی که NexusWorld را برای Isolate پس‌زمینه فراهم می‌کند.
NexusWorld provideCounterWorld() {
  final world = NexusWorld();

  // 1. ثبت سرویس‌ها: CounterCubit به عنوان یک Singleton ثبت می‌شود.
  final cubit = CounterCubit();
  world.services.registerSingleton(cubit);

  // 2. افزودن سیستم‌ها:
  world.addSystem(CounterSystem());
  world.addSystem(InputSystem());
  world.addSystem(HistorySystem()); // NEW: Add the history system

  // 3. ایجاد موجودیت‌ها (Entities):

  // موجودیت برای نمایشگر شمارنده
  final counterDisplay = Entity();
  counterDisplay
      .add(PositionComponent(x: 100, y: 200, width: 200, height: 100));
  counterDisplay.add(BlocComponent<CounterCubit, int>(cubit));
  counterDisplay.add(CounterStateComponent(cubit.state));
  counterDisplay.add(TagsComponent({'counter_display'}));
  // NEW: Add history tracking for the counter's state
  counterDisplay.add(HistoryComponent(
    trackedComponents: {'CounterStateComponent'},
  ));
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

  // --- NEW: Undo and Redo Buttons ---
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
  // --- END NEW ---

  return world;
}

/// نقطه شروع برنامه Flutter.
void main() {
  registerCoreComponents();
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
          if (state == null) return const SizedBox.shrink();

          return Material(
            color: Colors.transparent,
            child: Center(
              child: Text(
                '${state.value}',
                style:
                    const TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
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
        // --- NEW: Builders for Undo/Redo buttons ---
        'undo_button': (context, id, controller, manager) {
          // We can get the history state to enable/disable the button
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
        // --- END NEW ---
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
        ),
      ),
    );
  }
}

/// سیستمی که به تغییرات وضعیت در CounterCubit گوش می‌دهد و
/// CounterStateComponent متناظر را به‌روزرسانی می‌کند.
class CounterSystem extends BlocSystem<CounterCubit, int> {
  @override
  void onStateChange(Entity entity, int state) {
    // Check if the state has actually changed before adding the component.
    final currentState = entity.get<CounterStateComponent>();
    if (currentState == null || currentState.value != state) {
      entity.add(CounterStateComponent(state));
    }
  }
}
