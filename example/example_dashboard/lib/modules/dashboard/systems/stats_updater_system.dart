import 'package:nexus/nexus.dart';
import 'package:example_dashboard/services/mock_api_service.dart';
import 'package:example_dashboard/shared/components/tags.dart';
import 'package:example_dashboard/modules/dashboard/components/stats_card_component.dart';

/// یک رویداد داخلی برای فعال کردن به‌روزرسانی کارت‌های آمار.
class _UpdateStatsEvent {}

/// این سیستم مسئول به‌روزرسانی دوره‌ای داده‌های کارت‌های آمار است.
class StatsUpdaterSystem extends System {
  late final MockApiService _apiService;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    _apiService = services.get<MockApiService>();

    // یک تایمر ایجاد می‌کنیم که هر 3 ثانیه یک بار رویداد به‌روزرسانی را ارسال کند.
    final timerEntity = Entity();
    world.addEntity(timerEntity);
    timerEntity.add(TimerComponent([
      TimerTask(
        id: 'stats-updater',
        duration: 3,
        repeats: true,
        onTickEvent: _UpdateStatsEvent(),
      )
    ]));

    // به رویداد تایمر گوش می‌دهیم.
    listen<_UpdateStatsEvent>((event) => _fetchUpdates());
  }

  /// تمام کارت‌های آمار را پیدا کرده و برای هر کدام یک درخواست API جدید ثبت می‌کند.
  void _fetchUpdates() {
    final statsCards = world.entities.values.where((e) =>
        e.get<TagsComponent>()?.hasTag(DashboardTags.statsCard) ?? false);

    for (final card in statsCards) {
      final cardData = card.get<StatsCardComponent>();
      if (cardData == null) continue;

      // یک کامپوننت درخواست جدید اضافه می‌کنیم تا ApiSystem آن را پردازش کند.
      card.add(
        ApiRequestComponent(
          url: '/stats/${cardData.title.toLowerCase()}',
          onParse: (json) {
            // پاسخ شبیه‌سازی شده را به یک کامپوننت جدید تبدیل می‌کنیم.
            return [
              StatsCardComponent(
                title: cardData.title,
                value: json['value'] as String,
                iconData: cardData.iconData,
                trend: Trend.values[json['trend_index'] as int],
              ),
            ];
          },
        ),
      );
    }
  }
}
