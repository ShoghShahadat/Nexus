import 'package:nexus/nexus.dart';

/// An event to apply or update the filter criteria for a specific list.
/// رویدادی برای اعمال یا به‌روزرسانی معیارهای فیلتر برای یک لیست خاص.
class UpdateListFilterEvent {
  final String listId;
  final Map<String, dynamic> filterCriteria;

  UpdateListFilterEvent({required this.listId, required this.filterCriteria});
}

/// An event to change the sorting order of a specific list.
/// رویدادی برای تغییر ترتیب مرتب‌سازی یک لیست خاص.
class UpdateListSortEvent {
  final String listId;
  final String sortByField;
  final bool isAscending;

  UpdateListSortEvent({
    required this.listId,
    required this.sortByField,
    this.isAscending = true,
  });
}

/// An event to update the search query for a specific list.
/// رویدادی برای به‌روزرسانی عبارت جستجو برای یک لیست خاص.
class UpdateListSearchEvent {
  final String listId;
  final String query;

  UpdateListSearchEvent({required this.listId, required this.query});
}

/// An event fired after a drag-and-drop operation to reorder an item.
/// رویدادی که پس از عملیات کشیدن و رها کردن برای جابجایی یک آیتم ارسال می‌شود.
class ReorderListItemEvent {
  final String listId;
  final EntityId itemId;
  final int newIndex;

  ReorderListItemEvent({
    required this.listId,
    required this.itemId,
    required this.newIndex,
  });
}

/// An event fired when a swipe action is performed on a list item.
/// رویدادی که هنگام انجام یک عمل سوایپ روی یک آیتم لیست ارسال می‌شود.
class SwipeActionEvent {
  final EntityId itemId;
  final String action; // e.g., 'delete', 'archive'

  SwipeActionEvent({required this.itemId, required this.action});
}

/// An internal event fired by a system to notify the ListStateSystem that an
/// item has been permanently removed and should be purged from the list's state.
/// یک رویداد داخلی که توسط یک سیستم ارسال می‌شود تا به ListStateSystem اطلاع دهد
/// که یک آیتم به طور دائم حذف شده و باید از وضعیت لیست پاک شود.
class PurgeListItemEvent {
  final EntityId itemId;

  PurgeListItemEvent(this.itemId);
}
