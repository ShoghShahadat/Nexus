import 'dart:async';
import 'package:nexus/nexus.dart';
import 'package:example_dashboard/modules/dashboard/components/stats_card_component.dart';
import 'package:example_dashboard/services/mock_api_service.dart';
import 'package:example_dashboard/shared/components/tags.dart';

/// سیستمی که به صورت دوره‌ای آمار کارت‌ها را با داده‌های جدید به‌روزرسانی می‌کند.
/// این سیستم نقش یک سرویس پس‌زمینه را شبیه‌سازی می‌کند.
class StatsUpdaterSystem extends UpdateSystem {
  late final MockApiService _api;
  Timer? _timer;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    _api = services.get<MockApiService>();
    // یک تایمر برای به‌روزرسانی داده‌ها هر ۳ ثانیه یک‌بار تنظیم می‌کنیم.
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _updateStats());
  }

  @override
  void onRemovedFromWorld() {
    _timer?.cancel();
    super.onRemovedFromWorld();
  }

  /// متد اصلی برای دریافت داده‌های جدید و آپدیت کردن Entityها.
  void _updateStats() async {
    for (final entity in matchedEntities) {
      final currentStats = entity.get<StatsCardComponent>()!;
      // دریافت داده جدید از سرویس شبیه‌سازی شده
      final newStats = await _api.fetchUpdatedStats(currentStats.title);

      // ایجاد یک کامپوننت جدید با داده‌های به‌روز شده
      final updatedComponent = StatsCardComponent(
        title: currentStats.title,
        value: newStats.value,
        trend: newStats.trend,
        iconCodePoint: currentStats.iconCodePoint,
        colorValue: currentStats.colorValue,
      );

      // اضافه کردن کامپوننت جدید به Entity.
      // این کار به صورت خودکار باعث ارسال ComponentUpdate به ترد UI و
      // بازسازی ویجت مربوطه توسط EntityBuilder می‌شود.
      entity.add(updatedComponent);
    }
  }

  @override
  bool matches(Entity entity) {
    // این سیستم فقط روی Entityهایی کار می‌کند که تگ کارت آمار را دارند.
    return entity.get<TagsComponent>()?.hasTag(DashboardTags.statsCard) ??
        false;
  }

  @override
  void update(Entity entity, double dt) {
    // منطق اصلی در تایمر اجرا می‌شود، بنابراین این متد خالی است.
  }
}
