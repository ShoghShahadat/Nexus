import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';

/// A system that handles direct interactions with list items, such as
/// reordering or swipe actions.
/// سیستمی که تعاملات مستقیم با آیتم‌های لیست، مانند جابجایی یا اعمال سوایپ،
/// را مدیریت می‌کند.
class ListItemInteractionSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    world.eventBus.on<ReorderListItemEvent>(_onReorderItem);
    world.eventBus.on<SwipeActionEvent>(_onSwipeAction);
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
      // Adjust index if the item was moved from before its new position.
      // ایندکس را در صورتی که آیتم از قبل از موقعیت جدیدش جابجا شده باشد، تنظیم می‌کند.
      final insertIndex =
          oldIndex < event.newIndex ? event.newIndex - 1 : event.newIndex;
      newAllItems.insert(insertIndex, event.itemId);

      manager.add(ListComponent(
        listId: listComp.listId,
        allItems: newAllItems,
        // Also update visible items to reflect the reorder immediately.
        // visibleItems را نیز به‌روز می‌کند تا جابجایی فوراً نمایش داده شود.
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
        // Mark the item for an exit animation.
        // آیتم را برای انیمیشن خروج علامت‌گذاری می‌کند.
        itemEntity.add(AnimateOutComponent());
        break;
      // Other actions like 'archive', 'copy', etc. can be handled here.
      // اعمال دیگر مانند 'بایگانی'، 'کپی' و... می‌توانند اینجا مدیریت شوند.
    }
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven

  @override
  void update(Entity entity, double dt) {}
}
