import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:example_dashboard/modules/dashboard/components/stats_card_component.dart';
import 'package:example_dashboard/shared/components/tags.dart';
import 'package:example_dashboard/services/mock_api_service.dart';

/// Assembler برای ایجاد موجودیت‌های مربوط به کارت‌های آمار.
class StatsCardAssembler extends EntityAssembler<EntityId> {
  final MockApiService _apiService = MockApiService();

  StatsCardAssembler(NexusWorld world, EntityId context)
      : super(world, context);

  @override
  List<Entity> assemble() {
    final container = Entity()
      ..add(TagsComponent({DashboardTags.statsCardContainer}))
      ..add(ParentComponent(context));

    world.addEntity(container);

    final cardsData = [
      {
        'title': 'Revenue',
        'icon': Icons.attach_money,
        'color': Colors.green.value
      },
      {
        'title': 'Users',
        'icon': Icons.people_outline,
        'color': Colors.blue.value
      },
      {
        'title': 'Engagement',
        'icon': Icons.favorite_border,
        'color': Colors.red.value
      },
      {
        'title': 'Sales',
        'icon': Icons.shopping_cart_outlined,
        'color': Colors.orange.value
      },
    ];

    final cardEntities = cardsData.map((data) {
      final cardEntity = Entity()
        ..add(TagsComponent({DashboardTags.statsCard}))
        ..add(ParentComponent(container.id))
        ..add(StatsCardComponent(
          title: data['title'] as String,
          value: 'Loading...',
          trend: Trend.up,
          icon: data['icon'] as IconData,
          iconColorValue: data['color'] as int,
        ))
        // کامپوننت درخواست API برای به‌روزرسانی داده‌ها
        ..add(ApiRequestComponent(
          url: '/api/stats/${data['title']}',
          onParse: (json) {
            return [
              StatsCardComponent(
                title: data['title'] as String,
                value: json['value'] as String,
                trend: Trend.values[json['trend_index'] as int],
                icon: data['icon'] as IconData,
                iconColorValue: data['color'] as int,
              )
            ];
          },
        ));

      world.addEntity(cardEntity);
      return cardEntity;
    }).toList();

    // کامپوننت فرزندان را به کانتینر اضافه می‌کنیم
    container.add(ChildrenComponent(cardEntities.map((e) => e.id).toList()));

    return [container, ...cardEntities];
  }
}
