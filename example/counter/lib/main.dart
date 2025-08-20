import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus_example/counter_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- FINAL FIX: Create a single, static instance for debug mode ---
// Static variables in Dart preserve their state across Hot Reloads.
// This is the key to stateful Hot Reload.
final InMemoryStorageAdapter _debugStorage = InMemoryStorageAdapter();

class InMemoryStorageAdapter implements StorageAdapter {
  final Map<String, Map<String, dynamic>> _data = {};

  @override
  Future<void> init() async {}

  @override
  Future<Map<String, dynamic>?> load(String key) async {
    return _data[key.replaceFirst('nexus_', '')];
  }

  @override
  Future<void> save(String key, Map<String, dynamic> data) async {
    _data[key.replaceFirst('nexus_', '')] = data;
  }

  @override
  Future<Map<String, Map<String, dynamic>>> loadAll() async {
    return _data;
  }
}

class PrefsAdapter implements StorageAdapter {
  late SharedPreferences _prefs;

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<Map<String, dynamic>?> load(String key) async {
    final data = _prefs.getString(key);
    if (data == null) return null;
    return jsonDecode(data);
  }

  @override
  Future<void> save(String key, Map<String, dynamic> data) async {
    await _prefs.setString(key, jsonEncode(data));
  }

  @override
  Future<Map<String, Map<String, dynamic>>> loadAll() async {
    final allData = <String, Map<String, dynamic>>{};
    final keys = _prefs.getKeys().where((k) => k.startsWith('nexus_'));
    for (final key in keys) {
      final loadedData = await load(key);
      if (loadedData != null) {
        allData[key.replaceFirst('nexus_', '')] = loadedData;
      }
    }
    return allData;
  }
}

class CounterUpdatedEvent {
  final int newValue;
  CounterUpdatedEvent(this.newValue);
}

class MoodChangedEvent {
  final String newMood;
  MoodChangedEvent(this.newMood);
}

Future<void> isolateInitializer() async {
  // Use the single static instance in debug mode, or a new PrefsAdapter in release.
  final StorageAdapter storage = kDebugMode ? _debugStorage : PrefsAdapter();
  await storage.init();

  if (!GetIt.I.isRegistered<StorageAdapter>()) {
    GetIt.I.registerSingleton<StorageAdapter>(storage);
  }

  if (!GetIt.I.isRegistered<CounterCubit>()) {
    GetIt.I.registerSingleton(CounterCubit());
  }
}

NexusWorld provideCounterWorld() {
  final world = NexusWorld();

  world.addSystem(CounterSystem());
  world.addSystem(InputSystem());
  world.addSystem(HistorySystem());
  world.addSystem(RuleSystem());
  world.addSystem(PersistenceSystem());

  final counterDisplay = Entity();
  counterDisplay.add(CustomWidgetComponent(widgetType: 'counter_display'));
  counterDisplay.add(PersistenceComponent('counter_entity'));
  counterDisplay.add(TagsComponent({'counter_display'}));
  counterDisplay.add(BlackboardComponent({'mood': 'happy'}));
  counterDisplay.add(CounterStateComponent(0));
  counterDisplay.add(HistoryComponent(
    trackedComponents: {'CounterStateComponent', 'BlackboardComponent'},
  ));
  counterDisplay.add(RuleComponent(
    triggers: {CounterUpdatedEvent},
    condition: (entity, event) => true,
    actions: (entity, event) {
      final newMood =
          (event as CounterUpdatedEvent).newValue > 5 ? 'angry' : 'happy';
      final blackboard = entity.get<BlackboardComponent>()!;
      if (blackboard.get<String>('mood') != newMood) {
        blackboard.set('mood', newMood);
        entity.add(blackboard);
        world.eventBus.fire(MoodChangedEvent(newMood));
      }
    },
  ));

  final incrementButton = Entity();
  incrementButton.add(CustomWidgetComponent(widgetType: 'increment_button'));
  incrementButton.add(ClickableComponent((entity) {
    world.services.get<CounterCubit>().increment();
    world.eventBus.fire(SaveDataEvent());
  }));
  incrementButton.add(TagsComponent({'increment_button'}));

  final decrementButton = Entity();
  decrementButton.add(CustomWidgetComponent(widgetType: 'decrement_button'));
  decrementButton.add(ClickableComponent((entity) {
    world.services.get<CounterCubit>().decrement();
    world.eventBus.fire(SaveDataEvent());
  }));
  decrementButton.add(TagsComponent({'decrement_button'}));

  final buttonRow = Entity();
  buttonRow.add(CustomWidgetComponent(widgetType: 'row'));
  buttonRow.add(ChildrenComponent([
    decrementButton.id,
    incrementButton.id,
  ]));

  final contentColumn = Entity();
  contentColumn.add(CustomWidgetComponent(widgetType: 'column'));
  contentColumn.add(ChildrenComponent([
    counterDisplay.id,
    buttonRow.id,
  ]));

  final rootEntity = Entity();
  rootEntity.add(TagsComponent({'root'}));
  rootEntity.add(CustomWidgetComponent(widgetType: 'center_layout'));
  rootEntity.add(ChildrenComponent([contentColumn.id]));

  world.addEntity(counterDisplay);
  world.addEntity(incrementButton);
  world.addEntity(decrementButton);
  world.addEntity(buttonRow);
  world.addEntity(contentColumn);
  world.addEntity(rootEntity);

  return world;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerCoreComponents();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final rootIsolateToken = RootIsolateToken.instance;

    final renderingSystem = FlutterRenderingSystem(
      builders: {
        'center_layout': (context, id, controller, manager, child) {
          return Center(child: child);
        },
        'counter_display': (context, id, controller, manager, child) {
          final state = controller.get<CounterStateComponent>(id);
          final blackboard = controller.get<BlackboardComponent>(id);
          final mood = blackboard?.get<String>('mood') ?? 'unknown';

          if (state == null) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${state.value}',
                  style: TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: mood == 'angry' ? Colors.redAccent : Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Mood: $mood",
                  style: const TextStyle(
                      fontSize: 20, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          );
        },
        'increment_button': (context, id, controller, manager, child) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton(
              onPressed: () => manager.send(EntityTapEvent(id)),
              child: const Icon(Icons.add),
            ),
          );
        },
        'decrement_button': (context, id, controller, manager, child) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton(
              onPressed: () => manager.send(EntityTapEvent(id)),
              child: const Icon(Icons.remove),
            ),
          );
        },
      },
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Nexus Persistence Example'),
        ),
        body: NexusWidget(
          worldProvider: provideCounterWorld,
          renderingSystem: renderingSystem,
          isolateInitializer: isolateInitializer,
          rootIsolateToken: rootIsolateToken,
        ),
      ),
    );
  }
}

class CounterSystem extends BlocSystem<CounterCubit, int> {
  @override
  void onStateChange(int state) {
    try {
      final displayEntity = world.entities.values.firstWhere(
          (e) => e.get<TagsComponent>()?.hasTag('counter_display') ?? false);

      final currentState = displayEntity.get<CounterStateComponent>();
      if (currentState == null || currentState.value != state) {
        displayEntity.add(CounterStateComponent(state));
        world.eventBus.fire(CounterUpdatedEvent(state));
      }
    } catch (e) {
      // Safe to ignore.
    }
  }
}
