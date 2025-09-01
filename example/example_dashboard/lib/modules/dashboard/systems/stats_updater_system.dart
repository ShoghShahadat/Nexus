import 'dart:async';
import 'package:nexus/nexus.dart';
import 'package:example_dashboard/services/mock_api_service.dart';
import 'package:example_dashboard/modules/dashboard/components/stats_card_component.dart';

/// سیستمی که به صورت دوره‌ای آمار کارت‌ها را به‌روزرسانی می‌کند.
class StatsUpdaterSystem extends UpdateSystem {
  late final MockApiService _apiService;
  final Map<EntityId, Timer> _timers = {};

  /// در این متد، ما با اطمینان به سرویس ثبت‌شده دسترسی پیدا می‌کنیم.
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    // This call will now succeed because the service was registered in the module's onLoad.
    // این فراخوانی اکنون موفقیت‌آمیز خواهد بود زیرا سرویس در onLoad ماژول ثبت شده است.
    _apiService = services.get<MockApiService>();
  }

  @override
  bool matches(Entity entity) {
    // این سیستم روی تمام موجودیت‌هایی که کامپوننت کارت آمار را دارند، عمل می‌کند.
    return entity.has<StatsCardComponent>();
  }

  @override
  void onEntityAdded(Entity entity) {
    super.onEntityAdded(entity);
    // برای هر کارت جدید، یک تایمر برای به‌روزرسانی دوره‌ای ایجاد می‌کنیم.
    _startTimerForEntity(entity);
  }

  @override
  void onEntityRemoved(Entity entity) {
    // هنگام حذف یک کارت، تایمر مربوط به آن را نیز متوقف و حذف می‌کنیم.
    _timers[entity.id]?.cancel();
    _timers.remove(entity.id);
    super.onEntityRemoved(entity);
  }

  void _startTimerForEntity(Entity entity) {
    // هر 5 ثانیه یک‌بار آمار را به‌روز کن.
    _timers[entity.id] = Timer.periodic(const Duration(seconds: 5), (_) {
      _updateStats(entity);
    });
    // بلافاصله پس از اضافه شدن نیز یک‌بار به‌روز کن.
    _updateStats(entity);
  }

  Future<void> _updateStats(Entity entity) async {
    final card = entity.get<StatsCardComponent>();
    if (card == null || card.isLoading) return;

    // وضعیت لودینگ را فعال می‌کنیم.
    entity.add(card.copyWith(isLoading: true));

    final newStats = await _apiService.fetchUpdatedStats(card.title);

    // پس از دریافت داده‌های جدید، کامپوننت را با اطلاعات جدید به‌روز می‌کنیم.
    final currentCard = entity.get<StatsCardComponent>();
    if (currentCard != null) {
      entity.add(currentCard.copyWith(
        value: newStats.value,
        trend: newStats.trend,
        isLoading: false,
      ));
    }
  }

  @override
  void update(Entity entity, double dt) {
    // منطق اصلی این سیستم مبتنی بر تایمر است و نیازی به اجرای کد در حلقه update ندارد.
  }
}
