import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:example_dashboard/modules/dashboard/widgets/header_widget.dart';
import 'package:example_dashboard/modules/dashboard/widgets/cards/stats_card_widget.dart';
import 'package:example_dashboard/shared/components/tags.dart';

/// ویجت اصلی که صفحه داشبورد را رندر می‌کند.
/// REFACTORED: This scene now builds its layout based on a single 'root' entity,
/// which is a more robust and scalable ECS pattern.
/// بازآفرینی: این صفحه اکنون لایوت خود را بر اساس یک Entity ریشه واحد می‌سازد
/// که یک الگوی ECS قوی‌تر و مقیاس‌پذیرتر است.
class DashboardScene extends StatelessWidget {
  const DashboardScene({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // EntityBuilder به دنبال Entity ریشه می‌گردد تا ساختار کلی صفحه را بسازد.
        child: EntityBuilder<ChildrenComponent>(
          entityId:
              NexusScope.cacheOf(context).findEntityByTag(DashboardTags.root),
          loadingBuilder: (context) =>
              const Center(child: CircularProgressIndicator()),
          builder: (context, rootChildren) {
            // ID های هدر و کانتینر کارت‌ها از Entity ریشه خوانده می‌شود.
            final headerId = rootChildren.children[0];
            final cardContainerId = rootChildren.children[1];

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HeaderWidget(entityId: headerId),
                  const SizedBox(height: 24),
                  Expanded(
                    child: EntityBuilder<ChildrenComponent>(
                      entityId: cardContainerId,
                      builder: (context, cardContainerChildren) {
                        return GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200,
                            childAspectRatio: 3 / 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: cardContainerChildren.children.length,
                          itemBuilder: (context, index) {
                            final entityId =
                                cardContainerChildren.children[index];
                            return StatsCardWidget(entityId: entityId);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// یک متد کمکی برای یافتن EntityId بر اساس تگ از طریق ComponentCache.
/// این یک پیاده‌سازی موقت برای دمو است.
extension EntityFinder on ComponentCache {
  EntityId findEntityByTag(String tag) {
    // HACK: This is a workaround for the demo because the cache doesn't
    // expose a direct way to query entities. In a real app, you might have
    // a singleton entity or a more sophisticated lookup mechanism.
    for (var i = 0; i < 200; i++) {
      // Search a reasonable range of IDs
      try {
        final tagsComponent = get<TagsComponent>(i);
        if (tagsComponent?.hasTag(tag) ?? false) {
          return i;
        }
      } catch (_) {
        // Ignore errors for non-existent entities
      }
    }
    throw Exception('Entity with tag "$tag" not found!');
  }
}
