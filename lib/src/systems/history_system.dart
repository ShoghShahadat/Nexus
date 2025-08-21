import 'dart:async';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/history_component.dart';
import 'package:nexus/src/events/history_events.dart';

/// A system that manages undo/redo functionality for entities
/// with a [HistoryComponent].
class HistorySystem extends System {
  StreamSubscription? _undoSubscription;
  StreamSubscription? _redoSubscription;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    _undoSubscription = world.eventBus.on<UndoEvent>(_onUndo);
    _redoSubscription = world.eventBus.on<RedoEvent>(_onRedo);
  }

  @override
  void onRemovedFromWorld() {
    _undoSubscription?.cancel();
    _redoSubscription?.cancel();
    super.onRemovedFromWorld();
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

  void _applyState(Entity entity, HistoryComponent historyComp, int index) {
    final stateSnapshot = historyComp.history[index];

    for (final typeName in stateSnapshot.keys) {
      final componentJson = stateSnapshot[typeName]!;
      final component =
          ComponentFactoryRegistry.I.create(typeName, componentJson);
      entity.add(component);
    }

    entity.add(HistoryComponent(
      trackedComponents: historyComp.trackedComponents,
      history: historyComp.history,
      currentIndex: index,
    ));
  }

  @override
  bool matches(Entity entity) {
    return entity.has<HistoryComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final historyComp = entity.get<HistoryComponent>()!;
    bool hasChanges = false;

    for (final componentType in entity.dirtyComponents) {
      if (historyComp.trackedComponents.contains(componentType.toString())) {
        hasChanges = true;
        break;
      }
    }

    if (!hasChanges) return;

    final newSnapshot = <String, Map<String, dynamic>>{};
    for (final typeName in historyComp.trackedComponents) {
      final component = entity.allComponents
          .firstWhere((c) => c.runtimeType.toString() == typeName);
      if (component is SerializableComponent) {
        newSnapshot[typeName] = (component as SerializableComponent).toJson();
      }
    }

    if (historyComp.history.isNotEmpty &&
        _areSnapshotsEqual(
            historyComp.history[historyComp.currentIndex], newSnapshot)) {
      return;
    }

    final newHistory =
        List<Map<String, Map<String, dynamic>>>.from(historyComp.history);

    if (historyComp.currentIndex < newHistory.length - 1) {
      newHistory.removeRange(historyComp.currentIndex + 1, newHistory.length);
    }

    newHistory.add(newSnapshot);

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
