import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/responsive_component.dart';
import 'package:nexus/src/components/screen_info_component.dart';
import 'package:nexus/src/events/responsive_events.dart';

/// A system that manages responsive layout changes for entities.
///
/// It listens for `ScreenResizedEvent` and applies the appropriate archetypes
/// to entities with a `ResponsiveComponent`, allowing for data-driven UI
/// adaptation to different screen sizes and orientations.
class ResponsivenessSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    world.eventBus.on<ScreenResizedEvent>(_onScreenResized);
  }

  void _onScreenResized(ScreenResizedEvent event) {
    // First, update the central ScreenInfoComponent.
    final rootEntity = world.entities.values.firstWhereOrNull(
        (e) => e.get<TagsComponent>()?.hasTag('root') ?? false);

    rootEntity?.add(ScreenInfoComponent(
      width: event.newWidth,
      height: event.newHeight,
      orientation: event.newOrientation,
    ));

    // Then, process all responsive entities.
    final responsiveEntities =
        world.entities.values.where((e) => e.has<ResponsiveComponent>());

    for (final entity in responsiveEntities) {
      _applyResponsiveChanges(entity, event.newWidth);
    }
  }

  void _applyResponsiveChanges(Entity entity, double currentWidth) {
    final responsiveComp = entity.get<ResponsiveComponent>()!;

    // Find the correct archetype for the current screen width.
    Archetype? targetArchetype;
    final sortedBreakpoints = responsiveComp.breakpoints.keys.toList()..sort();
    for (final breakpoint in sortedBreakpoints) {
      if (currentWidth < breakpoint) {
        targetArchetype = responsiveComp.breakpoints[breakpoint]!;
        break;
      }
    }

    // Fallback if no breakpoint is matched (e.g., for the largest size).
    targetArchetype ??= responsiveComp.breakpoints[sortedBreakpoints.last];

    // If the target archetype is the same as the last applied one, do nothing.
    if (targetArchetype == responsiveComp.lastAppliedArchetype) {
      return;
    }

    // Remove the components of the old archetype.
    if (responsiveComp.lastAppliedArchetype != null) {
      for (final componentType
          in responsiveComp.lastAppliedArchetype!.componentTypes) {
        entity.removeByType(componentType);
      }
    }

    // Apply the components of the new archetype.
    targetArchetype?.apply(entity);

    // Update the component's state to remember the last applied archetype.
    responsiveComp.lastAppliedArchetype = targetArchetype;
    entity.add(responsiveComp);
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven.

  @override
  void update(Entity entity, double dt) {}
}
