import 'package:nexus/nexus.dart';

// --- List Manager Components ---

/// A component that defines the core structure of a list.
/// کامپوننتی که ساختار اصلی یک لیست را تعریف می‌کند.
class ListComponent extends Component with SerializableComponent {
  /// A unique identifier for this list, used by events to target it.
  /// یک شناسه یکتا برای این لیست که توسط رویدادها برای هدف قرار دادن آن استفاده می‌شود.
  final String listId;

  /// The complete, unfiltered, and unsorted list of all item entity IDs.
  /// لیست کامل، فیلتر نشده و مرتب نشده از شناسه‌های تمام آیتم‌ها.
  final List<EntityId> allItems;

  /// The list of item entity IDs that should be rendered after filtering,
  /// sorting, and searching. This list is managed by the `ListStateSystem`.
  /// لیست شناسه‌هایی که پس از پردازش باید رندر شوند. این لیست توسط `ListStateSystem` مدیریت می‌شود.
  final List<EntityId> visibleItems;

  ListComponent({
    required this.listId,
    List<EntityId>? allItems,
    List<EntityId>? visibleItems,
  })  : allItems = allItems ?? [],
        visibleItems = visibleItems ?? [];

  factory ListComponent.fromJson(Map<String, dynamic> json) {
    return ListComponent(
      listId: json['listId'] as String,
      allItems: (json['allItems'] as List).cast<EntityId>(),
      visibleItems: (json['visibleItems'] as List).cast<EntityId>(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'listId': listId,
        'allItems': allItems,
        'visibleItems': visibleItems,
      };

  @override
  List<Object?> get props => [listId, allItems, visibleItems];
}

/// A component that holds the current state of list manipulations like
/// filtering, sorting, and searching.
/// کامپوننتی که وضعیت فعلی دستکاری‌های لیست مانند فیلتر، مرتب‌سازی و جستجو را نگهداری می‌کند.
class ListStateComponent extends Component with SerializableComponent {
  final Map<String, dynamic> filterCriteria;
  final String? sortByField;
  final bool isAscending;
  final String searchQuery;

  ListStateComponent({
    Map<String, dynamic>? filterCriteria,
    this.sortByField,
    this.isAscending = true,
    this.searchQuery = '',
  }) : filterCriteria = filterCriteria ?? {};

  factory ListStateComponent.fromJson(Map<String, dynamic> json) {
    return ListStateComponent(
      filterCriteria: json['filterCriteria'] as Map<String, dynamic>,
      sortByField: json['sortByField'] as String?,
      isAscending: json['isAscending'] as bool,
      searchQuery: json['searchQuery'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'filterCriteria': filterCriteria,
        'sortByField': sortByField,
        'isAscending': isAscending,
        'searchQuery': searchQuery,
      };

  @override
  List<Object?> get props =>
      [filterCriteria, sortByField, isAscending, searchQuery];
}

// --- List Item Components ---

/// A marker component that triggers an exit animation for a list item.
/// یک کامپوننت نشانگر که انیمیشن خروج را برای یک آیتم لیست فعال می‌کند.
///
/// When this component is added to an entity, the `ListItemAnimationSystem`
/// will create an animation. Upon completion, the entity will be removed.
/// وقتی این کامپوننت به یک موجودیت اضافه می‌شود، `ListItemAnimationSystem` یک
/// انیمیشن ایجاد می‌کند. پس از اتمام، موجودیت حذف خواهد شد.
class AnimateOutComponent extends Component with SerializableComponent {
  AnimateOutComponent();

  factory AnimateOutComponent.fromJson(Map<String, dynamic> json) =>
      AnimateOutComponent();

  @override
  Map<String, dynamic> toJson() => {};

  @override
  List<Object?> get props => [];
}
