import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:example_dashboard/shared/components/tags.dart';
import 'package:example_dashboard/modules/dashboard/components/stats_card_component.dart';

/// مسئول ایجاد موجودیت‌های کارت‌های آمار.
class StatsCardAssembler extends EntityAssembler {
  StatsCardAssembler(super.world, super.context);

  @override
  List<Entity> assemble() {
    final cardsData = [
      (title: 'Revenue', value: '\$12,450', icon: Icons.attach_money_rounded),
      (title: 'Users', value: '1,250', icon: Icons.people_alt_rounded),
      (title: 'Orders', value: '4,820', icon: Icons.shopping_cart_rounded),
      (title: 'Engagement', value: '64.8%', icon: Icons.insights_rounded),
    ];

    final entities = <Entity>[];
    for (final data in cardsData) {
      final entity = Entity();
      world.addEntity(entity);

      entity.add(TagsComponent({DashboardTags.statsCard}));
      entity.add(StatsCardComponent(
        title: data.title,
        value: data.value,
        iconData: data.icon.codePoint,
        trend: Trend.stable,
      ));
      entity.add(ApiStatusComponent(status: ApiStatus.idle));
      entities.add(entity);
    }
    return entities;
  }
}
