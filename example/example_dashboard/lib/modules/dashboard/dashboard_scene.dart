import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:example_dashboard/shared/components/tags.dart';
import 'package:example_dashboard/modules/dashboard/components/stats_card_component.dart';

/// ویجت اصلی که صحنه داشبورد را رندر می‌کند.
class DashboardScene extends StatelessWidget {
  const DashboardScene({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          // با استفاده از EntityBuilder، تنها در صورت تغییر کامپوننت ChildrenComponent ریشه،
          // این بخش بازسازی (rebuild) می‌شود.
          child: EntityBuilder<ChildrenComponent>(
            entityId: 0, // ID موجودیت ریشه همیشه 0 است.
            loadingBuilder: (context) =>
                const Center(child: CircularProgressIndicator()),
            builder: (context, childrenComponent) {
              final childrenIds = childrenComponent.children;
              final headerId = childrenIds.firstWhere((id) =>
                  NexusScope.cacheOf(context)
                      .get<TagsComponent>(id)
                      ?.hasTag(DashboardTags.header) ??
                  false);
              final cardIds = childrenIds
                  .where((id) =>
                      NexusScope.cacheOf(context)
                          .get<TagsComponent>(id)
                          ?.hasTag(DashboardTags.statsCard) ??
                      false)
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // رندر هدر
                  _HeaderWidget(entityId: headerId),
                  const SizedBox(height: 20),
                  // رندر کارت‌های آمار در یک گرید واکنش‌گرا
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 400,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 2.2,
                      ),
                      itemCount: cardIds.length,
                      itemBuilder: (context, index) {
                        return _StatsCardWidget(entityId: cardIds[index]);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// ویجت برای نمایش هدر.
class _HeaderWidget extends StatelessWidget {
  final EntityId entityId;
  const _HeaderWidget({required this.entityId});

  @override
  Widget build(BuildContext context) {
    return EntityBuilder<CustomWidgetComponent>(
      entityId: entityId,
      builder: (context, component) {
        final theme = Theme.of(context).textTheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(component.properties['title'] ?? 'Dashboard',
                style: theme.headlineMedium),
            Text(component.properties['subtitle'] ?? '',
                style: theme.titleLarge),
          ],
        );
      },
    );
  }
}

/// ویجت برای نمایش یک کارت آمار.
class _StatsCardWidget extends StatelessWidget {
  final EntityId entityId;
  const _StatsCardWidget({required this.entityId});

  @override
  Widget build(BuildContext context) {
    // این ویجت به تغییرات StatsCardComponent گوش می‌دهد و تنها در صورت نیاز بازسازی می‌شود.
    return EntityBuilder<StatsCardComponent>(
      entityId: entityId,
      builder: (context, card) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        IconData trendIcon;
        Color trendColor;
        switch (card.trend) {
          case Trend.up:
            trendIcon = Icons.arrow_upward;
            trendColor = Colors.green;
            break;
          case Trend.down:
            trendIcon = Icons.arrow_downward;
            trendColor = Colors.red;
            break;
          case Trend.stable:
            trendIcon = Icons.remove;
            trendColor = Colors.grey;
            break;
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colorScheme.primary.withOpacity(0.1),
                  child: Icon(
                      IconData(card.iconData, fontFamily: 'MaterialIcons'),
                      color: colorScheme.primary,
                      size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card.title, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      if (card.isLoading)
                        const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2))
                      else
                        Text(card.value, style: theme.textTheme.headlineSmall),
                    ],
                  ),
                ),
                Icon(trendIcon, color: trendColor, size: 28),
              ],
            ),
          ),
        );
      },
    );
  }
}
