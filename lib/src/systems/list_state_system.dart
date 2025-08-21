import 'dart:async';
import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';

/// The primary system for managing the state of lists.
class ListStateSystem extends System {
  StreamSubscription? _filterSubscription;
  StreamSubscription? _sortSubscription;
  StreamSubscription? _searchSubscription;
  StreamSubscription? _purgeSubscription;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    _filterSubscription =
        world.eventBus.on<UpdateListFilterEvent>(_onUpdateFilter);
    _sortSubscription = world.eventBus.on<UpdateListSortEvent>(_onUpdateSort);
    _searchSubscription =
        world.eventBus.on<UpdateListSearchEvent>(_onUpdateSearch);
    _purgeSubscription = world.eventBus.on<PurgeListItemEvent>(_onPurgeItem);
  }

  @override
  void onRemovedFromWorld() {
    _filterSubscription?.cancel();
    _sortSubscription?.cancel();
    _searchSubscription?.cancel();
    _purgeSubscription?.cancel();
    super.onRemovedFromWorld();
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

    if (state.searchQuery.isNotEmpty) {
      items = items.where((itemId) {
        final itemEntity = world.entities[itemId];
        final data = itemEntity?.get<BlackboardComponent>();
        if (data == null) return false;
        return data.toJson()['data'].values.any((value) =>
            value is String && value.toLowerCase().contains(state.searchQuery));
      }).toList();
    }

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
