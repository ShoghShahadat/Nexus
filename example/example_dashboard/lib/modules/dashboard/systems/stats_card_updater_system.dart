import 'package:nexus/nexus.dart';
import 'package:example_dashboard/modules/dashboard/components/stats_card_component.dart';
import 'package:example_dashboard/shared/components/tags.dart';

/// سیستمی که به صورت دوره‌ای درخواست آپدیت برای کارت‌های آمار ارسال می‌کند.
class StatsCardUpdaterSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    // به رویداد سفارشی برای فعال کردن به‌روزرسانی‌ها گوش می‌دهیم
    listen<_RequestUpdateEvent>(_onRequestUpdate);

    // تنظیمات اولیه: تمام کارت‌های آمار را پیدا کرده و برایشان تایمر ایجاد می‌کنیم
    final statCards = world.entities.values.where((e) =>
        e.get<TagsComponent>()?.hasTag(DashboardTags.statsCard) ?? false);

    for (final entity in statCards) {
      final cardComp = entity.get<StatsCardComponent>();
      if (cardComp != null) {
        // برای هر کارت یک تایمر تکرارشونده ایجاد می‌کنیم
        entity.add(TimerComponent([
          TimerTask(
            id: 'update_timer_${entity.id}',
            duration: 5.0, // هر 5 ثانیه
            repeats: true,
            // وقتی تایمر یک چرخه را کامل می‌کند، رویداد سفارشی ما را شلیک می‌کند
            onCompleteEvent: _RequestUpdateEvent(entity.id, cardComp.title),
          )
        ]));
      }
    }
  }

  /// رویداد درخواست به‌روزرسانی که توسط TimerSystem شلیک می‌شود را مدیریت می‌کند.
  void _onRequestUpdate(_RequestUpdateEvent event) {
    final entity = world.entities[event.entityId];
    if (entity == null) return;

    // یک ApiRequestComponent برای واکشی داده‌های جدید اضافه می‌کنیم
    entity.add(ApiRequestComponent(
      url: '/api/stats/${event.title}',
      onParse: (json) {
        final cardComp = entity.get<StatsCardComponent>();
        if (cardComp == null) return []; // نباید اتفاق بیفتد

        // از متد قدرتمند `copyWith` برای یک به‌روزرسانی تمیز،
        // غیرقابل تغییر و بدون خطا استفاده می‌شود. این روش بسیار امن‌تر از
        // ساخت مجدد کامپوننت از ابتدا است.
        return [
          cardComp.copyWith({
            'value': json['value'],
            'trend_index': json['trend_index'],
          })
        ];
      },
    ));
  }
}

// یک رویداد خصوصی و داخلی که برای ارتباط بین TimerSystem و این سیستم استفاده می‌شود.
class _RequestUpdateEvent {
  final EntityId entityId;
  final String title;

  _RequestUpdateEvent(this.entityId, this.title);
}
