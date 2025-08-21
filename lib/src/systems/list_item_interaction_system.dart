import 'dart:async';
import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';

/// A system that handles direct interactions with list items, such as
/// reordering or swipe actions.
class ListItemInteractionSystem extends System {
  StreamSubscription? _reorderSubscription;
  StreamSubscription? _swipeSubscription;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    _reorderSubscription =
        world.eventBus.on<ReorderListItemEvent>(_onReorderItem);
    _swipeSubscription = world.eventBus.on<SwipeActionEvent>(_onSwipeAction);
  }

  @override
  void onRemovedFromWorld() {
    _reorderSubscription?.cancel();
    _swipeSubscription?.cancel();
    super.onRemovedFromWorld();
  }

  void _onReorderItem(ReorderListItemEvent event) {
    final manager = world.entities.values.firstWhereOrNull(
        (e) => e.get<ListComponent>()?.listId == event.listId);
    if (manager == null) return;

    final listComp = manager.get<ListComponent>()!;
    final newAllItems = List<EntityId>.from(listComp.allItems);

    final oldIndex = newAllItems.indexOf(event.itemId);
    if (oldIndex != -1) {
      newAllItems.removeAt(oldIndex);
      final insertIndex =
          oldIndex < event.newIndex ? event.newIndex - 1 : event.newIndex;
      newAllItems.insert(insertIndex, event.itemId);

      manager.add(ListComponent(
        listId: listComp.listId,
        allItems: newAllItems,
        visibleItems: _reorderVisibleItems(
            listComp.visibleItems, event.itemId, event.newIndex),
      ));
    }
  }

  List<EntityId> _reorderVisibleItems(
      List<EntityId> visible, EntityId itemId, int newIndex) {
    final newVisibleItems = List<EntityId>.from(visible);
    final oldVisibleIndex = newVisibleItems.indexOf(itemId);
    if (oldVisibleIndex != -1) {
      newVisibleItems.removeAt(oldVisibleIndex);
      final insertIndex = oldVisibleIndex < newIndex ? newIndex - 1 : newIndex;
      if (insertIndex <= newVisibleItems.length) {
        newVisibleItems.insert(insertIndex, itemId);
      }
    }
    return newVisibleItems;
  }

  void _onSwipeAction(SwipeActionEvent event) {
    final itemEntity = world.entities[event.itemId];
    if (itemEntity == null) return;

    switch (event.action) {
      case 'delete':
        itemEntity.add(AnimateOutComponent());
        break;
    }
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven

  @override
  void update(Entity entity, double dt) {}
}
