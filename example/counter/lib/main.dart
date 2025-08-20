import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus_example/counter_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Custom Storage Adapter using SharedPreferences ---
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

// --- Events & Custom Components for the example ---
class CounterUpdatedEvent {
  final int newValue;
  CounterUpdatedEvent(this.newValue);
}

class MoodChangedEvent {
  final String newMood;
  MoodChangedEvent(this.newMood);
}

/// Initializes services required by the logic isolate.
Future<void> isolateInitializer() async {
  final storage = PrefsAdapter();
  await storage.init();
  GetIt.instance.registerSingleton<StorageAdapter>(storage);
}

/// This function now only defines the blueprint of the world.
NexusWorld provideCounterWorld() {
  final world = NexusWorld();

  world.addSystem(CounterSystem());
  world.addSystem(InputSystem());
  world.addSystem(HistorySystem());
  world.addSystem(RuleSystem());
  world.addSystem(PersistenceSystem());

  final counterDisplay = Entity();
  counterDisplay.add(PersistenceComponent('counter_entity'));
  counterDisplay
      .add(PositionComponent(x: 100, y: 150, width: 200, height: 100));
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

  world.addEntity(counterDisplay);

  final incrementButton = Entity();
  incrementButton.add(PositionComponent(x: 210, y: 320, width: 80, height: 50));
  incrementButton.add(ClickableComponent((entity) {
    world.services.get<CounterCubit>().increment();
    world.eventBus.fire(SaveDataEvent());
  }));
  incrementButton.add(TagsComponent({'increment_button'}));
  world.addEntity(incrementButton);

  final decrementButton = Entity();
  decrementButton.add(PositionComponent(x: 110, y: 320, width: 80, height: 50));
  decrementButton.add(ClickableComponent((entity) {
    world.services.get<CounterCubit>().decrement();
    world.eventBus.fire(SaveDataEvent());
  }));
  decrementButton.add(TagsComponent({'decrement_button'}));
  world.addEntity(decrementButton);

  return world;
}

/// Main entry point.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerCoreComponents();
  runApp(const MyApp());
}

/// The root widget.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- FIX: Use the correct static getter for RootIsolateToken ---
    final rootIsolateToken = RootIsolateToken.instance;

    final renderingSystem = FlutterRenderingSystem(
      builders: {
        'counter_display': (context, id, controller, manager, child) {
          final state = controller.get<CounterStateComponent>(id);
          final blackboard = controller.get<BlackboardComponent>(id);
          final mood = blackboard?.get<String>('mood') ?? 'unknown';

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
            ),
          );
        },
        'increment_button': (context, id, controller, manager, child) {
          return ElevatedButton(
            onPressed: () => manager.send(EntityTapEvent(id)),
            child: const Icon(Icons.add),
          );
        },
        'decrement_button': (context, id, controller, manager, child) {
          return ElevatedButton(
            onPressed: () => manager.send(EntityTapEvent(id)),
            child: const Icon(Icons.remove),
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
          worldProvider: () {
            final world = provideCounterWorld();
            if (!GetIt.instance.isRegistered<CounterCubit>()) {
              GetIt.instance.registerSingleton(CounterCubit());
            }
            final cubit = GetIt.instance.get<CounterCubit>();
            final counterEntity = world.entities.values
                .firstWhere((e) => e.has<PersistenceComponent>());
            counterEntity.add(BlocComponent<CounterCubit, int>(cubit));
            return world;
          },
          renderingSystem: renderingSystem,
          isolateInitializer: isolateInitializer,
          rootIsolateToken: rootIsolateToken,
        ),
      ),
    );
  }
}

/// System that listens to BLoC state changes.
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
