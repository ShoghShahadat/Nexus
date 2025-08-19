import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus_example/counter_cubit.dart';

/// A self-contained module for the counter feature.
///
/// This module registers all necessary systems and provides methods to
/// create the entities required for the counter UI. A large application
/// would be composed of many such modules.
class CounterModule extends NexusModule {
  @override
  List<System> get systems => [_CounterDisplaySystem()];

  /// Creates all entities related to the counter feature and adds them to the world.
  void createEntities(NexusWorld world, CounterCubit counterCubit) {
    world.addEntity(_createCounterDisplay(counterCubit));
    world.addEntity(_createIncrementButton(counterCubit));
    world.addEntity(_createDecrementButton(counterCubit));
  }

  Entity _createCounterDisplay(CounterCubit cubit) {
    final entity = Entity();
    entity.add(
        PositionComponent(x: 80, y: 250, width: 250, height: 100, scale: 0));
    entity.add(BlocComponent<CounterCubit, int>(cubit));
    entity.add(CounterStateComponent(cubit.state));
    entity.add(TagsComponent({})); // Add an empty set of tags
    entity.add(WidgetComponent((context, entity) {
      final state = entity.get<CounterStateComponent>()!.value;
      return Material(
        key: ValueKey(state),
        elevation: 4.0,
        borderRadius: BorderRadius.circular(12),
        color: state >= 0 ? Colors.deepPurple : Colors.redAccent,
        child: Center(
          child: Text('Count: $state',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
        ),
      );
    }));
    entity.add(AnimationComponent(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      onUpdate: (entity, value) {
        final pos = entity.get<PositionComponent>()!;
        pos.scale = value;
        entity.add(pos);
      },
      onComplete: (entity) {
        // We no longer add velocity here to keep the example focused.
      },
    ));
    return entity;
  }

  Entity _createIncrementButton(CounterCubit cubit) {
    final entity = Entity();
    entity.add(PositionComponent(x: 220, y: 370, width: 110, height: 50));
    entity.add(WidgetComponent(
      (context, entity) => ElevatedButton(
        onPressed: cubit.increment,
        child: const Icon(Icons.add),
      ),
    ));
    return entity;
  }

  Entity _createDecrementButton(CounterCubit cubit) {
    final entity = Entity();
    entity.add(PositionComponent(x: 80, y: 370, width: 110, height: 50));
    entity.add(WidgetComponent(
      (context, entity) => ElevatedButton(
        onPressed: cubit.decrement,
        child: const Icon(Icons.remove),
      ),
    ));
    return entity;
  }
}

/// The system that updates the counter's data component.
/// It now ONLY manages the "warning" tag based on the state.
class _CounterDisplaySystem extends BlocSystem<CounterCubit, int> {
  @override
  void onStateChange(Entity entity, int state) {
    // First, update the state component as before.
    entity.add(CounterStateComponent(state));

    // Now, manage the warning tag based purely on the state.
    // The PulsingWarningSystem will react to the presence of this tag.
    final tags = entity.get<TagsComponent>();
    if (tags != null) {
      final wasWarning = tags.hasTag('warning');
      final isWarning = state < 0;

      if (isWarning && !wasWarning) {
        // If the state is negative and it wasn't before, add the tag.
        tags.add('warning');
        entity.add(tags);
      } else if (!isWarning && wasWarning) {
        // If the state is non-negative and it was a warning before, remove the tag.
        tags.remove('warning');
        entity.add(tags);
      }
    }
  }
}
