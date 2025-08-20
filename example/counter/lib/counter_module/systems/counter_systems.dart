import 'package:nexus/nexus.dart';
import 'package:nexus_example/counter_cubit.dart';
import 'package:nexus_example/counter_module/logic/warning_logic.dart';

/// Provides all systems related to the counter feature.
class CounterSystemProvider extends SystemProvider {
  @override
  List<System> get systems => [
        _CounterDisplaySystem(),
        ShapeSelectionSystem(),
      ];
}

/// The system that updates the counter's data component.
/// It now acts as a coordinator, delegating logic to specialized functions.
class _CounterDisplaySystem extends BlocSystem<CounterCubit, int> {
  @override
  void onStateChange(Entity entity, int state) {
    // Update the core state component.
    entity.add(CounterStateComponent(state));

    // Delegate the warning tag logic to our specialized function.
    handleWarningTag(entity, state);

    // You could add more logic delegations here, for example:
    // handleScoreCalculation(entity, state);
    // handleAchievementUnlocking(entity, state);
  }
}
