import 'dart:async';
import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/responsive_component.dart';
import 'package:nexus/src/components/screen_info_component.dart';
import 'package:nexus/src/events/responsive_events.dart';

/// A system that manages responsive layout changes for entities.
class ResponsivenessSystem extends System {
  StreamSubscription? _resizeSubscription;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    _resizeSubscription =
        world.eventBus.on<ScreenResizedEvent>(_onScreenResized);
  }

  @override
  void onRemovedFromWorld() {
    _resizeSubscription?.cancel();
    super.onRemovedFromWorld();
  }

  void _onScreenResized(ScreenResizedEvent event) {
    final rootEntity = world.entities.values.firstWhereOrNull(
        (e) => e.get<TagsComponent>()?.hasTag('root') ?? false);

    rootEntity?.add(ScreenInfoComponent(
      width: event.newWidth,
      height: event.newHeight,
      orientation: event.newOrientation,
    ));

    final responsiveEntities =
        world.entities.values.where((e) => e.has<ResponsiveComponent>());

    for (final entity in responsiveEntities) {
      _applyResponsiveChanges(entity, event.newWidth);
    }
  }

  void _applyResponsiveChanges(Entity entity, double currentWidth) {
    final responsiveComp = entity.get<ResponsiveComponent>()!;

    Archetype? targetArchetype;
    final sortedBreakpoints = responsiveComp.breakpoints.keys.toList()..sort();
    for (final breakpoint in sortedBreakpoints) {
      if (currentWidth < breakpoint) {
        targetArchetype = responsiveComp.breakpoints[breakpoint]!;
        break;
      }
    }

    targetArchetype ??= responsiveComp.breakpoints[sortedBreakpoints.last];

    if (targetArchetype == responsiveComp.lastAppliedArchetype) {
      return;
    }

    if (responsiveComp.lastAppliedArchetype != null) {
      for (final componentType
          in responsiveComp.lastAppliedArchetype!.componentTypes) {
        entity.removeByType(componentType);
      }
    }

    targetArchetype?.apply(entity);

    responsiveComp.lastAppliedArchetype = targetArchetype;
    entity.add(responsiveComp);
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven.

  @override
  void update(Entity entity, double dt) {}
}
