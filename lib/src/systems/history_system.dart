import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/history_component.dart';
import 'package:nexus/src/events/history_events.dart';

/// A system that manages undo/redo functionality for entities
/// with a [HistoryComponent].
class HistorySystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    world.eventBus.on<UndoEvent>(_onUndo);
    world.eventBus.on<RedoEvent>(_onRedo);
  }

  void _onUndo(UndoEvent event) {
    final entity = world.entities[event.entityId];
    if (entity == null) return;

    final historyComp = entity.get<HistoryComponent>();
    if (historyComp == null || !historyComp.canUndo) return;

    // Move to the previous state
    final newIndex = historyComp.currentIndex - 1;
    _applyState(entity, historyComp, newIndex);
  }

  void _onRedo(RedoEvent event) {
    final entity = world.entities[event.entityId];
    if (entity == null) return;

    final historyComp = entity.get<HistoryComponent>();
    if (historyComp == null || !historyComp.canRedo) return;

    // Move to the next state
    final newIndex = historyComp.currentIndex + 1;
    _applyState(entity, historyComp, newIndex);
  }

  /// Applies a specific state from history to an entity.
  void _applyState(Entity entity, HistoryComponent historyComp, int index) {
    final stateSnapshot = historyComp.history[index];

    // Restore components from the snapshot
    for (final typeName in stateSnapshot.keys) {
      final componentJson = stateSnapshot[typeName]!;
      final component =
          ComponentFactoryRegistry.I.create(typeName, componentJson);
      entity.add(component);
    }

    // Update the history component with the new index
    entity.add(HistoryComponent(
      trackedComponents: historyComp.trackedComponents,
      history: historyComp.history,
      currentIndex: index,
    ));
  }

  @override
  bool matches(Entity entity) {
    // This system acts on entities that can have their history tracked.
    return entity.has<HistoryComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final historyComp = entity.get<HistoryComponent>()!;
    bool hasChanges = false;

    // Check if any of the tracked components are dirty
    for (final componentType in entity.dirtyComponents) {
      if (historyComp.trackedComponents.contains(componentType.toString())) {
        hasChanges = true;
        break;
      }
    }

    if (!hasChanges) return;

    // Create a new snapshot of the tracked components
    final newSnapshot = <String, Map<String, dynamic>>{};
    for (final typeName in historyComp.trackedComponents) {
      final component = entity.allComponents
          .firstWhere((c) => c.runtimeType.toString() == typeName);
      if (component is SerializableComponent) {
        newSnapshot[typeName] = (component as SerializableComponent).toJson();
      }
    }

    // If the new snapshot is identical to the current one, do nothing.
    if (historyComp.history.isNotEmpty &&
        _areSnapshotsEqual(
            historyComp.history[historyComp.currentIndex], newSnapshot)) {
      return;
    }

    // Create the new history list
    final newHistory =
        List<Map<String, Map<String, dynamic>>>.from(historyComp.history);

    // If we are not at the end of the history, truncate the future states
    if (historyComp.currentIndex < newHistory.length - 1) {
      newHistory.removeRange(historyComp.currentIndex + 1, newHistory.length);
    }

    newHistory.add(newSnapshot);

    // Update the component
    entity.add(HistoryComponent(
      trackedComponents: historyComp.trackedComponents,
      history: newHistory,
      currentIndex: newHistory.length - 1,
    ));
  }

  bool _areSnapshotsEqual(Map<String, dynamic> s1, Map<String, dynamic> s2) {
    if (s1.length != s2.length) return false;
    for (final key in s1.keys) {
      if (s2[key].toString() != s1[key].toString()) {
        return false;
      }
    }
    return true;
  }
}
