import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:example_dashboard/modules/dashboard/components/stats_card_component.dart';
import 'package:example_dashboard/shared/components/tags.dart';

/// این کلاس مسئولیت ساخت Entityهای مربوط به کارت‌های آمار را دارد.
class StatsCardAssembler {
  final NexusWorld world;

  StatsCardAssembler(this.world);

  /// لیستی از Entityهای کارت آمار را با داده‌های اولیه ایجاد می‌کند.
  List<Entity> assemble() {
    return [
      _createCard(
        title: 'Revenue',
        value: '1,250,000',
        icon: Icons.attach_money,
        trend: Trend.up,
        color: Colors.green,
      ),
      _createCard(
        title: 'Users',
        value: '3,420',
        icon: Icons.people_outline,
        trend: Trend.up,
        color: Colors.blue,
      ),
      _createCard(
        title: 'Orders',
        value: '1,890',
        icon: Icons.shopping_cart_outlined,
        trend: Trend.down,
        color: Colors.orange,
      ),
      _createCard(
        title: 'Engagement',
        value: '78.5%',
        icon: Icons.favorite_border,
        trend: Trend.neutral,
        color: Colors.red,
      ),
    ];
  }

  /// یک متد کمکی برای ساخت یک Entity کارت آمار.
  Entity _createCard({
    required String title,
    required String value,
    required IconData icon,
    required Trend trend,
    required Color color,
  }) {
    final entity = Entity()
      ..add(StatsCardComponent(
        title: title,
        value: value,
        iconCodePoint: icon.codePoint,
        trend: trend,
        // FIX: Removed deprecated '.value' property.
        // اصلاح: پراپرتی منسوخ شده '.value' حذف شد.
        colorValue: color.value,
      ))
      ..add(TagsComponent({DashboardTags.statsCard}));
    return entity;
  }
}
