import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';

/// The primary system for managing the state of lists.
/// سیستم اصلی برای مدیریت وضعیت لیست‌ها.
///
/// This system is event-driven and responds to filter, sort, and search events.
/// It processes the `allItems` list from a `ListComponent` and updates the
/// `visibleItems` list accordingly. It assumes item data is stored in a
/// `BlackboardComponent` on each item entity.
/// این سیستم رویداد-محور است و به رویدادهای فیلتر، مرتب‌سازی و جستجو پاسخ می‌دهد.
/// لیست `allItems` را پردازش کرده و `visibleItems` را به‌روز می‌کند. فرض بر این است که
/// داده‌های هر آیتم در یک `BlackboardComponent` ذخیره شده است.
class ListStateSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    world.eventBus.on<UpdateListFilterEvent>(_onUpdateFilter);
    world.eventBus.on<UpdateListSortEvent>(_onUpdateSort);
    world.eventBus.on<UpdateListSearchEvent>(_onUpdateSearch);
    world.eventBus.on<PurgeListItemEvent>(_onPurgeItem);
  }

  // --- Event Handlers ---

  void _onUpdateFilter(UpdateListFilterEvent event) {
    final manager = _getListManager(event.listId);
    if (manager == null) return;
    final state = manager.get<ListStateComponent>()!;
    manager.add(ListStateComponent(
      filterCriteria: event.filterCriteria,
      sortByField: state.sortByField,
      isAscending: state.isAscending,
      searchQuery: state.searchQuery,
    ));
    _recalculateVisibleItems(manager);
  }

  void _onUpdateSort(UpdateListSortEvent event) {
    final manager = _getListManager(event.listId);
    if (manager == null) return;
    final state = manager.get<ListStateComponent>()!;
    manager.add(ListStateComponent(
      filterCriteria: state.filterCriteria,
      sortByField: event.sortByField,
      isAscending: event.isAscending,
      searchQuery: state.searchQuery,
    ));
    _recalculateVisibleItems(manager);
  }

  void _onUpdateSearch(UpdateListSearchEvent event) {
    final manager = _getListManager(event.listId);
    if (manager == null) return;
    final state = manager.get<ListStateComponent>()!;
    manager.add(ListStateComponent(
      filterCriteria: state.filterCriteria,
      sortByField: state.sortByField,
      isAscending: state.isAscending,
      searchQuery: event.query.toLowerCase(),
    ));
    _recalculateVisibleItems(manager);
  }

  void _onPurgeItem(PurgeListItemEvent event) {
    // Find all list managers and remove the purged item from their lists.
    // تمام مدیران لیست را پیدا کرده و آیتم پاک‌شده را از لیست‌هایشان حذف می‌کند.
    final allManagers =
        world.entities.values.where((e) => e.has<ListComponent>()).toList();

    for (final manager in allManagers) {
      final listComp = manager.get<ListComponent>()!;
      if (listComp.allItems.contains(event.itemId)) {
        final newAllItems = List<EntityId>.from(listComp.allItems)
          ..remove(event.itemId);
        manager.add(ListComponent(
          listId: listComp.listId,
          allItems: newAllItems,
          visibleItems: listComp.visibleItems,
        ));
        _recalculateVisibleItems(manager);
      }
    }
  }

  // --- Core Logic ---

  void _recalculateVisibleItems(Entity manager) {
    final listComp = manager.get<ListComponent>()!;
    final state = manager.get<ListStateComponent>()!;
    var items = List<EntityId>.from(listComp.allItems);

    // 1. Filtering
    if (state.filterCriteria.isNotEmpty) {
      items = items.where((itemId) {
        final itemEntity = world.entities[itemId];
        final data = itemEntity?.get<BlackboardComponent>();
        if (data == null) return false;
        return state.filterCriteria.entries.every((entry) {
          return data.get(entry.key) == entry.value;
        });
      }).toList();
    }

    // 2. Searching
    if (state.searchQuery.isNotEmpty) {
      items = items.where((itemId) {
        final itemEntity = world.entities[itemId];
        final data = itemEntity?.get<BlackboardComponent>();
        if (data == null) return false;
        // Simple search: checks if any string value contains the query.
        // جستجوی ساده: بررسی می‌کند آیا هیچ مقدار رشته‌ای شامل عبارت جستجو هست یا خیر.
        return data.toJson()['data'].values.any((value) =>
            value is String && value.toLowerCase().contains(state.searchQuery));
      }).toList();
    }

    // 3. Sorting
    if (state.sortByField != null) {
      items.sort((aId, bId) {
        final aEntity = world.entities[aId];
        final bEntity = world.entities[bId];
        final aData = aEntity?.get<BlackboardComponent>();
        final bData = bEntity?.get<BlackboardComponent>();

        final aValue = aData?.get<Comparable>(state.sortByField!);
        final bValue = bData?.get<Comparable>(state.sortByField!);

        if (aValue == null || bValue == null) return 0;
        final comparison = aValue.compareTo(bValue);
        return state.isAscending ? comparison : -comparison;
      });
    }

    // Update the manager with the new list of visible items.
    // مدیر لیست را با لیست جدید آیتم‌های قابل مشاهده به‌روز می‌کند.
    manager.add(ListComponent(
      listId: listComp.listId,
      allItems: listComp.allItems,
      visibleItems: items,
    ));
  }

  Entity? _getListManager(String listId) {
    return world.entities.values
        .firstWhereOrNull((e) => e.get<ListComponent>()?.listId == listId);
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven

  @override
  void update(Entity entity, double dt) {}
}
