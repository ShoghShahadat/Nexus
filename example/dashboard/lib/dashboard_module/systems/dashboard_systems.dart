import 'dart:math';

import 'package:flutter/animation.dart' show Curves;
import 'package:nexus/nexus.dart';
import 'package:nexus_example/dashboard_module/components/dashboard_components.dart';

/// Provides all systems related to the dashboard feature.
class DashboardSystemProvider extends SystemProvider {
  @override
  List<System> get systems => [
        EntryAnimationSystem(),
        TaskExpansionSystem(),
        RealtimeDataSystem(),
      ];
}

// ... (EntryAnimationSystem and TaskExpansionSystem remain unchanged)
/// A system that creates and manages the entry animations for dashboard elements.
class EntryAnimationSystem extends System {
  @override
  bool matches(Entity entity) {
    return entity.has<EntryAnimationComponent>() &&
        !entity.has<AnimationComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final entryAnim = entity.get<EntryAnimationComponent>()!;
    entity.add(AnimationProgressComponent(0.0));

    entity.add(AnimationComponent(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      autostart: false,
      onUpdate: (e, value) {
        e.add(AnimationProgressComponent(value));
      },
      onComplete: (e) {
        e.remove<EntryAnimationComponent>();
      },
    ));

    Future.delayed(Duration(milliseconds: (entryAnim.delay * 1000).toInt()),
        () {
      if (world.entities.containsKey(entity.id)) {
        entity.get<AnimationComponent>()?.play();
      }
    });
  }
}

/// A dedicated system to handle the task expansion/collapse animation.
class TaskExpansionSystem extends System {
  @override
  bool matches(Entity entity) {
    return entity.has<TaskItemComponent>() &&
        entity.has<ExpandedStateComponent>() &&
        !entity.has<AnimationComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final expansionState = entity.get<ExpandedStateComponent>()!;
    final double startValue = expansionState.progress;
    final double endValue = expansionState.isExpanding ? 1.0 : 0.0;

    if (startValue == endValue) return;

    entity.add(AnimationComponent(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      onUpdate: (e, value) {
        final currentProgress = startValue + (endValue - startValue) * value;
        e.add(ExpandedStateComponent(
          progress: currentProgress,
          isExpanding: expansionState.isExpanding,
        ));
      },
      onComplete: (e) {
        if (!expansionState.isExpanding) {
          e.remove<ExpandedStateComponent>();
        }
      },
    ));
  }
}

/// A system that generates random data every frame for the live chart.
class RealtimeDataSystem extends System {
  final Random _random = Random();

  @override
  bool matches(Entity entity) {
    return entity.has<RealtimeChartComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    // *** FIX: Increment the frame count on each update. ***
    final currentChart = entity.get<RealtimeChartComponent>()!;
    final newFrameCount = currentChart.frameCount + 1;

    final newData = List.generate(20, (_) => _random.nextDouble() * 100);

    // Re-add the component with new data and the incremented frame count.
    entity.add(RealtimeChartComponent(newData, frameCount: newFrameCount));
  }
}
